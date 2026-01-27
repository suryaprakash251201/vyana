from fastapi import APIRouter, HTTPException
from typing import Optional, List

router = APIRouter()

# Fallback tool list to avoid empty UI if LangGraph tool loading fails
_FALLBACK_TOOLS = [
    {"name": "create_task", "description": "Creates a new task in the user's Google Tasks to-do list."},
    {"name": "list_tasks", "description": "Lists all uncompleted tasks from Google Tasks."},
    {"name": "complete_task", "description": "Marks a task as completed."},
    {"name": "update_task", "description": "Updates an existing task's title or due date."},
    {"name": "delete_task", "description": "Deletes a task."},
    {"name": "search_tasks", "description": "Search tasks by keyword."},
    {"name": "get_calendar_today", "description": "Gets calendar events for today."},
    {"name": "get_calendar_events", "description": "Gets calendar events for a specific date."},
    {"name": "get_calendar_range", "description": "Gets upcoming calendar events for the next N days."},
    {"name": "create_calendar_event", "description": "Creates a calendar event."},
    {"name": "get_unread_emails_summary", "description": "Gets a summary of recent unread emails."},
    {"name": "summarize_emails", "description": "Summarizes recent emails."},
    {"name": "send_email", "description": "Sends an email."},
    {"name": "search_emails", "description": "Search emails by keyword."},
    {"name": "add_contact", "description": "Adds a new contact."},
    {"name": "get_email_address", "description": "Finds email address for a contact."},
    {"name": "get_phone_number", "description": "Finds phone number for a contact."},
    {"name": "list_contacts", "description": "Lists all contacts."},
    {"name": "take_notes", "description": "Saves a note."},
    {"name": "get_notes", "description": "Retrieves recent notes."},
    {"name": "get_weather", "description": "Gets current weather for a city."},
    {"name": "get_forecast", "description": "Gets a short weather forecast for a city."},
    {"name": "web_search", "description": "Searches the web for information."},
    {"name": "get_news", "description": "Gets latest news on a topic."},
    {"name": "calculate", "description": "Evaluates a mathematical expression."},
    {"name": "get_time_now", "description": "Returns the current time and date in IST."},
    {"name": "convert_currency", "description": "Converts currency from one type to another."},
    {"name": "convert_units", "description": "Converts units (length, weight, temperature)."},
    {"name": "daily_digest", "description": "Creates a quick daily digest of tasks, calendar, and unread email count."},
]

@router.get("/list")
async def list_tools(include_mcp: bool = True):
    """Return list of available AI tools (LangGraph + optional MCP tools)."""
    formatted_tools = []
    try:
        from app.services.langgraph_tools import get_all_tools, get_mcp_tools_as_langchain

        tools = list(get_all_tools())
        if include_mcp:
            try:
                tools.extend(get_mcp_tools_as_langchain())
            except Exception:
                # MCP tools are optional; return base tools if MCP is unavailable
                pass

        for tool in tools:
            # LangChain tools expose name/description attributes
            if hasattr(tool, "name") and hasattr(tool, "description"):
                name = getattr(tool, "name")
                description = getattr(tool, "description")
                formatted_tools.append({
                    "name": name,
                    "description": description,
                    "category": _categorize_tool(name),
                })
            # Backward compatibility (if any tool is still in OpenAI function format)
            elif isinstance(tool, dict) and tool.get("type") == "function":
                func = tool.get("function", {})
                name = func.get("name", "")
                description = func.get("description", "")
                if name:
                    formatted_tools.append({
                        "name": name,
                        "description": description,
                        "category": _categorize_tool(name),
                    })

        if formatted_tools:
            return {"tools": formatted_tools}
    except Exception:
        # Fall through to fallback list below
        pass

    fallback = [
        {
            "name": t["name"],
            "description": t["description"],
            "category": _categorize_tool(t["name"]),
        }
        for t in _FALLBACK_TOOLS
    ]
    return {"tools": fallback}


@router.get("/")
async def list_tools_root():
    """Alias for /tools/list (helpful for quick checks)."""
    return await list_tools()

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
