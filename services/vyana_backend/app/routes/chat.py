from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from app.services.groq_client import groq_client

router = APIRouter()

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    conversation_id: Optional[str] = None
    messages: List[ChatMessage]
    settings: Dict[str, Any] = {}

@router.post("/stream")
async def chat_stream(req: ChatRequest):
    return StreamingResponse(
        groq_client.stream_chat(
            req.messages, 
            req.conversation_id or "default", 
            tools_enabled=req.settings.get("tools_enabled", True),
            model_name=req.settings.get("model", "llama-3.1-8b-instant"),
            memory_enabled=req.settings.get("memory_enabled", True),
            custom_instructions=req.settings.get("custom_instructions", ""),
            mcp_enabled=req.settings.get("mcp_enabled", True)
        ),
        media_type="text/event-stream"
    )

@router.post("/send")
async def chat_send(req: ChatRequest):
    response_content = await groq_client.chat_sync(
        req.messages,
        req.conversation_id or "default",
        tools_enabled=req.settings.get("tools_enabled", True),
        model_name=req.settings.get("model", "llama-3.1-8b-instant"),
        memory_enabled=req.settings.get("memory_enabled", True),
        custom_instructions=req.settings.get("custom_instructions", ""),
        mcp_enabled=req.settings.get("mcp_enabled", True)
    )
    return {
        "response": response_content,
        "conversation_id": req.conversation_id or "default"
    }
