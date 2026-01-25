import logging
from supabase import create_client, Client
from app.config import settings

logger = logging.getLogger(__name__)

url: str = settings.SUPABASE_URL
key: str = settings.SUPABASE_KEY

if not url:
    raise RuntimeError("SUPABASE_URL must be configured")
if not key:
    raise RuntimeError("SUPABASE_KEY must be configured")

try:
    supabase_client: Client = create_client(url, key)
except Exception as e:
    logger.error(f"Failed to initialize Supabase client: {e}")
    raise RuntimeError("Cannot initialize Supabase client") from e
