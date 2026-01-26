"""
Supabase Client - OPTIONAL

This project uses Supabase ONLY for user authentication in the Flutter app.
All data storage (contacts, notes, tasks) uses local JSON/SQLite files.

Backend services do NOT require Supabase - they use:
- Local JSON files for contacts and notes
- SQLite for tasks
- Google OAuth for calendar/gmail/tasks API access

This file is kept for potential future Supabase auth integration on backend.
"""
import logging
from typing import Optional

logger = logging.getLogger(__name__)

# Supabase client - DISABLED by default
# Only enable if you need Supabase backend features
supabase_client = None

try:
    from supabase import create_client, Client
    from app.config import settings
    
    url: str = settings.SUPABASE_URL or ""
    key: str = settings.SUPABASE_KEY or ""

    if url and key:
        try:
            supabase_client = create_client(url, key)
            logger.info("Supabase client initialized (optional - for auth only)")
        except Exception as e:
            logger.warning(f"Supabase initialization failed (optional): {e}")
            supabase_client = None
    else:
        logger.info("Supabase not configured - all features work without it")
except ImportError:
    logger.info("Supabase package not installed - all features work without it")
