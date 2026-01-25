import datetime
import logging
from typing import Optional, List, Dict, Any
from googleapiclient.discovery import build
from app.services.google_oauth import oauth_service
from app.config import settings

logger = logging.getLogger(__name__)

# Default calendar colors from Google Calendar
CALENDAR_COLORS = {
    "1": "#7986cb",  # Lavender
    "2": "#33b679",  # Sage
    "3": "#8e24aa",  # Grape
    "4": "#e67c73",  # Flamingo
    "5": "#f6c026",  # Banana
    "6": "#f5511d",  # Tangerine
    "7": "#039be5",  # Peacock
    "8": "#616161",  # Graphite
    "9": "#3f51b5",  # Blueberry
    "10": "#0b8043", # Basil
    "11": "#d60000", # Tomato
}

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

    # =========================================================================
    # Calendar List Operations
    # =========================================================================
    
    def list_calendars(self) -> List[Dict[str, Any]]:
        """List all calendars accessible by the user"""
        try:
            google_service = self._get_google_service()
            if not google_service:
                return [{"error": "Google Calendar not connected"}]

            calendar_list = google_service.calendarList().list().execute()
            calendars = []
            
            for cal in calendar_list.get('items', []):
                calendars.append({
                    "id": cal.get('id'),
                    "summary": cal.get('summary', 'Unnamed Calendar'),
                    "description": cal.get('description', ''),
                    "primary": cal.get('primary', False),
                    "backgroundColor": cal.get('backgroundColor', '#4285f4'),
                    "foregroundColor": cal.get('foregroundColor', '#ffffff'),
                    "accessRole": cal.get('accessRole', 'reader'),
                    "selected": cal.get('selected', False),
                })
            
            return calendars
        except Exception as e:
            logger.error(f"Error listing calendars: {e}")
            return [{"error": f"Error listing calendars: {e}"}]

    # =========================================================================
    # Event Operations
    # =========================================================================

    def get_events(self, start_date_str: str = None, end_date_str: str = None, 
                   user_id: str = None, calendar_id: str = None) -> List[Dict[str, Any]]:
        """Get events from Google Calendar with color and recurrence info"""
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
                
                # Determine if all-day event
                is_all_day = 'date' in start and 'dateTime' not in start
                
                # Get color
                color_id = e.get('colorId', '7')
                color = CALENDAR_COLORS.get(color_id, '#039be5')
                
                # Get recurrence info
                recurring_event_id = e.get('recurringEventId')
                
                # Get meeting link
                hangout_link = e.get('hangoutLink', '')
                conference_data = e.get('conferenceData', {})
                meet_link = ''
                if conference_data:
                    entry_points = conference_data.get('entryPoints', [])
                    for ep in entry_points:
                        if ep.get('entryPointType') == 'video':
                            meet_link = ep.get('uri', '')
                            break
                
                # Get reminders
                reminders = e.get('reminders', {})
                reminder_minutes = []
                if reminders.get('useDefault'):
                    reminder_minutes = [30]  # Default reminder
                else:
                    for override in reminders.get('overrides', []):
                        reminder_minutes.append(override.get('minutes', 30))
                
                # Get attachments
                attachments = []
                for att in e.get('attachments', []):
                    attachments.append({
                        "fileUrl": att.get('fileUrl', ''),
                        "title": att.get('title', ''),
                        "mimeType": att.get('mimeType', ''),
                    })
                
                structured.append({
                    "id": e.get('id'),
                    "summary": e.get('summary', ''),
                    "start": start_val or '',
                    "end": end_val or '',
                    "description": e.get('description', ''),
                    "location": e.get('location', ''),
                    "isAllDay": is_all_day,
                    "color": color,
                    "colorId": color_id,
                    "isRecurring": recurring_event_id is not None,
                    "recurringEventId": recurring_event_id,
                    "meetLink": meet_link or hangout_link,
                    "reminders": reminder_minutes,
                    "attachments": attachments,
                    "status": e.get('status', 'confirmed'),
                    "creator": e.get('creator', {}).get('email', ''),
                })
            
            return structured

        except Exception as e:
            logger.error(f"Error fetching Google Calendar: {e}")
            return [{"error": f"Error fetching calendar: {e}"}]

    def create_event(
        self, 
        summary: str, 
        start_time: str, 
        duration_minutes: int = 60, 
        description: str = None, 
        user_id: str = None, 
        calendar_id: str = None,
        is_all_day: bool = False,
        recurrence: str = None,  # DAILY, WEEKLY, MONTHLY, YEARLY
        recurrence_count: int = None,
        recurrence_until: str = None,  # YYYY-MM-DD
        add_meet_link: bool = False,
        color_id: str = None,
        reminders: List[int] = None,  # List of minutes before event
        location: str = None,
        attendees: List[str] = None,  # List of email addresses
    ) -> Dict[str, Any]:
        """Create a calendar event with all features"""
        try:
            google_service = self._get_google_service()
            if not google_service:
                return {"error": "Google Calendar not connected"}

            target_calendar_id = self._resolve_calendar_id(calendar_id)

            # Parse start time
            try:
                start_dt = datetime.datetime.fromisoformat(start_time.replace('Z', '+00:00'))
            except ValueError:
                start_dt = datetime.datetime.now()
            
            end_dt = start_dt + datetime.timedelta(minutes=duration_minutes)

            # Build event body
            event = {
                'summary': summary,
                'description': description,
                'location': location,
            }
            
            # Handle all-day vs timed event
            if is_all_day:
                event['start'] = {'date': start_dt.date().isoformat()}
                event['end'] = {'date': (start_dt.date() + datetime.timedelta(days=1)).isoformat()}
            else:
                event['start'] = {
                    'dateTime': start_dt.isoformat(),
                    'timeZone': 'Asia/Kolkata',
                }
                event['end'] = {
                    'dateTime': end_dt.isoformat(),
                    'timeZone': 'Asia/Kolkata',
                }
            
            # Add recurrence rule
            if recurrence:
                rrule = f"RRULE:FREQ={recurrence.upper()}"
                if recurrence_count:
                    rrule += f";COUNT={recurrence_count}"
                elif recurrence_until:
                    until_dt = datetime.datetime.strptime(recurrence_until, '%Y-%m-%d')
                    rrule += f";UNTIL={until_dt.strftime('%Y%m%dT235959Z')}"
                event['recurrence'] = [rrule]
            
            # Add Google Meet link
            if add_meet_link:
                event['conferenceData'] = {
                    'createRequest': {
                        'requestId': f"vyana-{datetime.datetime.now().timestamp()}",
                        'conferenceSolutionKey': {'type': 'hangoutsMeet'}
                    }
                }
            
            # Set color
            if color_id:
                event['colorId'] = color_id
            
            # Set reminders
            if reminders:
                event['reminders'] = {
                    'useDefault': False,
                    'overrides': [{'method': 'popup', 'minutes': m} for m in reminders]
                }
            else:
                event['reminders'] = {'useDefault': True}
            
            # Add attendees
            if attendees:
                event['attendees'] = [{'email': email} for email in attendees]
            
            # Create event with conference data support
            conference_version = 1 if add_meet_link else 0
            created_event = google_service.events().insert(
                calendarId=target_calendar_id, 
                body=event,
                conferenceDataVersion=conference_version
            ).execute()
            
            # Extract meet link from response
            meet_link = created_event.get('hangoutLink', '')
            
            result = {
                "success": True,
                "message": f"Event created: {summary} at {start_dt.strftime('%H:%M')}",
                "eventId": created_event.get('id'),
                "htmlLink": created_event.get('htmlLink'),
            }
            
            if meet_link:
                result["meetLink"] = meet_link
                result["message"] += f" (Meet link added)"
            
            return result
            
        except Exception as e:
            logger.error(f"Create Event Error: {e}")
            return {"error": f"Error creating event: {e}"}

    def update_event(
        self, 
        event_id: str, 
        summary: str = None, 
        start_time: str = None, 
        duration_minutes: int = None, 
        description: str = None, 
        calendar_id: str = None,
        is_all_day: bool = None,
        color_id: str = None,
        reminders: List[int] = None,
        location: str = None,
        add_meet_link: bool = False,
    ) -> Dict[str, Any]:
        """Update an existing calendar event"""
        try:
            google_service = self._get_google_service()
            if not google_service:
                return {"error": "Google Calendar not connected"}

            target_calendar_id = self._resolve_calendar_id(calendar_id)

            event = google_service.events().get(
                calendarId=target_calendar_id, 
                eventId=event_id
            ).execute()
            
            if summary:
                event['summary'] = summary
            if description is not None:
                event['description'] = description
            if location is not None:
                event['location'] = location
            if color_id:
                event['colorId'] = color_id
            
            if start_time:
                try:
                    start_dt = datetime.datetime.fromisoformat(start_time.replace('Z', '+00:00'))
                    
                    if is_all_day:
                        event['start'] = {'date': start_dt.date().isoformat()}
                        event['end'] = {'date': (start_dt.date() + datetime.timedelta(days=1)).isoformat()}
                    else:
                        event['start'] = {'dateTime': start_dt.isoformat(), 'timeZone': 'Asia/Kolkata'}
                        if duration_minutes:
                            end_dt = start_dt + datetime.timedelta(minutes=duration_minutes)
                            event['end'] = {'dateTime': end_dt.isoformat(), 'timeZone': 'Asia/Kolkata'}
                except ValueError:
                    pass
            
            if reminders is not None:
                if reminders:
                    event['reminders'] = {
                        'useDefault': False,
                        'overrides': [{'method': 'popup', 'minutes': m} for m in reminders]
                    }
                else:
                    event['reminders'] = {'useDefault': True}
            
            # Add Meet link if requested and not present
            conference_version = 0
            if add_meet_link and not event.get('hangoutLink'):
                event['conferenceData'] = {
                    'createRequest': {
                        'requestId': f"vyana-{datetime.datetime.now().timestamp()}",
                        'conferenceSolutionKey': {'type': 'hangoutsMeet'}
                    }
                }
                conference_version = 1
            
            updated_event = google_service.events().update(
                calendarId=target_calendar_id, 
                eventId=event_id, 
                body=event,
                conferenceDataVersion=conference_version
            ).execute()
            
            return {
                "success": True,
                "message": f"Event updated: {summary or event_id}",
                "eventId": updated_event.get('id'),
                "meetLink": updated_event.get('hangoutLink', ''),
            }
            
        except Exception as e:
            logger.error(f"Update Event Error: {e}")
            return {"error": f"Error updating event: {e}"}

    def delete_event(self, event_id: str, calendar_id: str = None) -> Dict[str, Any]:
        """Delete a calendar event"""
        try:
            google_service = self._get_google_service()
            if not google_service:
                return {"error": "Google Calendar not connected"}

            target_calendar_id = self._resolve_calendar_id(calendar_id)

            google_service.events().delete(
                calendarId=target_calendar_id, 
                eventId=event_id
            ).execute()
            
            return {
                "success": True,
                "message": "Event deleted from Google Calendar"
            }
            
        except Exception as e:
            logger.error(f"Delete Event Error: {e}")
            return {"error": f"Error deleting event: {e}"}

    # =========================================================================
    # Sync Operations (for two-way sync)
    # =========================================================================

    def get_changes_since(self, sync_token: str = None, calendar_id: str = None) -> Dict[str, Any]:
        """Get changes since last sync (incremental sync)"""
        try:
            google_service = self._get_google_service()
            if not google_service:
                return {"error": "Google Calendar not connected"}

            target_calendar_id = self._resolve_calendar_id(calendar_id)

            params = {
                'calendarId': target_calendar_id,
                'singleEvents': True,
            }
            
            if sync_token:
                params['syncToken'] = sync_token
            else:
                # Initial sync - get events from last 30 days to next 365 days
                now = datetime.datetime.now()
                params['timeMin'] = (now - datetime.timedelta(days=30)).isoformat() + 'Z'
                params['timeMax'] = (now + datetime.timedelta(days=365)).isoformat() + 'Z'

            events_result = google_service.events().list(**params).execute()
            
            changes = []
            for e in events_result.get('items', []):
                status = e.get('status', 'confirmed')
                if status == 'cancelled':
                    changes.append({
                        "type": "deleted",
                        "id": e.get('id'),
                    })
                else:
                    start = e.get('start', {})
                    end = e.get('end', {})
                    changes.append({
                        "type": "upsert",
                        "id": e.get('id'),
                        "summary": e.get('summary', ''),
                        "start": start.get('dateTime') or start.get('date'),
                        "end": end.get('dateTime') or end.get('date'),
                        "description": e.get('description', ''),
                        "location": e.get('location', ''),
                        "isAllDay": 'date' in start,
                    })
            
            return {
                "changes": changes,
                "nextSyncToken": events_result.get('nextSyncToken'),
            }
            
        except Exception as e:
            # If sync token is invalid, need full sync
            if "Sync token" in str(e) or "410" in str(e):
                return self.get_changes_since(None, calendar_id)
            logger.error(f"Sync Error: {e}")
            return {"error": f"Error syncing: {e}"}

    # =========================================================================
    # Quick Event (Natural Language)
    # =========================================================================

    def quick_add(self, text: str, calendar_id: str = None) -> Dict[str, Any]:
        """Create event from natural language text (e.g., 'Meeting tomorrow at 3pm')"""
        try:
            google_service = self._get_google_service()
            if not google_service:
                return {"error": "Google Calendar not connected"}

            target_calendar_id = self._resolve_calendar_id(calendar_id)

            created_event = google_service.events().quickAdd(
                calendarId=target_calendar_id,
                text=text
            ).execute()
            
            return {
                "success": True,
                "message": f"Event created: {created_event.get('summary', text)}",
                "eventId": created_event.get('id'),
                "htmlLink": created_event.get('htmlLink'),
            }
            
        except Exception as e:
            logger.error(f"Quick Add Error: {e}")
            return {"error": f"Error creating event: {e}"}


calendar_service = CalendarService()
