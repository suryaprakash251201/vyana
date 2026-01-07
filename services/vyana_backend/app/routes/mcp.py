"""
MCP (Model Context Protocol) API Routes
Provides endpoints for managing MCP connections from the Flutter app.
"""

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import RedirectResponse, HTMLResponse
from pydantic import BaseModel
from typing import Optional
import httpx

from app.services.mcp_service import mcp_service, KNOWN_MCP_SERVERS
from app.config import settings

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
    
    If ZERODHA_API_KEY is configured, uses Kite Connect API OAuth.
    Otherwise, uses Zerodha's hosted MCP at mcp.kite.trade.
    """
    # Check if custom Kite Connect API is configured
    if settings.ZERODHA_API_KEY:
        # Use Kite Connect OAuth
        auth_url = f"https://kite.zerodha.com/connect/login?v=3&api_key={settings.ZERODHA_API_KEY}"
        return {"auth_url": auth_url, "mode": "kite_connect"}
    else:
        # Use hosted MCP (no API key needed)
        config = KNOWN_MCP_SERVERS.get("zerodha")
        if not config:
            raise HTTPException(status_code=404, detail="Zerodha MCP not configured")
        return {"auth_url": config.auth_url, "mode": "hosted_mcp"}


@router.get("/zerodha/callback")
async def zerodha_callback(
    request_token: Optional[str] = Query(None),
    action: Optional[str] = Query(None),
    status: Optional[str] = Query(None)
):
    """
    Handle OAuth callback from Zerodha Kite.
    
    After the user authenticates on Zerodha, they are redirected here
    with a request_token. We exchange it for an access_token and connect.
    """
    if action == "login" and status == "cancelled":
        return HTMLResponse("""
        <html>
        <body style="font-family: sans-serif; text-align: center; padding: 50px;">
            <h2>❌ Authentication Cancelled</h2>
            <p>You cancelled the Zerodha login. Please try again from the app.</p>
            <script>setTimeout(() => window.close(), 3000);</script>
        </body>
        </html>
        """)
    
    if not request_token:
        raise HTTPException(status_code=400, detail="Missing request_token")
    
    # If using Kite Connect API, exchange request_token for access_token
    if settings.ZERODHA_API_KEY and settings.ZERODHA_API_SECRET:
        try:
            import hashlib
            # Generate checksum: SHA256(api_key + request_token + api_secret)
            checksum = hashlib.sha256(
                (settings.ZERODHA_API_KEY + request_token + settings.ZERODHA_API_SECRET).encode()
            ).hexdigest()
            
            # Exchange for access token
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    "https://api.kite.trade/session/token",
                    data={
                        "api_key": settings.ZERODHA_API_KEY,
                        "request_token": request_token,
                        "checksum": checksum
                    }
                )
                
                if response.status_code == 200:
                    data = response.json()
                    access_token = data.get("data", {}).get("access_token")
                    
                    if access_token:
                        # Connect to Zerodha MCP with access token
                        result = await mcp_service.connect("zerodha", access_token)
                        
                        if result.get("success"):
                            return HTMLResponse(f"""
                            <html>
                            <body style="font-family: sans-serif; text-align: center; padding: 50px;">
                                <h2>✅ Connected to Zerodha!</h2>
                                <p>Discovered {result.get('tools_count', 0)} tools.</p>
                                <p>You can close this window and return to the app.</p>
                                <script>setTimeout(() => window.close(), 3000);</script>
                            </body>
                            </html>
                            """)
                        else:
                            raise HTTPException(status_code=400, detail=result.get("error"))
                    else:
                        raise HTTPException(status_code=400, detail="No access token in response")
                else:
                    raise HTTPException(status_code=400, detail=f"Token exchange failed: {response.text}")
                    
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"OAuth error: {str(e)}")
    else:
        # Hosted MCP mode - just use request_token directly
        result = await mcp_service.connect("zerodha", request_token)
        
        if result.get("success"):
            return HTMLResponse(f"""
            <html>
            <body style="font-family: sans-serif; text-align: center; padding: 50px;">
                <h2>✅ Connected to Zerodha!</h2>
                <p>Discovered {result.get('tools_count', 0)} tools.</p>
                <p>You can close this window and return to the app.</p>
                <script>setTimeout(() => window.close(), 3000);</script>
            </body>
            </html>
            """)
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

