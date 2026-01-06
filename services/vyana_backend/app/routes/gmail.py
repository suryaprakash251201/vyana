from fastapi import APIRouter
from pydantic import BaseModel
from app.services.gmail_service import gmail_service

from typing import Optional

router = APIRouter()

class SummarizeRequest(BaseModel):
    max_messages: int = 5

@router.get("/unread")
def get_unread_count():
    return {"count": gmail_service.get_unread_count()}

@router.post("/summarize")
def summarize_emails(req: SummarizeRequest):
    return {"summary": gmail_service.summarize_emails(req.max_messages)}

@router.get("/list")
def list_emails(limit: int = 20, category: Optional[str] = None):
    return gmail_service.get_recent_messages(limit, category)

@router.get("/message/{message_id}")
def get_message(message_id: str):
    return gmail_service.get_message_details(message_id)

class SendEmailRequest(BaseModel):
    to_email: str
    subject: str
    body: str

@router.post("/send")
def send_email(req: SendEmailRequest):
    return {"result": gmail_service.send_email(req.to_email, req.subject, req.body)}
