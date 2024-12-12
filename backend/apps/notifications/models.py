"""
Models for the notifications application.
"""

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError

User = get_user_model()

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
    """User notification preferences."""

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='notification_preferences'
    )
    
    # Individual notification type toggles
    budget_alerts = models.BooleanField(default=True)
    expense_alerts = models.BooleanField(default=True)
    system_notifications = models.BooleanField(default=True)
    reminders = models.BooleanField(default=True)
    budget_exceeded_alerts = models.BooleanField(default=True)
    recurring_expense_alerts = models.BooleanField(default=True)
    threshold_alerts = models.BooleanField(default=True)
    
    # Delivery preferences
    email_notifications = models.BooleanField(default=True)
    push_notifications = models.BooleanField(default=True)
    
    # Frequency settings
    FREQUENCY_CHOICES = [
        ('immediate', 'Immediate'),
        ('daily', 'Daily Digest'),
        ('weekly', 'Weekly Digest'),
    ]
    notification_frequency = models.CharField(
        max_length=20,
        choices=FREQUENCY_CHOICES,
        default='immediate'
    )
    
    # Quiet hours
    quiet_hours_start = models.TimeField(null=True, blank=True)
    quiet_hours_end = models.TimeField(null=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Notification Preference'
        verbose_name_plural = 'Notification Preferences'
    
    def clean(self):
        """Validate notification preferences."""
        if self.quiet_hours_start and not self.quiet_hours_end:
            raise ValidationError(_('Both quiet hours start and end must be set.'))
        if self.quiet_hours_end and not self.quiet_hours_start:
            raise ValidationError(_('Both quiet hours start and end must be set.'))
    
    def save(self, *args, **kwargs):
        """Override save to run full_clean."""
        self.full_clean()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f'Notification preferences for {self.user}'
