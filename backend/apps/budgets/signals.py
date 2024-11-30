# apps/budgets/signals.py
"""
Signal handlers for budgets application.
"""

from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.utils import timezone
from .models import Budget
from apps.notifications.services import NotificationService


@receiver(pre_save, sender=Budget)
def check_budget_dates(sender, instance, **kwargs):
    """
    Signal to validate budget dates before saving.

    Args:
        sender: The model class
        instance: The actual budget instance
        **kwargs: Additional keyword arguments
    """
    if instance.end_date and instance.start_date:
        if instance.end_date < instance.start_date:
            raise ValueError("End date cannot be before start date")


@receiver(post_save, sender=Budget)
def notify_budget_creation(sender, instance, created, **kwargs):
    """
    Signal to send notification when a new budget is created.

    Args:
        sender: The model class
        instance: The actual budget instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if created:
        NotificationService.send_budget_creation_notification(instance)


@receiver(post_save, sender=Budget)
def handle_recurring_budget(sender, instance, created, **kwargs):
    """
    Signal to handle recurring budget logic.

    Args:
        sender: The model class
        instance: The actual budget instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if not created and instance.is_active and instance.recurrence != "NONE":
        today = timezone.now().date()

        # Check if the budget is ending and needs to be renewed
        if instance.end_date == today:
            Budget.objects.create(
                user=instance.user,
                name=instance.name,
                amount=instance.amount,
                category=instance.category,
                start_date=today + timezone.timedelta(days=1),
                end_date=instance.calculate_next_end_date(),
                recurrence=instance.recurrence,
                notification_threshold=instance.notification_threshold,
                description=f"Auto-renewed from budget {instance.id}",
                is_active=True,
            )
