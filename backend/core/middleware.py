import uuid
from django.utils.deprecation import MiddlewareMixin
from django.core.cache import cache
from .cache_config import CACHE_TIMEOUTS

class RequestTrackingMiddleware(MiddlewareMixin):
    def process_request(self, request):
        # Generate unique request ID
        request.id = str(uuid.uuid4())
        return None

class CacheMiddleware(MiddlewareMixin):
    def process_response(self, request, response):
        # Add cache control headers based on endpoint
        path = request.path_info.strip('/')
        
        # Define cache times for different endpoints
        if 'analytics' in path:
            max_age = CACHE_TIMEOUTS['analytics']
        elif 'categories' in path:
            max_age = CACHE_TIMEOUTS['categories']
        elif 'budget' in path:
            max_age = CACHE_TIMEOUTS['budget']
        elif 'expense' in path:
            max_age = CACHE_TIMEOUTS['expense']
        else:
            max_age = 0

        if request.method in ['GET', 'HEAD'] and max_age > 0:
            response['Cache-Control'] = f'public, max-age={max_age}'
        else:
            response['Cache-Control'] = 'no-store, no-cache, must-revalidate'

        return response
