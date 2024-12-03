"""Authentication URLs."""

from django.urls import path

from .views import UserViewSet

urlpatterns = [
    path("token/", UserViewSet.as_view({"post": "login"}), name="token"),
    path("register/", UserViewSet.as_view({"post": "register"}), name="register"),
    path("check-email/", UserViewSet.as_view({"get": "check_email"}), name="check-email"),
    path("verify-email/", UserViewSet.as_view({"post": "verify_email"}), name="verify-email"),
    path("send-verification-email/", UserViewSet.as_view({"post": "send_verification_email"}), name="send-verification-email"),
    path("reset-password/", UserViewSet.as_view({"post": "reset_password"}), name="reset-password"),
    path("reset-password-confirm/", UserViewSet.as_view({"post": "reset_password_confirm"}), name="reset-password-confirm"),
    path("google/", UserViewSet.as_view({"post": "google_login"}), name="google"),
    path("facebook/", UserViewSet.as_view({"post": "facebook_login"}), name="facebook"),
    path("apple/", UserViewSet.as_view({"post": "apple_login"}), name="apple"),
    path("verify-2fa/", UserViewSet.as_view({"post": "verify_2fa"}), name="verify-2fa"),
    path("security-status/", UserViewSet.as_view({"get": "security_status"}), name="security-status"),
    path("profile/", UserViewSet.as_view({"get": "profile", "put": "update_profile"}), name="profile"),
]
