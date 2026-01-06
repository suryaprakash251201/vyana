from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from app.services.calendar_service import calendar_service

router = APIRouter()

@router.get("/events")
def get_events(date: Optional[str] = None, start: Optional[str] = None, end: Optional[str] = None):
    # date/start/end format expected: YYYY-MM-DD
    # 'date' is kept for backward compatibility
    return {"events": calendar_service.get_events(start_date_str=start or date, end_date_str=end)}

@router.get("/today")
def get_events_today():
    # Deprecated fallback
    return {"events": calendar_service.get_events(None)}

class CreateEventRequest(BaseModel):
    summary: str
    start_time: str
    duration_minutes: int = 60
    description: Optional[str] = None

@router.post("/create")
def create_event(req: CreateEventRequest):
    return {"result": calendar_service.create_event(req.summary, req.start_time, req.duration_minutes, req.description)}

class UpdateEventRequest(BaseModel):
    id: str
    summary: Optional[str] = None
    start_time: Optional[str] = None
    duration_minutes: Optional[int] = None
    description: Optional[str] = None

@router.put("/update")
def update_event(req: UpdateEventRequest):
    return {"result": calendar_service.update_event(
        req.id, req.summary, req.start_time, req.duration_minutes, req.description
    )}

class DeleteEventRequest(BaseModel):
    id: str

@router.delete("/delete")
def delete_event(req: DeleteEventRequest):
    return {"result": calendar_service.delete_event(req.id)}
