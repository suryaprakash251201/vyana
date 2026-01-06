import requests
import datetime
from dateutil import parser as date_parser
import json
import logging
from app.config import settings

logger = logging.getLogger(__name__)

class CalendarService:
    def __init__(self):
        self.base_url = f"{settings.SUPABASE_URL}/rest/v1/calendar_events"
        self.headers = {
            "apikey": settings.SUPABASE_KEY,
            "Authorization": f"Bearer {settings.SUPABASE_KEY}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        }

    def get_events(self, start_date_str: str = None, end_date_str: str = None):
        """
        Get events for a specific date or range.
        If only start_date_str is provided, fetches for that single day.
        If end_date_str is provided, fetches from start_date (00:00) to end_date (23:59).
        """
        try:
            if start_date_str:
                start_dt = date_parser.parse(start_date_str)
            else:
                # Use local time for "today"
                start_dt = datetime.datetime.now()
            
            # Start at beginning of the start day
            start_dt = start_dt.replace(hour=0, minute=0, second=0, microsecond=0)
            
            if end_date_str:
                end_dt = date_parser.parse(end_date_str)
                # Set to end of next day? Or just use < (end_dt + 1 day)?
                # Let's assume end_date_str is inclusive for the day.
                end_dt = end_dt.replace(hour=0, minute=0, second=0, microsecond=0) + datetime.timedelta(days=1)
            else:
                end_dt = start_dt + datetime.timedelta(days=1)
            
            start_iso = start_dt.isoformat()
            end_iso = end_dt.isoformat()
            
            logger.info(f"Fetching events from {start_iso} to {end_iso}")
            
            # Supabase PostgREST filtering
            query = f"?select=*&start_time=gte.{start_iso}&start_time=lt.{end_iso}&order=start_time.asc"
            
            response = requests.get(f"{self.base_url}{query}", headers=self.headers)
            logger.info(f"Supabase response status: {response.status_code}")
            
            if response.status_code != 200:
                logger.error(f"Supabase error: {response.text}")
                return [{"error": f"Supabase error: {response.text}"}]
            
            events = response.json()
            logger.info(f"Found {len(events)} events")
            
            # Map to expected structure
            structured = []
            for e in events:
                structured.append({
                    "id": e.get('id'),
                    "summary": e.get('summary', 'No Title'),
                    "start": e.get('start_time'),
                    "link": "",
                    "location": e.get('location', ''),
                    "description": e.get('description', '')
                })
            return structured

        except Exception as e:
            logger.error(f"Error fetching calendar: {e}")
            return [{"error": f"Error fetching calendar: {e}"}]

    def create_event(self, summary: str, start_time: str, duration_minutes: int = 60, description: str = None):
        try:
            # Parse and normalize the start_time
            parsed_time = date_parser.parse(start_time)
            
            data = {
                "summary": summary,
                "start_time": parsed_time.isoformat(),
                "duration_minutes": duration_minutes,
                "user_id": "app_user"
            }
            
            if description:
                data["description"] = description
            
            logger.info(f"Creating event: {data}")
            
            response = requests.post(self.base_url, headers=self.headers, json=data)
            
            if response.status_code not in [200, 201]:
                logger.error(f"Supabase create error: {response.status_code} - {response.text}")
                return f"Error creating event: {response.text}"
            
            created = response.json()
            logger.info(f"Event created: {created}")
            
            if created:
                return f"Event created: {summary} at {parsed_time.strftime('%Y-%m-%d %H:%M')}"
            return "Event created"
            
        except Exception as e:
            logger.error(f"Error creating event: {e}")
            return f"Error creating event: {e}"

    def update_event(self, event_id: str, summary: str = None, start_time: str = None, 
                     duration_minutes: int = None, description: str = None):
        try:
            data = {}
            if summary:
                data["summary"] = summary
            if start_time:
                parsed_time = date_parser.parse(start_time)
                data["start_time"] = parsed_time.isoformat()
            if duration_minutes:
                data["duration_minutes"] = duration_minutes
            if description is not None:
                data["description"] = description
            
            if not data:
                return "No fields to update"
            
            logger.info(f"Updating event {event_id}: {data}")
            
            response = requests.patch(
                f"{self.base_url}?id=eq.{event_id}",
                headers=self.headers,
                json=data
            )
            
            if response.status_code not in [200, 204]:
                logger.error(f"Supabase update error: {response.status_code} - {response.text}")
                return f"Error updating event: {response.text}"
            
            return f"Event updated successfully"
            
        except Exception as e:
            logger.error(f"Error updating event: {e}")
            return f"Error updating event: {e}"

    def delete_event(self, event_id: str):
        try:
            response = requests.delete(
                f"{self.base_url}?id=eq.{event_id}",
                headers=self.headers
            )
            
            if response.status_code not in [200, 204]:
                logger.error(f"Supabase delete error: {response.status_code} - {response.text}")
                return f"Error deleting event: {response.text}"
            
            return "Event deleted successfully"
            
        except Exception as e:
            logger.error(f"Error deleting event: {e}")
            return f"Error deleting event: {e}"

calendar_service = CalendarService()
