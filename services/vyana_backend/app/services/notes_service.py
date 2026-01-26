import json
import os
import uuid
import logging
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)

# Storage path for notes
STORAGE_DIR = Path(__file__).parent.parent / "storage"
NOTES_FILE = STORAGE_DIR / "notes.json"


class NotesService:
    """
    Notes Service - Local JSON file storage (no Supabase required)
    """
    
    def __init__(self):
        logger.info("NotesService (Local JSON) initialized")
        self._ensure_storage()
    
    def _ensure_storage(self):
        """Ensure storage directory and file exist"""
        STORAGE_DIR.mkdir(parents=True, exist_ok=True)
        if not NOTES_FILE.exists():
            self._save_notes([])
    
    def _load_notes(self) -> List[Dict]:
        """Load notes from JSON file"""
        try:
            if NOTES_FILE.exists():
                with open(NOTES_FILE, 'r', encoding='utf-8') as f:
                    return json.load(f)
            return []
        except Exception as e:
            logger.error(f"Error loading notes: {e}")
            return []
    
    def _save_notes(self, notes: List[Dict]):
        """Save notes to JSON file"""
        try:
            with open(NOTES_FILE, 'w', encoding='utf-8') as f:
                json.dump(notes, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Error saving notes: {e}")

    def save_note(self, content: str, title: str = None) -> str:
        """Save a new note"""
        try:
            notes = self._load_notes()
            
            new_note = {
                "id": str(uuid.uuid4()),
                "title": title or "Quick Note",
                "content": content,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat()
            }
            
            notes.insert(0, new_note)  # Add to beginning (newest first)
            self._save_notes(notes)
            
            logger.info(f"Note saved: {new_note['title']}")
            return f"Note saved: {title or 'Quick Note'}"
            
        except Exception as e:
            logger.error(f"Error saving note: {e}")
            return f"Error saving note: {e}"

    def get_notes(self, limit: int = 10) -> List[Dict]:
        """Get recent notes"""
        try:
            notes = self._load_notes()
            # Already sorted by newest first (inserted at beginning)
            return notes[:limit]
        except Exception as e:
            logger.error(f"Error getting notes: {e}")
            return []
    
    def get_note(self, note_id: str) -> Optional[Dict]:
        """Get a single note by ID"""
        try:
            notes = self._load_notes()
            for note in notes:
                if note.get("id") == note_id:
                    return note
            return None
        except Exception as e:
            logger.error(f"Error getting note: {e}")
            return None
    
    def update_note(self, note_id: str, title: str = None, content: str = None) -> Dict:
        """Update an existing note"""
        try:
            notes = self._load_notes()
            
            for i, note in enumerate(notes):
                if note.get("id") == note_id:
                    if title is not None:
                        notes[i]["title"] = title
                    if content is not None:
                        notes[i]["content"] = content
                    notes[i]["updated_at"] = datetime.utcnow().isoformat()
                    
                    self._save_notes(notes)
                    return {"success": True, "note": notes[i]}
            
            return {"success": False, "error": "Note not found"}
        except Exception as e:
            logger.error(f"Error updating note: {e}")
            return {"success": False, "error": str(e)}
    
    def delete_note(self, note_id: str) -> Dict:
        """Delete a note"""
        try:
            notes = self._load_notes()
            original_len = len(notes)
            notes = [n for n in notes if n.get("id") != note_id]
            
            if len(notes) < original_len:
                self._save_notes(notes)
                return {"success": True, "message": "Note deleted"}
            return {"success": False, "error": "Note not found"}
        except Exception as e:
            logger.error(f"Error deleting note: {e}")
            return {"success": False, "error": str(e)}
    
    def search_notes(self, query: str) -> List[Dict]:
        """Search notes by title or content"""
        try:
            notes = self._load_notes()
            query_lower = query.lower()
            
            results = []
            for note in notes:
                if (query_lower in (note.get("title") or "").lower() or
                    query_lower in (note.get("content") or "").lower()):
                    results.append(note)
            
            return results
        except Exception as e:
            logger.error(f"Error searching notes: {e}")
            return []


notes_service = NotesService()
