from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from groq import Groq
import os
import logging
from app.config import settings

router = APIRouter()
logger = logging.getLogger(__name__)

class TTSRequest(BaseModel):
    text: str
    voice: str = "orpheus"  # Default voice

# Available voices for Groq TTS
AVAILABLE_VOICES = ["orpheus", "charon", "lethe", "proteus", "zeus", "atlas", "hera"]

@router.post("/synthesize")
async def synthesize_speech(request: TTSRequest):
    """Convert text to speech using Groq Playback TTS API."""
    if not request.text or len(request.text.strip()) == 0:
        raise HTTPException(status_code=400, detail="Text cannot be empty")
    
    # Limit text length to prevent abuse
    if len(request.text) > 5000:
        raise HTTPException(status_code=400, detail="Text too long. Maximum 5000 characters.")
    
    try:
        api_key = getattr(settings, "GROQ_API_KEY", None) or os.environ.get("GROQ_API_KEY")
        if not api_key:
            raise HTTPException(status_code=500, detail="GROQ_API_KEY not configured")
        
        client = Groq(api_key=api_key)
        
        # Use Groq's TTS API with Canopylabs Orpheus model
        response = client.audio.speech.create(
            model="playai-tts",  # Groq's PlayAI TTS model (or use "canopylabs/orpheus-v1-english")
            voice=request.voice if request.voice in AVAILABLE_VOICES else "Arista-PlayAI",
            input=request.text,
            response_format="mp3"
        )
        
        # Stream the audio response
        def audio_stream():
            for chunk in response.iter_bytes(chunk_size=4096):
                yield chunk
        
        return StreamingResponse(
            audio_stream(),
            media_type="audio/mpeg",
            headers={"Content-Disposition": "inline; filename=speech.mp3"}
        )
        
    except Exception as e:
        logger.error(f"TTS error: {e}")
        raise HTTPException(status_code=500, detail=f"TTS synthesis failed: {str(e)}")

@router.get("/voices")
async def get_voices():
    """Get list of available TTS voices."""
    return {
        "voices": [
            {"id": "orpheus", "name": "Orpheus", "description": "Male, neutral"},
            {"id": "charon", "name": "Charon", "description": "Male, deep"},
            {"id": "lethe", "name": "Lethe", "description": "Female, soft"},
            {"id": "proteus", "name": "Proteus", "description": "Male, dynamic"},
            {"id": "zeus", "name": "Zeus", "description": "Male, authoritative"},
            {"id": "atlas", "name": "Atlas", "description": "Male, calm"},
            {"id": "hera", "name": "Hera", "description": "Female, warm"},
        ]
    }
