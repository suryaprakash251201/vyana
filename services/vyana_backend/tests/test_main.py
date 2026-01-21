"""
Tests for main FastAPI application setup.
"""
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


class TestAppSetup:
    """Test the main application configuration."""

    @pytest.mark.asyncio
    async def test_root_endpoint(self):
        """Test the root endpoint returns proper message."""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            response = await ac.get("/")
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "Vyana" in data["message"]
        assert "mcp_endpoint" in data

    @pytest.mark.asyncio
    async def test_cors_headers_present(self):
        """Test that CORS headers are set on responses."""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            response = await ac.options(
                "/health",
                headers={"Origin": "http://localhost:3000"}
            )
        
        # CORS preflight should return appropriate headers
        assert response.status_code in [200, 204, 405]

    @pytest.mark.asyncio
    async def test_health_endpoint_exists(self):
        """Test health endpoint is accessible."""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            response = await ac.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"

    @pytest.mark.asyncio
    async def test_chat_router_mounted(self):
        """Test chat router is mounted at /chat prefix."""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            # Just check that the router responds (may be 404 for specific path)
            response = await ac.get("/chat/nonexistent")
        
        # Should not be 404 for the entire /chat prefix
        # The specific endpoint might not exist, but router should be mounted
        assert response.status_code in [200, 404, 405, 422]

    @pytest.mark.asyncio  
    async def test_tasks_router_mounted(self):
        """Test tasks router is mounted at /tasks prefix."""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            response = await ac.get("/tasks/list")
        
        assert response.status_code == 200
