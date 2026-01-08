import logging
from supabase import create_client, Client
from app.config import settings

logger = logging.getLogger(__name__)

url: str = settings.SUPABASE_URL
key: str = settings.SUPABASE_KEY

if not url or "supabase.co" not in url:
    logger.warning("SUPABASE_URL is not set or invalid. Supabase calls will fail.")
    # Fallback to avoid immediate crash on import, but failures on usage
    if not url:
        url = "https://placeholder.supabase.co" 

if not key:
    logger.warning("SUPABASE_KEY is not set.")

try:
    supabase_client: Client = create_client(url, key)
except Exception as e:
    logger.error(f"Failed to initialize Supabase client: {e}")
    # Create a dummy client or re-raise? 
    # Allowing it to crash might be better to signal config error, 
    # but to keep app alive we might just log.
    supabase_client = None
