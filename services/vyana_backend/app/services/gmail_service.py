from googleapiclient.discovery import build
from app.services.google_oauth import oauth_service
import base64
from email.mime.text import MIMEText

class GmailService:
    def get_service(self):
        creds = oauth_service.get_credentials()
        if not creds:
            return None
        return build('gmail', 'v1', credentials=creds)

    def get_unread_count(self):
        service = self.get_service()
        if not service:
            return "Gmail not connected"
        try:
            results = service.users().labels().get(userId='me', id='INBOX').execute()
            return results.get('messagesUnread', 0)
        except Exception as e:
            return f"Error: {e}"

    def summarize_emails(self, max_results=5):
        service = self.get_service()
        if not service:
            return "Gmail not connected"
        
        try:
            results = service.users().messages().list(userId='me', labelIds=['INBOX'], q='is:unread', maxResults=max_results).execute()
            messages = results.get('messages', [])
            
            summary = []
            for msg in messages:
                m_data = service.users().messages().get(userId='me', id=msg['id'], format='metadata').execute()
                headers = m_data.get('payload', {}).get('headers', [])
                subject = next((h['value'] for h in headers if h['name'] == 'Subject'), '(No Subject)')
                sender = next((h['value'] for h in headers if h['name'] == 'From'), '(Unknown)')
                summary.append(f"- From: {sender} | Subject: {subject}")
                
            return "\n".join(summary) if summary else "No unread emails."
        except Exception as e:
            return f"Error fetching emails: {e}"

    def get_recent_messages(self, limit=10, category=None):
        service = self.get_service()
        if not service:
             return {"error": "Gmail not connected"}
        
        try:
             query = 'label:INBOX'
             if category:
                 # category should be 'primary', 'social', 'updates', 'promotions', 'forums'
                 query += f' category:{category}'
             
             results = service.users().messages().list(userId='me', q=query, maxResults=limit).execute()
             messages = results.get('messages', [])
             
             msg_list = []
             for msg in messages:
                  m_data = service.users().messages().get(userId='me', id=msg['id'], format='metadata').execute()
                  headers = m_data.get('payload', {}).get('headers', [])
                  subject = next((h['value'] for h in headers if h['name'] == 'Subject'), '(No Subject)')
                  sender = next((h['value'] for h in headers if h['name'] == 'From'), '(Unknown)')
                  # Get internal date (ms)
                  internal_date = int(m_data.get('internalDate', 0))
                  
                  msg_list.append({
                      "id": msg['id'],
                      "subject": subject,
                      "sender": sender,
                      "timestamp": internal_date,
                      "snippet": m_data.get('snippet', '')
                  })
             return {"messages": msg_list}
        except Exception as e:
             return {"error": str(e)}

    def get_message_details(self, message_id):
        service = self.get_service()
        if not service:
            return {"error": "Gmail not connected"}
        try:
            msg = service.users().messages().get(userId='me', id=message_id, format='full').execute()
            payload = msg.get('payload', {})
            headers = payload.get('headers', [])
            
            subject = next((h['value'] for h in headers if h['name'] == 'Subject'), '(No Subject)')
            sender = next((h['value'] for h in headers if h['name'] == 'From'), '(Unknown)')
            date = next((h['value'] for h in headers if h['name'] == 'Date'), '')
            
            body = "No content"
            if 'parts' in payload:
                for part in payload['parts']:
                    if part['mimeType'] == 'text/plain':
                        data = part['body'].get('data')
                        if data:
                            body = base64.urlsafe_b64decode(data).decode()
                            break
            elif 'body' in payload:
                data = payload['body'].get('data')
                if data:
                    body = base64.urlsafe_b64decode(data).decode()
            
            return {
                "id": message_id,
                "subject": subject,
                "sender": sender,
                "date": date,
                "body": body
            }
        except Exception as e:
            return {"error": str(e)}

    def send_email(self, to_email, subject, body):
        service = self.get_service()
        if not service:
            return "Gmail not connected"
        try:
            message = MIMEText(body)
            message['to'] = to_email
            message['subject'] = subject
            raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
            body_req = {'raw': raw}
            
            sent = service.users().messages().send(userId='me', body=body_req).execute()
            return f"Email sent to {to_email}. Id: {sent['id']}"
        except Exception as e:
            return f"Error sending email: {e}"

gmail_service = GmailService()
