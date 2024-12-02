from django.http import JsonResponse
from rest_framework import status
from django.core.exceptions import ValidationError
from rest_framework.exceptions import APIException

class ErrorCodes:
    AUTH_ERROR = 1000
    VALIDATION_ERROR = 2000
    NOT_FOUND = 3000
    PERMISSION_DENIED = 4000
    SERVER_ERROR = 5000

class ErrorHandler:
    @staticmethod
    def format_error(code, message, details=None):
        return {
            'error': {
                'code': code,
                'message': message,
                'details': details or {}
            }
        }

class ErrorHandlerMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            response = self.get_response(request)
            return response
        except Exception as e:
            return self.handle_error(e)

    def handle_error(self, exc):
        if isinstance(exc, ValidationError):
            return JsonResponse(
                ErrorHandler.format_error(
                    ErrorCodes.VALIDATION_ERROR,
                    'Validation Error',
                    details=exc.message_dict
                ),
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if isinstance(exc, APIException):
            return JsonResponse(
                ErrorHandler.format_error(
                    ErrorCodes.SERVER_ERROR,
                    str(exc),
                ),
                status=exc.status_code
            )

        # Log unexpected errors
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f'Unexpected error: {str(exc)}', exc_info=True)

        return JsonResponse(
            ErrorHandler.format_error(
                ErrorCodes.SERVER_ERROR,
                'Internal Server Error'
            ),
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
