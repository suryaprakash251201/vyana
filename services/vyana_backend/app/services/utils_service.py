import logging
import re
from typing import Dict
import requests

logger = logging.getLogger(__name__)

class UtilsService:
    def __init__(self):
        # Free currency API - exchangerate.host (no API key required, live rates)
        self.currency_api_url = "https://api.exchangerate.host/latest"
    
    def calculate(self, expression: str) -> str:
        """Safely evaluate mathematical expressions"""
        try:
            # Sanitize input - only allow numbers, operators, and spaces
            if not re.match(r'^[\d\s\+\-\*\/\(\)\.\%]+$', expression):
                return "Invalid expression. Only numbers and basic operators (+, -, *, /, %, parentheses) are allowed."
            
            # Evaluate
            result = eval(expression)
            return f"{expression} = {result}"
        except ZeroDivisionError:
            return "Error: Division by zero"
        except Exception as e:
            logger.error(f"Calculation error: {e}")
            return f"Error calculating expression: {str(e)}"
    
    def convert_currency(self, amount: float, from_currency: str, to_currency: str) -> str:
        """Convert currency using live exchange rates"""
        try:
            from_currency = from_currency.upper()
            to_currency = to_currency.upper()
            
            # Fetch live rates from exchangerate.host (free, no API key)
            params = {
                'base': from_currency,
                'symbols': to_currency
            }
            
            response = requests.get(self.currency_api_url, params=params, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get('success') and to_currency in data.get('rates', {}):
                    rate = data['rates'][to_currency]
                    converted = amount * rate
                    
                    return f"{amount} {from_currency} = {converted:.2f} {to_currency} (Rate: {rate:.4f})"
                else:
                    # Fallback error
                    return f"Unable to convert {from_currency} to {to_currency}. Please check currency codes."
            else:
                return "Currency conversion service temporarily unavailable"
                
        except requests.exceptions.Timeout:
            return "Currency conversion request timed out"
        except Exception as e:
            logger.error(f"Currency conversion error: {e}")
            return f"Error converting currency: {str(e)}"
    
    def convert_units(self, value: float, from_unit: str, to_unit: str) -> str:
        """Convert between different units"""
        try:
            from_unit = from_unit.lower()
            to_unit = to_unit.lower()
            
            # Length conversions
            length_units = {
                'meter': 1.0, 'm': 1.0,
                'kilometer': 1000.0, 'km': 1000.0,
                'centimeter': 0.01, 'cm': 0.01,
                'millimeter': 0.001, 'mm': 0.001,
                'mile': 1609.34, 'mi': 1609.34,
                'yard': 0.9144, 'yd': 0.9144,
                'foot': 0.3048, 'ft': 0.3048,
                'inch': 0.0254, 'in': 0.0254,
            }
            
            # Weight conversions (to kg)
            weight_units = {
                'kilogram': 1.0, 'kg': 1.0,
                'gram': 0.001, 'g': 0.001,
                'milligram': 0.000001, 'mg': 0.000001,
                'pound': 0.453592, 'lb': 0.453592,
                'ounce': 0.0283495, 'oz': 0.0283495,
                'ton': 1000.0, 'tonne': 1000.0,
            }
            
            # Temperature conversions
            if from_unit in ['celsius', 'c'] and to_unit in ['fahrenheit', 'f']:
                result = (value * 9/5) + 32
                return f"{value}°C = {result:.2f}°F"
            elif from_unit in ['fahrenheit', 'f'] and to_unit in ['celsius', 'c']:
                result = (value - 32) * 5/9
                return f"{value}°F = {result:.2f}°C"
            elif from_unit in ['celsius', 'c'] and to_unit in ['kelvin', 'k']:
                result = value + 273.15
                return f"{value}°C = {result:.2f}K"
            elif from_unit in ['kelvin', 'k'] and to_unit in ['celsius', 'c']:
                result = value - 273.15
                return f"{value}K = {result:.2f}°C"
            
            # Length conversion
            if from_unit in length_units and to_unit in length_units:
                meters = value * length_units[from_unit]
                result = meters / length_units[to_unit]
                return f"{value} {from_unit} = {result:.4f} {to_unit}"
            
            # Weight conversion
            if from_unit in weight_units and to_unit in weight_units:
                kg = value * weight_units[from_unit]
                result = kg / weight_units[to_unit]
                return f"{value} {from_unit} = {result:.4f} {to_unit}"
            
            return f"Unsupported unit conversion: {from_unit} to {to_unit}"
            
        except Exception as e:
            logger.error(f"Unit conversion error: {e}")
            return f"Error converting units: {str(e)}"

utils_service = UtilsService()
