"""
MCP (Model Context Protocol) API Routes
Provides endpoints for managing MCP connections from the Flutter app.
"""

from fastapi import APIRouter, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from typing import Optional

from app.services.mcp_service import mcp_service, KNOWN_MCP_SERVERS

router = APIRouter(prefix="/mcp", tags=["MCP"])


class ConnectRequest(BaseModel):
    name: str
    auth_token: Optional[str] = None


class DisconnectRequest(BaseModel):
    name: str


@router.get("/servers")
async def list_servers():
    """
    List all known MCP servers with their connection status.
    Returns available MCPs that can be connected.
    """
    return {"servers": mcp_service.get_known_servers()}


@router.get("/connections")
async def list_connections():
    """
    List all active MCP connections.
    """
    connections = []
    for name in mcp_service.connections:
        connections.append(mcp_service.get_connection_status(name))
    return {"connections": connections}


@router.post("/connect")
async def connect(request: ConnectRequest):
    """
    Connect to an MCP server.
    
    Args:
        name: Name of the MCP server (e.g., "zerodha")
        auth_token: Optional OAuth token
    """
    result = await mcp_service.connect(request.name, request.auth_token)
    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("error", "Connection failed"))
    return result


@router.post("/disconnect")
async def disconnect(request: DisconnectRequest):
    """
    Disconnect from an MCP server.
    """
    result = await mcp_service.disconnect(request.name)
    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("error", "Disconnect failed"))
    return result


@router.get("/status/{name}")
async def get_status(name: str):
    """
    Get connection status for a specific MCP server.
    """
    return mcp_service.get_connection_status(name)


# ============================================================================
# Zerodha Kite MCP OAuth Flow
# ============================================================================

@router.get("/zerodha/auth")
async def zerodha_auth():
    """
    Initiate Zerodha OAuth flow.
    
    Zerodha's hosted MCP at mcp.kite.trade handles OAuth internally.
    This redirects the user to authenticate with Zerodha.
    """
    config = KNOWN_MCP_SERVERS.get("zerodha")
    if not config:
        raise HTTPException(status_code=404, detail="Zerodha MCP not configured")
    
    # Zerodha's hosted MCP URL - user will authenticate there
    return {"auth_url": config.auth_url}


@router.get("/zerodha/callback")
async def zerodha_callback(request_token: Optional[str] = None, action: Optional[str] = None):
    """
    Handle OAuth callback from Zerodha.
    
    After the user authenticates on Zerodha, they are redirected here.
    We then connect to the Zerodha MCP with the auth token.
    """
    if not request_token:
        raise HTTPException(status_code=400, detail="Missing request_token")
    
    # Connect to Zerodha MCP with the token
    result = await mcp_service.connect("zerodha", request_token)
    
    if result.get("success"):
        # Return success page or redirect to app
        return {
            "status": "connected",
            "message": "Successfully connected to Zerodha",
            "tools_discovered": result.get("tools_count", 0)
        }
    else:
        raise HTTPException(status_code=400, detail=result.get("error", "Connection failed"))


@router.get("/tools")
async def list_all_tools():
    """
    List all tools from all connected MCP servers.
    This is useful for debugging and understanding available capabilities.
    """
    tools = mcp_service.get_all_tools_for_llm()
    return {
        "total_tools": len(tools),
        "tools": [
            {
                "name": t["function"]["name"],
                "description": t["function"]["description"]
            }
            for t in tools
        ]
    }
