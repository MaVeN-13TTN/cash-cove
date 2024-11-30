"""
Enhanced user-related services.
"""

from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from django.db.models import Q
from ..models import Profile

# User = get_user_model()


class UserService:
    """
    Enhanced service class for user operations.
    """

    @staticmethod
    def update_user(user: User, data: Dict) -> User:
        """
        Update user data with validation and activity tracking.

        Args:
            user: User instance
            data: Update data

        Returns:
            User: Updated user instance

        Raises:
            ValidationError: If validation fails
        """
        restricted_fields = ["is_staff", "is_superuser", "is_active"]

        # Remove restricted fields
        for field in restricted_fields:
            data.pop(field, None)

        # Track significant changes
        significant_fields = ["email", "phone_number", "password"]
        significant_change = any(field in data for field in significant_fields)

        # Update user data
        for key, value in data.items():
            setattr(user, key, value)

        try:
            user.full_clean()
            user.save()

            # Handle significant changes
            if significant_change:
                from apps.notifications.services import NotificationService

                NotificationService.create_notification(
                    user_id=user.id,
                    title="Account Updated",
                    message="Important account information has been updated.",
                    notification_type="SECURITY",
                    priority="HIGH",
                )

            return user
        except Exception as e:
            raise ValidationError(f"Update failed: {str(e)}")

    @staticmethod
    def update_preferences(
        user: User, preferences: Dict, validate: bool = True
    ) -> User:
        """
        Update user preferences with validation.

        Args:
            user: User instance
            preferences: New preferences
            validate: Whether to validate preferences

        Returns:
            User: Updated user instance

        Raises:
            ValidationError: If validation fails
        """
        if validate:
            valid_keys = ["theme", "language", "notifications", "currency", "privacy"]
            invalid_keys = [key for key in preferences.keys() if key not in valid_keys]
            if invalid_keys:
                raise ValidationError(
                    f"Invalid preference keys: {', '.join(invalid_keys)}"
                )

        # Merge with existing preferences
        user.preferences.update(preferences)
        user.save(update_fields=["preferences"])
        return user

    @staticmethod
    def deactivate_account(
        user: User, password: str, reason: Optional[str] = None
    ) -> bool:
        """
        Deactivate user account with security measures.

        Args:
            user: User instance
            password: Current password
            reason: Deactivation reason

        Returns:
            bool: True if successful

        Raises:
            ValidationError: If validation fails
        """
        if not user.check_password(password):
            raise ValidationError(_("Invalid password"))

        # Store deactivation info
        user.preferences["deactivation"] = {
            "date": timezone.now().isoformat(),
            "reason": reason,
        }

        user.is_active = False
        user.save()

        # Send notification
        from apps.notifications.services import NotificationService

        NotificationService.create_notification(
            user_id=user.id,
            title="Account Deactivated",
            message="Your account has been deactivated.",
            notification_type="SECURITY",
            priority="HIGH",
        )

        return True

    @staticmethod
    def search_users(
        query: str, active_only: bool = True, limit: int = 10
    ) -> List[User]:
        """
        Search users by various criteria.

        Args:
            query: Search query
            active_only: Only active users
            limit: Result limit

        Returns:
            List[User]: Matching users
        """
        search_fields = (
            Q(username__icontains=query)
            | Q(email__icontains=query)
            | Q(first_name__icontains=query)
            | Q(last_name__icontains=query)
        )

        filters = Q(search_fields)
        if active_only:
            filters &= Q(is_active=True)

        return User.objects.filter(filters)[:limit]

    @staticmethod
    def get_user_activity_summary(user: User) -> Dict:
        """
        Get user activity summary.

        Args:
            user: User instance

        Returns:
            Dict: Activity summary
        """
        now = timezone.now()
        last_month = now - timedelta(days=30)

        return {
            "last_login": user.last_login,
            "days_since_join": (now.date() - user.date_joined.date()).days,
            "total_logins": user.preferences.get("login_count", 0),
            "recent_expenses": user.expenses.filter(created_at__gte=last_month).count(),
            "recent_budgets": user.budgets.filter(created_at__gte=last_month).count(),
            "profile_completion": UserService._calculate_profile_completion(user),
        }

    # apps/users/services/users_service.py (continued)

    @staticmethod
    def _calculate_profile_completion(user: User) -> int:
        """
        Calculate profile completion percentage.

        Args:
            user: User instance

        Returns:
            int: Completion percentage
        """
        fields = {
            "email": 15,
            "first_name": 10,
            "last_name": 10,
            "phone_number": 10,
            "avatar": 10,
            "bio": 10,
            "date_of_birth": 10,
            "is_verified": 15,
            "preferences": 10,
        }

        score = 0
        for field, points in fields.items():
            value = getattr(user, field)
            if value:
                if field == "preferences" and isinstance(value, dict):
                    if len(value) > 0:
                        score += points
                else:
                    score += points

        return score
