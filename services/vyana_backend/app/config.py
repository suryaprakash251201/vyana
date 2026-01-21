import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List

class Settings(BaseSettings):
    PORT: int = 8080
    HOST: str = "0.0.0.0"
    
    # SECURITY: No default - must be set in .env for production
    SECRET_KEY: str = ""
    
    # CORS Configuration - comma-separated origins for production security
    # Example: "http://localhost:3000,https://myapp.com"
    CORS_ORIGINS: str = "*"  # Default to all for development
    
    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS_ORIGINS into a list. Use ['*'] for all origins."""
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]
    
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
    
    # Search API (Optional - for web search)
    # Get free API key from: https://serpapi.com/
    SERP_API_KEY: str = ""

    # Feature Toggles (Can be overriden by env or at runtime via API if we adding mutable state)
    ENABLE_TOOLS: bool = True
    TAMIL_MODE: bool = False

    # MCP Server Configuration
    MCP_SERVER_NAME: str = "VyanaMCP"
    MCP_SERVER_PATH: str = "/mcp-server"
    
    # Environment indicator
    DEBUG: bool = True

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding='utf-8', extra='ignore')

settings = Settings()

