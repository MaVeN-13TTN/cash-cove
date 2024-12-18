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
        
        # Check user's notification preferences
        try:
            preferences = user.notification_preferences
            
            # Check if this type of notification is enabled
            if notification_type == 'BUDGET_ALERT' and not preferences.budget_alerts:
                raise serializers.ValidationError("Budget alerts are disabled.")
            elif notification_type == 'EXPENSE_ALERT' and not preferences.expense_alerts:
                raise serializers.ValidationError("Expense alerts are disabled.")
            elif notification_type == 'SYSTEM' and not preferences.system_notifications:
                raise serializers.ValidationError("System notifications are disabled.")
            elif notification_type == 'REMINDER' and not preferences.reminders:
                raise serializers.ValidationError("Reminders are disabled.")
            elif notification_type == 'BUDGET_EXCEEDED' and not preferences.budget_exceeded_alerts:
                raise serializers.ValidationError("Budget exceeded alerts are disabled.")
            elif notification_type == 'RECURRING_EXPENSE' and not preferences.recurring_expense_alerts:
                raise serializers.ValidationError("Recurring expense alerts are disabled.")
            elif notification_type == 'THRESHOLD_REACHED' and not preferences.threshold_alerts:
                raise serializers.ValidationError("Threshold alerts are disabled.")
                
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
            'id',
            'budget_alerts',
            'expense_alerts',
            'system_notifications',
            'reminders',
            'budget_exceeded_alerts',
            'recurring_expense_alerts',
            'threshold_alerts',
            'email_notifications',
            'push_notifications',
            'notification_frequency',
            'quiet_hours_start',
            'quiet_hours_end',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate(self, data):
        """Validate notification preferences."""
        quiet_hours_start = data.get('quiet_hours_start')
        quiet_hours_end = data.get('quiet_hours_end')
        
        if quiet_hours_start and not quiet_hours_end:
            raise serializers.ValidationError({
                'quiet_hours_end': 'Quiet hours end time must be set if start time is set.'
            })
        
        if quiet_hours_end and not quiet_hours_start:
            raise serializers.ValidationError({
                'quiet_hours_start': 'Quiet hours start time must be set if end time is set.'
            })
        
        if quiet_hours_start and quiet_hours_end:
            if quiet_hours_start == quiet_hours_end:
                raise serializers.ValidationError({
                    'quiet_hours': 'Quiet hours start and end times cannot be the same.'
                })
        
        return data


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
