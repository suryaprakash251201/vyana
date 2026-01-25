import logging
from typing import List, Dict, Optional
from app.services.supabase import supabase_client

logger = logging.getLogger(__name__)

class ContactService:
    def __init__(self):
        logger.info("ContactService (Supabase) initialized")

    def add_contact(self, name: str, email: str) -> str:
        """Add or update a contact in Supabase"""
        if not supabase_client:
            return "Error: Supabase not configured."

        try:
            # Check if exists by email to update, or just upsert
            data = {"name": name, "email": email}
            
            # Upsert based on email (assuming email is unique constraint)
            # Or we can just insert and handle error. Let's try upsert if possible, 
            # but standard insert is safer if we don't know constraints.
            # Let's do a select first to be safe about "updating" logic for names.
            
            existing = supabase_client.table("contacts").select("*").eq("email", email).execute()
            
            if existing.data:
                # Update
                supabase_client.table("contacts").update({"name": name}).eq("email", email).execute()
                return f"Updated contact {name} with email {email}"
            else:
                # Insert
                supabase_client.table("contacts").insert(data).execute()
                return f"Added contact {name} ({email})"
                
        except Exception as e:
            logger.error(f"Supabase error adding contact: {e}")
            return f"Error saving contact: {str(e)}"

    def get_email_address(self, name: str) -> str:
        """Find email address for a name (fuzzy match)"""
        if not supabase_client:
            return "Error: Supabase not configured."
            
        try:
            # Exact match (case insensitive typically handled by DB, but here we depend on exact or ilike)
            # Try ilike for partial match
            response = supabase_client.table("contacts").select("email").ilike("name", f"%{name}%").limit(1).execute()
            
            if response.data:
                return response.data[0]['email']
                
            return f"Contact '{name}' not found."
            
        except Exception as e:
            logger.error(f"Supabase error getting contact: {e}")
            return f"Error finding contact: {str(e)}"

    def list_contacts(self) -> str:
        """List all contacts"""
        if not supabase_client:
            return "Error: Supabase not configured."
            
        try:
            response = supabase_client.table("contacts").select("name, email").execute()
            contacts = response.data
            
            if not contacts:
                return "No contacts found."
            
            return "\n".join([f"- {c['name']}: {c['email']}" for c in contacts])
            
        except Exception as e:
            logger.error(f"Supabase error listing contacts: {e}")
            return f"Error listing contacts: {str(e)}"
            
    def get_all_contacts_json(self) -> List[Dict]:
        """Return raw list for UI"""
        if not supabase_client:
            return []
        try:
            response = supabase_client.table("contacts").select("*").order("name").execute()
            return response.data
        except Exception as e:
            logger.error(f"Supabase error listing contacts json: {e}")
            return []

contact_service = ContactService()
