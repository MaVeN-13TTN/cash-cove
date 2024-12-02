from django.http import JsonResponse
from django.utils.deprecation import MiddlewareMixin
import logging

logger = logging.getLogger(__name__)

class ErrorHandlingMiddleware(MiddlewareMixin):
    """
    Middleware to handle exceptions and format error responses.
    """

    def process_exception(self, request, exception):
        """
        Process exceptions and return a JSON response.

        Args:
            request: HTTP request object
            exception: Exception instance

        Returns:
            JsonResponse: Formatted error response
        """
        logger.error(f"Error occurred: {exception}", exc_info=True)
        response_data = {
            "error": str(exception),
            "message": "An unexpected error occurred. Please try again later."
        }
        return JsonResponse(response_data, status=500)
