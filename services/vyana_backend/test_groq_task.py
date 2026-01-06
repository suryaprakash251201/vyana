import os
import json
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GROQ_API_KEY")
client = Groq(api_key=api_key)

print("\n--- Test: Create Task Tool ---")
tools = [
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
    }
]

try:
    completion = client.chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=[
            {"role": "system", "content": "You are a helper. Use tools."},
            {"role": "user", "content": "create task buy milk tomorrow"}
        ],
        tools=tools,
        tool_choice="auto",
        stream=False
    )
    print("Response Content:", completion.choices[0].message.content)
    print("Tool Calls:", completion.choices[0].message.tool_calls)
except Exception as e:
    print("Test Failed:", e)
