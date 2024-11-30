"""
Serializers for the notifications application.
"""

from rest_framework import serializers
from django.utils.translation import gettext_lazy as _
from ..models import Notification, NotificationPreference


class NotificationSerializer(serializers.ModelSerializer):
    """
    Serializer for Notification model.
    """

    age_in_minutes = serializers.IntegerField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)

    class Meta:
        """
        Meta options for NotificationSerializer.
        """

        model = Notification
        fields = [
            "id",
            "title",
            "message",
            "notification_type",
            "priority",
            "is_read",
            "read_at",
            "action_url",
            "data",
            "expires_at",
            "created_at",
            "age_in_minutes",
            "is_expired",
        ]
        read_only_fields = ["created_at", "read_at"]


class NotificationCreateSerializer(NotificationSerializer):
    """
    Serializer for creating notifications with validation.
    """

    class Meta(NotificationSerializer.Meta):
        """
        Meta options for NotificationCreateSerializer.
        """

        fields = NotificationSerializer.Meta.fields + ["user"]

    def validate(self, data):
        """Validate notification data."""
        user = data["user"]
        notification_type = data["notification_type"]
        priority = data.get("priority", Notification.Priority.MEDIUM)

        # Check user's notification preferences
        try:
            preferences = user.notification_preferences
            if not preferences.can_notify(notification_type, priority):
                raise serializers.ValidationError(
                    _("User has disabled this type of notification.")
                )
        except NotificationPreference.DoesNotExist:
            pass  # No preferences set, allow notification

        return data


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    """
    Serializer for NotificationPreference model.
    """

    class Meta:
        """
        Meta options for NotificationPreferenceSerializer.
        """

        model = NotificationPreference
        fields = [
            "id",
            "email_notifications",
            "push_notifications",
            "notification_types",
            "quiet_hours_start",
            "quiet_hours_end",
            "minimum_priority",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def validate_notification_types(self, value):
        """Validate notification types."""
        valid_types = dict(Notification.NotificationTypes.choices).keys()
        invalid_types = [t for t in value if t not in valid_types]

        if invalid_types:
            raise serializers.ValidationError(
                _("Invalid notification types: {}").format(", ".join(invalid_types))
            )
        return value


class NotificationListSerializer(NotificationSerializer):
    """
    Simplified serializer for listing notifications.
    """

    class Meta(NotificationSerializer.Meta):
        """
        Meta options for NotificationListSerializer.
        """

        fields = [
            "id",
            "title",
            "notification_type",
            "priority",
            "is_read",
            "created_at",
            "is_expired",
        ]


class NotificationBulkActionSerializer(serializers.Serializer):
    """
    Serializer for bulk notification actions.
    """

    notification_ids = serializers.ListField(
        child=serializers.IntegerField(), min_length=1
    )
    action = serializers.ChoiceField(choices=["mark_read", "mark_unread", "delete"])
