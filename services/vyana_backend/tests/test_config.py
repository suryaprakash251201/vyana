"""
Tests for configuration and settings module.
"""
import pytest
from unittest.mock import patch
import os
from pydantic import ValidationError


class TestSettings:
    """Test the Settings configuration class."""

    def test_cors_origins_list_returns_wildcard(self):
        """Test that CORS_ORIGINS='*' returns ['*']."""
        from app.config import Settings
        
        with patch.dict(os.environ, {
            'GEMINI_API_KEY': 'test',
            'GROQ_API_KEY': 'test',
            'GOOGLE_CLIENT_ID': 'test',
            'GOOGLE_CLIENT_SECRET': 'test',
            'GOOGLE_REDIRECT_URI': 'http://test',
            'CORS_ORIGINS': '*',
            'SUPABASE_URL': 'https://test.supabase.co',
            'SUPABASE_KEY': 'test_supabase_key',
            'SECRET_KEY': 'test_secret'
        }):
            settings = Settings(_env_file=None)
            assert settings.cors_origins_list == ['*']

    def test_cors_origins_list_parses_multiple(self):
        """Test that comma-separated origins are parsed correctly."""
        from app.config import Settings
        
        with patch.dict(os.environ, {
            'GEMINI_API_KEY': 'test',
            'GROQ_API_KEY': 'test',
            'GOOGLE_CLIENT_ID': 'test',
            'GOOGLE_CLIENT_SECRET': 'test',
            'GOOGLE_REDIRECT_URI': 'http://test',
            'CORS_ORIGINS': 'http://localhost:3000,https://myapp.com',
            'SUPABASE_URL': 'https://test.supabase.co',
            'SUPABASE_KEY': 'test_supabase_key',
            'SECRET_KEY': 'test_secret'
        }):
            settings = Settings(_env_file=None)
            assert settings.cors_origins_list == ['http://localhost:3000', 'https://myapp.com']

    def test_port_env_override(self):
        """Test port can be overridden via environment variable."""
        from app.config import Settings
        
        with patch.dict(os.environ, {
            'GEMINI_API_KEY': 'test',
            'GROQ_API_KEY': 'test',
            'GOOGLE_CLIENT_ID': 'test',
            'GOOGLE_CLIENT_SECRET': 'test',
            'GOOGLE_REDIRECT_URI': 'http://test',
            'SUPABASE_URL': 'https://test.supabase.co',
            'SUPABASE_KEY': 'test_supabase_key',
            'SECRET_KEY': 'test_secret',
            'PORT': '9090'
        }):
            settings = Settings(_env_file=None)
            assert settings.PORT == 9090

    def test_secret_key_required(self):
        """Test SECRET_KEY must be provided."""
        from app.config import Settings
        
        with patch.dict(os.environ, {
            'GEMINI_API_KEY': 'test',
            'GROQ_API_KEY': 'test',
            'GOOGLE_CLIENT_ID': 'test',
            'GOOGLE_CLIENT_SECRET': 'test',
            'GOOGLE_REDIRECT_URI': 'http://test',
            'SUPABASE_URL': 'https://test.supabase.co',
            'SUPABASE_KEY': 'test_supabase_key',
            'SECRET_KEY': 'test_secret'
        }, clear=False):
            # Remove SECRET_KEY if it exists
            env = os.environ.copy()
            env.pop('SECRET_KEY', None)
            with patch.dict(os.environ, env, clear=True):
                with pytest.raises(ValidationError):
                    Settings(_env_file=None)
