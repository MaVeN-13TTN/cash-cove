# Add these settings to your settings.py file

# Cache Configuration
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'PARSER_CLASS': 'redis.connection.HiredisParser',
            'CONNECTION_POOL_CLASS': 'redis.connection.BlockingConnectionPool',
            'CONNECTION_POOL_CLASS_KWARGS': {
                'max_connections': 50,
                'timeout': 20,
            },
            'COMPRESSOR': 'django_redis.compressors.zlib.ZlibCompressor',
        }
    }
}

# Cache time to live is 15 minutes by default
CACHE_TTL = 60 * 15

# DRF Settings
REST_FRAMEWORK = {
    # ... existing settings ...
    
    # Exception Handler
    'EXCEPTION_HANDLER': 'core.exceptions.custom_exception_handler',
    
    # Throttling
    'DEFAULT_THROTTLE_CLASSES': [
        'core.throttling.CustomUserRateThrottle',
        'core.throttling.CustomAnonRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'user': '1000/day',
        'anon': '100/day',
        'burst': '60/minute',
        'analytics': '300/hour',
        'expenses': '120/minute',
        'sharing': '30/minute',
    }
}

# Middleware Configuration
MIDDLEWARE += [
    'core.middleware.RequestTrackingMiddleware',
    'core.middleware.CacheMiddleware',
]

# Cache Settings
USE_CACHE = True
CACHE_MIDDLEWARE_SECONDS = 60 * 15  # 15 minutes
CACHE_MIDDLEWARE_KEY_PREFIX = 'budget_tracker'
