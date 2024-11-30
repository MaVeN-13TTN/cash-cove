# apps/users/services/profile_service.py
"""
Enhanced profile-related services.
"""

from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from django.db.models import Q
from ..models import Profile, User


class ProfileService:
    """
    Enhanced service class for profile operations.
    """

    @staticmethod
    def update_profile(profile: Profile, data: Dict) -> Profile:
        """
        Update profile with validation and notifications.

        Args:
            profile: Profile instance
            data: Update data

        Returns:
            Profile: Updated profile instance

        Raises:
            ValidationError: If validation fails
        """
        # Track security-related changes
        security_fields = ["two_factor_enabled", "notification_emails"]
        security_changes = {}

        for field in security_fields:
            if field in data and getattr(profile, field) != data[field]:
                security_changes[field] = data[field]

        # Update profile
        for key, value in data.items():
            setattr(profile, key, value)

        try:
            profile.full_clean()
            profile.save()

            # Handle security changes
            if security_changes:
                from apps.notifications.services import NotificationService

                NotificationService.create_notification(
                    user_id=profile.user.id,
                    title="Security Settings Updated",
                    message="Your security preferences have been updated.",
                    notification_type="SECURITY",
                    priority="HIGH",
                    data={"changes": security_changes},
                )

            return profile
        except Exception as e:
            raise ValidationError(f"Profile update failed: {str(e)}")

    @staticmethod
    def toggle_two_factor(profile: Profile) -> bool:
        """
        Toggle 2FA with proper validation and logging.

        Args:
            profile: Profile instance

        Returns:
            bool: New 2FA status

        Raises:
            ValidationError: If operation fails
        """
        try:
            new_status = profile.toggle_two_factor()

            # Log security event
            from apps.notifications.services import NotificationService

            NotificationService.create_notification(
                user_id=profile.user.id,
                title="Two-Factor Authentication Status Changed",
                message=f"2FA has been {'enabled' if new_status else 'disabled'}.",
                notification_type="SECURITY",
                priority="HIGH",
            )

            return new_status
        except Exception as e:
            raise ValidationError(f"Failed to toggle 2FA: {str(e)}")

    @staticmethod
    def get_or_create_profile(user: User) -> Profile:
        """
        Get or create user profile with default settings.

        Args:
            user: User instance

        Returns:
            Profile: User's profile
        """
        profile, created = Profile.objects.get_or_create(
            user=user,
            defaults={
                "language": user.preferences.get("language", "en"),
                "timezone": user.preferences.get("timezone", "UTC"),
                "theme": Profile.ThemeChoices.SYSTEM,
                "default_currency": Profile.CurrencyChoices.USD,
            },
        )
        return profile

    @staticmethod
    def get_profile_stats(profile: Profile) -> Dict:
        """
        Get comprehensive profile statistics.

        Args:
            profile: Profile instance

        Returns:
            Dict: Profile statistics
        """
        now = timezone.now()
        user = profile.user
        last_month = now - timedelta(days=30)

        return {
            "account_age_days": (now.date() - user.date_joined.date()).days,
            "login_history": {
                "last_login": user.last_login,
                "login_count": user.preferences.get("login_count", 0),
                "last_ip": user.last_login_ip,
            },
            "security_status": {
                "is_verified": user.is_verified,
                "two_factor_enabled": profile.two_factor_enabled,
                "last_password_change": user.preferences.get("last_password_change"),
                "notification_emails": profile.notification_emails,
            },
            "activity_metrics": {
                "recent_expenses": user.expenses.filter(
                    created_at__gte=last_month
                ).count(),
                "recent_budgets": user.budgets.filter(
                    created_at__gte=last_month
                ).count(),
                "shared_expenses": user.expense_shares.count(),
            },
            "preferences": {
                "theme": profile.theme,
                "language": profile.language,
                "currency": profile.default_currency,
                "timezone": profile.timezone,
            },
        }

    @staticmethod
    def validate_notification_settings(profile: Profile) -> Optional[str]:
        """
        Validate notification settings configuration.

        Args:
            profile: Profile instance

        Returns:
            Optional[str]: Warning message if any
        """
        warnings = []

        if not profile.notification_emails and not profile.activity_emails:
            warnings.append("All email notifications are disabled")

        if profile.two_factor_enabled and not profile.notification_emails:
            warnings.append("2FA is enabled but email notifications are disabled")

        return "; ".join(warnings) if warnings else None

    @staticmethod
    def cleanup_inactive_profiles(days: int = 180) -> Tuple[int, List[str]]:
        """
        Clean up inactive profiles.

        Args:
            days: Inactivity threshold in days

        Returns:
            Tuple[int, List[str]]: Count and list of cleaned profiles
        """
        threshold = timezone.now() - timedelta(days=days)
        inactive_users = User.objects.filter(last_login__lt=threshold, is_active=True)

        cleaned = []
        for user in inactive_users:
            user.is_active = False
            user.save()
            cleaned.append(user.email)

        return len(cleaned), cleaned
