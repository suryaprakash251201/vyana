import datetime
import logging
from app.services.supabase import supabase_client
import uuid

logger = logging.getLogger(__name__)

class CalendarService:
    def get_events(self, start_date_str: str = None, end_date_str: str = None, user_id: str = None):
        try:
            # Query Supabase 'calendar_events'
            query = supabase_client.table('calendar_events').select("*")
            
            if user_id:
                query = query.eq('user_id', user_id)
            
            # Simple date filtering if provided (assuming user wants >= start)
            # You might need better date filtering depending on requirements
            # But specific date range filtering in Supabase requires exact field matching or operators
            
            # For now, let's just fetch all and filter in python or basic order
            # (Optimise later for performance)
            
            result = query.order('start_time').execute()
            events = result.data
            
            logger.info(f"Found {len(events)} events in Supabase")

            structured = []
            for e in events:
                # Map Supabase fields to frontend expectation
                structured.append({
                    "id": e['id'],
                    "summary": e['summary'],
                    "start": e['start_time'], # Expecting ISO string
                    "description": e.get('description', ''),
                    "end": e.get('end_time', ''),
                    # Add location if you add it to schema, otherwise empty
                    "location": "" 
                })
            return structured

        except Exception as e:
            logger.error(f"Error fetching Supabase calendar: {e}")
            return [{"error": f"Error fetching calendar: {e}"}]

    def create_event(self, summary: str, start_time: str, duration_minutes: int = 60, description: str = None, user_id: str = None):
        try:
            # Parse start time
            try:
                start_dt = datetime.datetime.fromisoformat(start_time.replace('Z', '+00:00'))
            except ValueError:
                start_dt = datetime.datetime.now()

            end_dt = start_dt + datetime.timedelta(minutes=duration_minutes)

            data = {
                'summary': summary,
                'description': description,
                'start_time': start_dt.isoformat(),
                'end_time': end_dt.isoformat(),
            }
            if user_id:
                data['user_id'] = user_id
            else:
                # Fallback: Try to get first user (requires Service Role Key)
                try:
                    users_list = supabase_client.auth.admin.list_users()
                    if users_list: # list_users returns an object with 'users' usually, or list
                        # supabase-py v2 returns UserList object?
                        # Let's check typical response. Usually `users` property.
                        users = getattr(users_list, 'users', [])
                        if not users and isinstance(users_list, list):
                             users = users_list
                        
                        if users:
                            data['user_id'] = users[0].id
                            logger.info(f"Using fallback user_id: {data['user_id']}")
                except Exception as ex:
                    logger.warning(f"Could not fetch fallback user: {ex}")
            
            res = supabase_client.table('calendar_events').insert(data).execute()
            
            return f"Event created: {summary} at {start_dt.strftime('%H:%M')}"
        except Exception as e:
            logger.error(f"Create Event Error: {e}")
            return f"Error creating event: {e}"

    def update_event(self, event_id: str, summary: str = None, start_time: str = None, duration_minutes: int = None, description: str = None):
        try:
            data = {}
            if summary:
                data['summary'] = summary
            if description:
                data['description'] = description
            
            if start_time:
                 try:
                    start_dt = datetime.datetime.fromisoformat(start_time.replace('Z', '+00:00'))
                    data['start_time'] = start_dt.isoformat()
                    
                    if duration_minutes:
                         end_dt = start_dt + datetime.timedelta(minutes=duration_minutes)
                         data['end_time'] = end_dt.isoformat()
                 except ValueError:
                    pass

            supabase_client.table('calendar_events').update(data).eq('id', event_id).execute()
            return f"Event updated: {summary or event_id}"
        except Exception as e:
            logger.error(f"Update Event Error: {e}")
            return f"Error updating event: {e}"

    def delete_event(self, event_id: str):
        try:
            supabase_client.table('calendar_events').delete().eq('id', event_id).execute()
            return "Event deleted"
        except Exception as e:
            logger.error(f"Delete Event Error: {e}")
            return f"Error deleting event: {e}"

calendar_service = CalendarService()
