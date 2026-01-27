# Vyana Tech Stack (Frontend & Backend)

This document summarizes the technologies used in this project, with a focus on frontend and backend components, plus key integrations and deployment notes.

## Frontend (Client)

Primary app lives in [apps/vyana_flutter/](apps/vyana_flutter/).

### Core
- **Framework**: Flutter (Dart SDK ^3.10.4)
- **Platforms**: Android, iOS, Windows, Linux, Web (Flutter multi-platform)
- **State management**: Riverpod + code generation
- **Routing**: GoRouter
- **HTTP**: http

### UI/UX Libraries
- flutter_animate (animations)
- animated_text_kit (text animations)
- google_fonts (typography)
- flutter_markdown + flutter_html (rich text rendering)
- gap (layout spacing)

### Device & OS Capabilities
- permission_handler (permissions)
- record (audio recording)
- audioplayers (audio playback)
- flutter_local_notifications + timezone (notifications + time zones)
- path_provider (filesystem paths)
- url_launcher (open external URLs)

### Storage & Auth
- shared_preferences (local storage)
- supabase_flutter (Supabase client + auth)

### Key References
- Flutter dependencies: [apps/vyana_flutter/pubspec.yaml](apps/vyana_flutter/pubspec.yaml)
- App entry: [apps/vyana_flutter/lib/main.dart](apps/vyana_flutter/lib/main.dart)
- Architecture overview: [ARCHITECTURE.md](ARCHITECTURE.md)

## Backend (Server)

Primary backend lives in [services/vyana_backend/](services/vyana_backend/).

### Core
- **Framework**: FastAPI
- **Server**: Uvicorn
- **Config**: python-dotenv + Pydantic Settings

### AI & LLM Tooling
- **Google Gemini**: google-generativeai
- **Groq**: groq
- **LangChain + LangGraph**: langchain, langchain-core, langchain-groq, langgraph

### Google Integrations
- Google OAuth + People/Calendar/Gmail/Tasks APIs via:
  - google-auth-oauthlib
  - google-auth-httplib2
  - google-api-python-client

### Data & Storage
- SQLAlchemy (SQLite)
- Supabase SDK (supabase)

### API & Networking
- httpx, requests
- python-multipart (file uploads)

### MCP & Streaming
- fastmcp (Model Context Protocol)
- sse-starlette (server-sent events)

### Key References
- Backend dependencies: [services/vyana_backend/requirements.txt](services/vyana_backend/requirements.txt)
- App entry: [services/vyana_backend/app/main.py](services/vyana_backend/app/main.py)
- API docs: [services/vyana_backend/API.md](services/vyana_backend/API.md)
- Architecture overview: [ARCHITECTURE.md](ARCHITECTURE.md)

## Deployment & DevOps

- Docker compose for backend containerization: [services/vyana_backend/docker-compose.yml](services/vyana_backend/docker-compose.yml)
- CI/CD workflows indicated in architecture notes: [ARCHITECTURE.md](ARCHITECTURE.md)

## Summary

- **Frontend**: Flutter app using Riverpod, GoRouter, Supabase, and platform APIs for audio, notifications, and storage.
- **Backend**: FastAPI server with AI integrations (Gemini, Groq), LangChain/LangGraph, Google APIs, SQLite + Supabase, and MCP support.
