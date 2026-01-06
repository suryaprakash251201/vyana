import os
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GROQ_API_KEY")
print(f"API Key found: {bool(api_key)}")

client = Groq(api_key=api_key)

# Test 1: Simple Chat
print("\n--- Test 1: Simple Chat ---")
try:
    completion = client.chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=[
            {"role": "user", "content": "hi"}
        ],
        stream=False
    )
    print("Response:", completion.choices[0].message.content)
except Exception as e:
    print("Test 1 Failed:", e)

# Test 2: Chat with Tools (Simulating the error)
print("\n--- Test 2: Chat with Tools ---")
tools = [
     {
        "type": "function",
        "function": {
            "name": "list_tasks",
            "description": "Lists all uncompleted tasks",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    }
]

try:
    completion = client.chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=[
            {"role": "system", "content": "Use tools."},
            {"role": "user", "content": "list my tasks"}
        ],
        tools=tools,
        tool_choice="auto",
        stream=False
    )
    print("Response Content:", completion.choices[0].message.content)
    print("Tool Calls:", completion.choices[0].message.tool_calls)
except Exception as e:
    print("Test 2 Failed:", e)
