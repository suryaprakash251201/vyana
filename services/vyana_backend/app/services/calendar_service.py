import datetime
import logging
from googleapiclient.discovery import build
from app.services.google_oauth import oauth_service

logger = logging.getLogger(__name__)

class CalendarService:
    def get_service(self):
        creds = oauth_service.get_credentials()
        if not creds:
            logger.warning("No valid Google credentials found.")
            return None
        return build('calendar', 'v3', credentials=creds)

    def get_events(self, start_date_str: str = None, end_date_str: str = None):
        try:
            service = self.get_service()
            if not service:
                return [{"error": "Not authenticated. Please connect Google Calendar in settings."}]

            # Default to now if no start date
            if start_date_str:
                start_dt = datetime.datetime.fromisoformat(start_date_str.replace('Z', '+00:00'))
            else:
                start_dt = datetime.datetime.utcnow()
            
            time_min = start_dt.isoformat() + 'Z'
            
            logger.info(f"Fetching Google Calendar events from {time_min}")
            
            events_result = service.events().list(
                calendarId='primary', 
                timeMin=time_min,
                maxResults=10, 
                singleEvents=True,
                orderBy='startTime'
            ).execute()
            
            events = events_result.get('items', [])
            logger.info(f"Found {len(events)} events")

            structured = []
            for e in events:
                start = e['start'].get('dateTime', e['start'].get('date'))
                structured.append({
                    "id": e['id'],
                    "summary": e.get('summary', 'No Title'),
                    "start": start,
                    "link": e.get('htmlLink', ''),
                    "location": e.get('location', ''),
                    "description": e.get('description', '')
                })
            return structured

        except Exception as e:
            logger.error(f"Error fetching calendar: {e}")
            return [{"error": f"Error fetching calendar: {e}"}]

    def create_event(self, summary: str, start_time: str, duration_minutes: int = 60, description: str = None):
        try:
            service = self.get_service()
            if not service:
                return "Not authenticated"

            # Parse start time
            try:
                start_dt = datetime.datetime.fromisoformat(start_time.replace('Z', '+00:00'))
            except ValueError:
                # Handle cases where ISO format might be slightly off
                start_dt = datetime.datetime.now() # Fallback

            end_dt = start_dt + datetime.timedelta(minutes=duration_minutes)

            event = {
                'summary': summary,
                'description': description or '',
                'start': {
                    'dateTime': start_dt.isoformat(),
                    'timeZone': 'Asia/Kolkata', # Defaulting to IST as per project context
                },
                'end': {
                    'dateTime': end_dt.isoformat(),
                    'timeZone': 'Asia/Kolkata',
                },
            }

            created_event = service.events().insert(calendarId='primary', body=event).execute()
            logger.info(f"Event created: {created_event.get('htmlLink')}")
            return f"Event created: {summary} at {start_dt.strftime('%H:%M')}"

        except Exception as e:
            logger.error(f"Error creating event: {e}")
            return f"Error creating event: {e}"

    def delete_event(self, event_id: str):
        try:
            service = self.get_service()
            if not service:
                return "Not authenticated"
            
            service.events().delete(calendarId='primary', eventId=event_id).execute()
            return "Event deleted"
        except Exception as e:
            logger.error(f"Error deleting event: {e}")
            return f"Error deleting event: {e}"

calendar_service = CalendarService()
