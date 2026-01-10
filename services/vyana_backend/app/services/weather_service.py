import logging
import requests
from typing import Optional, Dict
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

class WeatherService:
    def __init__(self):
        # Using OpenWeatherMap API (free tier)
        # User should add OPENWEATHER_API_KEY to .env
        self.api_key = None  # Will be loaded from env if available
        self.base_url = "https://api.openweathermap.org/data/2.5"
        self._cache = {}
        self._cache_duration = 600  # 10 minutes cache
    
    def get_weather(self, city: str = "Mumbai") -> str:
        """Get current weather for a city"""
        try:
            # Check cache
            cache_key = f"weather_{city}"
            if cache_key in self._cache:
                cached_data, cached_time = self._cache[cache_key]
                if datetime.now() - cached_time < timedelta(seconds=self._cache_duration):
                    return cached_data
            
            # Use wttr.in as fallback (no API key needed)
            url = f"https://wttr.in/{city}?format=%C+%t+%h+%w"
            response = requests.get(url, timeout=5)
            
            if response.status_code == 200:
                weather_text = response.text.strip()
                result = f"Weather in {city}: {weather_text}"
                self._cache[cache_key] = (result, datetime.now())
                return result
            else:
                return f"Could not fetch weather for {city}"
                
        except Exception as e:
            logger.error(f"Weather error: {e}")
            return f"Weather service unavailable: {str(e)}"
    
    def get_forecast(self, city: str = "Mumbai") -> str:
        """Get 3-day forecast"""
        try:
            # Use wttr.in for simple forecast
            url = f"https://wttr.in/{city}?format=j1"
            response = requests.get(url, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                weather_data = data.get('weather', [])[:3]  # Next 3 days
                
                forecast = f"3-Day Forecast for {city}:\n"
                for day in weather_data:
                    date = day.get('date')
                    max_temp = day.get('maxtempC')
                    min_temp = day.get('mintempC')
                    desc = day.get('hourly', [{}])[0].get('weatherDesc', [{}])[0].get('value', 'N/A')
                    forecast += f"- {date}: {desc}, {min_temp}°C - {max_temp}°C\n"
                
                return forecast.strip()
            else:
                return f"Could not fetch forecast for {city}"
                
        except Exception as e:
            logger.error(f"Forecast error: {e}")
            return f"Forecast service unavailable: {str(e)}"

weather_service = WeatherService()
