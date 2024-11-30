"""
Authentication service for users.
"""

from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple, List, Any, Union
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from django.contrib.auth.tokens import default_token_generator
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.conf import settings
from django.core.cache import cache
from django.db import transaction
from django.core.exceptions import ValidationError
from ..models import Profile, User


class AuthService:
    """
    Service class for authentication operations.
    """

    LOGIN_ATTEMPT_CACHE_PREFIX = "login_attempt_"
    MAX_LOGIN_ATTEMPTS = 5
    LOCKOUT_TIME = 30  # minutes

    @staticmethod
    @transaction.atomic
    def register_user(data: Dict[str, Any]) -> Tuple[User, Profile]:
        """
        Register new user with enhanced security and validation.

        Args:
            data: User registration data

        Returns:
            Tuple[User, Profile]: Created user and profile

        Raises:
            ValidationError: If registration fails
        """
        # Validate email domain if necessary
        email = data["email"].lower()
        if AuthService._is_disposable_email(email):
            raise ValidationError(_("Disposable email addresses are not allowed."))

        # Create user with transaction
        user = User.objects.create_user(
            email=email,
            username=data.get("username", email),
            password=data["password"],
            first_name=data.get("first_name", ""),
            last_name=data.get("last_name", ""),
        )

        # Initialize user preferences
        user.preferences = {
            "language": data.get("language", "en"),
            "timezone": data.get("timezone", "UTC"),
            "registration_ip": data.get("ip_address"),
            "registration_date": datetime.now().isoformat(),
        }
        user.save()

        # Create profile
        profile = Profile.objects.create(
            user=user,
            language=data.get("language", "en"),
            timezone=data.get("timezone", "UTC"),
        )

        # Send emails
        AuthService._send_welcome_email(user)
        AuthService.send_verification_email(user)

        return user, profile

    @staticmethod
    def authenticate_user(
        email: str, password: str, ip_address: Optional[str] = None
    ) -> Tuple[Optional[User], Optional[str]]:
        """Authentication handler."""
        if AuthService._is_account_locked(email):
            return None, _("Account temporarily locked. Try again later.")

        try:
            user = User.objects.get(email=email.lower())

            if not user.is_active:
                return None, _("Account is deactivated.")

            if not user.check_password(password):
                AuthService._record_failed_attempt(email)
                return None, _("Invalid credentials.")

            AuthService._clear_login_attempts(email)
            AuthService._update_login_metadata(user, ip_address)

            return user, None

        except User.DoesNotExist:
            AuthService._record_failed_attempt(email)
            return None, _("Invalid credentials.")

    @staticmethod
    def send_verification_email(user: User) -> None:
        """Send verification email."""
        token = default_token_generator.make_token(user)
        uid = urlsafe_base64_encode(force_bytes(user.pk))
        verification_link = f"{settings.FRONTEND_URL}/verify-email/{uid}/{token}"

        send_mail(
            subject="Verify Your Email",
            message=f"Click the link to verify your email: {verification_link}",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=True,
        )

    @staticmethod
    def _is_disposable_email(email: str) -> bool:
        """Check disposable email."""
        disposable_domains = [
            "tempmail.com",
            "throwaway.com",
        ]
        domain = email.split("@")[1]
        return domain in disposable_domains

    @staticmethod
    def _record_failed_attempt(email: str) -> None:
        """Record failed attempt."""
        key = f"{AuthService.LOGIN_ATTEMPT_CACHE_PREFIX}{email}"
        attempts = cache.get(key, 0)
        attempts += 1

        if attempts >= AuthService.MAX_LOGIN_ATTEMPTS:
            cache.set(key, attempts, AuthService.LOCKOUT_TIME * 60)
        else:
            cache.set(key, attempts, 300)

    @staticmethod
    def _is_account_locked(email: str) -> bool:
        """Check if account is locked."""
        key = f"{AuthService.LOGIN_ATTEMPT_CACHE_PREFIX}{email}"
        attempts = cache.get(key, 0)
        return attempts >= AuthService.MAX_LOGIN_ATTEMPTS

    @staticmethod
    def _update_login_metadata(user: User, ip_address: Optional[str]) -> None:
        """Update login metadata."""
        if ip_address:
            user.last_login_ip = ip_address

        user.preferences["login_count"] = user.preferences.get("login_count", 0) + 1
        user.preferences["last_login_at"] = datetime.now().isoformat()

        if ip_address:
            recent_ips = user.preferences.get("recent_ips", [])
            if ip_address not in recent_ips:
                recent_ips.insert(0, ip_address)
                user.preferences["recent_ips"] = recent_ips[:5]

        user.save(update_fields=["last_login_ip", "preferences"])

    @staticmethod
    def get_tokens_for_user(user: User) -> Dict[str, str]:
        """Get authentication tokens."""
        refresh = RefreshToken.for_user(user)

        refresh["email"] = user.email
        refresh["is_verified"] = user.is_verified
        refresh["preferences"] = {
            "theme": user.profile.theme,
            "language": user.profile.language,
        }

        return {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        }

    @staticmethod
    def track_suspicious_activity(
        user: User, activity_type: str, details: Dict[str, Any]
    ) -> None:
        """Track suspicious activity."""
        from apps.notifications.services import NotificationService

        user.preferences.setdefault("suspicious_activities", []).append(
            {
                "type": activity_type,
                "timestamp": datetime.now().isoformat(),
                "details": details,
            }
        )
        user.save(update_fields=["preferences"])

        NotificationService.create_notification(
            user_id=user.id,
            title="Suspicious Account Activity Detected",
            message=f"We detected suspicious activity: {activity_type}",
            notification_type="SECURITY_ALERT",
            priority="HIGH",
            data={"activity_details": details},
        )

    @staticmethod
    def get_security_status(user: User) -> Dict[str, Any]:
        """Get security status."""
        return {
            "account_verified": user.is_verified,
            "two_factor_enabled": user.profile.two_factor_enabled,
            "last_password_change": user.preferences.get("last_password_change"),
            "recent_suspicious_activities": len(
                user.preferences.get("suspicious_activities", [])
            ),
            "active_sessions": user.preferences.get("active_sessions", []),
            "login_attempts": cache.get(
                f"{AuthService.LOGIN_ATTEMPT_CACHE_PREFIX}{user.email}", 0
            ),
            "security_recommendations": AuthService._get_security_recommendations(user),
        }

    @staticmethod
    def _get_security_recommendations(user: User) -> List[Dict[str, Any]]:
        """Get security recommendations."""
        recommendations = []

        if not user.is_verified:
            recommendations.append(
                {
                    "type": "VERIFY_EMAIL",
                    "message": "Verify your email address to secure your account",
                    "priority": "HIGH",
                }
            )

        if not user.profile.two_factor_enabled:
            recommendations.append(
                {
                    "type": "ENABLE_2FA",
                    "message": "Enable two-factor authentication for extra security",
                    "priority": "HIGH",
                }
            )

        last_password_change = user.preferences.get("last_password_change")
        if last_password_change:
            last_change = datetime.fromisoformat(last_password_change)
            if (datetime.now() - last_change).days > 90:
                recommendations.append(
                    {
                        "type": "UPDATE_PASSWORD",
                        "message": "Consider updating your password",
                        "priority": "MEDIUM",
                    }
                )

        return recommendations