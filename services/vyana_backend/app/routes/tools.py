from fastapi import APIRouter, HTTPException
from app.services.groq_client import groq_client
from typing import Optional, List

router = APIRouter()

@router.get("/list")
async def list_tools():
    """Return list of available AI tools"""
    tools = groq_client._get_tools()
    
    # Format for frontend
    formatted_tools = []
    for tool in tools:
        if tool.get('type') == 'function':
            func = tool['function']
            formatted_tools.append({
                'name': func['name'],
                'description': func['description'],
                'category': _categorize_tool(func['name'])
            })
    
    return {"tools": formatted_tools}

def _categorize_tool(name: str) -> str:
    """Categorize tools by function"""
    if name.startswith("mcp_"):
        return "MCP"
    if 'task' in name:
        return 'Tasks'
    elif 'calendar' in name or 'event' in name:
        return 'Calendar'
    elif 'note' in name:
        return 'Notes'
    elif 'email' in name:
        return 'Email'
    elif 'digest' in name:
        return 'Summary'
    elif 'weather' in name or 'forecast' in name:
        return 'Weather'
    elif 'search' in name or 'news' in name:
        return 'Search'
    elif 'calculate' in name or 'convert' in name or 'time' in name:
        return 'Utilities'
    elif 'contact' in name:
        return 'Contacts'
    else:
        return 'Other'

# ============== Contacts API - Google Contacts Replacement ==============

from pydantic import BaseModel

class AddContactRequest(BaseModel):
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    company: Optional[str] = None
    notes: Optional[str] = None
    is_favorite: bool = False
    labels: Optional[List[str]] = None

class UpdateContactRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    company: Optional[str] = None
    notes: Optional[str] = None
    is_favorite: Optional[bool] = None
    labels: Optional[List[str]] = None

@router.get("/contacts")
async def get_contacts(favorites_only: bool = False, search: Optional[str] = None):
    """Get all contacts from Google Contacts with optional filtering"""
    from app.services.google_contacts_service import google_contacts_service
    
    if search:
        contacts = google_contacts_service.search_contacts(search)
    else:
        contacts = google_contacts_service.get_all_contacts(favorites_only=favorites_only)
    
    return {"contacts": contacts}

@router.get("/contacts/{contact_id}")
async def get_contact(contact_id: str):
    """Get a single contact by ID from Google Contacts"""
    from app.services.google_contacts_service import google_contacts_service
    
    contact = google_contacts_service.get_contact(contact_id)
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    return {"contact": contact}

@router.post("/contacts")
async def add_contact(request: AddContactRequest):
    """Add a new contact to Google Contacts"""
    from app.services.google_contacts_service import google_contacts_service
    
    result = google_contacts_service.add_contact(
        name=request.name,
        email=request.email,
        phone=request.phone,
        company=request.company,
        notes=request.notes,
        is_favorite=request.is_favorite
    )
    
    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("error", "Failed to add contact"))
    return result

@router.put("/contacts/{contact_id}")
async def update_contact(contact_id: str, request: UpdateContactRequest):
    """Update an existing contact in Google Contacts"""
    from app.services.google_contacts_service import google_contacts_service
    
    result = google_contacts_service.update_contact(
        contact_id=contact_id,
        name=request.name,
        email=request.email,
        phone=request.phone,
        company=request.company,
        notes=request.notes,
        is_favorite=request.is_favorite
    )
    
    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("error", "Failed to update contact"))
    return result

@router.delete("/contacts/{contact_id}")
async def delete_contact(contact_id: str):
    """Delete a contact from Google Contacts"""
    from app.services.google_contacts_service import google_contacts_service
    
    result = google_contacts_service.delete_contact(contact_id)
    
    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("error", "Failed to delete contact"))
    return result

@router.post("/contacts/{contact_id}/favorite")
async def toggle_favorite(contact_id: str):
    """Toggle favorite (starred) status for a contact"""
    from app.services.google_contacts_service import google_contacts_service
    
    result = google_contacts_service.toggle_favorite(contact_id)
    
    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("error", "Failed to toggle favorite"))
    return result
