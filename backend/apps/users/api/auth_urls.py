"""Authentication URLs."""

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    UserViewSet, 
    RegisterView,
    ResetPasswordView, 
    ResetPasswordConfirmView,
    CustomTokenObtainPairView,
    ProfileViewSet,
    CheckEmailView
)

urlpatterns = [
    # Authentication Endpoints
    path('register/', RegisterView.as_view(), name='register'),
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Password Management
    path('reset-password/', ResetPasswordView.as_view(), name='reset_password'),
    path('reset-password-confirm/', ResetPasswordConfirmView.as_view(), name='reset_password_confirm'),
    
    # User Profile and Security Endpoints
    path('profile/', ProfileViewSet.as_view({
        'get': 'retrieve',
        'put': 'update',
        'patch': 'partial_update'
    }), name='user_profile'),
    path('security-status/', UserViewSet.as_view({'get': 'security_status'}), name='security_status'),
    
    # Additional Authentication Routes
    path('check-email/', CheckEmailView.as_view(), name="check-email"),
    path('send-verification-email/', UserViewSet.as_view({"post": "send_verification_email"}), name="send-verification-email"),
    path('google/', UserViewSet.as_view({"post": "google_login"}), name="google"),
    path('facebook/', UserViewSet.as_view({"post": "facebook_login"}), name="facebook"),
    path('verify-2fa/', UserViewSet.as_view({"post": "verify_2fa"}), name="verify-2fa"),
]
