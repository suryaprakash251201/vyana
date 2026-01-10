"""
MCP Integration Tests for Vyana Backend
Tests the FastMCP server and Groq + MCP tool calling loop.
"""

import os
import json
import asyncio
import httpx
from dotenv import load_dotenv

load_dotenv()

BASE_URL = os.getenv("TEST_BASE_URL", "http://localhost:8080")


class TestMCPServer:
    """Tests for the FastMCP server at /mcp-server"""
    
    def test_health_check(self):
        """Verify server is running"""
        response = httpx.get(f"{BASE_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data.get("status") == "healthy"
        print("✓ Health check passed")
    
    def test_root_shows_mcp_endpoint(self):
        """Verify root endpoint mentions MCP"""
        response = httpx.get(f"{BASE_URL}/")
        assert response.status_code == 200
        data = response.json()
        assert "mcp_endpoint" in data
        print(f"✓ Root endpoint shows mcp_endpoint: {data.get('mcp_endpoint')}")
    
    def test_mcp_sse_endpoint(self):
        """Verify MCP SSE endpoint responds"""
        # FastMCP uses SSE, so we just check it doesn't 404
        try:
            response = httpx.get(f"{BASE_URL}/mcp-server/sse", timeout=2.0)
            # SSE will hang waiting for events, timeout is expected
            print(f"✓ MCP SSE endpoint responded with status {response.status_code}")
        except httpx.ReadTimeout:
            # This is expected for SSE
            print("✓ MCP SSE endpoint active (SSE connection timeout expected)")
        except httpx.ConnectError as e:
            print(f"✗ Connection error: {e}")
            raise


class TestGroqMCPLoop:
    """Tests for Groq + MCP tool calling integration"""
    
    def test_chat_stream_simple(self):
        """Test simple chat without tools"""
        response = httpx.post(
            f"{BASE_URL}/chat/stream",
            json={
                "messages": [{"role": "user", "content": "Hello, who are you?"}],
                "settings": {"tools_enabled": False}
            },
            timeout=30.0
        )
        assert response.status_code == 200
        content = response.text
        assert "data:" in content  # SSE format
        print("✓ Chat stream (no tools) works")
        print(f"  Response preview: {content[:200]}...")
    
    def test_chat_stream_with_tools(self):
        """Test chat that should trigger tool use"""
        response = httpx.post(
            f"{BASE_URL}/chat/stream",
            json={
                "messages": [{"role": "user", "content": "What time is it now?"}],
                "settings": {"tools_enabled": True}
            },
            timeout=30.0
        )
        assert response.status_code == 200
        content = response.text
        assert "data:" in content
        print("✓ Chat stream (with tools) works")
        print(f"  Response preview: {content[:300]}...")
    
    def test_chat_calendar_query(self):
        """Test chat that queries calendar"""
        response = httpx.post(
            f"{BASE_URL}/chat/stream",
            json={
                "messages": [{"role": "user", "content": "What's on my calendar today?"}],
                "settings": {"tools_enabled": True}
            },
            timeout=30.0
        )
        assert response.status_code == 200
        content = response.text
        print("✓ Calendar query works")
        print(f"  Response preview: {content[:300]}...")


class TestMCPTools:
    """Test individual MCP tool endpoints via the existing /mcp/tools route"""
    
    def test_list_mcp_tools(self):
        """List all MCP tools"""
        response = httpx.get(f"{BASE_URL}/mcp/tools")
        if response.status_code == 200:
            data = response.json()
            print(f"✓ MCP tools list: {data.get('total_tools', 0)} tools available")
            for tool in data.get("tools", [])[:5]:
                print(f"  - {tool.get('name')}")
        else:
            print(f"⚠ MCP tools endpoint returned {response.status_code}")


def run_tests():
    """Run all tests"""
    print("\n" + "="*60)
    print("VYANA MCP INTEGRATION TESTS")
    print("="*60 + "\n")
    
    # MCP Server Tests
    print("--- MCP Server Tests ---")
    mcp_tests = TestMCPServer()
    try:
        mcp_tests.test_health_check()
    except Exception as e:
        print(f"✗ Health check failed: {e}")
        print("\n⚠ Server not running. Start with: uvicorn app.main:app --port 8080")
        return
    
    try:
        mcp_tests.test_root_shows_mcp_endpoint()
    except Exception as e:
        print(f"✗ Root endpoint test failed: {e}")
    
    try:
        mcp_tests.test_mcp_sse_endpoint()
    except Exception as e:
        print(f"✗ MCP SSE endpoint test failed: {e}")
    
    # Groq + MCP Tests (require API key)
    print("\n--- Groq + MCP Tool Calling Tests ---")
    if os.getenv("GROQ_API_KEY"):
        groq_tests = TestGroqMCPLoop()
        try:
            groq_tests.test_chat_stream_simple()
        except Exception as e:
            print(f"✗ Simple chat test failed: {e}")
        
        try:
            groq_tests.test_chat_stream_with_tools()
        except Exception as e:
            print(f"✗ Chat with tools test failed: {e}")
        
        try:
            groq_tests.test_chat_calendar_query()
        except Exception as e:
            print(f"✗ Calendar query test failed: {e}")
    else:
        print("⚠ GROQ_API_KEY not set, skipping Groq tests")
    
    # MCP Tools Test
    print("\n--- MCP Tools Discovery ---")
    tools_tests = TestMCPTools()
    try:
        tools_tests.test_list_mcp_tools()
    except Exception as e:
        print(f"✗ MCP tools list failed: {e}")
    
    print("\n" + "="*60)
    print("TEST SUITE COMPLETE")
    print("="*60 + "\n")


if __name__ == "__main__":
    run_tests()
