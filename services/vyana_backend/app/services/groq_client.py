import os
import json
import logging
from groq import Groq
import re
from app.config import settings
from app.services.tasks_repo import tasks_repo
from app.services.calendar_service import calendar_service
from app.services.gmail_service import gmail_service
from app.services.notes_service import notes_service
from app.services.mcp_service import mcp_service

# Setup logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

class GroqClient:
    def __init__(self):
        # ensure GROQ_API_KEY is in settings or env
        api_key = getattr(settings, "GROQ_API_KEY", None) or os.environ.get("GROQ_API_KEY")
        if not api_key:
            logger.warning("GROQ_API_KEY not found in settings or env.")
        
        self.client = Groq(api_key=api_key)
        self.model_name = "llama-3.1-8b-instant" # Default
        logger.info(f"GroqClient initialized.")

    def transcribe_audio(self, file_content: bytes, filename: str) -> str:
        try:
            transcription = self.client.audio.transcriptions.create(
                file=(filename, file_content),
                model="whisper-large-v3",
                response_format="text"
            )
            return transcription
        except Exception as e:
            logger.error(f"Transcription error: {e}")
            raise e

    def _get_tools(self):
        """Returns list of tools in OpenAI/Groq format, including MCP tools"""
        # Base tools (built-in)
        base_tools = [
            {
                "type": "function",
                "function": {
                    "name": "create_task",
                    "description": "Creates a new task in the personal to-do list",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "title": {"type": "string", "description": "The task title"},
                            "due_date": {"type": "string", "description": "Optional due date in YYYY-MM-DD format"}
                        },
                        "required": ["title"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "list_tasks",
                    "description": "Lists all uncompleted tasks",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "limit": {"type": "integer", "description": "Optional limit"}
                        }
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_calendar_today",
                    "description": "Gets calendar events for today",
                    "parameters": {
                        "type": "object",
                        "properties": {
                             "limit": {"type": "integer", "description": "Optional limit"}
                        }
                    }
                }
            },
             {
                "type": "function",
                "function": {
                    "name": "get_unread_emails_summary",
                    "description": "Gets a summary of recent unread emails",
                    "parameters": {
                        "type": "object",
                        "properties": {
                             "limit": {"type": "integer", "description": "Optional limit"}
                        }
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "create_calendar_event",
                    "description": "Creates a calendar event. Use this when the user wants to schedule something. The start_time MUST be in ISO 8601 format like '2026-01-05T16:00:00'. Convert natural language times to ISO format using the current date provided in the system context.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "summary": {"type": "string", "description": "Event title/summary"},
                            "start_time": {"type": "string", "description": "Start time in ISO 8601 format (e.g., 2026-01-05T16:00:00)"},
                            "duration_minutes": {"type": "integer", "description": "Duration in minutes, default 60"}
                        },
                        "required": ["summary", "start_time"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "take_notes",
                    "description": "Saves a note for the user. Use this when the user asks to remember something or take a note.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "title": {"type": "string", "description": "Note title"},
                            "content": {"type": "string", "description": "Note content"}
                        },
                        "required": ["content"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "send_email",
                    "description": "Sends an email",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "to_email": {"type": "string", "description": "Recipient email"},
                            "subject": {"type": "string", "description": "Email subject"},
                            "body": {"type": "string", "description": "Email body"}
                        },
                        "required": ["to_email", "subject", "body"]
                    }
                }
            }
        ]
        
        # Add MCP tools dynamically from connected MCP servers
        mcp_tools = mcp_service.get_all_tools_for_llm()
        logger.debug(f"Adding {len(mcp_tools)} MCP tools to AI")
        
        return base_tools + mcp_tools

    def _execute_function(self, function_name, function_args):
        """Execute a function call and return result as JSON string"""
        logger.info(f"Executing function: {function_name} with args: {function_args}")
        try:
            args = json.loads(function_args) if isinstance(function_args, str) else function_args
            
            # Check if this is an MCP tool (prefixed with mcp_)
            if mcp_service.is_mcp_tool(function_name):
                logger.info(f"Routing to MCP service: {function_name}")
                return mcp_service.execute_tool_sync(function_name, args)
            
            # Built-in tools
            if function_name == "create_task":
                result = tasks_repo.add_task(args["title"], args.get("due_date"))
                return json.dumps({"id": result.id, "status": "Task created"})
            elif function_name == "list_tasks":
                tasks = tasks_repo.list_tasks(include_completed=False)
                return json.dumps([{"title": t.title, "due": t.due_date} for t in tasks])
            elif function_name == "get_calendar_today":
                return str(calendar_service.get_events())
            elif function_name == "get_unread_emails_summary":
                return str(gmail_service.summarize_emails())
            elif function_name == "create_calendar_event":
                return str(calendar_service.create_event(args["summary"], args["start_time"], args.get("duration_minutes", 60)))
            elif function_name == "take_notes":
                return str(notes_service.save_note(args["content"], args.get("title")))
            elif function_name == "send_email":
                return str(gmail_service.send_email(args["to_email"], args["subject"], args["body"]))
            else:
                return "Unknown function"
        except Exception as e:
            logger.error(f"Error executing {function_name}: {e}")
            return f"Error: {str(e)}"

    async def stream_chat(self, messages, conversation_id: str, tools_enabled: bool, model_name: str = None, memory_enabled: bool = True, custom_instructions: str = None):
        # Use user provided model or default to llama-3.1-8b-instant
        model = model_name if model_name and ("llama" in model_name or "mixtral" in model_name) else self.model_name
        
        # Get current date/time for context in IST
        from datetime import datetime
        try:
            from zoneinfo import ZoneInfo
            ist = ZoneInfo("Asia/Kolkata")
        except ImportError:
            import pytz
            ist = pytz.timezone("Asia/Kolkata")
            
        now = datetime.now(ist)
        current_datetime = now.strftime("%Y-%m-%d %H:%M")
        current_date = now.strftime("%Y-%m-%d")
        day_of_week = now.strftime("%A")
        
        # Build system prompt with context
        system_content = f"""You are Vyana, an advanced and helpful personal AI assistant. 
Current Date: {current_date} ({day_of_week})
Current Time: {current_datetime} (IST - Indian Standard Time)

Time & Scheduling Instructions:
- Internalize that the current timezone is Indian Standard Time (IST, UTC+5:30).
- When the user mentions relative times like 'today', 'tomorrow', 'at 4pm', always convert them to the ISO 8601 format (YYYY-MM-DDTHH:MM:SS) based on the current IST time provided above.
- Example: If today is 2026-01-05 and user says '4pm today', use 2026-01-05T16:00:00.

Interaction Style:
- Be concise, professional, yet warm and engaging.
- Using Llama 3.1 8B, optimize your responses for clarity and helpfulness.
- If the user asks for a schedule or calendar action, prioritize using the available tools.
- **CRITICAL:** When a tool returns data (like stock holdings, calendar events, etc.), you MUST summarize it in natural language. **NEVER** output raw JSON, code blocks with data, or debugging information unless the user explicitly asks for "technical details".
- Present financial or list data in clean markdown tables or bullet points, not as raw data structures.

If the user's request requires a tool, you MUST call the appropriate tool. If no tool is needed, provide a helpful text response. Never provide an empty response."""
        
        # Add custom instructions if provided
        if custom_instructions:
            system_content += f"\n\nUser's personal instructions: {custom_instructions}"
        
        # Convert messages to Groq format
        groq_messages = []
        if memory_enabled:
            groq_messages.append({"role": "system", "content": system_content})
            for m in messages[:-1]:
                groq_messages.append({"role": m.role if m.role != "model" else "assistant", "content": m.content})
        else:
            groq_messages.append({"role": "system", "content": system_content})
        
        # Add current user message
        groq_messages.append({"role": "user", "content": messages[-1].content})

        tools = self._get_tools() if tools_enabled else None
        
        try:
            # Attempt 1: With Tools
            try:
                completion = self.client.chat.completions.create(
                    model=model,
                    messages=groq_messages,
                    tools=tools,
                    tool_choice="auto" if tools else "none",
                    stream=False 
                )
            except Exception as e:
                error_str = str(e)
                # Check for failed generation due to XML tool call
                rescue_result = None
                
                if "failed_generation" in error_str:
                    try:
                        # Extract the inner failed generation string
                        # Error format: ... 'failed_generation': '<function=name>args' ...
                        # Simplified regex to find <function=...>
                        match = re.search(r"<function=(\w+)>(.+?)(?:'|\}|$)", error_str)
                        if match:
                            fn_name = match.group(1)
                            fn_args = match.group(2)
                            # Cleanup arg string if needed (sometimes it has trailing quote if regex caught it)
                            if fn_args.endswith("'}"): fn_args = fn_args[:-2]
                            if fn_args.endswith("'"): fn_args = fn_args[:-1]
                            
                            logger.info(f"Rescuing tool call: {fn_name} args: {fn_args}")
                            
                            # Execute
                            fn_result = self._execute_function(fn_name, fn_args)
                            rescue_result = f"I have executed the request. Result: {fn_result}"
                    except Exception as rescue_err:
                        logger.error(f"Rescue failed: {rescue_err}")

                if rescue_result:
                     yield f"data: {json.dumps({'type': 'text', 'content': rescue_result})}\\n\\n"
                     return # End stream
                
                # If tool use fails (e.g. empty output) and NOT rescued, try without tools
                elif "model output must contain" in error_str or "400" in error_str:
                    logger.warning(f"Tool use failed ({e}), retrying without tools...")
                    completion = self.client.chat.completions.create(
                        model=model,
                        messages=groq_messages,
                        tools=None,
                        tool_choice="none",
                        stream=False 
                    )
                else:
                    raise e

            response_message = completion.choices[0].message
            tool_calls = response_message.tool_calls

            if tool_calls:
                # Append assistant message with tool calls
                groq_messages.append(response_message)

                # Execute tools and collect results
                tool_results = []
                for tool_call in tool_calls:
                    function_name = tool_call.function.name
                    function_args = tool_call.function.arguments
                    logger.info(f"Tool call: {function_name} with args: {function_args}")
                    function_response = self._execute_function(function_name, function_args)
                    logger.info(f"Tool result: {function_response}")
                    tool_results.append(function_response)
                    
                    groq_messages.append({
                        "tool_call_id": tool_call.id,
                        "role": "tool",
                        "name": function_name,
                        "content": function_response,
                    })
                
                # Second call: Get final response after tool execution
                try:
                    stream = self.client.chat.completions.create(
                        model=model,
                        messages=groq_messages,
                        stream=True
                    )
                    
                    has_content = False
                    for chunk in stream:
                        content = chunk.choices[0].delta.content
                        if content:
                            has_content = True
                            yield f"data: {json.dumps({'type': 'text', 'content': content})}\n\n"
                    
                    # If no content was streamed, send a fallback response
                    if not has_content:
                        fallback = f"Done! {'; '.join(tool_results)}"
                        yield f"data: {json.dumps({'type': 'text', 'content': fallback})}\n\n"
                        
                except Exception as e:
                    logger.error(f"Error in second LLM call: {e}")
                    # Fallback: send tool result directly
                    fallback = f"Completed. {'; '.join(tool_results)}"
                    yield f"data: {json.dumps({'type': 'text', 'content': fallback})}\n\n"

            else:
                # No tool calls, just return the content (which is already in response_message? No, we used stream=False)
                # If we used stream=False, we have the full text. We can simulate stream or just send it.
                # To support 'typing' effect, we can just send it as one chunk or split it.
                # Or we can re-request with stream=True (wasteful).
                # Sending as one chunk is fine.
                if response_message.content:
                     yield f"data: {json.dumps({'type': 'text', 'content': response_message.content})}\n\n"

        except Exception as e:
            logger.error(f"Error in Groq stream: {e}")
            yield f"data: {json.dumps({'type': 'error', 'content': str(e)})}\n\n"
