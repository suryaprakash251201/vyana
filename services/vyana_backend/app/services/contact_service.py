import logging
import json
import os
import uuid
from typing import List, Dict, Optional
from datetime import datetime
from pathlib import Path

logger = logging.getLogger(__name__)

# Storage path for contacts
STORAGE_DIR = Path(__file__).parent.parent / "storage"
CONTACTS_FILE = STORAGE_DIR / "contacts.json"


class ContactService:
    """
    Contact Service - Local JSON file storage (no Supabase required)
    A self-hosted Google Contacts replacement
    """
    
    def __init__(self):
        logger.info("ContactService (Local JSON) initialized")
        self._ensure_storage()
    
    def _ensure_storage(self):
        """Ensure storage directory and file exist"""
        STORAGE_DIR.mkdir(parents=True, exist_ok=True)
        if not CONTACTS_FILE.exists():
            self._save_contacts([])
    
    def _load_contacts(self) -> List[Dict]:
        """Load contacts from JSON file"""
        try:
            if CONTACTS_FILE.exists():
                with open(CONTACTS_FILE, 'r', encoding='utf-8') as f:
                    return json.load(f)
            return []
        except Exception as e:
            logger.error(f"Error loading contacts: {e}")
            return []
    
    def _save_contacts(self, contacts: List[Dict]):
        """Save contacts to JSON file"""
        try:
            with open(CONTACTS_FILE, 'w', encoding='utf-8') as f:
                json.dump(contacts, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Error saving contacts: {e}")

    def add_contact(self, name: str, email: str = None, phone: str = None, 
                    company: str = None, notes: str = None, 
                    is_favorite: bool = False, labels: List[str] = None) -> Dict:
        """Add a new contact"""
        try:
            contacts = self._load_contacts()
            
            new_contact = {
                "id": str(uuid.uuid4()),
                "name": name,
                "email": email,
                "phone": phone,
                "company": company,
                "notes": notes,
                "is_favorite": is_favorite,
                "labels": labels or [],
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat()
            }
            
            contacts.append(new_contact)
            self._save_contacts(contacts)
            
            return {"success": True, "contact": new_contact, "message": f"Added contact {name}"}
                
        except Exception as e:
            logger.error(f"Error adding contact: {e}")
            return {"success": False, "error": str(e)}

    def update_contact(self, contact_id: str, name: str = None, email: str = None, 
                       phone: str = None, company: str = None, notes: str = None,
                       is_favorite: bool = None, labels: List[str] = None) -> Dict:
        """Update an existing contact"""
        try:
            contacts = self._load_contacts()
            
            for i, contact in enumerate(contacts):
                if contact.get("id") == contact_id:
                    if name is not None:
                        contacts[i]["name"] = name
                    if email is not None:
                        contacts[i]["email"] = email
                    if phone is not None:
                        contacts[i]["phone"] = phone
                    if company is not None:
                        contacts[i]["company"] = company
                    if notes is not None:
                        contacts[i]["notes"] = notes
                    if is_favorite is not None:
                        contacts[i]["is_favorite"] = is_favorite
                    if labels is not None:
                        contacts[i]["labels"] = labels
                    contacts[i]["updated_at"] = datetime.utcnow().isoformat()
                    
                    self._save_contacts(contacts)
                    return {"success": True, "contact": contacts[i], "message": "Contact updated"}
            
            return {"success": False, "error": "Contact not found"}
                
        except Exception as e:
            logger.error(f"Error updating contact: {e}")
            return {"success": False, "error": str(e)}

    def delete_contact(self, contact_id: str) -> Dict:
        """Delete a contact"""
        try:
            contacts = self._load_contacts()
            original_len = len(contacts)
            contacts = [c for c in contacts if c.get("id") != contact_id]
            
            if len(contacts) < original_len:
                self._save_contacts(contacts)
                return {"success": True, "message": "Contact deleted"}
            return {"success": False, "error": "Contact not found"}
                
        except Exception as e:
            logger.error(f"Error deleting contact: {e}")
            return {"success": False, "error": str(e)}

    def get_contact(self, contact_id: str) -> Optional[Dict]:
        """Get a single contact by ID"""
        try:
            contacts = self._load_contacts()
            for contact in contacts:
                if contact.get("id") == contact_id:
                    return contact
            return None
        except Exception as e:
            logger.error(f"Error getting contact: {e}")
            return None

    def search_contacts(self, query: str) -> List[Dict]:
        """Search contacts by name, email, phone, or company"""
        try:
            contacts = self._load_contacts()
            query_lower = query.lower()
            
            results = []
            for contact in contacts:
                if (query_lower in (contact.get("name") or "").lower() or
                    query_lower in (contact.get("email") or "").lower() or
                    query_lower in (contact.get("phone") or "").lower() or
                    query_lower in (contact.get("company") or "").lower()):
                    results.append(contact)
            
            return sorted(results, key=lambda x: x.get("name", "").lower())
        except Exception as e:
            logger.error(f"Error searching contacts: {e}")
            return []

    def get_email_address(self, name: str) -> str:
        """Find email address for a name (fuzzy match) - for AI tool use"""
        try:
            contacts = self._load_contacts()
            name_lower = name.lower()
            
            for contact in contacts:
                if name_lower in (contact.get("name") or "").lower():
                    email = contact.get("email")
                    if email:
                        return f"{email} (found: {contact['name']})"
            
            return f"Contact '{name}' not found."
            
        except Exception as e:
            logger.error(f"Error getting contact: {e}")
            return f"Error finding contact: {str(e)}"

    def get_phone_number(self, name: str) -> str:
        """Find phone number for a name (fuzzy match) - for AI tool use"""
        try:
            contacts = self._load_contacts()
            name_lower = name.lower()
            
            for contact in contacts:
                if name_lower in (contact.get("name") or "").lower():
                    phone = contact.get("phone")
                    if phone:
                        return f"{phone} (found: {contact['name']})"
            
            return f"Phone number for '{name}' not found."
            
        except Exception as e:
            logger.error(f"Error getting phone: {e}")
            return f"Error finding phone: {str(e)}"

    def list_contacts(self) -> str:
        """List all contacts - for AI tool use"""
        try:
            contacts = self._load_contacts()
            
            if not contacts:
                return "No contacts found."
            
            lines = []
            for c in sorted(contacts, key=lambda x: x.get("name", "").lower()):
                parts = [f"- {c['name']}"]
                if c.get('email'):
                    parts.append(f"email: {c['email']}")
                if c.get('phone'):
                    parts.append(f"phone: {c['phone']}")
                lines.append(", ".join(parts))
            
            return "\n".join(lines)
            
        except Exception as e:
            logger.error(f"Error listing contacts: {e}")
            return f"Error listing contacts: {str(e)}"
            
    def get_all_contacts_json(self, favorites_only: bool = False) -> List[Dict]:
        """Return raw list for UI"""
        try:
            contacts = self._load_contacts()
            if favorites_only:
                contacts = [c for c in contacts if c.get("is_favorite")]
            return sorted(contacts, key=lambda x: x.get("name", "").lower())
        except Exception as e:
            logger.error(f"Error listing contacts json: {e}")
            return []

    def get_contacts_by_label(self, label: str) -> List[Dict]:
        """Get contacts with a specific label"""
        try:
            contacts = self._load_contacts()
            results = [c for c in contacts if label in (c.get("labels") or [])]
            return sorted(results, key=lambda x: x.get("name", "").lower())
        except Exception as e:
            logger.error(f"Error getting contacts by label: {e}")
            return []

    def toggle_favorite(self, contact_id: str) -> Dict:
        """Toggle favorite status for a contact"""
        try:
            contacts = self._load_contacts()
            
            for i, contact in enumerate(contacts):
                if contact.get("id") == contact_id:
                    new_status = not contact.get("is_favorite", False)
                    contacts[i]["is_favorite"] = new_status
                    contacts[i]["updated_at"] = datetime.utcnow().isoformat()
                    self._save_contacts(contacts)
                    return {"success": True, "is_favorite": new_status}
            
            return {"success": False, "error": "Contact not found"}
                
        except Exception as e:
            logger.error(f"Error toggling favorite: {e}")
            return {"success": False, "error": str(e)}


contact_service = ContactService()
