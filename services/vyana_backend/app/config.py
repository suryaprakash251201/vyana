import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PORT: int = 8080
    HOST: str = "0.0.0.0"
    SECRET_KEY: str = "dev_secret"
    
    GEMINI_API_KEY: str
    GEMINI_MODEL: str = "gemini-3-pro-preview"
    GROQ_API_KEY: str

    SUPABASE_URL: str = ""  # Required: set in .env
    SUPABASE_KEY: str = ""  # Required: set in .env

    GOOGLE_CLIENT_ID: str
    GOOGLE_CLIENT_SECRET: str
    GOOGLE_REDIRECT_URI: str

    # Zerodha MCP Configuration (Optional - for Kite Connect API)
    ZERODHA_API_KEY: str = ""
    ZERODHA_API_SECRET: str = ""
    ZERODHA_REDIRECT_URI: str = ""  # e.g., http://localhost:8080/mcp/zerodha/callback

    # Feature Toggles (Can be overriden by env or at runtime via API if we adding mutable state)
    ENABLE_TOOLS: bool = True
    TAMIL_MODE: bool = False

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding='utf-8', extra='ignore')

settings = Settings()
