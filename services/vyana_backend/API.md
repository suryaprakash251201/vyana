# Vyana Backend API Documentation

## Overview

The Vyana backend is a Python FastAPI application that provides AI-powered personal assistant capabilities.

**Base URL**: `http://localhost:8080` (configurable via `PORT` env var)

---

## Authentication

Most endpoints require Google OAuth authentication. The auth flow is:

1. Call `GET /google/auth` to get the OAuth URL
2. User completes OAuth in browser
3. Callback at `GET /google/oauth/callback` stores tokens

---

## Endpoints

### Health & Root

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Root endpoint, returns API info |
| `GET` | `/health` | Health check endpoint |

**Response (Health)**:
```json
{
  "status": "ok",
  "version": "0.1.0"
}
```

---

### Chat

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/chat/send` | Send a message to the AI assistant |
| `GET` | `/chat/stream` | SSE stream for chat responses |

**Request (Send)**:
```json
{
  "message": "What's on my calendar today?",
  "conversation_id": "optional-uuid",
  "tools_enabled": true
}
```

---

### Tasks

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/tasks/list` | List all uncompleted tasks |
| `POST` | `/tasks/create` | Create a new task |
| `POST` | `/tasks/complete` | Mark a task as completed |

**Request (Create)**:
```json
{
  "title": "Buy groceries",
  "due_date": "2026-01-20"
}
```

**Response (Task)**:
```json
{
  "id": "uuid",
  "title": "Buy groceries",
  "due_date": "2026-01-20",
  "is_completed": false,
  "created_at": "2026-01-19T10:00:00Z"
}
```

---

### Calendar

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/calendar/today` | Get today's calendar events |
| `POST` | `/calendar/create` | Create a calendar event |

**Request (Create)**:
```json
{
  "summary": "Team Meeting",
  "start_time": "2026-01-20T14:00:00",
  "duration_minutes": 60
}
```

---

### Gmail

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/gmail/unread` | Get unread email summaries |
| `POST` | `/gmail/send` | Send an email |

---

### Voice

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/voice/transcribe` | Transcribe audio to text |

**Request**: Multipart form with audio file

---

### Text-to-Speech

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/tts/speak` | Convert text to speech audio |

**Request**:
```json
{
  "text": "Hello, how can I help you today?"
}
```

---

### Tools

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/tools/list` | List available AI tools |
| `POST` | `/tools/toggle` | Enable/disable tools |

---

### MCP (Model Context Protocol)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/mcp/servers` | List configured MCP servers |
| `POST` | `/mcp/connect` | Connect to an MCP server |
| `POST` | `/mcp/call` | Call an MCP tool |

The MCP protocol endpoint is also exposed at `/mcp-server` for direct MCP client connections.

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GEMINI_API_KEY` | Yes | Google Gemini API key |
| `GROQ_API_KEY` | Yes | Groq API key for transcription |
| `GOOGLE_CLIENT_ID` | Yes | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Yes | Google OAuth client secret |
| `GOOGLE_REDIRECT_URI` | Yes | OAuth callback URL |
| `SECRET_KEY` | Yes | Server secret key |
| `CORS_ORIGINS` | No | Allowed CORS origins (default: `*`) |
| `SUPABASE_URL` | No | Supabase project URL |
| `SUPABASE_KEY` | No | Supabase anon key |
| `DEBUG` | No | Enable debug mode (default: `true`) |

---

## Error Responses

All error responses follow this format:

```json
{
  "detail": "Error message describing the issue"
}
```

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Not authenticated |
| 403 | Forbidden - Not authorized |
| 404 | Not Found - Resource doesn't exist |
| 500 | Internal Server Error |

---

## Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080

# Run tests
pytest tests/ -v
```
