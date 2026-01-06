import google.generativeai as genai
from google.generativeai.types import content_types
from collections.abc import Iterable
import json
import asyncio
import logging
from app.config import settings
from app.services.tasks_repo import tasks_repo
from app.services.google_oauth import oauth_service
from app.services.calendar_service import calendar_service
from app.services.gmail_service import gmail_service

# Setup logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

class GeminiClient:
    def __init__(self):
        genai.configure(api_key=settings.GEMINI_API_KEY)
        self.model_name = settings.GEMINI_MODEL
        logger.info(f"GeminiClient initialized with model: {self.model_name}")

    def _get_tool_functions(self):
        """Returns mapping of function name to callable"""
        return {
            "create_task": self._create_task,
            "list_tasks": self._list_tasks,
            "get_calendar_today": self._get_calendar_today,
            "get_unread_emails_summary": self._get_unread_emails_summary,
            "create_calendar_event": self._create_calendar_event,
            "send_email": self._send_email,
        }

    def _get_tools(self):
        """Returns list of tool declarations"""
        return [
            genai.protos.Tool(
                function_declarations=[
                    genai.protos.FunctionDeclaration(
                        name="create_task",
                        description="Creates a new task in the personal to-do list",
                        parameters=genai.protos.Schema(
                            type=genai.protos.Type.OBJECT,
                            properties={
                                "title": genai.protos.Schema(type=genai.protos.Type.STRING, description="The task title"),
                                "due_date": genai.protos.Schema(type=genai.protos.Type.STRING, description="Optional due date in YYYY-MM-DD format"),
                            },
                            required=["title"],
                        ),
                    ),
                    genai.protos.FunctionDeclaration(
                        name="list_tasks",
                        description="Lists all uncompleted tasks",
                        parameters=genai.protos.Schema(type=genai.protos.Type.OBJECT, properties={}),
                    ),
                    genai.protos.FunctionDeclaration(
                        name="get_calendar_today",
                        description="Gets calendar events for today",
                        parameters=genai.protos.Schema(type=genai.protos.Type.OBJECT, properties={}),
                    ),
                    genai.protos.FunctionDeclaration(
                        name="get_unread_emails_summary",
                        description="Gets a summary of recent unread emails",
                        parameters=genai.protos.Schema(type=genai.protos.Type.OBJECT, properties={}),
                    ),
                    genai.protos.FunctionDeclaration(
                        name="create_calendar_event",
                        description="Creates a generic calendar event. Use this for meetings, reminders, or any scheduled activity.",
                        parameters=genai.protos.Schema(
                            type=genai.protos.Type.OBJECT,
                            properties={
                                "summary": genai.protos.Schema(type=genai.protos.Type.STRING, description="Event title/summary"),
                                "start_time": genai.protos.Schema(type=genai.protos.Type.STRING, description="Start time in ISO format (YYYY-MM-DDTHH:MM:SS)"),
                                "duration_minutes": genai.protos.Schema(type=genai.protos.Type.INTEGER, description="Duration in minutes (default 60)"),
                            },
                            required=["summary", "start_time"],
                        ),
                    ),
                    genai.protos.FunctionDeclaration(
                        name="send_email",
                        description="Sends an email to a recipient",
                        parameters=genai.protos.Schema(
                            type=genai.protos.Type.OBJECT,
                            properties={
                                "to_email": genai.protos.Schema(type=genai.protos.Type.STRING, description="Recipient email address"),
                                "subject": genai.protos.Schema(type=genai.protos.Type.STRING, description="Email subject"),
                                "body": genai.protos.Schema(type=genai.protos.Type.STRING, description="Email body content"),
                            },
                            required=["to_email", "subject", "body"],
                        ),
                    ),
                ]
            )
        ]

    def _get_model(self, tools_enabled: bool, model_name: str):
        logger.debug(f"Getting model: {model_name}, tools_enabled: {tools_enabled}")
        if tools_enabled:
            return genai.GenerativeModel(
                model_name=model_name,
                tools=self._get_tools(),
                system_instruction="You are Vyana, the private executive assistant for Suryaprakash. Be brief by default. When the user asks to create a task, ALWAYS use the create_task function."
            )
        else:
            return genai.GenerativeModel(
                model_name=model_name,
                system_instruction="You are Vyana, the private executive assistant for Suryaprakash. Be brief by default."
            )

    def _create_task(self, title: str, due_date: str = None):
        """Creates a new task in the personal to-do list."""
        logger.info(f"Creating task: {title}, due_date: {due_date}")
        result = tasks_repo.add_task(title, due_date)
        logger.info(f"Task created with ID: {result.id}")
        return f"Task '{title}' created successfully with ID {result.id}"

    def _list_tasks(self):
        """Lists all uncompleted tasks."""
        logger.info("Listing tasks")
        tasks = tasks_repo.list_tasks(include_completed=False)
        if not tasks:
            return "No pending tasks."
        return "\n".join([f"- {t.title}" + (f" (due: {t.due_date})" if t.due_date else "") for t in tasks])

    def _get_calendar_today(self):
        """Gets calendar events for today."""
        logger.info("Getting calendar events")
        return calendar_service.get_events_today()

    def _get_unread_emails_summary(self):
        """Gets a summary of recent unread emails."""
        logger.info("Getting email summary")
        return gmail_service.summarize_emails()

    def _create_calendar_event(self, summary: str, start_time: str, duration_minutes: int = 60):
        """Creates a calendar event."""
        logger.info(f"Creating event: {summary} at {start_time}")
        return calendar_service.create_event(summary, start_time, duration_minutes)

    def _send_email(self, to_email: str, subject: str, body: str):
        """Sends an email."""
        logger.info(f"Sending email to {to_email}")
        return gmail_service.send_email(to_email, subject, body)

    def _execute_function(self, function_call):
        """Execute a function call and return the result"""
        fn_name = function_call.name
        fn_args = dict(function_call.args) if function_call.args else {}
        logger.info(f"Executing function: {fn_name} with args: {fn_args}")
        
        tool_functions = self._get_tool_functions()
        if fn_name in tool_functions:
            try:
                result = tool_functions[fn_name](**fn_args)
                logger.info(f"Function {fn_name} result: {result}")
                return result
            except Exception as e:
                logger.error(f"Error executing {fn_name}: {e}")
                return f"Error executing {fn_name}: {str(e)}"
        logger.warning(f"Unknown function: {fn_name}")
        return f"Unknown function: {fn_name}"

    async def stream_chat(self, messages, conversation_id: str, tools_enabled: bool, model_name: str = None, memory_enabled: bool = True):
        logger.info(f"stream_chat called: tools_enabled={tools_enabled}, model={model_name or self.model_name}, memory_enabled={memory_enabled}")
        model = self._get_model(tools_enabled, model_name or self.model_name)
        
        # Convert Pydantic messages to Gemini format
        history = []
        if memory_enabled:
            for m in messages[:-1]:
                role = "user" if m.role == "user" else "model"
                history.append({"role": role, "parts": [m.content]})
        
        last_message = messages[-1].content
        logger.debug(f"Last message: {last_message}")
        logger.debug(f"History length: {len(history)}")
        
        chat = model.start_chat(history=history)
        
        try:
            if tools_enabled:
                logger.info("Sending message with tools enabled")
                response = chat.send_message(last_message)
                logger.debug(f"Initial response candidates: {len(response.candidates) if response.candidates else 0}")
                
                # Check if the response contains function calls
                max_iterations = 5
                iteration = 0
                
                while iteration < max_iterations:
                    iteration += 1
                    logger.debug(f"Iteration {iteration}")
                    
                    # Check for function calls in the response
                    has_function_call = False
                    
                    if response.candidates and len(response.candidates) > 0:
                        candidate = response.candidates[0]
                        if candidate.content and candidate.content.parts:
                            for part in candidate.content.parts:
                                if hasattr(part, 'function_call') and part.function_call and part.function_call.name:
                                    has_function_call = True
                                    fn_call = part.function_call
                                    logger.info(f"Found function call: {fn_call.name}")
                                    fn_result = self._execute_function(fn_call)
                                    
                                    # Send function result back to the model
                                    response = chat.send_message(
                                        genai.protos.Content(
                                            parts=[genai.protos.Part(
                                                function_response=genai.protos.FunctionResponse(
                                                    name=fn_call.name,
                                                    response={"result": fn_result}
                                                )
                                            )]
                                        )
                                    )
                                    logger.debug("Function result sent back to model")
                                    break
                    
                    if not has_function_call:
                        logger.debug("No function call found, breaking loop")
                        break
                
                # Get text from response safely
                try:
                    response_text = response.text
                    logger.info(f"Final response text: {response_text[:100] if response_text else 'None'}...")
                except Exception as text_err:
                    logger.warning(f"Could not get response.text: {text_err}")
                    # Try to extract text from parts
                    response_text = ""
                    if response.candidates and len(response.candidates) > 0:
                        candidate = response.candidates[0]
                        if candidate.content and candidate.content.parts:
                            for part in candidate.content.parts:
                                if hasattr(part, 'text') and part.text:
                                    response_text += part.text
                
                if response_text:
                    yield f"data: {json.dumps({'type': 'text', 'content': response_text})}\n\n"
                else:
                    yield f"data: {json.dumps({'type': 'text', 'content': 'Done! The action has been completed.'})}\n\n"
            else:
                # Streaming for non-tool mode
                logger.info("Streaming without tools")
                response = chat.send_message(last_message, stream=True)
                for chunk in response:
                    if chunk.text:
                        yield f"data: {json.dumps({'type': 'text', 'content': chunk.text})}\n\n"
                    
        except Exception as e:
            logger.error(f"Error in stream_chat: {e}", exc_info=True)
            yield f"data: {json.dumps({'type': 'error', 'content': str(e)})}\n\n"

gemini_client = GeminiClient()

