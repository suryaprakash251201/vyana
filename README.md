# Vyana - Personal AI Assistant

Vyana ("Breath/Life" in Sanskrit, implying pervasive care) is a private, personal AI executive assistant built for Suryaprakash.

## Architecture

- **Frontend**: Flutter (Android/Windows)
- **Backend**: Python FastAPI
- **AI**: Gemini 2.0 Flash (via Backend)
- **Data**: Local SQLite + Google APIs (Gmail, Calendar)

## Prerequisites

- Flutter SDK (Latest Stable)
- Python 3.10+
- Google Cloud Project with OAuth Crednetials

## Getting Started

### 1. Backend Setup

```bash
cd services/vyana_backend
python -m venv venv
# Windows
.\venv\Scripts\activate
# Install dependencies
pip install -r requirements.txt

# Create .env
cp .env.example .env
# EDIT .env with your keys!

# Run Server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

### 2. Frontend Setup

```bash
cd apps/vyana_flutter
flutter pub get
flutter run
```

## Security & Privacy

- **No Keys in App**: All API keys reside in backend `.env`.
- **Local Network**: App communicates with backend over local network (or localhost `10.0.2.2` on emulator).
- **Kill Switch**: Use the in-app settings to completely disable external tool access.
