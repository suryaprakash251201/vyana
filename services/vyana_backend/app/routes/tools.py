from fastapi import APIRouter
from app.services.groq_client import groq_client

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
    else:
        return 'Other'

from pydantic import BaseModel
class AddContactRequest(BaseModel):
    name: str
    email: str

@router.get("/contacts")
async def get_contacts():
    """Get all contacts for UI"""
    from app.services.contact_service import contact_service
    return {"contacts": contact_service.get_all_contacts_json()}

@router.post("/contacts")
async def add_contact(request: AddContactRequest):
    """Add contact via UI"""
    from app.services.contact_service import contact_service
    result = contact_service.add_contact(request.name, request.email)
    
    # Check if result string starts with "Error" (simple error handling from service)
    if result.startswith("Error"):
        return {"success": False, "error": result}
    return {"success": True, "message": result}
