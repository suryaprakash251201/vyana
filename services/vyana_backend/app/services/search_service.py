import logging
import requests
from typing import List, Dict, Optional
from datetime import datetime
from app.config import settings

logger = logging.getLogger(__name__)

class SearchService:
    def __init__(self):
        # Using SerpAPI for reliable search (free tier: 100 searches/month)
        # Get free API key from: https://serpapi.com/
        self.serp_api_key = getattr(settings, 'SERP_API_KEY', None)
        self.serp_url = "https://serpapi.com/search"
        
        # Fallback to DuckDuckGo
        self.ddg_url = "https://api.duckduckgo.com/"
    
    def web_search(self, query: str) -> str:
        """Search the web using SerpAPI (with DDG fallback)"""
        
        # Try SerpAPI first if API key is available
        if self.serp_api_key:
            try:
                result = self._search_with_serpapi(query)
                if result and not result.startswith("No"):
                    return result
            except Exception as e:
                logger.warning(f"SerpAPI failed: {e}, falling back to DuckDuckGo")
        
        # Fallback to DuckDuckGo
        return self._search_with_duckduckgo(query)
    
    def _search_with_serpapi(self, query: str) -> Optional[str]:
        """Search using SerpAPI (Google Search)"""
        try:
            params = {
                'q': query,
                'api_key': self.serp_api_key,
                'engine': 'google',
                'num': 3  # Get top 3 results
            }
            
            response = requests.get(self.serp_url, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                
                #Check for answer box
                answer_box = data.get('answer_box', {})
                if answer_box:
                    answer = answer_box.get('answer') or answer_box.get('snippet')
                    if answer:
                        source = answer_box.get('link', '')
                        result = f"{answer}"
                        if source:
                            result += f"\n\nSource: {source}"
                        return result
                
                # Check for knowledge graph
                knowledge_graph = data.get('knowledge_graph', {})
                if knowledge_graph:
                    title = knowledge_graph.get('title', '')
                    description = knowledge_graph.get('description', '')
                    if title and description:
                        source = knowledge_graph.get('website', '')
                        result = f"{title}: {description}"
                        if source:
                            result += f"\n\nWebsite: {source}"
                        return result
                
                # Get organic results
                organic_results = data.get('organic_results', [])
                if organic_results:
                    results_text = []
                    for i, result in enumerate(organic_results[:3], 1):
                        title = result.get('title', '')
                        snippet = result.get('snippet', '')
                        link = result.get('link', '')
                        
                        if title and snippet:
                            results_text.append(f"{i}. {title}\n{snippet}\nSource: {link}")
                    
                    if results_text:
                        return "\n\n".join(results_text)
                
                return None
            else:
                logger.error(f"SerpAPI error: {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"SerpAPI search error: {e}")
            return None
    
    def _search_with_duckduckgo(self, query: str) -> str:
        """Fallback search using DuckDuckGo Instant Answer API"""
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
                        result += f"\nSource: {abstract_url}"
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
                                result += f"\nSource: {url}"
                            return result
                
                return f"No direct information found for '{query}'. Try rephrasing your search query."
            else:
                return f"Search service temporarily unavailable (status: {response.status_code})"
                
        except Exception as e:
            logger.error(f"DuckDuckGo search error: {e}")
            return f"Search failed: {str(e)}"
    
    def get_news(self, topic: str = "technology") -> str:
        """Get latest news headlines"""
        
        # If SerpAPI available, use Google News
        if self.serp_api_key:
            try:
                params = {
                    'q': topic,
                    'api_key': self.serp_api_key,
                    'engine': 'google_news',
                    'gl': 'in',  # India
                    'hl': 'en'   # English
                }
                
                response = requests.get(self.serp_url, params=params, timeout=10)
                
                if response.status_code == 200:
                    data = response.json()
                    news_results = data.get('news_results', [])
                    
                    if news_results:
                        headlines = []
                        for i, article in enumerate(news_results[:5], 1):
                            title = article.get('title', '')
                            source = article.get('source', {}).get('name', 'Unknown')
                            link = article.get('link', '')
                            
                            if title:
                                headlines.append(f"{i}. {title} ({source})\n{link}")
                        
                        if headlines:
                            return f"Latest news on {topic}:\n\n" + "\n\n".join(headlines)
            
            except Exception as e:
                logger.warning(f"News search failed: {e}")
        
        # Fallback
        try:
            search_query = f"{topic} latest news"
            result = self.web_search(search_query)
            return f"Latest on {topic}:\n{result}"
        except Exception as e:
            logger.error(f"News error: {e}")
            return f"News service unavailable: {str(e)}"

search_service = SearchService()
