"""
DeepSeek AI Client for Vyana
LangGraph-based AI Agent using DeepSeek's API directly
"""
import os
import json
import logging
import re
import httpx
from typing import TypedDict, Annotated, Sequence, Literal
from datetime import datetime

from langchain_openai import ChatOpenAI
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, SystemMessage, ToolMessage
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from langgraph.graph.message import add_messages

from app.config import settings
from app.services.langgraph_tools import get_all_tools, get_mcp_tools_as_langchain
from app.services.mcp_service import mcp_service
from app.services.cache_service import cache_service

# Setup logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# DeepSeek API Configuration
DEEPSEEK_BASE_URL = "https://api.deepseek.com"
DEEPSEEK_MODELS = {
    "deepseek-chat": "deepseek-chat",
    "deepseek-reasoner": "deepseek-reasoner",
}

# Whisper API for audio transcription (using OpenAI-compatible endpoint)
WHISPER_BASE_URL = "https://api.openai.com/v1"


def _get_ist_timezone():
    """Get IST timezone object"""
    try:
        from zoneinfo import ZoneInfo
        return ZoneInfo("Asia/Kolkata")
    except ImportError:
        import pytz
        return pytz.timezone("Asia/Kolkata")


class AgentState(TypedDict):
    """State for the LangGraph agent"""
    messages: Annotated[Sequence[BaseMessage], add_messages]
    current_time: str
    current_date: str
    day_of_week: str
    custom_instructions: str


class DeepSeekClient:
    """
    LangGraph-based AI Agent Client using DeepSeek API
    Uses LangGraph for structured agent workflows with tool calling
    """
    
    def __init__(self):
        # Get DeepSeek API key
        api_key = getattr(settings, "DEEPSEEK_API_KEY", None) or os.environ.get("DEEPSEEK_API_KEY")
        if not api_key:
            logger.warning("DEEPSEEK_API_KEY not found in settings or env.")
        
        self.api_key = api_key
        
        # Model settings
        self.model_name = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")
        self.max_input_messages = int(os.getenv("DEEPSEEK_MAX_MESSAGES", "10"))
        self.max_output_tokens = int(os.getenv("DEEPSEEK_MAX_OUTPUT_TOKENS", "4096"))
        self.temperature = float(os.getenv("DEEPSEEK_TEMPERATURE", "0.3"))
        
        # Initialize DeepSeek LLM via LangChain OpenAI (DeepSeek is OpenAI-compatible)
        if api_key:
            self.llm = ChatOpenAI(
                api_key=api_key,
                base_url=DEEPSEEK_BASE_URL,
                model=self.model_name,
                temperature=self.temperature,
                max_tokens=self.max_output_tokens,
            )
            logger.info(f"DeepSeekClient initialized with model: {self.model_name}")
        else:
            self.llm = None
            logger.error("DeepSeekClient could not be initialized - no API key")
    
    def transcribe_audio(self, file_content: bytes, filename: str) -> str:
        """
        Transcribe audio using OpenAI Whisper API or compatible service.
        Falls back to basic speech recognition if no API key available.
        """
        # Try using OpenAI Whisper API if OPENAI_API_KEY is set
        openai_key = os.environ.get("OPENAI_API_KEY")
        
        if openai_key:
            try:
                import httpx
                with httpx.Client(timeout=60.0) as client:
                    response = client.post(
                        f"{WHISPER_BASE_URL}/audio/transcriptions",
                        headers={"Authorization": f"Bearer {openai_key}"},
                        files={"file": (filename, file_content)},
                        data={"model": "whisper-1"}
                    )
                    if response.status_code == 200:
                        return response.json().get("text", "")
                    else:
                        logger.error(f"Whisper API error: {response.status_code} - {response.text}")
            except Exception as e:
                logger.error(f"Transcription error with OpenAI: {e}")
        
        # If no OpenAI key, return a message
        logger.warning("No OPENAI_API_KEY set for audio transcription")
        raise ValueError("Audio transcription requires OPENAI_API_KEY to be set for Whisper API")
    
    def _get_system_prompt(self, current_date: str, day_of_week: str, current_datetime: str, custom_instructions: str = None, include_mcp: bool = True) -> str:
        """Build the system prompt with context"""
        
        # Build MCP tools section dynamically
        mcp_tools_section = ""
        if include_mcp:
            try:
                mcp_tool_defs = mcp_service.get_all_tools_for_llm()
                if mcp_tool_defs:
                    mcp_tools_section = "\n\n**ZERODHA/STOCK MARKET ACCESS (IMPORTANT)**:\nYou have DIRECT access to the user's Zerodha trading account via MCP tools. When the user asks about:\n"
                    mcp_tools_section += "- Portfolio, holdings, stocks, investments → Use `mcp_zerodha_get_holdings`\n"
                    mcp_tools_section += "- Positions, intraday trades → Use `mcp_zerodha_get_positions`\n"
                    mcp_tools_section += "- Margins, funds, balance → Use `mcp_zerodha_get_margins`\n"
                    mcp_tools_section += "- Orders placed today → Use `mcp_zerodha_get_orders`\n"
                    mcp_tools_section += "- Stock prices, quotes → Use `mcp_zerodha_get_quote`\n"
                    mcp_tools_section += "\n**YOU MUST USE THESE TOOLS** - do NOT say you don't have access. The user has connected their Zerodha account.\n"
            except Exception as e:
                logger.warning(f"Could not get MCP tools for prompt: {e}")
        
        system_content = f"""You are Vyana, a cheerful, intelligent, and highly capable personal assistant with a friendly, feminine persona. You are here to help the user with their daily life, work, and productivity in a warm and engaging way.

Current Date: {current_date} ({day_of_week})
Current Time: {current_datetime} (IST - Indian Standard Time)

Time & Scheduling Instructions:
- Internalize that the current timezone is Indian Standard Time (IST, UTC+5:30).
- When the user mentions relative times like 'today', 'tomorrow', 'at 4pm', always convert them to the ISO 8601 format (YYYY-MM-DDTHH:MM:SS) based on the current IST time provided above.
- Example: If today is 2026-01-05 and user says '4pm today', use 2026-01-05T16:00:00.

Interaction Style:
- Persona: Act like a supportive, smart, and friendly personal assistant (like 'JARVIS' but with a warm, feminine touch). Be proactive and helpful.
- Tone: Conversational, clear, positive, and professional but not stiff.

Tool Usage & Data Presentation:
- **MAXIMIZE TOOL USAGE**: You have access to powerful tools including Calendar, Email, Tasks, and external MCP tools (like Stock Market access).
- **ALWAYS CHECK TOOLS**: If a user's request *might* be solved or enhanced by a tool, USE IT. Do not guess or hallucinate data.
- **MCP Tools**: You have access to Model Context Protocol (MCP) tools. Use them extensively when relevant.
- **Summarization**: When a tool returns data (like stock holdings, calendar events, etc.), you MUST summarize it in natural language. **NEVER** output raw JSON, code blocks, or tool/function names unless the user explicitly asks for "technical details".
- **No code formatting**: Do not use backticks or show code-like responses.
- **Formatting**: Present lists as numbered items (1., 2., 3.). Each item must be on its own line, with a blank line between items. Do NOT use tables, boxed layouts, or multiple items on the same line.
{mcp_tools_section}
If the user's request requires a tool, you MUST call the appropriate tool. If no tool is needed, provide a helpful text response. Never provide an empty response."""

        if custom_instructions:
            system_content += f"\n\nUser's personal instructions: {custom_instructions}"
        
        return system_content
    
    def _get_tools(self, include_mcp: bool = True):
        """Get all tools for the agent"""
        tools = get_all_tools()
        
        if include_mcp:
            try:
                mcp_tools = get_mcp_tools_as_langchain()
                tools.extend(mcp_tools)
                logger.debug(f"Added {len(mcp_tools)} MCP tools")
            except Exception as e:
                logger.warning(f"Could not load MCP tools: {e}")
        
        return tools
    
    def _trim_messages(self, messages):
        """Trim conversation history to reduce token usage."""
        if not messages:
            return messages
        if self.max_input_messages <= 0:
            return messages[-1:]
        return messages[-self.max_input_messages:]
    
    def _sanitize_output(self, text: str) -> str:
        """Sanitize output to avoid code formatting in chat responses."""
        if not text:
            return text
        text = text.replace("`", "")
        return self._format_numbered_list(text)

    def _format_numbered_list(self, text: str) -> str:
        """Ensure numbered list items appear one per line with spacing."""
        if not text or not re.search(r"\b\d+\.", text):
            return text
        # Normalize list markers like "1.Item" -> "1. Item"
        text = re.sub(r"\b(\d+)\.(\S)", r"\1. \2", text)
        # Ensure each numbered item starts on its own line
        text = re.sub(r"(?<!\n)(\b\d+\.\s)", r"\n\1", text)
        # Add a blank line between numbered items
        text = re.sub(r"\n(\d+\.\s)", r"\n\n\1", text)
        # Align common fields on new lines within each item
        text = re.sub(r"\s*(\*+\s*)?(Time|Due|Description|Notes|Type):", r"\n\1\2:", text, flags=re.IGNORECASE)
        # Normalize extra blank lines (max one blank line between items)
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip()
    
    def _create_agent_graph(self, tools_enabled: bool = True, mcp_enabled: bool = True, model_name: str = None):
        """Create the LangGraph agent workflow"""
        
        if not self.api_key:
            raise ValueError("DEEPSEEK_API_KEY not configured")
        
        # Select appropriate LLM
        if model_name and model_name != self.model_name:
            llm = ChatOpenAI(
                api_key=self.api_key,
                base_url=DEEPSEEK_BASE_URL,
                model=model_name,
                temperature=self.temperature,
                max_tokens=self.max_output_tokens,
            )
        else:
            llm = self.llm
        
        # Get tools if enabled
        tools = self._get_tools(include_mcp=mcp_enabled) if tools_enabled else []
        
        # Log tool names for debugging
        tool_names = [t.name for t in tools] if tools else []
        logger.info(f"Agent graph created with {len(tools)} tools: {tool_names[:10]}{'...' if len(tool_names) > 10 else ''}")
        
        # Bind tools to LLM
        if tools:
            llm_with_tools = llm.bind_tools(tools)
        else:
            llm_with_tools = llm
        
        # Capture mcp_enabled for closure
        include_mcp_in_prompt = mcp_enabled
        
        # Define the agent node
        def agent_node(state: AgentState):
            """The main agent node that calls the LLM"""
            messages = state["messages"]
            
            # Build system message with MCP awareness
            system_prompt = self._get_system_prompt(
                current_date=state.get("current_date", ""),
                day_of_week=state.get("day_of_week", ""),
                current_datetime=state.get("current_time", ""),
                custom_instructions=state.get("custom_instructions", ""),
                include_mcp=include_mcp_in_prompt
            )
            
            # Prepend system message
            full_messages = [SystemMessage(content=system_prompt)] + list(messages)
            
            # Call LLM
            response = llm_with_tools.invoke(full_messages)
            
            # Log if tool calls were made
            if hasattr(response, "tool_calls") and response.tool_calls:
                logger.info(f"LLM requested tool calls: {[tc['name'] for tc in response.tool_calls]}")
            
            return {"messages": [response]}
        
        # Define the routing logic
        def should_continue(state: AgentState) -> Literal["tools", END]:
            """Determine if we should continue to tools or end"""
            messages = state["messages"]
            last_message = messages[-1]
            
            # If the LLM made tool calls, route to tool node
            if hasattr(last_message, "tool_calls") and last_message.tool_calls:
                return "tools"
            
            # Otherwise, end the graph
            return END
        
        # Build the graph
        workflow = StateGraph(AgentState)
        
        # Add nodes
        workflow.add_node("agent", agent_node)
        
        if tools:
            tool_node = ToolNode(tools)
            workflow.add_node("tools", tool_node)
            
            # Add edges
            workflow.add_conditional_edges(
                "agent",
                should_continue,
                {
                    "tools": "tools",
                    END: END
                }
            )
            workflow.add_edge("tools", "agent")
        else:
            workflow.add_edge("agent", END)
        
        # Set entry point
        workflow.set_entry_point("agent")
        
        # Compile
        return workflow.compile()
    
    async def stream_chat(self, messages, conversation_id: str, tools_enabled: bool, model_name: str = None, memory_enabled: bool = True, custom_instructions: str = None, mcp_enabled: bool = True, max_output_tokens: int = None):
        """
        Stream chat using LangGraph agent
        Yields SSE-formatted responses
        """
        # Use provided model or default
        model = model_name if model_name else self.model_name
        
        # Get the user's message for caching
        user_message = messages[-1].content if messages else ""
        
        # Check cache for simple queries (no tools enabled)
        if not tools_enabled and not mcp_enabled:
            cached_response = await cache_service.get_chat_response(
                message=user_message,
                model=model,
                tools_enabled=False
            )
            if cached_response:
                logger.info(f"Returning cached response for: {user_message[:50]}...")
                yield f"data: {json.dumps({'type': 'text', 'content': cached_response, 'cached': True})}\n\n"
                return
        
        # Get current date/time for context in IST
        ist = _get_ist_timezone()
        now = datetime.now(ist)
        current_datetime = now.strftime("%Y-%m-%d %H:%M")
        current_date = now.strftime("%Y-%m-%d")
        day_of_week = now.strftime("%A")
        
        # Create agent graph
        graph = self._create_agent_graph(
            tools_enabled=tools_enabled,
            mcp_enabled=mcp_enabled,
            model_name=model
        )
        
        # Convert messages to LangChain format
        langchain_messages = []
        if memory_enabled:
            history = self._trim_messages(messages[:-1])
            for m in history:
                role = m.role if m.role != "model" else "assistant"
                if role == "user":
                    langchain_messages.append(HumanMessage(content=m.content))
                elif role == "assistant":
                    langchain_messages.append(AIMessage(content=m.content))
        
        # Add current user message
        langchain_messages.append(HumanMessage(content=messages[-1].content))
        
        # Initialize state
        initial_state = AgentState(
            messages=langchain_messages,
            current_time=current_datetime,
            current_date=current_date,
            day_of_week=day_of_week,
            custom_instructions=custom_instructions or ""
        )
        
        try:
            # Stream the graph execution
            final_response = ""
            
            async for event in graph.astream(initial_state):
                # Process events from the graph
                for node_name, node_output in event.items():
                    if node_name == "agent":
                        messages_output = node_output.get("messages", [])
                        for msg in messages_output:
                            if isinstance(msg, AIMessage):
                                # Check for tool calls
                                if hasattr(msg, "tool_calls") and msg.tool_calls:
                                    # Tool calls are being made, wait for results
                                    logger.info(f"Tool calls: {[tc['name'] for tc in msg.tool_calls]}")
                                elif msg.content:
                                    # Regular content - stream it
                                    content = self._sanitize_output(msg.content)
                                    final_response = content
                                    yield f"data: {json.dumps({'type': 'text', 'content': content})}\n\n"
                    
                    elif node_name == "tools":
                        # Tool results - log them
                        messages_output = node_output.get("messages", [])
                        for msg in messages_output:
                            if isinstance(msg, ToolMessage):
                                logger.info(f"Tool result: {msg.name} -> {msg.content[:100]}...")
            
            # If no content was yielded, send a fallback
            if not final_response:
                fallback = self._sanitize_output("Done! The action was completed successfully.")
                yield f"data: {json.dumps({'type': 'text', 'content': fallback})}\n\n"
            
            # Cache the response for simple queries (no tools)
            if final_response and not tools_enabled and not mcp_enabled:
                await cache_service.set_chat_response(
                    message=user_message,
                    response=final_response,
                    model=model,
                    tools_enabled=False
                )
                
        except Exception as e:
            logger.error(f"Error in LangGraph stream: {e}")
            yield f"data: {json.dumps({'type': 'error', 'content': str(e)})}\n\n"
    
    async def chat_sync(self, messages, conversation_id: str, tools_enabled: bool, model_name: str = None, memory_enabled: bool = True, custom_instructions: str = None, mcp_enabled: bool = True) -> str:
        """
        Non-streaming version of chat using LangGraph
        Returns the full response string
        """
        # Use provided model or default
        model = model_name if model_name else self.model_name
        
        # Get the user's message for caching
        user_message = messages[-1].content if messages else ""
        
        # Check cache for simple queries (no tools enabled)
        if not tools_enabled and not mcp_enabled:
            cached_response = await cache_service.get_chat_response(
                message=user_message,
                model=model,
                tools_enabled=False
            )
            if cached_response:
                logger.info(f"Returning cached response for: {user_message[:50]}...")
                return cached_response
        
        # Get current date/time for context in IST
        ist = _get_ist_timezone()
        now = datetime.now(ist)
        current_datetime = now.strftime("%Y-%m-%d %H:%M")
        current_date = now.strftime("%Y-%m-%d")
        day_of_week = now.strftime("%A")
        
        # Create agent graph
        graph = self._create_agent_graph(
            tools_enabled=tools_enabled,
            mcp_enabled=mcp_enabled,
            model_name=model
        )
        
        # Convert messages to LangChain format
        langchain_messages = []
        if memory_enabled:
            history = self._trim_messages(messages[:-1])
            for m in history:
                role = m.role if m.role != "model" else "assistant"
                if role == "user":
                    langchain_messages.append(HumanMessage(content=m.content))
                elif role == "assistant":
                    langchain_messages.append(AIMessage(content=m.content))
        
        # Add current user message
        langchain_messages.append(HumanMessage(content=messages[-1].content))
        
        # Initialize state
        initial_state = AgentState(
            messages=langchain_messages,
            current_time=current_datetime,
            current_date=current_date,
            day_of_week=day_of_week,
            custom_instructions=custom_instructions or ""
        )
        
        try:
            # Run the graph to completion
            final_state = await graph.ainvoke(initial_state)
            
            # Get the last AI message
            for msg in reversed(final_state["messages"]):
                if isinstance(msg, AIMessage) and msg.content:
                    response = self._sanitize_output(msg.content)
                    
                    # Cache the response for simple queries (no tools)
                    if not tools_enabled and not mcp_enabled:
                        await cache_service.set_chat_response(
                            message=user_message,
                            response=response,
                            model=model,
                            tools_enabled=False
                        )
                    
                    return response
            
            return "I processed your request."
            
        except Exception as e:
            logger.error(f"Error in LangGraph chat_sync: {e}")
            return f"Error: {str(e)}"


# Shared singleton instance - export as both names for compatibility
deepseek_client = DeepSeekClient()
groq_client = deepseek_client  # Alias for backward compatibility with chat routes
