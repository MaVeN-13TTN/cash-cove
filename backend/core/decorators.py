from functools import wraps
from django.core.cache import cache
from .cache_config import CacheService, CACHE_TIMEOUTS
from rest_framework.response import Response

def cached_response(cache_type):
    """
    Decorator to cache API responses
    
    Usage:
    @cached_response('budget')
    def get_budget(self, request, budget_id):
        ...
    """
    def decorator(func):
        @wraps(func)
        def wrapper(self, request, *args, **kwargs):
            # Don't cache for non-GET requests
            if request.method != 'GET':
                return func(self, request, *args, **kwargs)

            # Generate cache key
            cache_key = CacheService.get_cache_key(
                cache_type,
                request.user.id if request.user.is_authenticated else 'anon',
                *args
            )

            # Try to get from cache
            cached_response = cache.get(cache_key)
            if cached_response is not None:
                return Response(cached_response)

            # Get fresh response
            response = func(self, request, *args, **kwargs)
            
            # Cache the response
            if response.status_code == 200:
                cache.set(
                    cache_key,
                    response.data,
                    timeout=CACHE_TIMEOUTS.get(cache_type, 300)
                )

            return response
        return wrapper
    return decorator

def invalidate_cache(cache_type):
    """
    Decorator to invalidate cache after modification
    
    Usage:
    @invalidate_cache('budget')
    def update_budget(self, request, budget_id):
        ...
    """
    def decorator(func):
        @wraps(func)
        def wrapper(self, request, *args, **kwargs):
            response = func(self, request, *args, **kwargs)
            
            if response.status_code in [200, 201, 204]:
                # Generate cache key pattern
                cache_key = CacheService.get_cache_key(
                    cache_type,
                    request.user.id if request.user.is_authenticated else 'anon',
                    *args
                )
                
                # Invalidate matching cache entries
                CacheService.bulk_invalidate(cache_key)
            
            return response
        return wrapper
    return decorator
