"""
Vyana MCP Server
Exposes existing services as MCP tools using FastMCP.
"""

import json
import logging
from datetime import datetime
from typing import Optional
from fastmcp import FastMCP

# Import existing services
from app.services.calendar_service import calendar_service
from app.services.gmail_service import gmail_service
from app.services.tasks_repo import tasks_repo
from app.services.notes_service import notes_service
from app.services.weather_service import weather_service
from app.services.search_service import search_service
from app.services.utils_service import utils_service
from app.config import settings

# Setup logging
logger = logging.getLogger(__name__)

# Create FastMCP server
mcp_server = FastMCP(
    name=getattr(settings, "MCP_SERVER_NAME", "VyanaMCP"),
    instructions="""
    Vyana is an advanced personal AI assistant serving Boss Suryaprakash.
    Use these tools to help with calendar, email, tasks, weather, and more.
    Always respond professionally and helpfully.
    """
)


# =============================================================================
# Calendar Tools
# =============================================================================

@mcp_server.tool()
async def check_calendar(days: int = 7) -> str:
    """
    Get calendar events for the specified number of days.
    
    Args:
        days: Number of days to check (default: 7)
    
    Returns:
        Summary of calendar events
    """
    try:
        events = calendar_service.get_events()
        if not events:
            return "No upcoming events found."
        
        # Filter to requested days
        from datetime import datetime, timedelta
        try:
            from zoneinfo import ZoneInfo
            ist = ZoneInfo("Asia/Kolkata")
        except ImportError:
            import pytz
            ist = pytz.timezone("Asia/Kolkata")
        
        now = datetime.now(ist)
        cutoff = now + timedelta(days=days)
        
        filtered = []
        for e in events:
            if isinstance(e, dict) and "error" not in e:
                start = e.get("start", "")
                if start:
                    try:
                        event_dt = datetime.fromisoformat(start.replace("Z", "+00:00"))
                        if event_dt <= cutoff:
                            filtered.append(e)
                    except ValueError:
                        filtered.append(e)  # Include if can't parse date
        
        if not filtered:
            return f"No events in the next {days} days."
        
        result = f"Found {len(filtered)} events in the next {days} days:\n"
        for e in filtered[:10]:  # Limit to 10
            result += f"- {e.get('summary', 'Untitled')} at {e.get('start', 'Unknown time')}\n"
        
        return result
    except Exception as e:
        logger.error(f"check_calendar error: {e}")
        return f"Error checking calendar: {str(e)}"


@mcp_server.tool()
async def create_calendar_event(
    summary: str,
    start_time: str,
    duration_minutes: int = 60,
    description: Optional[str] = None
) -> str:
    """
    Create a new calendar event.
    
    Args:
        summary: Event title/summary
        start_time: Start time in ISO 8601 format (e.g., 2026-01-10T14:00:00)
        duration_minutes: Duration in minutes (default: 60)
        description: Optional event description
    
    Returns:
        Confirmation message
    """
    try:
        result = calendar_service.create_event(
            summary=summary,
            start_time=start_time,
            duration_minutes=duration_minutes,
            description=description
        )
        return str(result)
    except Exception as e:
        logger.error(f"create_calendar_event error: {e}")
        return f"Error creating event: {str(e)}"


# =============================================================================
# Gmail Tools
# =============================================================================

@mcp_server.tool()
async def get_gmail_unread(limit: int = 5) -> str:
    """
    Get summary of unread emails.
    
    Args:
        limit: Maximum number of emails to show (default: 5)
    
    Returns:
        Summary of unread emails
    """
    try:
        result = gmail_service.summarize_emails(max_results=limit)
        return str(result)
    except Exception as e:
        logger.error(f"get_gmail_unread error: {e}")
        return f"Error fetching emails: {str(e)}"


@mcp_server.tool()
async def send_email(to_email: str, subject: str, body: str) -> str:
    """
    Send an email.
    
    Args:
        to_email: Recipient email address
        subject: Email subject
        body: Email body content
    
    Returns:
        Confirmation message
    """
    try:
        result = gmail_service.send_email(to_email, subject, body)
        return str(result)
    except Exception as e:
        logger.error(f"send_email error: {e}")
        return f"Error sending email: {str(e)}"


# =============================================================================
# Task Tools
# =============================================================================

@mcp_server.tool()
async def list_tasks(limit: int = 20) -> str:
    """
    List all uncompleted tasks.
    
    Args:
        limit: Maximum number of tasks to return (default: 20)
    
    Returns:
        JSON list of tasks
    """
    try:
        tasks = tasks_repo.list_tasks(include_completed=False)
        task_list = [
            {"id": t.id, "title": t.title, "due": t.due_date}
            for t in tasks[:limit]
        ]
        if not task_list:
            return "No pending tasks."
        return json.dumps(task_list, indent=2)
    except Exception as e:
        logger.error(f"list_tasks error: {e}")
        return f"Error listing tasks: {str(e)}"


@mcp_server.tool()
async def create_task(title: str, due_date: Optional[str] = None) -> str:
    """
    Create a new task.
    
    Args:
        title: Task title
        due_date: Optional due date in YYYY-MM-DD format
    
    Returns:
        Confirmation with task ID
    """
    try:
        task = tasks_repo.add_task(title, due_date)
        return json.dumps({"id": task.id, "status": "Task created", "title": title})
    except Exception as e:
        logger.error(f"create_task error: {e}")
        return f"Error creating task: {str(e)}"


@mcp_server.tool()
async def complete_task(task_id: int) -> str:
    """
    Mark a task as completed.
    
    Args:
        task_id: ID of the task to complete
    
    Returns:
        Confirmation message
    """
    try:
        success = tasks_repo.complete_task(task_id)
        return json.dumps({
            "success": success,
            "message": "Task completed" if success else "Task not found"
        })
    except Exception as e:
        logger.error(f"complete_task error: {e}")
        return f"Error completing task: {str(e)}"


# =============================================================================
# Notes Tools
# =============================================================================

@mcp_server.tool()
async def take_notes(content: str, title: Optional[str] = None) -> str:
    """
    Save a note.
    
    Args:
        content: Note content
        title: Optional note title
    
    Returns:
        Confirmation message
    """
    try:
        result = notes_service.save_note(content, title)
        return str(result)
    except Exception as e:
        logger.error(f"take_notes error: {e}")
        return f"Error saving note: {str(e)}"


@mcp_server.tool()
async def get_notes(limit: int = 10) -> str:
    """
    Get recent notes.
    
    Args:
        limit: Number of notes to retrieve (default: 10)
    
    Returns:
        JSON list of notes
    """
    try:
        notes = notes_service.get_notes(limit)
        return json.dumps(notes, indent=2)
    except Exception as e:
        logger.error(f"get_notes error: {e}")
        return f"Error fetching notes: {str(e)}"


# =============================================================================
# Weather Tools
# =============================================================================

@mcp_server.tool()
async def get_weather(city: str = "Mumbai") -> str:
    """
    Get current weather for a city.
    
    Args:
        city: City name (default: Mumbai)
    
    Returns:
        Weather information
    """
    try:
        result = weather_service.get_weather(city)
        return str(result)
    except Exception as e:
        logger.error(f"get_weather error: {e}")
        return f"Error fetching weather: {str(e)}"


@mcp_server.tool()
async def get_forecast(city: str = "Mumbai") -> str:
    """
    Get 3-day weather forecast.
    
    Args:
        city: City name (default: Mumbai)
    
    Returns:
        Weather forecast
    """
    try:
        result = weather_service.get_forecast(city)
        return str(result)
    except Exception as e:
        logger.error(f"get_forecast error: {e}")
        return f"Error fetching forecast: {str(e)}"


# =============================================================================
# Search Tools
# =============================================================================

@mcp_server.tool()
async def web_search(query: str) -> str:
    """
    Search the web for information.
    
    Args:
        query: Search query
    
    Returns:
        Search results
    """
    try:
        result = search_service.web_search(query)
        return json.dumps({"result": result})
    except Exception as e:
        logger.error(f"web_search error: {e}")
        return f"Error searching: {str(e)}"


@mcp_server.tool()
async def get_news(topic: str = "technology") -> str:
    """
    Get latest news on a topic.
    
    Args:
        topic: News topic (default: technology)
    
    Returns:
        News articles
    """
    try:
        result = search_service.get_news(topic)
        return json.dumps({"result": result})
    except Exception as e:
        logger.error(f"get_news error: {e}")
        return f"Error fetching news: {str(e)}"


# =============================================================================
# Utility Tools
# =============================================================================

@mcp_server.tool()
async def calculate(expression: str) -> str:
    """
    Evaluate a mathematical expression.
    
    Args:
        expression: Math expression (e.g., "2 + 2" or "10 * 5")
    
    Returns:
        Calculation result
    """
    try:
        result = utils_service.calculate(expression)
        return json.dumps({"result": result})
    except Exception as e:
        logger.error(f"calculate error: {e}")
        return f"Error calculating: {str(e)}"


@mcp_server.tool()
async def convert_currency(
    amount: float,
    from_currency: str,
    to_currency: str
) -> str:
    """
    Convert currency from one type to another.
    
    Args:
        amount: Amount to convert
        from_currency: Source currency code (USD, EUR, INR, etc.)
        to_currency: Target currency code
    
    Returns:
        Converted amount
    """
    try:
        result = utils_service.convert_currency(amount, from_currency, to_currency)
        return json.dumps({"result": result})
    except Exception as e:
        logger.error(f"convert_currency error: {e}")
        return f"Error converting: {str(e)}"


@mcp_server.tool()
async def convert_units(value: float, from_unit: str, to_unit: str) -> str:
    """
    Convert units (length, weight, temperature).
    
    Args:
        value: Value to convert
        from_unit: Source unit (m, km, kg, lb, c, f, etc.)
        to_unit: Target unit
    
    Returns:
        Converted value
    """
    try:
        result = utils_service.convert_units(value, from_unit, to_unit)
        return json.dumps({"result": result})
    except Exception as e:
        logger.error(f"convert_units error: {e}")
        return f"Error converting: {str(e)}"


# =============================================================================
# System Info Tool
# =============================================================================

@mcp_server.tool()
async def get_current_time() -> str:
    """
    Get the current date and time in IST.
    
    Returns:
        Current date, time, and day of week
    """
    try:
        try:
            from zoneinfo import ZoneInfo
            ist = ZoneInfo("Asia/Kolkata")
        except ImportError:
            import pytz
            ist = pytz.timezone("Asia/Kolkata")
        
        now = datetime.now(ist)
        return json.dumps({
            "date": now.strftime("%Y-%m-%d"),
            "time": now.strftime("%H:%M:%S"),
            "day": now.strftime("%A"),
            "timezone": "IST (Asia/Kolkata)"
        })
    except Exception as e:
        logger.error(f"get_current_time error: {e}")
        return f"Error getting time: {str(e)}"


logger.info(f"VyanaMCP server initialized with {len(mcp_server._tool_manager._tools)} tools")
