"""
Tests for configuration and settings module.
"""
import pytest
from unittest.mock import patch
import os


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
            'CORS_ORIGINS': '*'
        }):
            settings = Settings()
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
            'CORS_ORIGINS': 'http://localhost:3000,https://myapp.com'
        }):
            settings = Settings()
            assert settings.cors_origins_list == ['http://localhost:3000', 'https://myapp.com']

    def test_default_port(self):
        """Test default port is 8080."""
        from app.config import Settings
        
        with patch.dict(os.environ, {
            'GEMINI_API_KEY': 'test',
            'GROQ_API_KEY': 'test',
            'GOOGLE_CLIENT_ID': 'test',
            'GOOGLE_CLIENT_SECRET': 'test',
            'GOOGLE_REDIRECT_URI': 'http://test',
        }):
            settings = Settings()
            assert settings.PORT == 8080

    def test_secret_key_empty_by_default(self):
        """Test SECRET_KEY is empty by default (must be set in production)."""
        from app.config import Settings
        
        with patch.dict(os.environ, {
            'GEMINI_API_KEY': 'test',
            'GROQ_API_KEY': 'test',
            'GOOGLE_CLIENT_ID': 'test',
            'GOOGLE_CLIENT_SECRET': 'test',
            'GOOGLE_REDIRECT_URI': 'http://test',
        }, clear=False):
            # Remove SECRET_KEY if it exists
            env = os.environ.copy()
            env.pop('SECRET_KEY', None)
            with patch.dict(os.environ, env, clear=True):
                settings = Settings()
                assert settings.SECRET_KEY == ''
