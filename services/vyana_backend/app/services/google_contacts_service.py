"""
Google Contacts Service using People API
Replaces local JSON storage with Google Contacts sync
"""
import logging
from typing import List, Dict, Optional
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from app.services.google_oauth import oauth_service

logger = logging.getLogger(__name__)


class GoogleContactsService:
    """
    Google Contacts Service - Uses Google People API
    Syncs contacts with user's Google account
    """
    
    def __init__(self):
        logger.info("GoogleContactsService initialized")
    
    def _get_service(self):
        """Get authenticated People API service"""
        creds = oauth_service.get_credentials()
        if not creds:
            return None
        return build('people', 'v1', credentials=creds)
    
    def _parse_contact(self, person: dict) -> Dict:
        """Parse Google People API person to contact dict"""
        resource_name = person.get('resourceName', '')
        contact_id = resource_name.replace('people/', '') if resource_name else ''
        
        # Get name
        names = person.get('names', [])
        name = names[0].get('displayName', '') if names else ''
        
        # Get email
        emails = person.get('emailAddresses', [])
        email = emails[0].get('value', '') if emails else None
        
        # Get phone
        phones = person.get('phoneNumbers', [])
        phone = phones[0].get('value', '') if phones else None
        
        # Get organization/company
        orgs = person.get('organizations', [])
        company = orgs[0].get('name', '') if orgs else None
        
        # Get notes/biography
        bios = person.get('biographies', [])
        notes = bios[0].get('value', '') if bios else None
        
        # Check if starred (favorite)
        memberships = person.get('memberships', [])
        is_favorite = any(
            m.get('contactGroupMembership', {}).get('contactGroupResourceName') == 'contactGroups/starred'
            for m in memberships
        )
        
        return {
            'id': contact_id,
            'name': name,
            'email': email,
            'phone': phone,
            'company': company,
            'notes': notes,
            'is_favorite': is_favorite,
            'resource_name': resource_name,
        }

    def get_all_contacts(self, favorites_only: bool = False) -> List[Dict]:
        """Get all contacts from Google"""
        try:
            service = self._get_service()
            if not service:
                logger.warning("Google not connected")
                return []
            
            contacts = []
            page_token = None
            
            while True:
                results = service.people().connections().list(
                    resourceName='people/me',
                    pageSize=100,
                    personFields='names,emailAddresses,phoneNumbers,organizations,biographies,memberships',
                    pageToken=page_token
                ).execute()
                
                connections = results.get('connections', [])
                for person in connections:
                    contact = self._parse_contact(person)
                    if contact['name']:  # Only include contacts with names
                        if favorites_only and not contact['is_favorite']:
                            continue
                        contacts.append(contact)
                
                page_token = results.get('nextPageToken')
                if not page_token:
                    break
            
            # Sort by name
            contacts.sort(key=lambda x: x.get('name', '').lower())
            return contacts
            
        except HttpError as e:
            logger.error(f"Google API error: {e}")
            return []
        except Exception as e:
            logger.error(f"Error getting contacts: {e}")
            return []

    def search_contacts(self, query: str) -> List[Dict]:
        """Search contacts by name, email, or phone"""
        try:
            service = self._get_service()
            if not service:
                return []
            
            # Use People API search
            results = service.people().searchContacts(
                query=query,
                readMask='names,emailAddresses,phoneNumbers,organizations,biographies,memberships',
                pageSize=20
            ).execute()
            
            contacts = []
            for result in results.get('results', []):
                person = result.get('person', {})
                contact = self._parse_contact(person)
                if contact['name']:
                    contacts.append(contact)
            
            return contacts
            
        except HttpError as e:
            logger.error(f"Google API search error: {e}")
            # Fallback to local search
            all_contacts = self.get_all_contacts()
            query_lower = query.lower()
            return [c for c in all_contacts if 
                    query_lower in (c.get('name') or '').lower() or
                    query_lower in (c.get('email') or '').lower() or
                    query_lower in (c.get('phone') or '').lower()]
        except Exception as e:
            logger.error(f"Error searching contacts: {e}")
            return []

    def get_contact(self, contact_id: str) -> Optional[Dict]:
        """Get a single contact by ID"""
        try:
            service = self._get_service()
            if not service:
                return None
            
            resource_name = f'people/{contact_id}'
            person = service.people().get(
                resourceName=resource_name,
                personFields='names,emailAddresses,phoneNumbers,organizations,biographies,memberships'
            ).execute()
            
            return self._parse_contact(person)
            
        except HttpError as e:
            logger.error(f"Google API error getting contact: {e}")
            return None
        except Exception as e:
            logger.error(f"Error getting contact: {e}")
            return None

    def add_contact(self, name: str, email: str = None, phone: str = None,
                    company: str = None, notes: str = None,
                    is_favorite: bool = False) -> Dict:
        """Create a new contact in Google"""
        try:
            service = self._get_service()
            if not service:
                return {"success": False, "error": "Google not connected. Please connect in Settings."}
            
            # Build contact body
            body = {
                'names': [{'givenName': name}],
            }
            
            if email:
                body['emailAddresses'] = [{'value': email}]
            if phone:
                body['phoneNumbers'] = [{'value': phone}]
            if company:
                body['organizations'] = [{'name': company}]
            if notes:
                body['biographies'] = [{'value': notes}]
            
            # Create contact
            person = service.people().createContact(body=body).execute()
            
            # Add to starred if favorite
            if is_favorite:
                resource_name = person.get('resourceName')
                try:
                    service.contactGroups().members().modify(
                        resourceName='contactGroups/starred',
                        body={'resourceNamesToAdd': [resource_name]}
                    ).execute()
                except Exception as e:
                    logger.warning(f"Could not add to starred: {e}")
            
            contact = self._parse_contact(person)
            return {"success": True, "contact": contact, "message": f"Added contact {name}"}
            
        except HttpError as e:
            logger.error(f"Google API error creating contact: {e}")
            return {"success": False, "error": str(e)}
        except Exception as e:
            logger.error(f"Error creating contact: {e}")
            return {"success": False, "error": str(e)}

    def update_contact(self, contact_id: str, name: str = None, email: str = None,
                       phone: str = None, company: str = None, notes: str = None,
                       is_favorite: bool = None) -> Dict:
        """Update an existing contact"""
        try:
            service = self._get_service()
            if not service:
                return {"success": False, "error": "Google not connected"}
            
            resource_name = f'people/{contact_id}'
            
            # Get current contact
            current = service.people().get(
                resourceName=resource_name,
                personFields='names,emailAddresses,phoneNumbers,organizations,biographies,memberships,metadata'
            ).execute()
            
            # Build update body
            update_fields = []
            body = {}
            
            if name is not None:
                body['names'] = [{'givenName': name}]
                update_fields.append('names')
            
            if email is not None:
                body['emailAddresses'] = [{'value': email}] if email else []
                update_fields.append('emailAddresses')
            
            if phone is not None:
                body['phoneNumbers'] = [{'value': phone}] if phone else []
                update_fields.append('phoneNumbers')
            
            if company is not None:
                body['organizations'] = [{'name': company}] if company else []
                update_fields.append('organizations')
            
            if notes is not None:
                body['biographies'] = [{'value': notes}] if notes else []
                update_fields.append('biographies')
            
            body['etag'] = current.get('etag')
            
            # Update contact
            if update_fields:
                person = service.people().updateContact(
                    resourceName=resource_name,
                    updatePersonFields=','.join(update_fields),
                    body=body
                ).execute()
            else:
                person = current
            
            # Handle favorite status
            if is_favorite is not None:
                try:
                    if is_favorite:
                        service.contactGroups().members().modify(
                            resourceName='contactGroups/starred',
                            body={'resourceNamesToAdd': [resource_name]}
                        ).execute()
                    else:
                        service.contactGroups().members().modify(
                            resourceName='contactGroups/starred',
                            body={'resourceNamesToRemove': [resource_name]}
                        ).execute()
                except Exception as e:
                    logger.warning(f"Could not update starred status: {e}")
            
            contact = self._parse_contact(person)
            return {"success": True, "contact": contact, "message": "Contact updated"}
            
        except HttpError as e:
            logger.error(f"Google API error updating contact: {e}")
            return {"success": False, "error": str(e)}
        except Exception as e:
            logger.error(f"Error updating contact: {e}")
            return {"success": False, "error": str(e)}

    def delete_contact(self, contact_id: str) -> Dict:
        """Delete a contact"""
        try:
            service = self._get_service()
            if not service:
                return {"success": False, "error": "Google not connected"}
            
            resource_name = f'people/{contact_id}'
            service.people().deleteContact(resourceName=resource_name).execute()
            
            return {"success": True, "message": "Contact deleted"}
            
        except HttpError as e:
            logger.error(f"Google API error deleting contact: {e}")
            return {"success": False, "error": str(e)}
        except Exception as e:
            logger.error(f"Error deleting contact: {e}")
            return {"success": False, "error": str(e)}

    def toggle_favorite(self, contact_id: str) -> Dict:
        """Toggle favorite (starred) status"""
        try:
            service = self._get_service()
            if not service:
                return {"success": False, "error": "Google not connected"}
            
            resource_name = f'people/{contact_id}'
            
            # Get current contact to check starred status
            person = service.people().get(
                resourceName=resource_name,
                personFields='memberships'
            ).execute()
            
            memberships = person.get('memberships', [])
            is_starred = any(
                m.get('contactGroupMembership', {}).get('contactGroupResourceName') == 'contactGroups/starred'
                for m in memberships
            )
            
            # Toggle starred
            if is_starred:
                service.contactGroups().members().modify(
                    resourceName='contactGroups/starred',
                    body={'resourceNamesToRemove': [resource_name]}
                ).execute()
                return {"success": True, "is_favorite": False}
            else:
                service.contactGroups().members().modify(
                    resourceName='contactGroups/starred',
                    body={'resourceNamesToAdd': [resource_name]}
                ).execute()
                return {"success": True, "is_favorite": True}
            
        except HttpError as e:
            logger.error(f"Google API error toggling favorite: {e}")
            return {"success": False, "error": str(e)}
        except Exception as e:
            logger.error(f"Error toggling favorite: {e}")
            return {"success": False, "error": str(e)}

    # AI Tool methods (for groq_client)
    def get_email_address(self, name: str) -> str:
        """Find email address for a name - for AI tool use"""
        try:
            contacts = self.search_contacts(name)
            if contacts:
                contact = contacts[0]
                if contact.get('email'):
                    return f"{contact['email']} (found: {contact['name']})"
            return f"Contact '{name}' not found."
        except Exception as e:
            return f"Error finding contact: {str(e)}"

    def get_phone_number(self, name: str) -> str:
        """Find phone number for a name - for AI tool use"""
        try:
            contacts = self.search_contacts(name)
            if contacts:
                contact = contacts[0]
                if contact.get('phone'):
                    return f"{contact['phone']} (found: {contact['name']})"
            return f"Phone number for '{name}' not found."
        except Exception as e:
            return f"Error finding phone: {str(e)}"

    def list_contacts(self) -> str:
        """List all contacts - for AI tool use"""
        try:
            contacts = self.get_all_contacts()
            
            if not contacts:
                return "No contacts found. Make sure Google is connected in Settings."
            
            lines = []
            for c in contacts[:20]:  # Limit to 20 for AI context
                parts = [f"- {c['name']}"]
                if c.get('email'):
                    parts.append(f"email: {c['email']}")
                if c.get('phone'):
                    parts.append(f"phone: {c['phone']}")
                lines.append(", ".join(parts))
            
            if len(contacts) > 20:
                lines.append(f"... and {len(contacts) - 20} more contacts")
            
            return "\n".join(lines)
        except Exception as e:
            return f"Error listing contacts: {str(e)}"


# Singleton instance
google_contacts_service = GoogleContactsService()
