"""
Currency helper functions.
"""

from decimal import Decimal, ROUND_HALF_UP
from typing import Union, Dict
import requests
from django.core.cache import cache
from ..constants import DEFAULT_CURRENCY, SUPPORTED_CURRENCIES
from ..exceptions.custom_exceptions import InvalidCurrency

# Cache key for exchange rates
EXCHANGE_RATES_CACHE_KEY = "exchange_rates"
EXCHANGE_RATES_CACHE_TIMEOUT = 3600  # 1 hour


def format_currency(amount: Union[Decimal, float], currency: str = DEFAULT_CURRENCY) -> str:
    """
    Format amount with currency symbol.
    """
    if currency not in dict(SUPPORTED_CURRENCIES):
        raise InvalidCurrency(f"Currency {currency} not supported")
    
    amount = Decimal(str(amount)).quantize(Decimal(".01"), rounding=ROUND_HALF_UP)
    
    currency_formats = {
        "USD": "${:,.2f}",
        "EUR": "€{:,.2f}",
        "GBP": "£{:,.2f}",
        "JPY": "¥{:,.0f}",
        "KES": "KSh {:,.2f}",
    }
    
    return currency_formats.get(currency, "${:,.2f}").format(amount)


def get_exchange_rates(base_currency: str = DEFAULT_CURRENCY) -> Dict[str, float]:
    """
    Get current exchange rates from cache or API.
    """
    cache_key = f"{EXCHANGE_RATES_CACHE_KEY}_{base_currency}"
    rates = cache.get(cache_key)
    
    if rates is None:
        try:
            # Using exchangerate-api.com as an example
            response = requests.get(
                f"https://v6.exchangerate-api.com/v6/YOUR_API_KEY/latest/{base_currency}"
            )
            response.raise_for_status()
            rates = response.json().get("conversion_rates", {})
            cache.set(cache_key, rates, EXCHANGE_RATES_CACHE_TIMEOUT)
        except requests.RequestException:
            # Fallback to some default rates if API call fails
            rates = {currency[0]: 1.0 for currency in SUPPORTED_CURRENCIES}
    
    return rates


def convert_currency(
    amount: Union[Decimal, float],
    from_currency: str,
    to_currency: str
) -> Decimal:
    """
    Convert amount between currencies.
    """
    if from_currency == to_currency:
        return Decimal(str(amount))
    
    rates = get_exchange_rates(from_currency)
    if to_currency not in rates:
        raise InvalidCurrency(f"Cannot convert to {to_currency}")
    
    converted = Decimal(str(amount)) * Decimal(str(rates[to_currency]))
    return converted.quantize(Decimal(".01"), rounding=ROUND_HALF_UP)


def validate_currency(currency: str) -> bool:
    """
    Check if currency is supported.
    """
    return currency in dict(SUPPORTED_CURRENCIES)


def get_currency_symbol(currency: str) -> str:
    """
    Get currency symbol.
    """
    symbols = {
        "USD": "$",
        "EUR": "€",
        "GBP": "£",
        "JPY": "¥",
        "KES": "KSh",
    }
    return symbols.get(currency, "$")