import requests
import logging
from app.config import settings

logger = logging.getLogger(__name__)

class NotesService:
    def __init__(self):
        self.base_url = f"{settings.SUPABASE_URL}/rest/v1/notes"
        self.headers = {
            "apikey": settings.SUPABASE_KEY,
            "Authorization": f"Bearer {settings.SUPABASE_KEY}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        }

    def save_note(self, content: str, title: str = None):
        try:
            data = {
                "title": title or "Quick Note",
                "content": content,
                "user_id": "app_user"
            }
            
            logger.info(f"Saving note: {data}")
            
            response = requests.post(self.base_url, headers=self.headers, json=data)
            
            if response.status_code not in [200, 201]:
                logger.error(f"Supabase save note error: {response.status_code} - {response.text}")
                return f"Error saving note: {response.text}"
            
            created = response.json()
            logger.info(f"Note saved: {created}")
            
            return f"Note saved: {title or 'Quick Note'}"
            
        except Exception as e:
            logger.error(f"Error saving note: {e}")
            return f"Error saving note: {e}"

    def get_notes(self, limit: int = 10):
        try:
            query = f"?select=*&order=created_at.desc&limit={limit}"
            response = requests.get(f"{self.base_url}{query}", headers=self.headers)
            
            if response.status_code != 200:
                logger.error(f"Supabase get notes error: {response.text}")
                return []
            
            return response.json()
            
        except Exception as e:
            logger.error(f"Error getting notes: {e}")
            return []

notes_service = NotesService()
