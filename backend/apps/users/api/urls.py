# urls.py
"""URL configuration for users application."""

from django.urls import path
from .views import UserViewSet, ProfileViewSet, SecurityStatusViewSet

urlpatterns = [
    # Authentication endpoints
    path(
        "api/v1/auth/register/",
        UserViewSet.as_view({"post": "register"}),
        name="register-user",
    ),
    path("api/v1/auth/token/", UserViewSet.as_view({"post": "login"}), name="token"),
    path(
        "api/v1/auth/verify-email/",
        UserViewSet.as_view({"post": "verify_email"}),
        name="verify-email",
    ),
    path(
        "api/v1/auth/reset-password/",
        UserViewSet.as_view({"post": "reset_password"}),
        name="reset-password",
    ),
    path(
        "api/v1/auth/reset-password-confirm/",
        UserViewSet.as_view({"post": "reset_password_confirm"}),
        name="reset-password-confirm",
    ),
    # User management endpoints
    path("api/v1/users/", UserViewSet.as_view({"get": "list"}), name="user-list"),
    path(
        "api/v1/users/check-email/",
        UserViewSet.as_view({"get": "check_email", "post": "check_email"}),
        name="check-email",
    ),
    path(
        "api/v1/users/<int:pk>/",
        UserViewSet.as_view({"get": "retrieve", "put": "update", "delete": "destroy"}),
        name="user-detail",
    ),
    path(
        "api/v1/users/<int:pk>/deactivate/",
        UserViewSet.as_view({"post": "deactivate"}),
        name="user-deactivate",
    ),
    # Profile endpoints
    path(
        "api/v1/auth/profile/",
        UserViewSet.as_view({"get": "profile"}),
        name="user-profile",
    ),
    path(
        "api/v1/users/profile/",
        ProfileViewSet.as_view({"get": "retrieve", "put": "update"}),
        name="profile-detail",
    ),
    path(
        "api/v1/users/profile/2fa/",
        ProfileViewSet.as_view({"post": "toggle_2fa"}),
        name="toggle-2fa",
    ),
    # Security endpoints
    path(
        "api/v1/auth/security-status/",
        SecurityStatusViewSet.as_view({"get": "list"}),
        name="security-status",
    ),
]
