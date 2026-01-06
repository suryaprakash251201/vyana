from fastapi import APIRouter
from app.services.google_oauth import oauth_service

router = APIRouter()

@router.get("/status")
def get_status():
    return {"authenticated": oauth_service.is_authenticated()}

@router.get("/start")
def start_auth():
    return {"auth_url": oauth_service.get_auth_url()}

@router.get("/callback")
def auth_callback(code: str):
    msg = oauth_service.handle_callback(code)
    return {"message": msg}

@router.post("/logout")
def logout():
    oauth_service.logout()
    return {"message": "Logged out"}
