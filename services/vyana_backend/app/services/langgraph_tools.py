"""
LangGraph Tools - All tool definitions for the Vyana AI Agent
Converted from manual tool definitions to LangChain tool format
"""
import json
import logging
from typing import Optional
from datetime import datetime, timedelta
from langchain_core.tools import tool

from app.services import google_tasks_service
from app.services.calendar_service import calendar_service
from app.services.gmail_service import gmail_service
from app.services.notes_service import notes_service
from app.services.mcp_service import mcp_service
from app.services.weather_service import weather_service
from app.services.search_service import search_service
from app.services.utils_service import utils_service
from app.services.google_contacts_service import google_contacts_service

logger = logging.getLogger(__name__)


def _get_ist_timezone():
    """Get IST timezone object"""
    try:
        from zoneinfo import ZoneInfo
        return ZoneInfo("Asia/Kolkata")
    except ImportError:
        import pytz
        return pytz.timezone("Asia/Kolkata")


# ============== TASK MANAGEMENT TOOLS ==============

@tool
def create_task(title: str, due_date: Optional[str] = None, notes: Optional[str] = None, task_list_id: str = "@default") -> str:
    """Creates a new task in the user's Google Tasks to-do list. Use when user wants to add, create, or make a new task.
    
    Args:
        title: The task title
        due_date: Optional due date in YYYY-MM-DD format
        notes: Optional task notes
        task_list_id: Optional task list id (default @default)
    """
    try:
        result = google_tasks_service.create_task(
            title=title,
            task_list_id=task_list_id,
            notes=notes,
            due=due_date
        )
        return json.dumps({"id": result.get("id"), "status": "Task created", "title": title})
    except Exception as e:
        logger.error(f"Error creating task: {e}")
        return json.dumps({"error": "Google Tasks not connected. Please go to Settings > Connect Google Account to enable task features."})


@tool
def list_tasks(limit: int = 100, task_list_id: str = "@default") -> str:
    """Lists all uncompleted tasks from the user's Google Tasks. Use when user asks 'what are my tasks', 'show my tasks', 'check tasks', 'pending tasks', or 'to-do list'.
    
    Args:
        limit: Optional limit for number of tasks
        task_list_id: Optional task list id (default @default)
    """
    try:
        tasks = google_tasks_service.list_tasks(
            task_list_id=task_list_id,
            show_completed=False,
            max_results=int(limit)
        )
        return json.dumps([{"id": t.get("id"), "title": t.get("title"), "due": t.get("due")} for t in tasks])
    except Exception as e:
        logger.error(f"Error listing tasks: {e}")
        return json.dumps({"error": "Google Tasks not connected. Please go to Settings > Connect Google Account to enable task features."})


@tool
def complete_task(task_id: str, task_list_id: str = "@default") -> str:
    """Marks a task as completed.
    
    Args:
        task_id: ID of the task to complete
        task_list_id: Optional task list id (default @default)
    """
    try:
        result = google_tasks_service.complete_task(
            task_id=task_id,
            task_list_id=task_list_id
        )
        return json.dumps({"success": True, "message": "Task completed", "id": result.get("id")})
    except Exception as e:
        logger.error(f"Error completing task: {e}")
        return json.dumps({"error": "Google Tasks not connected. Please go to Settings > Connect Google Account to enable task features."})


@tool
def update_task(task_id: str, title: Optional[str] = None, due_date: Optional[str] = None, notes: Optional[str] = None, task_list_id: str = "@default") -> str:
    """Updates an existing task's title or due date.
    
    Args:
        task_id: ID of the task
        title: New title (optional)
        due_date: New due date in YYYY-MM-DD format (optional)
        notes: New notes (optional)
        task_list_id: Optional task list id (default @default)
    """
    try:
        result = google_tasks_service.update_task(
            task_id=task_id,
            task_list_id=task_list_id,
            title=title,
            notes=notes,
            due=due_date
        )
        return json.dumps({"success": True, "message": "Task updated", "id": result.get("id")})
    except Exception as e:
        logger.error(f"Error updating task: {e}")
        return json.dumps({"error": "Google Tasks not connected. Please go to Settings > Connect Google Account to enable task features."})


@tool
def delete_task(task_id: str, task_list_id: str = "@default") -> str:
    """Deletes a task permanently.
    
    Args:
        task_id: ID of the task to delete
        task_list_id: Optional task list id (default @default)
    """
    try:
        google_tasks_service.delete_task(
            task_id=task_id,
            task_list_id=task_list_id
        )
        return json.dumps({"success": True, "message": "Task deleted"})
    except Exception as e:
        logger.error(f"Error deleting task: {e}")
        return json.dumps({"error": "Google Tasks not connected. Please go to Settings > Connect Google Account to enable task features."})


@tool
def search_tasks(query: str, task_list_id: str = "@default") -> str:
    """Searches tasks by title keyword.
    
    Args:
        query: Search keyword
        task_list_id: Optional task list id (default @default)
    """
    try:
        query_lower = query.lower()
        tasks = google_tasks_service.list_tasks(
            task_list_id=task_list_id,
            show_completed=False,
            max_results=200
        )
        filtered = [t for t in tasks if query_lower in (t.get("title") or "").lower()]
        return json.dumps([{"id": t.get("id"), "title": t.get("title"), "due": t.get("due")} for t in filtered])
    except Exception as e:
        logger.error(f"Error searching tasks: {e}")
        return json.dumps({"error": "Google Tasks not connected. Please go to Settings > Connect Google Account to enable task features."})


# ============== CALENDAR TOOLS ==============

@tool
def get_calendar_today(limit: int = 10) -> str:
    """Gets calendar events for today only. Use get_calendar_events for other dates.
    
    Args:
        limit: Optional limit for number of events
    """
    return str(calendar_service.get_events())


@tool
def get_calendar_events(date: str) -> str:
    """Gets calendar events for a specific date. Use this when user asks about events on a specific day like 'tomorrow', 'next Monday', or a specific date. Convert the date to YYYY-MM-DD format.
    
    Args:
        date: Date in YYYY-MM-DD format (e.g., 2026-01-27 for tomorrow)
    """
    if date:
        events = calendar_service.get_events(start_date_str=date, end_date_str=date)
        if isinstance(events, list) and len(events) > 0 and isinstance(events[0], dict) and events[0].get("error"):
            return json.dumps({"error": "Google Calendar not connected. Please go to Settings > Connect Google Account."})
        return json.dumps(events)
    return json.dumps({"error": "Date parameter required"})


@tool
def get_calendar_range(days: int = 7) -> str:
    """Gets upcoming calendar events for the next N days starting from today.
    
    Args:
        days: Number of days to look ahead (default 7)
    """
    events = calendar_service.get_events()
    try:
        ist = _get_ist_timezone()
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
                        filtered.append(e)
        return json.dumps(filtered)
    except Exception:
        return json.dumps(events)


@tool
def create_calendar_event(summary: str, start_time: str, duration_minutes: int = 60) -> str:
    """Creates a calendar event. Use this when the user wants to schedule something. The start_time MUST be in ISO 8601 format like '2026-01-05T16:00:00'. Convert natural language times to ISO format using the current date provided in the system context.
    
    Args:
        summary: Event title/summary
        start_time: Start time in ISO 8601 format (e.g., 2026-01-05T16:00:00)
        duration_minutes: Duration in minutes, default 60
    """
    result = calendar_service.create_event(summary, start_time, duration_minutes)
    if isinstance(result, dict) and result.get("error"):
        return json.dumps({"error": "Google Calendar not connected. Please go to Settings > Connect Google Account to enable calendar features."})
    return str(result)


# ============== EMAIL TOOLS ==============

@tool
def get_unread_emails_summary(limit: int = 5) -> str:
    """Gets a summary of recent unread emails.
    
    Args:
        limit: Optional limit for number of emails
    """
    result = gmail_service.summarize_emails(limit)
    if isinstance(result, dict) and result.get("error"):
        return json.dumps({"error": "Google account not connected. Please go to Settings > Connect Google Account to enable email features."})
    return str(result)


@tool
def summarize_emails(limit: int = 5) -> str:
    """Summarizes recent unread emails with optional limit.
    
    Args:
        limit: Max emails to summarize (default 5)
    """
    result = gmail_service.summarize_emails(limit)
    if isinstance(result, dict) and result.get("error"):
        return json.dumps({"error": "Google account not connected. Please go to Settings > Connect Google Account to enable email features."})
    return str(result)


@tool
def send_email(to_email: str, subject: str, body: str) -> str:
    """Sends an email. If you only have a name (e.g., 'Alice'), USE 'get_email_address' FIRST to find their email.
    
    Args:
        to_email: Recipient email address
        subject: Email subject
        body: Email body
    """
    return str(gmail_service.send_email(to_email, subject, body))


@tool
def search_emails(query: str, limit: int = 5) -> str:
    """Searches for emails using specified criteria. Useful for finding emails from a person or about a topic.
    
    Args:
        query: Search query used for filtering (e.g., 'from:zerodha', 'subject:invoice', 'is:unread')
        limit: Max number of emails to return (default 5)
    """
    return json.dumps(gmail_service.search_messages(query, limit))


# ============== CONTACT TOOLS ==============

@tool
def add_contact(name: str, email: Optional[str] = None, phone: Optional[str] = None, company: Optional[str] = None, notes: Optional[str] = None) -> str:
    """Saves a new contact. Use this when the user asks to save someone's contact info (name, email, phone, company).
    
    Args:
        name: Name of the person
        email: Email address (optional)
        phone: Phone number (optional)
        company: Company/organization (optional)
        notes: Additional notes (optional)
    """
    result = google_contacts_service.add_contact(
        name=name,
        email=email,
        phone=phone,
        company=company,
        notes=notes
    )
    return result.get("message", str(result))


@tool
def get_email_address(name: str) -> str:
    """Finds an email address for a contact by name.
    
    Args:
        name: Name to look up
    """
    return google_contacts_service.get_email_address(name)


@tool
def get_phone_number(name: str) -> str:
    """Finds a phone number for a contact by name.
    
    Args:
        name: Name to look up
    """
    return google_contacts_service.get_phone_number(name)


@tool
def list_contacts() -> str:
    """Lists all saved contacts with their names, emails, and phone numbers."""
    return google_contacts_service.list_contacts()


# ============== NOTES TOOLS ==============

@tool
def take_notes(content: str, title: Optional[str] = None) -> str:
    """Saves a note for the user. Use this when the user asks to remember something or take a note.
    
    Args:
        content: Note content
        title: Note title (optional)
    """
    return str(notes_service.save_note(content, title))


@tool
def get_notes(limit: int = 10) -> str:
    """Retrieves recent notes.
    
    Args:
        limit: Number of notes to retrieve, default 10
    """
    notes = notes_service.get_notes(limit)
    return json.dumps(notes)


# ============== WEATHER TOOLS ==============

@tool
def get_weather(city: str = "Mumbai") -> str:
    """Gets current weather for a city.
    
    Args:
        city: City name, default Mumbai
    """
    return weather_service.get_weather(city)


@tool
def get_forecast(city: str = "Mumbai") -> str:
    """Gets 3-day weather forecast for a city.
    
    Args:
        city: City name, default Mumbai
    """
    return weather_service.get_forecast(city)


# ============== SEARCH TOOLS ==============

@tool
def web_search(query: str) -> str:
    """Searches the web for information.
    
    Args:
        query: Search query
    """
    result = search_service.web_search(query)
    return json.dumps({"result": result})


@tool
def get_news(topic: str = "technology") -> str:
    """Gets latest news on a topic.
    
    Args:
        topic: News topic, default 'technology'
    """
    result = search_service.get_news(topic)
    return json.dumps({"result": result})


# ============== UTILITY TOOLS ==============

@tool
def calculate(expression: str) -> str:
    """Evaluates a mathematical expression.
    
    Args:
        expression: Math expression like '2 + 2' or '10 * 5'
    """
    result = utils_service.calculate(expression)
    return json.dumps({"result": result})


@tool
def get_time_now() -> str:
    """Returns the current time and date in IST."""
    ist = _get_ist_timezone()
    now = datetime.now(ist)
    return json.dumps({"result": now.strftime("%Y-%m-%d %H:%M:%S IST")})


@tool
def convert_currency(amount: float, from_currency: str, to_currency: str) -> str:
    """Converts currency from one type to another.
    
    Args:
        amount: Amount to convert
        from_currency: Source currency code (USD, EUR, INR, etc.)
        to_currency: Target currency code
    """
    result = utils_service.convert_currency(amount, from_currency, to_currency)
    return json.dumps({"result": result})


@tool
def convert_units(value: float, from_unit: str, to_unit: str) -> str:
    """Converts units (length, weight, temperature).
    
    Args:
        value: Value to convert
        from_unit: Source unit (m, km, kg, lb, c, f, etc.)
        to_unit: Target unit
    """
    result = utils_service.convert_units(value, from_unit, to_unit)
    return json.dumps({"result": result})


@tool
def daily_digest() -> str:
    """Creates a quick daily digest of tasks, calendar, and unread email count."""
    ist = _get_ist_timezone()
    today = datetime.now(ist).date()
    try:
        tasks = google_tasks_service.list_tasks(
            task_list_id="@default",
            show_completed=False,
            max_results=100
        )
    except Exception as e:
        logger.error(f"Error fetching tasks for digest: {e}")
        tasks = []
    events = calendar_service.get_events()
    today_events = []
    for e in events:
        if isinstance(e, dict) and "error" not in e:
            start = e.get("start", "")
            if start:
                try:
                    event_dt = datetime.fromisoformat(start.replace("Z", "+00:00")).date()
                    if event_dt == today:
                        today_events.append(e)
                except ValueError:
                    continue
    unread = gmail_service.get_unread_count()
    return json.dumps({
        "pending_tasks": len(tasks),
        "today_events": len(today_events),
        "unread_emails": unread
    })


def get_all_tools():
    """Returns all available LangChain tools"""
    return [
        # Task tools
        create_task,
        list_tasks,
        complete_task,
        update_task,
        delete_task,
        search_tasks,
        # Calendar tools
        get_calendar_today,
        get_calendar_events,
        get_calendar_range,
        create_calendar_event,
        # Email tools
        get_unread_emails_summary,
        summarize_emails,
        send_email,
        search_emails,
        # Contact tools
        add_contact,
        get_email_address,
        get_phone_number,
        list_contacts,
        # Notes tools
        take_notes,
        get_notes,
        # Weather tools
        get_weather,
        get_forecast,
        # Search tools
        web_search,
        get_news,
        # Utility tools
        calculate,
        get_time_now,
        convert_currency,
        convert_units,
        daily_digest,
    ]


def get_mcp_tools_as_langchain():
    """Dynamically convert MCP tools to LangChain tools"""
    from langchain_core.tools import StructuredTool
    
    mcp_tools = []
    mcp_tool_defs = mcp_service.get_all_tools_for_llm()
    
    for tool_def in mcp_tool_defs:
        func_def = tool_def.get("function", {})
        tool_name = func_def.get("name", "")
        description = func_def.get("description", "")
        
        # Create a closure to capture the tool name
        def make_mcp_executor(name):
            def execute_mcp(**kwargs):
                return mcp_service.execute_tool_sync(name, kwargs)
            return execute_mcp
        
        mcp_tool = StructuredTool.from_function(
            func=make_mcp_executor(tool_name),
            name=tool_name,
            description=description,
        )
        mcp_tools.append(mcp_tool)
    
    return mcp_tools
