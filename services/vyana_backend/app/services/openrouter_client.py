"""
OpenRouter Client for Vyana
Provides access to DeepSeek and other models via OpenRouter API
"""
import os
import json
import logging
from typing import Optional, List, Dict, Any, AsyncIterator
from datetime import datetime

from langchain_openai import ChatOpenAI
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, SystemMessage, ToolMessage

from app.config import settings

logger = logging.getLogger(__name__)

# OpenRouter model mappings
OPENROUTER_MODELS = {
    # DeepSeek models
    "openrouter/deepseek/deepseek-chat": "deepseek/deepseek-chat",
    "openrouter/deepseek/deepseek-r1": "deepseek/deepseek-r1",
    "openrouter/deepseek/deepseek-r1-0528": "deepseek/deepseek-r1-0528",
    "openrouter/deepseek/deepseek-coder": "deepseek/deepseek-coder",
    # Claude models (if needed)
    "openrouter/anthropic/claude-3.5-sonnet": "anthropic/claude-3.5-sonnet",
    "openrouter/anthropic/claude-3-haiku": "anthropic/claude-3-haiku",
    # GPT models
    "openrouter/openai/gpt-4o": "openai/gpt-4o",
    "openrouter/openai/gpt-4o-mini": "openai/gpt-4o-mini",
}


def is_openrouter_model(model_name: str) -> bool:
    """Check if the model should use OpenRouter"""
    return model_name.startswith("openrouter/")


def get_openrouter_model_id(model_name: str) -> str:
    """Convert internal model name to OpenRouter model ID"""
    if model_name in OPENROUTER_MODELS:
        return OPENROUTER_MODELS[model_name]
    # If not in mapping, try stripping the prefix
    if model_name.startswith("openrouter/"):
        return model_name[len("openrouter/"):]
    return model_name


class OpenRouterClient:
    """
    OpenRouter API Client
    Uses LangChain's ChatOpenAI with OpenRouter base URL
    """
    
    def __init__(self):
        self.api_key = getattr(settings, "OPENROUTER_API_KEY", None) or os.environ.get("OPENROUTER_API_KEY")
        self.base_url = "https://openrouter.ai/api/v1"
        self.default_model = "deepseek/deepseek-chat"
        self.temperature = float(os.getenv("OPENROUTER_TEMPERATURE", "0.3"))
        self.max_tokens = int(os.getenv("OPENROUTER_MAX_TOKENS", "4096"))
        
        if not self.api_key:
            logger.warning("OPENROUTER_API_KEY not found. DeepSeek models will not work.")
        else:
            logger.info("OpenRouterClient initialized")
    
    def is_available(self) -> bool:
        """Check if OpenRouter is configured"""
        return bool(self.api_key)
    
    def get_llm(self, model_name: str, temperature: float = None, max_tokens: int = None, tools: List = None):
        """
        Get a LangChain ChatOpenAI instance configured for OpenRouter
        
        Args:
            model_name: Model name (e.g., 'openrouter/deepseek/deepseek-chat')
            temperature: Override temperature
            max_tokens: Override max tokens
            tools: Tools to bind to the model
        """
        if not self.api_key:
            raise ValueError("OPENROUTER_API_KEY not configured")
        
        # Get the actual OpenRouter model ID
        model_id = get_openrouter_model_id(model_name)
        
        llm = ChatOpenAI(
            api_key=self.api_key,
            base_url=self.base_url,
            model=model_id,
            temperature=temperature or self.temperature,
            max_tokens=max_tokens or self.max_tokens,
            default_headers={
                "HTTP-Referer": "https://vyana.app",  # Your app URL
                "X-Title": "Vyana AI Assistant",
            }
        )
        
        # Bind tools if provided
        if tools:
            llm = llm.bind_tools(tools)
        
        logger.info(f"OpenRouter LLM created for model: {model_id}")
        return llm


# Global singleton instance
openrouter_client = OpenRouterClient()
