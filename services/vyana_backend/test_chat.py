#!/usr/bin/env python3
"""Test chat streaming endpoint"""
import requests

def test_chat():
    url = "http://localhost:8000/chat/stream"
    payload = {
        "messages": [{"role": "user", "content": "Hello"}],
        "settings": {}
    }
    
    print(f"Sending request to {url}")
    print(f"Payload: {payload}")
    
    try:
        response = requests.post(url, json=payload, stream=True)
        print(f"Status: {response.status_code}")
        print(f"Headers: {dict(response.headers)}")
        print("\nResponse stream:")
        
        for chunk in response.iter_content(chunk_size=None, decode_unicode=True):
            if chunk:
                print(chunk, end='', flush=True)
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_chat()
