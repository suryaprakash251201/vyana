import datetime
import logging
from googleapiclient.discovery import build
from app.services.google_oauth import oauth_service
from app.config import settings

logger = logging.getLogger(__name__)

class CalendarService:
    def _get_google_service(self):
        creds = oauth_service.get_credentials()
        if not creds:
            return None
        return build('calendar', 'v3', credentials=creds)

    def _resolve_calendar_id(self, calendar_id: str | None) -> str:
        if calendar_id and calendar_id.strip():
            return calendar_id.strip()
        return settings.GOOGLE_CALENDAR_ID or "primary"

    def _to_iso(self, date_str: str, end: bool = False) -> str:
        # date_str format: YYYY-MM-DD
        suffix = "T23:59:59" if end else "T00:00:00"
        return f"{date_str}{suffix}"

    def get_events(self, start_date_str: str = None, end_date_str: str = None, user_id: str = None, calendar_id: str = None):
        try:
            google_service = self._get_google_service()
            if not google_service:
                return [{"error": "Google Calendar not connected"}]

            target_calendar_id = self._resolve_calendar_id(calendar_id)

            if start_date_str and end_date_str:
                time_min = self._to_iso(start_date_str)
                time_max = self._to_iso(end_date_str, end=True)
            elif start_date_str:
                time_min = self._to_iso(start_date_str)
                time_max = self._to_iso(start_date_str, end=True)
            else:
                today = datetime.datetime.now().date().isoformat()
                time_min = self._to_iso(today)
                time_max = self._to_iso(today, end=True)

            events_result = google_service.events().list(
                calendarId=target_calendar_id,
                timeMin=f"{time_min}Z",
                timeMax=f"{time_max}Z",
                singleEvents=True,
                orderBy='startTime'
            ).execute()

            items = events_result.get('items', [])
            structured = []
            for e in items:
                start = e.get('start', {})
                end = e.get('end', {})
                start_val = start.get('dateTime') or start.get('date')
                end_val = end.get('dateTime') or end.get('date')
                structured.append({
                    "id": e.get('id'),
                    "summary": e.get('summary', ''),
                    "start": start_val or '',
                    "description": e.get('description', ''),
                    "end": end_val or '',
                    "location": e.get('location', '')
                })
            return structured

        except Exception as e:
            logger.error(f"Error fetching Google Calendar: {e}")
            return [{"error": f"Error fetching calendar: {e}"}]

    def create_event(self, summary: str, start_time: str, duration_minutes: int = 60, description: str = None, user_id: str = None, calendar_id: str = None):
        try:
            google_service = self._get_google_service()
            if not google_service:
                return "Google Calendar not connected"

            target_calendar_id = self._resolve_calendar_id(calendar_id)

            try:
                start_dt = datetime.datetime.fromisoformat(start_time.replace('Z', '+00:00'))
            except ValueError:
                start_dt = datetime.datetime.now()
            end_dt = start_dt + datetime.timedelta(minutes=duration_minutes)

            event = {
                'summary': summary,
                'description': description,
                'start': {
                    'dateTime': start_dt.isoformat(),
                    'timeZone': 'Asia/Kolkata',
                },
                'end': {
                    'dateTime': end_dt.isoformat(),
                    'timeZone': 'Asia/Kolkata',
                },
                'reminders': {
                    'useDefault': True
                }
            }
            google_service.events().insert(calendarId=target_calendar_id, body=event).execute()
            return f"Event created in Google Calendar: {summary} at {start_dt.strftime('%H:%M')}"
        except Exception as e:
            logger.error(f"Create Event Error: {e}")
            return f"Error creating event: {e}"

    def update_event(self, event_id: str, summary: str = None, start_time: str = None, duration_minutes: int = None, description: str = None, calendar_id: str = None):
        try:
            google_service = self._get_google_service()
            if not google_service:
                return "Google Calendar not connected"

            target_calendar_id = self._resolve_calendar_id(calendar_id)

            event = google_service.events().get(calendarId=target_calendar_id, eventId=event_id).execute()
            if summary:
                event['summary'] = summary
            if description is not None:
                event['description'] = description
            if start_time:
                try:
                    start_dt = datetime.datetime.fromisoformat(start_time.replace('Z', '+00:00'))
                    event['start'] = {'dateTime': start_dt.isoformat(), 'timeZone': 'Asia/Kolkata'}
                    if duration_minutes:
                        end_dt = start_dt + datetime.timedelta(minutes=duration_minutes)
                        event['end'] = {'dateTime': end_dt.isoformat(), 'timeZone': 'Asia/Kolkata'}
                except ValueError:
                    pass
            google_service.events().update(calendarId=target_calendar_id, eventId=event_id, body=event).execute()
            return f"Event updated: {summary or event_id}"
        except Exception as e:
            logger.error(f"Update Event Error: {e}")
            return f"Error updating event: {e}"

    def delete_event(self, event_id: str, calendar_id: str = None):
        try:
            google_service = self._get_google_service()
            if not google_service:
                return "Google Calendar not connected"

            target_calendar_id = self._resolve_calendar_id(calendar_id)

            google_service.events().delete(calendarId=target_calendar_id, eventId=event_id).execute()
            return "Event deleted from Google Calendar"
        except Exception as e:
            logger.error(f"Delete Event Error: {e}")
            return f"Error deleting event: {e}"

calendar_service = CalendarService()
