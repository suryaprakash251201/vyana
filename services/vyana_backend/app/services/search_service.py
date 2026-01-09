import logging
import requests
from typing import List, Dict
from datetime import datetime

logger = logging.getLogger(__name__)

class SearchService:
    def __init__(self):
        # Using DuckDuckGo Instant Answer API (no key needed)
        self.ddg_url = "https://api.duckduckgo.com/"
    
    def web_search(self, query: str) -> str:
        """Search the web using DuckDuckGo"""
        try:
            params = {
                'q': query,
                'format': 'json',
                'no_html': 1,
                'skip_disambig': 1
            }
            
            response = requests.get(self.ddg_url, params=params, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                
                # Get abstract or first related topic
                abstract = data.get('Abstract', '')
                heading = data.get('Heading', '')
                abstract_url = data.get('AbstractURL', '')
                
                if abstract and heading:
                    result = f"{heading}: {abstract}"
                    if abstract_url:
                        result += f"
Source: {abstract_url}"
                    return result
                
                # Try related topics
                related = data.get('RelatedTopics', [])
                if related:
                    first = related[0]
                    if isinstance(first, dict):
                        text = first.get('Text', '')
                        url = first.get('FirstURL', '')
                        if text:
                            result = text
                            if url:
                                result += f"
Source: {url}"
                            return result
                
                return f"No direct answer found for '{query}'. Try a more specific search."
            else:
                return f"Search failed with status {response.status_code}"
                
        except Exception as e:
            logger.error(f"Search error: {e}")
            return f"Search service unavailable: {str(e)}"
    
    def get_news(self, topic: str = "technology") -> str:
        """Get latest news headlines (simplified)"""
        # Note: For real news, you'd use NewsAPI or similar
        # This is a placeholder that uses DuckDuckGo news search
        try:
            search_query = f"{topic} news"
            result = self.web_search(search_query)
            return f"Latest on {topic}:
{result}"
        except Exception as e:
            logger.error(f"News error: {e}")
            return f"News service unavailable: {str(e)}"

search_service = SearchService()
