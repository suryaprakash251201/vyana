"""
Redis Cache Service for Vyana
Provides caching for API responses to reduce costs
"""
import json
import hashlib
import logging
from typing import Optional, Any
from datetime import datetime
import redis.asyncio as redis

from app.config import settings

logger = logging.getLogger(__name__)


class CacheService:
    """
    Redis-based caching service for reducing API costs.
    
    Caches:
    - Simple chat responses (non-tool queries)
    - Weather data
    - Stock quotes
    - Search results
    """
    
    def __init__(self):
        self.redis: Optional[redis.Redis] = None
        self.enabled = settings.CACHE_ENABLED
        self.default_ttl = settings.CACHE_TTL
        self._connected = False
        
    async def connect(self):
        """Initialize Redis connection"""
        if not self.enabled:
            logger.info("Cache is disabled via settings")
            return
            
        try:
            self.redis = redis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True
            )
            # Test connection
            await self.redis.ping()
            self._connected = True
            logger.info(f"Redis cache connected: {settings.REDIS_URL}")
        except Exception as e:
            logger.warning(f"Redis connection failed (cache disabled): {e}")
            self.redis = None
            self._connected = False
    
    async def disconnect(self):
        """Close Redis connection"""
        if self.redis:
            await self.redis.close()
            self._connected = False
            logger.info("Redis cache disconnected")
    
    @property
    def is_connected(self) -> bool:
        """Check if Redis is connected"""
        return self._connected and self.redis is not None
    
    def _make_key(self, prefix: str, *args) -> str:
        """Generate a cache key from prefix and arguments"""
        # Create a hash of the arguments for consistent key length
        content = json.dumps(args, sort_keys=True, default=str)
        content_hash = hashlib.md5(content.encode()).hexdigest()[:16]
        return f"vyana:{prefix}:{content_hash}"
    
    def _make_chat_key(self, message: str, model: str, tools_enabled: bool) -> str:
        """Generate cache key for chat responses"""
        # Normalize message
        normalized = message.lower().strip()
        return self._make_key("chat", normalized, model, tools_enabled)
    
    # ==================== Chat Caching ====================
    
    async def get_chat_response(
        self, 
        message: str, 
        model: str = "deepseek-chat",
        tools_enabled: bool = False
    ) -> Optional[str]:
        """
        Get cached chat response for simple queries.
        Only caches responses for queries WITHOUT tool calls.
        """
        if not self.is_connected or tools_enabled:
            return None
            
        try:
            key = self._make_chat_key(message, model, tools_enabled)
            cached = await self.redis.get(key)
            if cached:
                logger.info(f"Cache HIT for chat: {message[:50]}...")
                return cached
            logger.debug(f"Cache MISS for chat: {message[:50]}...")
            return None
        except Exception as e:
            logger.error(f"Cache get error: {e}")
            return None
    
    async def set_chat_response(
        self,
        message: str,
        response: str,
        model: str = "deepseek-chat",
        tools_enabled: bool = False,
        ttl: int = None
    ) -> bool:
        """
        Cache a chat response.
        Only cache if:
        - Tools were NOT enabled (simple Q&A)
        - Response is not an error
        """
        if not self.is_connected or tools_enabled:
            return False
            
        # Don't cache error responses or very short responses
        if not response or len(response) < 10 or response.startswith("Error"):
            return False
            
        try:
            key = self._make_chat_key(message, model, tools_enabled)
            ttl = ttl or self.default_ttl
            await self.redis.setex(key, ttl, response)
            logger.info(f"Cache SET for chat: {message[:50]}... (TTL: {ttl}s)")
            return True
        except Exception as e:
            logger.error(f"Cache set error: {e}")
            return False
    
    # ==================== Weather Caching ====================
    
    async def get_weather(self, location: str) -> Optional[dict]:
        """Get cached weather data"""
        if not self.is_connected:
            return None
            
        try:
            key = self._make_key("weather", location.lower())
            cached = await self.redis.get(key)
            if cached:
                logger.info(f"Cache HIT for weather: {location}")
                return json.loads(cached)
            return None
        except Exception as e:
            logger.error(f"Weather cache get error: {e}")
            return None
    
    async def set_weather(self, location: str, data: dict, ttl: int = 1800) -> bool:
        """Cache weather data (30 min default TTL)"""
        if not self.is_connected:
            return False
            
        try:
            key = self._make_key("weather", location.lower())
            await self.redis.setex(key, ttl, json.dumps(data))
            logger.info(f"Cache SET for weather: {location} (TTL: {ttl}s)")
            return True
        except Exception as e:
            logger.error(f"Weather cache set error: {e}")
            return False
    
    # ==================== Stock Quote Caching ====================
    
    async def get_stock_quote(self, symbol: str) -> Optional[dict]:
        """Get cached stock quote"""
        if not self.is_connected:
            return None
            
        try:
            key = self._make_key("stock", symbol.upper())
            cached = await self.redis.get(key)
            if cached:
                logger.info(f"Cache HIT for stock: {symbol}")
                return json.loads(cached)
            return None
        except Exception as e:
            logger.error(f"Stock cache get error: {e}")
            return None
    
    async def set_stock_quote(self, symbol: str, data: dict, ttl: int = 60) -> bool:
        """Cache stock quote (1 min default TTL - stock data changes frequently)"""
        if not self.is_connected:
            return False
            
        try:
            key = self._make_key("stock", symbol.upper())
            await self.redis.setex(key, ttl, json.dumps(data))
            logger.info(f"Cache SET for stock: {symbol} (TTL: {ttl}s)")
            return True
        except Exception as e:
            logger.error(f"Stock cache set error: {e}")
            return False
    
    # ==================== Search Caching ====================
    
    async def get_search_results(self, query: str) -> Optional[dict]:
        """Get cached search results"""
        if not self.is_connected:
            return None
            
        try:
            key = self._make_key("search", query.lower())
            cached = await self.redis.get(key)
            if cached:
                logger.info(f"Cache HIT for search: {query[:50]}")
                return json.loads(cached)
            return None
        except Exception as e:
            logger.error(f"Search cache get error: {e}")
            return None
    
    async def set_search_results(self, query: str, data: dict, ttl: int = 3600) -> bool:
        """Cache search results (1 hour default TTL)"""
        if not self.is_connected:
            return False
            
        try:
            key = self._make_key("search", query.lower())
            await self.redis.setex(key, ttl, json.dumps(data))
            logger.info(f"Cache SET for search: {query[:50]} (TTL: {ttl}s)")
            return True
        except Exception as e:
            logger.error(f"Search cache set error: {e}")
            return False
    
    # ==================== Generic Caching ====================
    
    async def get(self, key: str) -> Optional[str]:
        """Get a value from cache"""
        if not self.is_connected:
            return None
        try:
            return await self.redis.get(f"vyana:{key}")
        except Exception as e:
            logger.error(f"Cache get error: {e}")
            return None
    
    async def set(self, key: str, value: str, ttl: int = None) -> bool:
        """Set a value in cache"""
        if not self.is_connected:
            return False
        try:
            ttl = ttl or self.default_ttl
            await self.redis.setex(f"vyana:{key}", ttl, value)
            return True
        except Exception as e:
            logger.error(f"Cache set error: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """Delete a key from cache"""
        if not self.is_connected:
            return False
        try:
            await self.redis.delete(f"vyana:{key}")
            return True
        except Exception as e:
            logger.error(f"Cache delete error: {e}")
            return False
    
    async def clear_pattern(self, pattern: str) -> int:
        """Clear all keys matching a pattern"""
        if not self.is_connected:
            return 0
        try:
            keys = []
            async for key in self.redis.scan_iter(f"vyana:{pattern}*"):
                keys.append(key)
            if keys:
                deleted = await self.redis.delete(*keys)
                logger.info(f"Cleared {deleted} cache keys matching: {pattern}")
                return deleted
            return 0
        except Exception as e:
            logger.error(f"Cache clear error: {e}")
            return 0
    
    async def get_stats(self) -> dict:
        """Get cache statistics"""
        if not self.is_connected:
            return {"status": "disconnected", "enabled": self.enabled}
            
        try:
            info = await self.redis.info("stats")
            memory = await self.redis.info("memory")
            keys = await self.redis.dbsize()
            
            return {
                "status": "connected",
                "enabled": self.enabled,
                "total_keys": keys,
                "hits": info.get("keyspace_hits", 0),
                "misses": info.get("keyspace_misses", 0),
                "memory_used": memory.get("used_memory_human", "N/A"),
                "hit_rate": round(
                    info.get("keyspace_hits", 0) / 
                    max(info.get("keyspace_hits", 0) + info.get("keyspace_misses", 0), 1) * 100,
                    2
                )
            }
        except Exception as e:
            logger.error(f"Cache stats error: {e}")
            return {"status": "error", "error": str(e)}


# Singleton instance
cache_service = CacheService()
