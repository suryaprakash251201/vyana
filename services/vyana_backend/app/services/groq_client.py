import os
import json
import logging
from groq import Groq
import re
from app.config import settings
from app.services import google_tasks_service as google_tasks_service
from app.services.calendar_service import calendar_service
from app.services.gmail_service import gmail_service
from app.services.notes_service import notes_service
from app.services.mcp_service import mcp_service
from app.services.weather_service import weather_service
from app.services.search_service import search_service
from app.services.utils_service import utils_service
from app.services.google_contacts_service import google_contacts_service

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

    def _sanitize_output(self, text: str) -> str:
        """Sanitize output to avoid code formatting in chat responses."""
        if not text:
            return text
        return text.replace("`", "")

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

    def _get_tools(self, include_mcp: bool = True):
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
                            "due_date": {"type": "string", "description": "Optional due date in YYYY-MM-DD format"},
                            "notes": {"type": "string", "description": "Optional task notes"},
                            "task_list_id": {"type": "string", "description": "Optional task list id (default @default)"}
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
                            "limit": {"type": "integer", "description": "Optional limit"},
                            "task_list_id": {"type": "string", "description": "Optional task list id (default @default)"}
                        }
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_calendar_today",
                    "description": "Gets calendar events for today only. Use get_calendar_events for other dates.",
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
                    "name": "get_calendar_events",
                    "description": "Gets calendar events for a specific date. Use this when user asks about events on a specific day like 'tomorrow', 'next Monday', or a specific date. Convert the date to YYYY-MM-DD format.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "date": {"type": "string", "description": "Date in YYYY-MM-DD format (e.g., 2026-01-27 for tomorrow)"}
                        },
                        "required": ["date"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_calendar_range",
                    "description": "Gets upcoming calendar events for the next N days starting from today",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "days": {"type": "integer", "description": "Number of days to look ahead (default 7)"}
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
                    "name": "summarize_emails",
                    "description": "Summarizes recent unread emails with optional limit",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "limit": {"type": "integer", "description": "Max emails to summarize (default 5)"}
                        }
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "daily_digest",
                    "description": "Creates a quick daily digest of tasks, calendar, and unread email count",
                    "parameters": {
                        "type": "object",
                        "properties": {}
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
                    "description": "Sends an email. If you only have a name (e.g., 'Alice'), USE 'get_email_address' FIRST to find their email.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "to_email": {"type": "string", "description": "Recipient email address"},
                            "subject": {"type": "string", "description": "Email subject"},
                            "body": {"type": "string", "description": "Email body"}
                        },
                        "required": ["to_email", "subject", "body"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "search_emails",
                    "description": "Searches for emails using specified criteria. Useful for finding emails from a person or about a topic.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string", "description": "Search query used for filtering (e.g., 'from:zerodha', 'subject:invoice', 'is:unread')"},
                            "limit": {"type": "integer", "description": "Max number of emails to return (default 5)"}
                        },
                        "required": ["query"]
                    }
                }
            },
            # Contact Management Tools
            {
                "type": "function",
                "function": {
                    "name": "add_contact",
                    "description": "Saves a new contact. Use this when the user asks to save someone's contact info (name, email, phone, company).",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "name": {"type": "string", "description": "Name of the person"},
                            "email": {"type": "string", "description": "Email address (optional)"},
                            "phone": {"type": "string", "description": "Phone number (optional)"},
                            "company": {"type": "string", "description": "Company/organization (optional)"},
                            "notes": {"type": "string", "description": "Additional notes (optional)"}
                        },
                        "required": ["name"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_email_address",
                    "description": "Finds an email address for a contact by name.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "name": {"type": "string", "description": "Name to look up"}
                        },
                        "required": ["name"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_phone_number",
                    "description": "Finds a phone number for a contact by name.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "name": {"type": "string", "description": "Name to look up"}
                        },
                        "required": ["name"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "list_contacts",
                    "description": "Lists all saved contacts with their names, emails, and phone numbers.",
                    "parameters": {
                        "type": "object",
                        "properties": {}
                    }
                }
            },
            # Task Management Enhancements
            {
                "type": "function",
                "function": {
                    "name": "complete_task",
                    "description": "Marks a task as completed",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "task_id": {"type": "string", "description": "ID of the task to complete"},
                            "task_list_id": {"type": "string", "description": "Optional task list id (default @default)"}
                        },
                        "required": ["task_id"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "update_task",
                    "description": "Updates an existing task's title or due date",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "task_id": {"type": "string", "description": "ID of the task"},
                            "title": {"type": "string", "description": "New title (optional)"},
                            "due_date": {"type": "string", "description": "New due date in YYYY-MM-DD format (optional)"},
                            "notes": {"type": "string", "description": "New notes (optional)"},
                            "task_list_id": {"type": "string", "description": "Optional task list id (default @default)"}
                        },
                        "required": ["task_id"]
                   }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "delete_task",
                    "description": "Deletes a task permanently",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "task_id": {"type": "string", "description": "ID of the task to delete"},
                            "task_list_id": {"type": "string", "description": "Optional task list id (default @default)"}
                        },
                        "required": ["task_id"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "search_tasks",
                    "description": "Searches tasks by title keyword",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string", "description": "Search keyword"},
                            "task_list_id": {"type": "string", "description": "Optional task list id (default @default)"}
                        },
                        "required": ["query"]
                    }
                }
            },
            # Notes Enhancement
            {
                "type": "function",
                "function": {
                    "name": "get_notes",
                    "description": "Retrieves recent notes",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "limit": {"type": "integer", "description": "Number of notes to retrieve, default 10"}
                        }
                    }
                }
            },
            # Weather Tools
            {
                "type": "function",
                "function": {
                    "name": "get_weather",
                    "description": "Gets current weather for a city",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "city": {"type": "string", "description": "City name, default Mumbai"}
                        }
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_forecast",
                    "description": "Gets 3-day weather forecast for a city",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "city": {"type": "string", "description": "City name, default Mumbai"}
                        }
                    }
                }
            },
            # Web Search Tools
            {
                "type": "function",
                "function": {
                    "name": "web_search",
                    "description": "Searches the web for information",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string", "description": "Search query"}
                        },
                        "required": ["query"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_news",
                    "description": "Gets latest news on a topic",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "topic": {"type": "string", "description": "News topic, default 'technology'"}
                        }
                    }
                }
            },
            # Utility Tools
            {
                "type": "function",
                "function": {
                    "name": "calculate",
                    "description": "Evaluates a mathematical expression",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "expression": {"type": "string", "description": "Math expression like '2 + 2' or '10 * 5'"}
                        },
                        "required": ["expression"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_time_now",
                    "description": "Returns the current time and date in IST",
                    "parameters": {
                        "type": "object",
                        "properties": {}
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "convert_currency",
                    "description": "Converts currency from one type to another",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "amount": {"type": "number", "description": "Amount to convert"},
                            "from_currency": {"type": "string", "description": "Source currency code (USD, EUR, INR, etc.)"},
                            "to_currency": {"type": "string", "description": "Target currency code"}
                        },
                        "required": ["amount", "from_currency", "to_currency"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "convert_units",
                    "description": "Converts units (length, weight, temperature)",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "value": {"type": "number", "description": "Value to convert"},
                            "from_unit": {"type": "string", "description": "Source unit (m, km, kg, lb, c, f, etc.)"},
                            "to_unit": {"type": "string", "description": "Target unit"}
                        },
                        "required": ["value", "from_unit", "to_unit"]
                    }
                }
            }
        ]
        
        # Add MCP tools dynamically from connected MCP servers
        if include_mcp:
            mcp_tools = mcp_service.get_all_tools_for_llm()
            logger.debug(f"Adding {len(mcp_tools)} MCP tools to AI")
            return base_tools + mcp_tools
        
        return base_tools

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
                result = google_tasks_service.create_task(
                    title=args["title"],
                    task_list_id=args.get("task_list_id", "@default"),
                    notes=args.get("notes"),
                    due=args.get("due_date")
                )
                return json.dumps({"id": result.get("id"), "status": "Task created"})
            elif function_name == "list_tasks":
                tasks = google_tasks_service.list_tasks(
                    task_list_id=args.get("task_list_id", "@default"),
                    show_completed=False,
                    max_results=int(args.get("limit", 100))
                )
                return json.dumps([{"id": t.get("id"), "title": t.get("title"), "due": t.get("due")} for t in tasks])
            elif function_name == "complete_task":
                result = google_tasks_service.complete_task(
                    task_id=args["task_id"],
                    task_list_id=args.get("task_list_id", "@default")
                )
                return json.dumps({"success": True, "message": "Task completed", "id": result.get("id")})
            elif function_name == "update_task":
                result = google_tasks_service.update_task(
                    task_id=args["task_id"],
                    task_list_id=args.get("task_list_id", "@default"),
                    title=args.get("title"),
                    notes=args.get("notes"),
                    due=args.get("due_date")
                )
                return json.dumps({"success": True, "message": "Task updated", "id": result.get("id")})
            elif function_name == "delete_task":
                google_tasks_service.delete_task(
                    task_id=args["task_id"],
                    task_list_id=args.get("task_list_id", "@default")
                )
                return json.dumps({"success": True, "message": "Task deleted"})
            elif function_name == "search_tasks":
                query = (args.get("query") or "").lower()
                tasks = google_tasks_service.list_tasks(
                    task_list_id=args.get("task_list_id", "@default"),
                    show_completed=False,
                    max_results=200
                )
                filtered = [t for t in tasks if query in (t.get("title") or "").lower()]
                return json.dumps([{"id": t.get("id"), "title": t.get("title"), "due": t.get("due")} for t in filtered])
            elif function_name == "get_calendar_today":
                return str(calendar_service.get_events())
            elif function_name == "get_calendar_events":
                # Get events for a specific date
                date_str = args.get("date")
                if date_str:
                    events = calendar_service.get_events(start_date_str=date_str, end_date_str=date_str)
                    if isinstance(events, list) and len(events) > 0 and isinstance(events[0], dict) and events[0].get("error"):
                        return json.dumps({"error": "Google Calendar not connected. Please go to Settings > Connect Google Account."})
                    return json.dumps(events)
                return json.dumps({"error": "Date parameter required"})
            elif function_name == "get_calendar_range":
                days = int(args.get("days", 7))
                events = calendar_service.get_events()
                try:
                    from datetime import datetime, timedelta
                    try:
                        from zoneinfo import ZoneInfo
                        ist = ZoneInfo("Asia/Kolkata")
                    except ImportError:
                        import pytz
                        ist = pytz.timezone("Asia/Kolkata")
                    now = datetime.now(ist)
                    cutoff = now + timedelta(days=days)
                    filtered = []
                    for e in events:
                        if isinstance(e, dict) and "error" not in e:
                            start = e.get("start", "")
                            if start:
                                try:
                                    event_dt = datetime.fromisoformat(start.replace("Z", "+00:00"))
                                    if event_dt <= cutoff:
                                        filtered.append(e)
                                except ValueError:
                                    filtered.append(e)
                    return json.dumps(filtered)
                except Exception:
                    return json.dumps(events)
            elif function_name == "get_unread_emails_summary":
                result = gmail_service.summarize_emails(args.get("limit", 5))
                if isinstance(result, dict) and result.get("error"):
                    return json.dumps({"error": "Google account not connected. Please go to Settings > Connect Google Account to enable email features."})
                return str(result)
            elif function_name == "summarize_emails":
                result = gmail_service.summarize_emails(args.get("limit", 5))
                if isinstance(result, dict) and result.get("error"):
                    return json.dumps({"error": "Google account not connected. Please go to Settings > Connect Google Account to enable email features."})
                return str(result)
            elif function_name == "create_calendar_event":
                result = calendar_service.create_event(args["summary"], args["start_time"], args.get("duration_minutes", 60))
                if isinstance(result, dict) and result.get("error"):
                    return json.dumps({"error": "Google Calendar not connected. Please go to Settings > Connect Google Account to enable calendar features."})
                return str(result)
            elif function_name == "take_notes":
                return str(notes_service.save_note(args["content"], args.get("title")))
            elif function_name == "get_notes":
                notes = notes_service.get_notes(args.get("limit", 10))
                return json.dumps(notes)
            elif function_name == "send_email":
                return str(gmail_service.send_email(args["to_email"], args["subject"], args["body"]))
            elif function_name == "search_emails":
                return json.dumps(gmail_service.search_messages(args["query"], args.get("limit", 5)))
            
            # Contact tools (Google Contacts)
            elif function_name == "add_contact":
                result = google_contacts_service.add_contact(
                    name=args["name"],
                    email=args.get("email"),
                    phone=args.get("phone"),
                    company=args.get("company"),
                    notes=args.get("notes")
                )
                return result.get("message", str(result))
            elif function_name == "get_email_address":
                return google_contacts_service.get_email_address(args["name"])
            elif function_name == "get_phone_number":
                return google_contacts_service.get_phone_number(args["name"])
            elif function_name == "list_contacts":
                return google_contacts_service.list_contacts()
            # Weather tools
            elif function_name == "get_weather":
                return weather_service.get_weather(args.get("city", "Mumbai"))
            elif function_name == "get_forecast":
                return weather_service.get_forecast(args.get("city", "Mumbai"))
            # Search tools
            elif function_name == "web_search":
                result = search_service.web_search(args["query"])
                return json.dumps({"result": result})
            elif function_name == "get_news":
                result = search_service.get_news(args.get("topic", "technology"))
                return json.dumps({"result": result})
            # Utility tools
            elif function_name == "calculate":
                result = utils_service.calculate(args["expression"])
                return json.dumps({"result": result})
            elif function_name == "convert_currency":
                result = utils_service.convert_currency(args["amount"], args["from_currency"], args["to_currency"])
                return json.dumps({"result": result})
            elif function_name == "convert_units":
                result = utils_service.convert_units(args["value"], args["from_unit"], args["to_unit"])
                return json.dumps({"result": result})
            elif function_name == "get_time_now":
                from datetime import datetime
                try:
                    from zoneinfo import ZoneInfo
                    ist = ZoneInfo("Asia/Kolkata")
                except ImportError:
                    import pytz
                    ist = pytz.timezone("Asia/Kolkata")
                now = datetime.now(ist)
                return json.dumps({"result": now.strftime("%Y-%m-%d %H:%M:%S IST")})
            elif function_name == "daily_digest":
                from datetime import datetime
                try:
                    from zoneinfo import ZoneInfo
                    ist = ZoneInfo("Asia/Kolkata")
                except ImportError:
                    import pytz
                    ist = pytz.timezone("Asia/Kolkata")
                today = datetime.now(ist).date()
                tasks = tasks_repo.list_tasks(include_completed=False)
                events = calendar_service.get_events()
                today_events = []
                for e in events:
                    if isinstance(e, dict) and "error" not in e:
                        start = e.get("start", "")
                        if start:
                            try:
                                event_dt = datetime.fromisoformat(start.replace("Z", "+00:00")).date()
                                if event_dt == today:
                                    today_events.append(e)
                            except ValueError:
                                continue
                unread = gmail_service.get_unread_count()
                return json.dumps({
                    "pending_tasks": len(tasks),
                    "today_events": len(today_events),
                    "unread_emails": unread
                })
            else:
                return "Unknown function"
        except Exception as e:
            logger.error(f"Error executing {function_name}: {e}")
            return f"Error: {str(e)}"

    async def stream_chat(self, messages, conversation_id: str, tools_enabled: bool, model_name: str = None, memory_enabled: bool = True, custom_instructions: str = None, mcp_enabled: bool = True):
        # Use user provided model or default to llama-3.1-8b-instant
        # Accept llama, mixtral, and gemma models
        model = model_name if model_name and ("llama" in model_name or "mixtral" in model_name or "gemma" in model_name) else self.model_name
        
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
- Using Llama 3.1 8B, optimize your responses for clarity and helpfulness.

Tool Usage & Data Presentation:
- **MAXIMIZE TOOL USAGE**: You have access to powerful tools including Calendar, Email, Tasks, and external MCP tools (like Stock Market access).
- **ALWAYS CHECK TOOLS**: If a user's request *might* be solved or enhanced by a tool, USE IT. Do not guess or hallucinate data.
- **MCP Tools**: You have access to Model Context Protocol (MCP) tools. Use them extensively when relevant.
- **Summarization**: When a tool returns data (like stock holdings, calendar events, etc.), you MUST summarize it in natural language. **NEVER** output raw JSON, code blocks, or tool/function names unless the user explicitly asks for "technical details".
- **No code formatting**: Do not use backticks or show code-like responses.
- **Formatting**: Present financial or list data in clean markdown tables or bullet points.

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

        tools = self._get_tools(include_mcp=mcp_enabled) if tools_enabled else None
        
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
                        # Try multiple patterns
                        
                        # Pattern 1: <function=name>{"args"}
                        match = re.search(r"<function=(\w+)>(\{.+?\})", error_str)
                        
                        # Pattern 2: function_name>{"args"} (missing <)
                        if not match:
                            match = re.search(r"(\w+)>\s*(\{.+?\})", error_str)
                        
                        # Pattern 3: <function=name>{args (incomplete JSON - find until end)
                        if not match:
                            match = re.search(r"<function=(\w+)>\s*(\{.+)", error_str)
                        
                        # Pattern 4: <function=name> </function> or <function=name></function> (empty args)
                        if not match:
                            match = re.search(r"<function=(\w+)>\s*</function>", error_str)
                            if match:
                                fn_name = match.group(1)
                                fn_args = "{}"  # Empty args
                                logger.info(f"Rescuing tool call with empty args: {fn_name}")
                                fn_result = self._execute_function(fn_name, fn_args)
                                # Will be summarized below
                        
                        # Pattern 5: <function=name> (just function name, no closing tag)
                        if not match and not rescue_result:
                            match = re.search(r"<function=(\w+)>(?:\s*)(?!</function>)", error_str)
                            if match:
                                fn_name = match.group(1)
                                fn_args = "{}"  # Empty args
                                logger.info(f"Rescuing tool call (no closing tag): {fn_name}")
                                fn_result = self._execute_function(fn_name, fn_args)
                                # Will be summarized below
                        
                        if match and not rescue_result:
                            fn_name = match.group(1)
                            fn_args = match.group(2) if len(match.groups()) > 1 else "{}"
                            
                            # Clean up the JSON string
                            # Remove trailing characters that aren't part of JSON
                            fn_args = fn_args.strip()
                            
                            # Handle empty or whitespace-only args
                            if not fn_args or fn_args.isspace():
                                fn_args = "{}"
                            
                            # Remove trailing quote/brace if they're escape artifacts
                            while fn_args and fn_args[-1] in ["'", "\\", " "]:
                                fn_args = fn_args[:-1]
                            
                            # Ensure JSON is complete (has closing brace)
                            if fn_args.startswith("{"):
                                open_braces = fn_args.count('{') - fn_args.count('}')
                                if open_braces > 0:
                                    fn_args = fn_args + '}' * open_braces
                            
                            # Replace single quotes with double quotes if needed
                            if "'" in fn_args and '"' not in fn_args:
                                fn_args = fn_args.replace("'", '"')
                            
                            logger.info(f"Rescuing tool call: {fn_name} args: {fn_args}")
                            
                            # Execute
                            fn_result = self._execute_function(fn_name, fn_args)
                            
                            # Use LLM to summarize the result instead of raw output
                            try:
                                summary_messages = [
                                    {"role": "system", "content": "You are Vyana, a helpful assistant. Summarize the following tool result in a friendly, natural way. Do NOT output raw JSON or code. Present the information clearly."},
                                    {"role": "user", "content": f"Tool: {fn_name}\nResult: {fn_result}\n\nPlease summarize this in natural language for the user."}
                                ]
                                summary_response = self.client.chat.completions.create(
                                    model=model,
                                    messages=summary_messages,
                                    stream=True
                                )
                                for chunk in summary_response:
                                    content = chunk.choices[0].delta.content
                                    if content:
                                        content = self._sanitize_output(content)
                                        yield f"data: {json.dumps({'type': 'text', 'content': content})}\n\n"
                                return
                            except Exception as sum_err:
                                logger.error(f"Summary LLM failed: {sum_err}")
                                rescue_result = f"Done! The action was completed successfully."
                            
                    except json.JSONDecodeError as je:
                        logger.error(f"Rescue JSON parse failed: {je}")
                        rescue_result = "I tried to execute that action but encountered a formatting issue. Please try rephrasing your request."
                    except Exception as rescue_err:
                        logger.error(f"Rescue failed: {rescue_err}")
                        rescue_result = f"I tried to execute that action but encountered an error: {rescue_err}"

                if rescue_result:
                     rescue_result = self._sanitize_output(rescue_result)
                     yield f"data: {json.dumps({'type': 'text', 'content': rescue_result})}\n\n"
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
                            content = self._sanitize_output(content)
                            yield f"data: {json.dumps({'type': 'text', 'content': content})}\n\n"
                    
                    # If no content was streamed, send a fallback response
                    if not has_content:
                        # Try to generate a natural summary
                        fallback = self._sanitize_output("Done! The action was completed successfully.")
                        yield f"data: {json.dumps({'type': 'text', 'content': fallback})}\n\n"
                        
                except Exception as e:
                    logger.error(f"Error in second LLM call: {e}")
                    # Fallback: summarize tool result
                    fallback = self._sanitize_output("Done! The action was completed successfully.")
                    yield f"data: {json.dumps({'type': 'text', 'content': fallback})}\n\n"

            else:
                # No tool calls, just return the content (which is already in response_message? No, we used stream=False)
                # If we used stream=False, we have the full text. We can simulate stream or just send it.
                # To support 'typing' effect, we can just send it as one chunk or split it.
                # Or we can re-request with stream=True (wasteful).
                # Sending as one chunk is fine.
                if response_message.content:
                     content = response_message.content
                     # If the model emitted an inline tool tag, execute it and summarize.
                     inline_match = re.search(r"<function=(\w+)>(\{.*?\})?\s*</function>", content, re.DOTALL)
                     if inline_match:
                         fn_name = inline_match.group(1)
                         fn_args = inline_match.group(2) or "{}"
                         logger.info(f"Inline tool tag detected: {fn_name} args: {fn_args}")
                         fn_result = self._execute_function(fn_name, fn_args)
                         try:
                             summary_messages = [
                                 {"role": "system", "content": "You are Vyana, a helpful assistant. Summarize the following tool result in a friendly, natural way. Do NOT output raw JSON or code. Present the information clearly."},
                                 {"role": "user", "content": f"Tool: {fn_name}\nResult: {fn_result}\n\nPlease summarize this in natural language for the user."}
                             ]
                             summary_response = self.client.chat.completions.create(
                                 model=model,
                                 messages=summary_messages,
                                 stream=True
                             )
                             for chunk in summary_response:
                                 chunk_content = chunk.choices[0].delta.content
                                 if chunk_content:
                                     chunk_content = self._sanitize_output(chunk_content)
                                     yield f"data: {json.dumps({'type': 'text', 'content': chunk_content})}\n\n"
                             return
                         except Exception as sum_err:
                             logger.error(f"Inline summary failed: {sum_err}")
                             fallback = self._sanitize_output("Done! The action was completed successfully.")
                             yield f"data: {json.dumps({'type': 'text', 'content': fallback})}\n\n"
                             return

                     content = self._sanitize_output(content)
                     yield f"data: {json.dumps({'type': 'text', 'content': content})}\n\n"

        except Exception as e:
            logger.error(f"Error in Groq stream: {e}")
            yield f"data: {json.dumps({'type': 'error', 'content': str(e)})}\n\n"

    async def chat_sync(self, messages, conversation_id: str, tools_enabled: bool, model_name: str = None, memory_enabled: bool = True, custom_instructions: str = None, mcp_enabled: bool = True) -> str:
        """
        Non-streaming version of chat for legacy/simple clients.
        Returns the full response string.
        """
        # Use user provided model or default to llama-3.1-8b-instant
        # Accept llama, mixtral, and gemma models
        model = model_name if model_name and ("llama" in model_name or "mixtral" in model_name or "gemma" in model_name) else self.model_name
        
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
- Using Llama 3.1 8B, optimize your responses for clarity and helpfulness.

Tool Usage & Data Presentation:
- **MAXIMIZE TOOL USAGE**: You have access to powerful tools including Calendar, Email, Tasks, and external MCP tools (like Stock Market access).
- **ALWAYS CHECK TOOLS**: If a user's request *might* be solved or enhanced by a tool, USE IT. Do not guess or hallucinate data.
- **MCP Tools**: You have access to Model Context Protocol (MCP) tools. Use them extensively when relevant.
- **Summarization**: When a tool returns data (like stock holdings, calendar events, etc.), you MUST summarize it in natural language. **NEVER** output raw JSON, code blocks, or tool/function names unless the user explicitly asks for "technical details".
- **No code formatting**: Do not use backticks or show code-like responses.
- **Formatting**: Present financial or list data in clean markdown tables or bullet points.

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

        tools = self._get_tools(include_mcp=mcp_enabled) if tools_enabled else None
        
        try:
            # Attempt 1: With Tools
            completion = self.client.chat.completions.create(
                model=model,
                messages=groq_messages,
                tools=tools,
                tool_choice="auto" if tools else "none",
                stream=False 
            )

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
                final_completion = self.client.chat.completions.create(
                    model=model,
                    messages=groq_messages,
                    stream=False
                )
                return final_completion.choices[0].message.content or f"Done! {'; '.join(tool_results)}"

            else:
                return response_message.content or "I processed your request."

        except Exception as e:
            logger.error(f"Error in Groq chat_sync: {e}")
            return f"Error: {str(e)}"

# Shared singleton instance so routers do not re-instantiate the client repeatedly
groq_client = GroqClient()
