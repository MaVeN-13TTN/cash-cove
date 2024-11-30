"""
Enhanced profile-related serializers.
"""

from rest_framework import serializers
from django.utils.translation import gettext_lazy as _
from ..models import Profile
from typing import Dict


class ProfileSerializer(serializers.ModelSerializer):
    """
    Enhanced serializer for Profile model.
    """

    user_email = serializers.EmailField(source="user.email", read_only=True)
    user_full_name = serializers.CharField(source="user.get_full_name", read_only=True)
    activity_status = serializers.SerializerMethodField()
    security_score = serializers.SerializerMethodField()

    class Meta:
        """Meta options for ProfileSerializer."""

        model = Profile
        fields = [
            "id",
            "user_email",
            "user_full_name",
            "theme",
            "default_currency",
            "language",
            "timezone",
            "notification_emails",
            "activity_emails",
            "marketing_emails",
            "two_factor_enabled",
            "activity_status",
            "security_score",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def validate_language(self, value: str) -> str:
        """Validate language code."""
        valid_languages = ["en", "es", "fr", "de"]  # Add supported languages
        if value not in valid_languages:
            raise serializers.ValidationError(_("Unsupported language code."))
        return value

    def validate_timezone(self, value: str) -> str:
        """Validate timezone."""
        from pytz import all_timezones

        if value not in all_timezones:
            raise serializers.ValidationError(_("Invalid timezone."))
        return value

    def get_activity_status(self, obj: Profile) -> str:
        """Get user's activity status."""
        from django.utils import timezone
        from datetime import timedelta

        last_login = obj.user.last_login
        if not last_login:
            return "inactive"

        days_since_login = (timezone.now() - last_login).days

        if days_since_login < 7:
            return "active"
        elif days_since_login < 30:
            return "semi-active"
        return "inactive"

    def get_security_score(self, obj: Profile) -> int:
        """Calculate security score based on profile settings."""
        score = 0

        # Basic security measures
        if obj.user.is_verified:
            score += 30
        if obj.two_factor_enabled:
            score += 40
        if obj.user.has_usable_password():  # Not using social auth only
            score += 20
        if obj.notification_emails:  # Can receive security notifications
            score += 10

        return score

    def to_representation(self, instance: Profile) -> Dict:
        """Customize profile representation."""
        data = super().to_representation(instance)
        request = self.context.get("request")

        # Include avatar URL if present
        if request and instance.user.avatar:
            data["avatar_url"] = request.build_absolute_uri(instance.user.avatar.url)

        return data
