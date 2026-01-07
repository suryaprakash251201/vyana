"""
MCP (Model Context Protocol) Service
Manages multiple MCP server connections and provides tool integration for the AI.
"""

import os
import json
import logging
import asyncio
import httpx
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum

from app.config import settings

# Setup logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


class MCPConnectionStatus(str, Enum):
    DISCONNECTED = "disconnected"
    CONNECTING = "connecting"
    CONNECTED = "connected"
    ERROR = "error"


@dataclass
class MCPConnection:
    """Represents a single MCP server connection"""
    name: str  # e.g., "zerodha", "notion"
    display_name: str  # e.g., "Zerodha Kite"
    url: str  # MCP server URL
    status: MCPConnectionStatus = MCPConnectionStatus.DISCONNECTED
    auth_token: Optional[str] = None  # User's OAuth token for this MCP
    tools: List[dict] = field(default_factory=list)  # Discovered tools from this MCP
    error_message: Optional[str] = None
    icon: str = "🔌"  # Emoji icon for UI


@dataclass
class MCPServerConfig:
    """Configuration for a known MCP server"""
    name: str
    display_name: str
    url: str
    auth_url: Optional[str]  # OAuth initiation URL
    requires_api_key: bool
    icon: str
    description: str


# Registry of known MCP servers
KNOWN_MCP_SERVERS: Dict[str, MCPServerConfig] = {
    "zerodha": MCPServerConfig(
        name="zerodha",
        display_name="Zerodha Kite",
        url="https://mcp.kite.trade/mcp",
        auth_url="https://mcp.kite.trade/",  # Zerodha hosted MCP has built-in auth
        requires_api_key=False,  # Hosted MCP handles auth internally
        icon="📈",
        description="Access your Zerodha trading account - view holdings, positions, and market data"
    ),
    # Future MCPs can be added here
    # "notion": MCPServerConfig(...),
    # "github": MCPServerConfig(...),
}


class MCPService:
    """
    Manages multiple MCP connections and provides unified tool access for AI.
    
    Architecture:
    - Maintains a registry of active connections
    - Discovers tools from connected MCP servers
    - Converts MCP tools to OpenAI/Groq function calling format
    - Executes MCP tool calls and returns results
    """
    
    def __init__(self):
        self.connections: Dict[str, MCPConnection] = {}
        self.http_client = httpx.AsyncClient(timeout=30.0)
        logger.info("MCPService initialized")
    
    def get_known_servers(self) -> List[dict]:
        """Get list of all known MCP servers with their connection status"""
        servers = []
        for name, config in KNOWN_MCP_SERVERS.items():
            connection = self.connections.get(name)
            servers.append({
                "name": config.name,
                "display_name": config.display_name,
                "icon": config.icon,
                "description": config.description,
                "status": connection.status.value if connection else "disconnected",
                "requires_api_key": config.requires_api_key,
                "tools_count": len(connection.tools) if connection else 0
            })
        return servers
    
    async def connect(self, name: str, auth_token: Optional[str] = None) -> dict:
        """
        Connect to an MCP server.
        
        Args:
            name: Name of the MCP server (e.g., "zerodha")
            auth_token: OAuth token if required
            
        Returns:
            Connection status and discovered tools
        """
        if name not in KNOWN_MCP_SERVERS:
            return {"success": False, "error": f"Unknown MCP server: {name}"}
        
        config = KNOWN_MCP_SERVERS[name]
        
        # Create or update connection
        connection = MCPConnection(
            name=config.name,
            display_name=config.display_name,
            url=config.url,
            status=MCPConnectionStatus.CONNECTING,
            auth_token=auth_token,
            icon=config.icon
        )
        self.connections[name] = connection
        
        try:
            # Discover tools from the MCP server
            tools = await self._discover_tools(connection)
            connection.tools = tools
            connection.status = MCPConnectionStatus.CONNECTED
            
            logger.info(f"Connected to {name} MCP, discovered {len(tools)} tools")
            return {
                "success": True,
                "name": name,
                "tools_count": len(tools),
                "tools": [t.get("name", "unknown") for t in tools]
            }
            
        except Exception as e:
            connection.status = MCPConnectionStatus.ERROR
            connection.error_message = str(e)
            logger.error(f"Failed to connect to {name} MCP: {e}")
            return {"success": False, "error": str(e)}
    
    async def disconnect(self, name: str) -> dict:
        """Disconnect from an MCP server"""
        if name in self.connections:
            del self.connections[name]
            logger.info(f"Disconnected from {name} MCP")
            return {"success": True, "name": name}
        return {"success": False, "error": f"Not connected to {name}"}
    
    async def _discover_tools(self, connection: MCPConnection) -> List[dict]:
        """
        Discover available tools from an MCP server.
        
        MCP uses JSON-RPC 2.0, so we send a tools/list request.
        """
        try:
            # MCP protocol: JSON-RPC 2.0 over HTTP
            request_body = {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/list",
                "params": {}
            }
            
            headers = {"Content-Type": "application/json"}
            if connection.auth_token:
                headers["Authorization"] = f"Bearer {connection.auth_token}"
            
            response = await self.http_client.post(
                connection.url,
                json=request_body,
                headers=headers
            )
            
            if response.status_code == 200:
                result = response.json()
                if "result" in result and "tools" in result["result"]:
                    return result["result"]["tools"]
                elif "error" in result:
                    raise Exception(result["error"].get("message", "Unknown error"))
            else:
                raise Exception(f"HTTP {response.status_code}: {response.text}")
                
        except httpx.RequestError as e:
            logger.error(f"Network error discovering tools: {e}")
            raise Exception(f"Network error: {str(e)}")
    
    async def execute_tool(self, mcp_name: str, tool_name: str, arguments: dict) -> str:
        """
        Execute a tool on an MCP server.
        
        Args:
            mcp_name: Name of the MCP server
            tool_name: Name of the tool to execute
            arguments: Tool arguments
            
        Returns:
            Tool execution result as string
        """
        if mcp_name not in self.connections:
            return json.dumps({"error": f"Not connected to {mcp_name}"})
        
        connection = self.connections[mcp_name]
        
        try:
            request_body = {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {
                    "name": tool_name,
                    "arguments": arguments
                }
            }
            
            headers = {"Content-Type": "application/json"}
            if connection.auth_token:
                headers["Authorization"] = f"Bearer {connection.auth_token}"
            
            response = await self.http_client.post(
                connection.url,
                json=request_body,
                headers=headers
            )
            
            if response.status_code == 200:
                result = response.json()
                if "result" in result:
                    # MCP returns content array
                    content = result["result"].get("content", [])
                    if content:
                        # Extract text from content items
                        texts = [item.get("text", str(item)) for item in content if "text" in item]
                        return "\n".join(texts) if texts else json.dumps(content)
                    return json.dumps(result["result"])
                elif "error" in result:
                    return json.dumps({"error": result["error"].get("message", "Unknown error")})
            
            return json.dumps({"error": f"HTTP {response.status_code}"})
            
        except Exception as e:
            logger.error(f"Error executing MCP tool {tool_name}: {e}")
            return json.dumps({"error": str(e)})
    
    def execute_tool_sync(self, full_tool_name: str, arguments: dict) -> str:
        """
        Synchronous wrapper for execute_tool.
        Tool name format: mcp_{mcp_name}_{tool_name}
        """
        # Parse tool name: mcp_zerodha_get_holdings -> zerodha, get_holdings
        parts = full_tool_name.split("_", 2)
        if len(parts) < 3 or parts[0] != "mcp":
            return json.dumps({"error": f"Invalid MCP tool name format: {full_tool_name}"})
        
        mcp_name = parts[1]
        tool_name = parts[2]
        
        # Run async in event loop
        try:
            loop = asyncio.get_event_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
        
        return loop.run_until_complete(self.execute_tool(mcp_name, tool_name, arguments))
    
    def get_all_tools_for_llm(self) -> List[dict]:
        """
        Get all MCP tools in OpenAI/Groq function calling format.
        
        Converts MCP tool schemas to OpenAI function format and prefixes
        tool names with mcp_{mcp_name}_ to avoid conflicts.
        """
        all_tools = []
        
        for mcp_name, connection in self.connections.items():
            if connection.status != MCPConnectionStatus.CONNECTED:
                continue
                
            for tool in connection.tools:
                # Convert MCP tool to OpenAI format
                # MCP format: {name, description, inputSchema}
                # OpenAI format: {type: "function", function: {name, description, parameters}}
                
                mcp_tool_name = tool.get("name", "unknown")
                prefixed_name = f"mcp_{mcp_name}_{mcp_tool_name}"
                
                openai_tool = {
                    "type": "function",
                    "function": {
                        "name": prefixed_name,
                        "description": f"[{connection.display_name}] {tool.get('description', 'No description')}",
                        "parameters": tool.get("inputSchema", {"type": "object", "properties": {}})
                    }
                }
                all_tools.append(openai_tool)
        
        return all_tools
    
    def is_mcp_tool(self, tool_name: str) -> bool:
        """Check if a tool name is an MCP tool"""
        return tool_name.startswith("mcp_")
    
    def get_connection_status(self, name: str) -> dict:
        """Get status of a specific MCP connection"""
        if name in self.connections:
            conn = self.connections[name]
            return {
                "name": conn.name,
                "display_name": conn.display_name,
                "status": conn.status.value,
                "tools_count": len(conn.tools),
                "error": conn.error_message
            }
        return {
            "name": name,
            "status": "disconnected",
            "tools_count": 0
        }


# Global singleton instance
mcp_service = MCPService()
