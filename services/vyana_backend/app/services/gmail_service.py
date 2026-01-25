from googleapiclient.discovery import build
from app.services.google_oauth import oauth_service
import base64
from email.mime.text import MIMEText
from typing import Tuple, Dict

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

    def search_messages(self, query: str, limit: int = 10):
        """
        Search emails using Gmail query format (e.g., 'from:sender subject:topic')
        """
        service = self.get_service()
        if not service:
             return {"error": "Gmail not connected"}
        
        try:
             results = service.users().messages().list(userId='me', q=query, maxResults=limit).execute()
             messages = results.get('messages', [])
             
             msg_list = []
             for msg in messages:
                  m_data = service.users().messages().get(userId='me', id=msg['id'], format='metadata').execute()
                  headers = m_data.get('payload', {}).get('headers', [])
                  subject = next((h['value'] for h in headers if h['name'] == 'Subject'), '(No Subject)')
                  sender = next((h['value'] for h in headers if h['name'] == 'From'), '(Unknown)')
                  date = next((h['value'] for h in headers if h['name'] == 'Date'), '')
                  
                  msg_list.append({
                      "id": msg['id'],
                      "subject": subject,
                      "sender": sender,
                      "date": date,
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
            
            text_body, html_body, inline_images = self._extract_bodies_and_inline_images(service, message_id, payload)

            if inline_images and html_body:
                for cid, data_uri in inline_images.items():
                    html_body = html_body.replace(f"cid:{cid}", data_uri)
            
            return {
                "id": message_id,
                "subject": subject,
                "sender": sender,
                "date": date,
                "body": text_body or "No content",
                "html_body": html_body or ""
            }
        except Exception as e:
            return {"error": str(e)}

    def _extract_bodies_and_inline_images(self, service, message_id, payload) -> Tuple[str, str, Dict[str, str]]:
        text_body = ""
        html_body = ""
        inline_images: Dict[str, str] = {}

        def decode_body(data: str) -> str:
            try:
                return base64.urlsafe_b64decode(data).decode(errors="ignore")
            except Exception:
                return ""

        def get_header(headers_list, name):
            for h in headers_list:
                if h.get('name', '').lower() == name.lower():
                    return h.get('value')
            return None

        def walk_part(part):
            nonlocal text_body, html_body, inline_images
            mime = part.get('mimeType', '')
            headers = part.get('headers', [])
            body = part.get('body', {})
            data = body.get('data')
            attachment_id = body.get('attachmentId')

            if mime == 'text/plain' and data and not text_body:
                text_body = decode_body(data)
            elif mime == 'text/html' and data and not html_body:
                html_body = decode_body(data)
            elif mime.startswith('image/'):
                content_id = get_header(headers, 'Content-ID')
                if content_id:
                    content_id = content_id.strip('<>')
                if attachment_id and content_id:
                    attachment = service.users().messages().attachments().get(
                        userId='me', messageId=message_id, id=attachment_id
                    ).execute()
                    attach_data = attachment.get('data')
                    if attach_data:
                        raw = base64.urlsafe_b64decode(attach_data)
                        data_uri = f"data:{mime};base64,{base64.b64encode(raw).decode()}"
                        inline_images[content_id] = data_uri

            for sub in part.get('parts', []) or []:
                walk_part(sub)

        if 'parts' in payload:
            for p in payload['parts']:
                walk_part(p)
        else:
            body = payload.get('body', {})
            data = body.get('data')
            if data:
                if payload.get('mimeType') == 'text/html':
                    html_body = decode_body(data)
                else:
                    text_body = decode_body(data)

        return text_body, html_body, inline_images

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
