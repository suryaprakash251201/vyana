from fastapi import APIRouter, UploadFile, File, HTTPException
from app.services.groq_client import groq_client
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")
    
    try:
        content = await file.read()
        logger.info(f"Transcribing audio file: {file.filename} size: {len(content)}")
        transcription = groq_client.transcribe_audio(content, file.filename)
        return {"text": transcription}
    except Exception as e:
        logger.error(f"Transcription error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
