"""
Models for the notifications application.
"""

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _


class Notification(models.Model):
    """
    Model for user notifications.
    """

    class NotificationTypes(models.TextChoices):
        """Notification type choices."""

        BUDGET_ALERT = "BUDGET_ALERT", _("Budget Alert")
        EXPENSE_ALERT = "EXPENSE_ALERT", _("Expense Alert")
        SYSTEM = "SYSTEM", _("System Notification")
        REMINDER = "REMINDER", _("Reminder")
        BUDGET_EXCEEDED = "BUDGET_EXCEEDED", _("Budget Exceeded")
        RECURRING_EXPENSE = "RECURRING_EXPENSE", _("Recurring Expense")
        THRESHOLD_REACHED = "THRESHOLD_REACHED", _("Threshold Reached")
        CUSTOM = "CUSTOM", _("Custom Notification")

    class Priority(models.TextChoices):
        """Notification priority choices."""

        LOW = "LOW", _("Low")
        MEDIUM = "MEDIUM", _("Medium")
        HIGH = "HIGH", _("High")
        URGENT = "URGENT", _("Urgent")

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
        verbose_name=_("User"),
    )
    title = models.CharField(_("Title"), max_length=255)
    message = models.TextField(_("Message"))
    notification_type = models.CharField(
        _("Type"),
        max_length=50,
        choices=NotificationTypes.choices,
        default=NotificationTypes.SYSTEM,
    )
    priority = models.CharField(
        _("Priority"), max_length=20, choices=Priority.choices, default=Priority.MEDIUM
    )
    is_read = models.BooleanField(_("Read"), default=False)
    read_at = models.DateTimeField(_("Read At"), null=True, blank=True)
    action_url = models.CharField(
        _("Action URL"),
        max_length=255,
        blank=True,
        help_text=_("URL for any action associated with this notification"),
    )
    data = models.JSONField(
        _("Additional Data"),
        default=dict,
        blank=True,
        help_text=_("Additional context for the notification"),
    )
    expires_at = models.DateTimeField(
        _("Expires At"),
        null=True,
        blank=True,
        help_text=_("When this notification should expire"),
    )
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)

    class Meta:
        """
        Meta options for Notification model.
        """

        verbose_name = _("Notification")
        verbose_name_plural = _("Notifications")
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "is_read"]),
            models.Index(fields=["notification_type"]),
            models.Index(fields=["created_at"]),
        ]

    def __str__(self) -> str:
        """String representation of the notification."""
        return f"{self.title} - {self.notification_type} ({self.user.username})"

    def mark_as_read(self) -> None:
        """Mark the notification as read."""
        from django.utils import timezone

        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=["is_read", "read_at"])

    def mark_as_unread(self) -> None:
        """Mark the notification as unread."""
        if self.is_read:
            self.is_read = False
            self.read_at = None
            self.save(update_fields=["is_read", "read_at"])

    @property
    def is_expired(self) -> bool:
        """Check if the notification has expired."""
        from django.utils import timezone

        if self.expires_at:
            return timezone.now() > self.expires_at
        return False

    @property
    def age_in_minutes(self) -> int:
        """Get the age of the notification in minutes."""
        from django.utils import timezone

        delta = timezone.now() - self.created_at
        return int(delta.total_seconds() / 60)


class NotificationPreference(models.Model):
    """
    Model for user notification preferences.
    """

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_preferences",
        verbose_name=_("User"),
    )
    email_notifications = models.BooleanField(_("Email Notifications"), default=True)
    push_notifications = models.BooleanField(_("Push Notifications"), default=True)
    notification_types = models.JSONField(
        _("Enabled Notification Types"),
        default=list,
        help_text=_("List of enabled notification types"),
    )
    quiet_hours_start = models.TimeField(_("Quiet Hours Start"), null=True, blank=True)
    quiet_hours_end = models.TimeField(_("Quiet Hours End"), null=True, blank=True)
    minimum_priority = models.CharField(
        _("Minimum Priority"),
        max_length=20,
        choices=Notification.Priority.choices,
        default=Notification.Priority.LOW,
    )
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)

    class Meta:
        """
        Meta options for NotificationPreference model.
        """

        verbose_name = _("Notification Preference")
        verbose_name_plural = _("Notification Preferences")

    def __str__(self) -> str:
        """String representation of the notification preferences."""
        return f"Notification Preferences for {self.user.username}"

    def can_notify(self, notification_type: str, priority: str) -> bool:
        """
        Check if a notification can be sent based on preferences.

        Args:
            notification_type: Type of notification
            priority: Priority level of notification

        Returns:
            bool: Whether notification can be sent
        """
        from django.utils import timezone

        # Check if notification type is enabled
        if notification_type not in self.notification_types:
            return False

        # Check priority level
        priority_levels = dict(Notification.Priority.choices)
        if list(priority_levels.keys()).index(priority) < list(
            priority_levels.keys()
        ).index(self.minimum_priority):
            return False

        # Check quiet hours
        if self.quiet_hours_start and self.quiet_hours_end:
            current_time = timezone.localtime().time()
            if self.quiet_hours_start <= current_time <= self.quiet_hours_end:
                return priority == Notification.Priority.URGENT

        return True
