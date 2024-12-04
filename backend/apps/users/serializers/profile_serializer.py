"""
Enhanced profile-related serializers.
"""

from rest_framework import serializers
from django.utils.translation import gettext_lazy as _
from ..models import Profile
from typing import Dict
from django.utils import timezone


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
        """
        Determine user activity status based on login history.
        
        Returns:
        - 'active': Logged in recently (within last 7 days)
        - 'inactive': No recent login
        """
        if not obj.user.last_login:
            return 'inactive'
        
        days_since_login = (timezone.now() - obj.user.last_login).days
        return 'active' if days_since_login <= 7 else 'inactive'

    def get_security_score(self, obj: Profile) -> int:
        """
        Calculate a security score based on user's security settings.
        
        Scoring:
        - Two-factor authentication: +50 points
        - Email verified: +30 points
        - Recent activity: +20 points
        
        Maximum score: 100
        """
        score = 0
        
        # Two-factor authentication
        if obj.two_factor_enabled:
            score += 50
        
        # Email verification
        if obj.user.is_active:
            score += 30
        
        # Recent activity
        if self.get_activity_status(obj) == 'active':
            score += 20
        
        return min(score, 100)

    def to_representation(self, instance: Profile) -> Dict:
        """Customize profile representation."""
        data = super().to_representation(instance)
        request = self.context.get("request")

        # Include avatar URL if present
        if request and instance.user.avatar:
            data["avatar_url"] = request.build_absolute_uri(instance.user.avatar.url)

        return data
