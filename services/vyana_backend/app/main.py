from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routes import chat, tasks, google_auth, health, calendar, gmail, voice, mcp, tools

app = FastAPI(title="Vyana Backend", version="0.1.0")

# CORS for Flutter web/emulator
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(health.router)
app.include_router(chat.router, prefix="/chat", tags=["chat"]) # Will implement soon
app.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
app.include_router(google_auth.router, prefix="/google", tags=["google"])
app.include_router(calendar.router, prefix="/calendar", tags=["calendar"])
app.include_router(gmail.router, prefix="/gmail", tags=["gmail"])
app.include_router(voice.router, prefix="/voice", tags=["voice"])
app.include_router(tools.router, prefix="/tools", tags=["tools"])
app.include_router(mcp.router)  # MCP routes (prefix defined in router)

@app.get("/")
def read_root():
    return {"message": "Vyana Backend Running"}
