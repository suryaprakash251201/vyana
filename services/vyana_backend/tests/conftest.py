"""
Pytest configuration and shared fixtures.
"""
import pytest
import os
from unittest.mock import patch


@pytest.fixture(autouse=True)
def mock_env_vars():
    """Ensure required environment variables are set for tests."""
    env_vars = {
        'GEMINI_API_KEY': 'test_gemini_key',
        'GROQ_API_KEY': 'test_groq_key',
        'GOOGLE_CLIENT_ID': 'test_client_id',
        'GOOGLE_CLIENT_SECRET': 'test_client_secret',
        'GOOGLE_REDIRECT_URI': 'http://localhost:8080/callback',
        'SECRET_KEY': 'test_secret_key',
        'DEBUG': 'true',
    }
    with patch.dict(os.environ, env_vars, clear=False):
        yield


@pytest.fixture
def test_client():
    """Create an async test client for the FastAPI app."""
    from httpx import AsyncClient, ASGITransport
    from app.main import app
    
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")
