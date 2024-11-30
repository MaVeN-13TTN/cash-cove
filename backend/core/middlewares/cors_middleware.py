"""
Custom CORS middleware configuration.
"""

from typing import Callable
from django.http import HttpRequest, HttpResponse
from django.conf import settings


class CorsMiddleware:
    """
    Custom middleware for handling CORS headers.
    Compliant with ASGI/WSGI applications.
    """

    def __init__(self, get_response: Callable) -> None:
        """
        Initialize the middleware with the get_response callable.

        Args:
            get_response: The callable that processes the request
        """
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        """
        Process the request and add CORS headers to the response.

        Args:
            request: The incoming HTTP request

        Returns:
            HttpResponse: The processed response with CORS headers
        """
        response = self.get_response(request)

        # Add CORS headers if origin is in allowed origins
        origin = request.headers.get("Origin")
        if origin and origin in settings.CORS_ALLOWED_ORIGINS:
            response["Access-Control-Allow-Origin"] = origin
            response["Access-Control-Allow-Methods"] = ",".join(
                ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
            )
            response["Access-Control-Allow-Headers"] = ",".join(
                [
                    "Accept",
                    "Accept-Encoding",
                    "Authorization",
                    "Content-Type",
                    "Origin",
                    "X-CSRFToken",
                    "X-Requested-With",
                ]
            )
            response["Access-Control-Allow-Credentials"] = "true"

            # Handle preflight requests
            if request.method == "OPTIONS":
                response["Access-Control-Max-Age"] = "86400"  # 24 hours

        return response

    def process_view(
        self,
        request: HttpRequest,
        view_func: Callable,
        view_args: list,
        view_kwargs: dict,
    ) -> None:
        """
        Process the view function before it's called.

        Args:
            request: The incoming HTTP request
            view_func: The view function to be called
            view_args: Positional arguments for the view
            view_kwargs: Keyword arguments for the view
        """
        return None
