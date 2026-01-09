from fastapi import APIRouter
from app.services.groq_client import GroqClient

router = APIRouter()
groq_client = GroqClient()

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
    if 'task' in name:
        return 'Tasks'
    elif 'calendar' in name or 'event' in name:
        return 'Calendar'
    elif 'note' in name:
        return 'Notes'
    elif 'email' in name:
        return 'Email'
    elif 'weather' in name or 'forecast' in name:
        return 'Weather'
    elif 'search' in name or 'news' in name:
        return 'Search'
    elif 'calculate' in name or 'convert' in name:
        return 'Utilities'
    else:
        return 'Other'
