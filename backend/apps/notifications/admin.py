"""
Admin configuration for the notifications application.
"""

from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import Notification, NotificationPreference


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """Admin configuration for Notification model."""

    list_display = (
        "title",
        "user",
        "notification_type",
        "priority",
        "is_read",
        "created_at",
    )

    list_filter = ("notification_type", "priority", "is_read", "created_at")

    search_fields = ("title", "message", "user__username", "user__email")

    readonly_fields = ("created_at", "read_at")

    date_hierarchy = "created_at"

    fieldsets = (
        (
            None,
            {"fields": ("user", "title", "message", "notification_type", "priority")},
        ),
        (_("Status"), {"fields": ("is_read", "read_at", "expires_at")}),
        (
            _("Additional Information"),
            {"fields": ("action_url", "data"), "classes": ("collapse",)},
        ),
        (_("Timestamps"), {"fields": ("created_at",), "classes": ("collapse",)}),
    )

    def get_queryset(self, request):
        """
        Override queryset to include related fields.
        """
        return super().get_queryset(request).select_related("user")


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    """Admin configuration for NotificationPreference model."""

    list_display = (
        "user",
        "email_notifications",
        "push_notifications",
        "minimum_priority",
        "updated_at",
    )

    list_filter = ("email_notifications", "push_notifications", "minimum_priority")

    search_fields = ("user__username", "user__email")

    readonly_fields = ("created_at", "updated_at")

    fieldsets = (
        (None, {"fields": ("user", "email_notifications", "push_notifications")}),
        (
            _("Notification Settings"),
            {"fields": ("notification_types", "minimum_priority")},
        ),
        (
            _("Quiet Hours"),
            {
                "fields": ("quiet_hours_start", "quiet_hours_end"),
                "classes": ("collapse",),
            },
        ),
        (
            _("Timestamps"),
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )

    def get_queryset(self, request):
        """
        Override queryset to include related fields.
        """
        return super().get_queryset(request).select_related("user")
