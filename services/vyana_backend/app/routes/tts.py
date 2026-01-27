from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

class TTSRequest(BaseModel):
    text: str
    voice: str = "arista"  # Default voice

# TTS is currently disabled - Groq TTS was removed
# TODO: Add alternative TTS provider (e.g., OpenAI TTS, ElevenLabs, etc.)

@router.post("/synthesize")
async def synthesize_speech(request: TTSRequest):
    """Convert text to speech - Currently disabled."""
    # TTS functionality is temporarily unavailable
    # Groq was the TTS provider and has been removed
    logger.warning("TTS synthesis requested but TTS is currently disabled")
    raise HTTPException(
        status_code=503, 
        detail="Text-to-speech is temporarily unavailable. TTS provider not configured."
    )

@router.get("/voices")
async def get_voices():
    """Get list of available TTS voices."""
    # Return empty list since TTS is disabled
    return {
        "voices": [],
        "default": None,
        "message": "TTS is currently unavailable"
    }

