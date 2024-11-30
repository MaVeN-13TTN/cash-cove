from django.core.cache import cache
from django.conf import settings
from datetime import timedelta

# Cache key prefixes for different types of data
CACHE_KEYS = {
    'user_profile': 'user_profile_{}',
    'budget': 'budget_{}',
    'expense': 'expense_{}',
    'analytics': 'analytics_{}_{}',  # user_id, metric_type
    'categories': 'categories_{}_{}',  # user_id, category_type
}

# Cache timeout settings (in seconds)
CACHE_TIMEOUTS = {
    'user_profile': 60 * 30,  # 30 minutes
    'budget': 60 * 15,  # 15 minutes
    'expense': 60 * 15,  # 15 minutes
    'analytics': 60 * 60,  # 1 hour
    'categories': 60 * 60 * 24,  # 24 hours
}

class CacheService:
    @staticmethod
    def get_cache_key(prefix: str, *args) -> str:
        """Generate a cache key based on prefix and arguments"""
        return CACHE_KEYS[prefix].format(*args)

    @staticmethod
    def get_or_set(key: str, callback, timeout=None):
        """Get value from cache or set it if not present"""
        return cache.get_or_set(key, callback, timeout)

    @staticmethod
    def invalidate(key: str):
        """Remove a key from cache"""
        cache.delete(key)

    @staticmethod
    def bulk_invalidate(pattern: str):
        """Remove multiple keys matching a pattern"""
        keys = cache.keys(f"*{pattern}*")
        cache.delete_many(keys)
