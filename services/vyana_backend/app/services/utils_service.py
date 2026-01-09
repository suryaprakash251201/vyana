import logging
from typing import Optional
import re

logger = logging.getLogger(__name__)

class UtilsService:
    """Utility functions for calculations, conversions, etc."""
    
    def calculate(self, expression: str) -> str:
        """Safely evaluate math expressions"""
        try:
            # Remove any dangerous characters
            safe_expr = re.sub(r'[^0-9+\-*/().\s]', '', expression)
            
            # Evaluate safely
            result = eval(safe_expr, {"__builtins__": {}}, {})
            return f"{expression} = {result}"
        except Exception as e:
            logger.error(f"Calculation error: {e}")
            return f"Invalid expression: {expression}"
    
    def convert_currency(self, amount: float, from_curr: str, to_curr: str) -> str:
        """Convert currency (simplified, static rates)"""
        # Static rates (USD base). In production, use live API
        rates = {
            'USD': 1.0,
            'EUR': 0.85,
            'GBP': 0.73,
            'INR': 83.12,
            'JPY': 110.0,
            'AUD': 1.35,
            'CAD': 1.25
        }
        
        try:
            from_curr = from_curr.upper()
            to_curr = to_curr.upper()
            
            if from_curr not in rates or to_curr not in rates:
                return f"Currency not supported: {from_curr} or {to_curr}"
            
            # Convert to USD first, then to target
            usd_amount = amount / rates[from_curr]
            result = usd_amount * rates[to_curr]
            
            return f"{amount} {from_curr} = {result:.2f} {to_curr}"
        except Exception as e:
            logger.error(f"Currency conversion error: {e}")
            return f"Conversion failed: {str(e)}"
    
    def convert_units(self, value: float, from_unit: str, to_unit: str) -> str:
        """Convert common units"""
        # Simple unit conversions
        conversions = {
            # Length
            ('m', 'km'): 0.001,
            ('km', 'm'): 1000,
            ('m', 'ft'): 3.28084,
            ('ft', 'm'): 0.3048,
            ('mi', 'km'): 1.60934,
            ('km', 'mi'): 0.621371,
            
            # Weight
            ('kg', 'lb'): 2.20462,
            ('lb', 'kg'): 0.453592,
            ('g', 'oz'): 0.035274,
            ('oz', 'g'): 28.3495,
            
            # Temperature (special case)
            ('c', 'f'): lambda x: (x * 9/5) + 32,
            ('f', 'c'): lambda x: (x - 32) * 5/9,
        }
        
        try:
            from_unit = from_unit.lower()
            to_unit = to_unit.lower()
            
            key = (from_unit, to_unit)
            if key in conversions:
                factor = conversions[key]
                if callable(factor):
                    result = factor(value)
                else:
                    result = value * factor
                return f"{value} {from_unit} = {result:.2f} {to_unit}"
            else:
                return f"Conversion not supported: {from_unit} to {to_unit}"
        except Exception as e:
            logger.error(f"Unit conversion error: {e}")
            return f"Conversion failed: {str(e)}"

utils_service = UtilsService()
