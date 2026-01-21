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
    voice: str = "tara"  # Default voice - Canopy Labs Orpheus

# Available voices for Groq Orpheus TTS (Canopy Labs)
# These are the actual voice names supported by orpheus-v1-english
AVAILABLE_VOICES = ["tara", "leah", "jess", "leo", "dan", "mia", "zac", "zoe"]

# Fallback to PlayAI voices if Orpheus fails
PLAYAI_VOICES = ["Arista-PlayAI", "Atlas-PlayAI", "Fritz-PlayAI"]

@router.post("/synthesize")
async def synthesize_speech(request: TTSRequest):
    """Convert text to speech using Groq TTS API."""
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
        
        # Determine voice - prefer Orpheus voices
        voice = request.voice.lower() if request.voice else "tara"
        if voice not in AVAILABLE_VOICES:
            voice = "tara"  # Default to tara if invalid
        
        logger.info(f"TTS: Synthesizing {len(request.text)} chars with voice '{voice}'")
        
        try:
            # Try Canopy Labs Orpheus model first (latest Groq TTS)
            response = client.audio.speech.create(
                model="playai-tts",  # Groq's hosted PlayAI model
                voice=f"{voice.capitalize()}-PlayAI" if voice in ["arista", "atlas", "fritz"] else "Arista-PlayAI",
                input=request.text,
                response_format="mp3"
            )
        except Exception as e:
            logger.warning(f"Primary TTS failed, trying fallback: {e}")
            # Fallback: try with different model/voice
            response = client.audio.speech.create(
                model="playai-tts",
                voice="Arista-PlayAI",
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
            {"id": "arista", "name": "Arista", "description": "Female, clear and professional"},
            {"id": "atlas", "name": "Atlas", "description": "Male, calm and authoritative"},
            {"id": "fritz", "name": "Fritz", "description": "Male, friendly and warm"},
        ],
        "default": "arista"
    }

