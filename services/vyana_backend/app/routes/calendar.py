from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, List
from app.services.calendar_service import calendar_service

router = APIRouter()

# =============================================================================
# Calendar List Endpoints
# =============================================================================

@router.get("/calendars")
def list_calendars():
    """List all available calendars for the authenticated user"""
    return {"calendars": calendar_service.list_calendars()}

# =============================================================================
# Event Endpoints
# =============================================================================

@router.get("/events")
def get_events(
    date: Optional[str] = None, 
    start: Optional[str] = None, 
    end: Optional[str] = None, 
    user_id: Optional[str] = None, 
    calendar_id: Optional[str] = None
):
    """Get events for a date range"""
    return {"events": calendar_service.get_events(
        start_date_str=start or date, 
        end_date_str=end, 
        user_id=user_id, 
        calendar_id=calendar_id
    )}

@router.get("/today")
def get_events_today(user_id: Optional[str] = None, calendar_id: Optional[str] = None):
    """Get today's events (deprecated, use /events)"""
    return {"events": calendar_service.get_events(None, user_id=user_id, calendar_id=calendar_id)}


class CreateEventRequest(BaseModel):
    summary: str
    start_time: str
    duration_minutes: int = 60
    description: Optional[str] = None
    user_id: Optional[str] = None
    calendar_id: Optional[str] = None
    # New features
    is_all_day: bool = False
    recurrence: Optional[str] = None  # DAILY, WEEKLY, MONTHLY, YEARLY
    recurrence_count: Optional[int] = None
    recurrence_until: Optional[str] = None  # YYYY-MM-DD
    add_meet_link: bool = False
    color_id: Optional[str] = None
    reminders: Optional[List[int]] = None  # List of minutes before event
    location: Optional[str] = None
    attendees: Optional[List[str]] = None  # List of email addresses


@router.post("/create")
def create_event(req: CreateEventRequest):
    """Create a new calendar event with full feature support"""
    result = calendar_service.create_event(
        summary=req.summary,
        start_time=req.start_time,
        duration_minutes=req.duration_minutes,
        description=req.description,
        user_id=req.user_id,
        calendar_id=req.calendar_id,
        is_all_day=req.is_all_day,
        recurrence=req.recurrence,
        recurrence_count=req.recurrence_count,
        recurrence_until=req.recurrence_until,
        add_meet_link=req.add_meet_link,
        color_id=req.color_id,
        reminders=req.reminders,
        location=req.location,
        attendees=req.attendees,
    )
    # For backward compatibility, include 'result' key
    if isinstance(result, dict):
        result['result'] = result.get('message', '')
    return result


class UpdateEventRequest(BaseModel):
    id: str
    summary: Optional[str] = None
    start_time: Optional[str] = None
    duration_minutes: Optional[int] = None
    description: Optional[str] = None
    calendar_id: Optional[str] = None
    # New features
    is_all_day: Optional[bool] = None
    color_id: Optional[str] = None
    reminders: Optional[List[int]] = None
    location: Optional[str] = None
    add_meet_link: bool = False


@router.put("/update")
def update_event(req: UpdateEventRequest):
    """Update an existing calendar event"""
    result = calendar_service.update_event(
        event_id=req.id,
        summary=req.summary,
        start_time=req.start_time,
        duration_minutes=req.duration_minutes,
        description=req.description,
        calendar_id=req.calendar_id,
        is_all_day=req.is_all_day,
        color_id=req.color_id,
        reminders=req.reminders,
        location=req.location,
        add_meet_link=req.add_meet_link,
    )
    if isinstance(result, dict):
        result['result'] = result.get('message', '')
    return result


class DeleteEventRequest(BaseModel):
    id: str
    calendar_id: Optional[str] = None


@router.delete("/delete")
def delete_event(req: DeleteEventRequest):
    """Delete a calendar event"""
    result = calendar_service.delete_event(req.id, req.calendar_id)
    if isinstance(result, dict):
        result['result'] = result.get('message', '')
    return result


# =============================================================================
# Sync Endpoints (Two-way sync)
# =============================================================================

class SyncRequest(BaseModel):
    sync_token: Optional[str] = None
    calendar_id: Optional[str] = None


@router.post("/sync")
def sync_events(req: SyncRequest):
    """Get changes since last sync for two-way sync support"""
    return calendar_service.get_changes_since(req.sync_token, req.calendar_id)


# =============================================================================
# Quick Add (Natural Language)
# =============================================================================

class QuickAddRequest(BaseModel):
    text: str
    calendar_id: Optional[str] = None


@router.post("/quick-add")
def quick_add_event(req: QuickAddRequest):
    """Create event from natural language text (e.g., 'Meeting tomorrow at 3pm')"""
    result = calendar_service.quick_add(req.text, req.calendar_id)
    if isinstance(result, dict):
        result['result'] = result.get('message', '')
    return result


# =============================================================================
# Calendar Colors
# =============================================================================

@router.get("/colors")
def get_colors():
    """Get available event colors"""
    from app.services.calendar_service import CALENDAR_COLORS
    return {"colors": [{"id": k, "color": v} for k, v in CALENDAR_COLORS.items()]}

