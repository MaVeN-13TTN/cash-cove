"""
Authentication and permission decorators.
"""

from functools import wraps
from django.core.exceptions import PermissionDenied
from django.http import HttpResponseForbidden
from rest_framework.exceptions import ValidationError
from apps.users.models import User
from ..constants import MAX_BUDGETS_PER_USER


def require_verified_email(view_func):
    """
    Decorator to ensure user has verified their email.
    """
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return HttpResponseForbidden("Authentication required")
        if not request.user.email_verified:
            raise ValidationError("Email verification required")
        return view_func(request, *args, **kwargs)
    return _wrapped_view


def check_budget_limit(view_func):
    """
    Decorator to check if user has reached their budget limit.
    """
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        if request.method == "POST":
            user_budget_count = request.user.budgets.count()
            if user_budget_count >= MAX_BUDGETS_PER_USER:
                raise ValidationError(
                    f"Maximum number of budgets ({MAX_BUDGETS_PER_USER}) reached"
                )
        return view_func(request, *args, **kwargs)
    return _wrapped_view


def require_subscription(subscription_type):
    """
    Decorator to check if user has required subscription type.
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            if not hasattr(request.user, "subscription"):
                raise PermissionDenied("No active subscription")
            if request.user.subscription.type != subscription_type:
                raise PermissionDenied(
                    f"{subscription_type} subscription required"
                )
            return view_func(request, *args, **kwargs)
        return _wrapped_view
    return decorator


def staff_required(view_func):
    """
    Decorator to ensure user is staff member.
    """
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return HttpResponseForbidden("Authentication required")
        if not request.user.is_staff:
            raise PermissionDenied("Staff access required")
        return view_func(request, *args, **kwargs)
    return _wrapped_view