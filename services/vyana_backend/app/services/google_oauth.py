import os
import json
import sqlite3
from google_auth_oauthlib.flow import Flow
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from app.config import settings

# Database for tokens - use DATA_DIR for Docker compatibility
DATA_DIR = os.environ.get("DATA_DIR", ".")
os.makedirs(DATA_DIR, exist_ok=True)
DB_PATH = os.path.join(DATA_DIR, "vyana.db")

class OAuthService:
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        self._init_db()
        
        # Scopes required for Gmail, Calendar, and Tasks
        self.SCOPES = [
            'https://www.googleapis.com/auth/gmail.modify',
            'https://www.googleapis.com/auth/calendar',
            'https://www.googleapis.com/auth/tasks'
        ]

    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS auth (
                    key TEXT PRIMARY KEY,
                    value TEXT
                )
            """)

    def _save_creds(self, creds: Credentials):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "INSERT OR REPLACE INTO auth (key, value) VALUES (?, ?)",
                ("google_creds", creds.to_json())
            )

    def _load_creds(self) -> Credentials | None:
        with sqlite3.connect(self.db_path) as conn:
            row = conn.execute("SELECT value FROM auth WHERE key='google_creds'").fetchone()
            if row:
                return Credentials.from_authorized_user_info(json.loads(row[0]))
        return None

    def get_credentials(self) -> Credentials | None:
        creds = self._load_creds()
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
                self._save_creds(creds)
            except Exception as e:
                print(f"Error refreshing token: {e}")
                return None
        return creds

    def get_auth_url(self):
        flow = Flow.from_client_config(
            {
                "web": {
                    "client_id": settings.GOOGLE_CLIENT_ID,
                    "client_secret": settings.GOOGLE_CLIENT_SECRET,
                    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                    "token_uri": "https://oauth2.googleapis.com/token",
                }
            },
            scopes=self.SCOPES,
            redirect_uri=settings.GOOGLE_REDIRECT_URI
        )
        auth_url, _ = flow.authorization_url(prompt='consent')
        return auth_url

    def handle_callback(self, code: str):
        try:
            print(f"Handling callback with code: {code[:10]}...")
            flow = Flow.from_client_config(
                 {
                    "web": {
                        "client_id": settings.GOOGLE_CLIENT_ID,
                        "client_secret": settings.GOOGLE_CLIENT_SECRET,
                        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                        "token_uri": "https://oauth2.googleapis.com/token",
                    }
                },
                scopes=self.SCOPES,
                redirect_uri=settings.GOOGLE_REDIRECT_URI
            )
            flow.fetch_token(code=code)
            creds = flow.credentials
            self._save_creds(creds)
            print("Successfully saved new credentials.")
            return "Authentication successful! You can close this window and return to the app."
        except Exception as e:
            print(f"Error in handle_callback: {e}")
            return f"Authentication failed: {str(e)}"

    def is_authenticated(self) -> bool:
        creds = self.get_credentials()
        return creds is not None and creds.valid

    def logout(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("DELETE FROM auth WHERE key='google_creds'")
            return True

oauth_service = OAuthService()
