# urls.py
"""URL configuration for users application."""

from django.urls import path
from .views import (
    RegisterView,
    ResetPasswordView,
    ResetPasswordConfirmView,
    CustomTokenObtainPairView,
    ProfileViewSet,
    SecurityStatusViewSet,
    CheckEmailView,
)

urlpatterns = [
    # Authentication endpoints
    path("api/v1/auth/register/", RegisterView.as_view(), name="register-user"),
    path("api/v1/auth/token/", CustomTokenObtainPairView.as_view(), name="token"),
    path("api/v1/auth/reset-password/", ResetPasswordView.as_view(), name="reset-password"),
    path(
        "api/v1/auth/reset-password-confirm/",
        ResetPasswordConfirmView.as_view(),
        name="reset-password-confirm",
    ),
    path(
        "api/v1/auth/check-email/",
        CheckEmailView.as_view(),
        name="check-email",
    ),
    
    # Profile endpoints
    path(
        "api/v1/auth/profile/",
        ProfileViewSet.as_view({"get": "retrieve", "put": "update", "patch": "partial_update"}),
        name="profile-detail",
    ),
    path(
        "api/v1/auth/profile/2fa/",
        ProfileViewSet.as_view({"post": "toggle_2fa"}),
        name="profile-2fa",
    ),
    
    # Security Status
    path(
        "api/v1/auth/security-status/",
        SecurityStatusViewSet.as_view({"get": "list"}),
        name="security-status",
    ),
]
