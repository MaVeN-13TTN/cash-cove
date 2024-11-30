from rest_framework.views import exception_handler
from rest_framework.exceptions import APIException
from rest_framework import status
from django.core.exceptions import ValidationError
from django.http import Http404
from rest_framework.response import Response

class ServiceUnavailableError(APIException):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_detail = 'Service temporarily unavailable.'
    default_code = 'service_unavailable'

class RateLimitExceededError(APIException):
    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    default_detail = 'Rate limit exceeded.'
    default_code = 'rate_limit_exceeded'

class InvalidRequestError(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = 'Invalid request.'
    default_code = 'invalid_request'

def custom_exception_handler(exc, context):
    """
    Custom exception handler that formats errors to match frontend expectations
    """
    response = exception_handler(exc, context)

    if response is None:
        if isinstance(exc, Http404):
            response = Response(
                {'error': {'code': 'not_found', 'message': 'Resource not found'}},
                status=status.HTTP_404_NOT_FOUND
            )
        elif isinstance(exc, ValidationError):
            response = Response(
                {'error': {'code': 'validation_error', 'message': str(exc)}},
                status=status.HTTP_400_BAD_REQUEST
            )
        else:
            response = Response(
                {'error': {'code': 'internal_error', 'message': 'An unexpected error occurred'}},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    else:
        error = {
            'code': exc.default_code if hasattr(exc, 'default_code') else 'error',
            'message': str(exc.detail) if hasattr(exc, 'detail') else str(exc)
        }

        # Add field-specific errors if available
        if hasattr(exc, 'detail') and isinstance(exc.detail, dict):
            error['fields'] = exc.detail

        response.data = {'error': error}

    # Add request ID for tracking (if available)
    if hasattr(context['request'], 'id'):
        response.data['request_id'] = context['request'].id

    return response
