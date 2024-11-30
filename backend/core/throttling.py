from rest_framework.throttling import UserRateThrottle, AnonRateThrottle
from django.core.cache import cache

class CustomAnonRateThrottle(AnonRateThrottle):
    rate = '100/day'

class CustomUserRateThrottle(UserRateThrottle):
    rate = '1000/day'

class BurstRateThrottle(UserRateThrottle):
    """Throttle for burst requests (e.g., real-time updates)"""
    scope = 'burst'
    rate = '60/minute'

class AnalyticsRateThrottle(UserRateThrottle):
    """Specific throttle for analytics endpoints"""
    scope = 'analytics'
    rate = '300/hour'

class ExpenseRateThrottle(UserRateThrottle):
    """Specific throttle for expense-related endpoints"""
    scope = 'expenses'
    rate = '120/minute'

class SharingRateThrottle(UserRateThrottle):
    """Specific throttle for sharing-related endpoints"""
    scope = 'sharing'
    rate = '30/minute'
