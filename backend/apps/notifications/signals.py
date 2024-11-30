"""
Signal handlers for notifications application.
"""

from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver
from django.utils import timezone
from apps.budgets.models import Budget
from apps.expenses.models import Expense
from .models import Notification, NotificationPreference
from .services.notifications_service import NotificationService


@receiver(post_save, sender=Budget)
def handle_budget_notifications(sender, instance, created, **kwargs):
    """
    Signal handler for budget-related notifications.

    Args:
        sender: The model class
        instance: The actual budget instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if created:
        # Notification for new budget creation
        NotificationService.create_notification(
            user_id=instance.user.id,
            title=f"New Budget Created: {instance.name}",
            message=(
                f"A new budget of {instance.amount} has been created "
                f"for {instance.category}."
            ),
            notification_type=Notification.NotificationTypes.BUDGET_ALERT,
            priority=Notification.Priority.MEDIUM,
            data={"budget_id": instance.id},
        )
    else:
        # Check if budget utilization has changed significantly
        if instance.utilization_percentage >= instance.notification_threshold:
            NotificationService.send_budget_threshold_notification(instance)


@receiver(post_save, sender=Expense)
def handle_expense_notifications(sender, instance, created, **kwargs):
    """
    Signal handler for expense-related notifications.

    Args:
        sender: The model class
        instance: The actual expense instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if created:
        # High value expense notification
        if instance.amount >= 1000:  # Threshold for high value
            NotificationService.create_notification(
                user_id=instance.user.id,
                title="High Value Expense Recorded",
                message=(
                    f"A high value expense of {instance.amount} "
                    f"has been recorded for {instance.category}."
                ),
                notification_type=Notification.NotificationTypes.EXPENSE_ALERT,
                priority=Notification.Priority.HIGH,
                data={"expense_id": instance.id},
            )

        # Check budget impact
        if instance.budget:
            if (
                instance.budget.utilization_percentage
                >= instance.budget.notification_threshold
            ):
                NotificationService.send_budget_threshold_notification(instance.budget)


@receiver(post_save, sender=NotificationPreference)
def handle_preference_changes(sender, instance, created, **kwargs):
    """
    Signal handler for notification preference changes.

    Args:
        sender: The model class
        instance: The actual preference instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if not created:
        NotificationService.create_notification(
            user_id=instance.user.id,
            title="Notification Settings Updated",
            message="Your notification preferences have been updated.",
            notification_type=Notification.NotificationTypes.SYSTEM,
            priority=Notification.Priority.LOW,
        )


@receiver(pre_delete, sender=Notification)
def handle_notification_cleanup(sender, instance, **kwargs):
    """
    Signal handler for notification deletion cleanup.

    Args:
        sender: The model class
        instance: The actual notification instance
        **kwargs: Additional keyword arguments
    """
    # Add any cleanup logic here if needed
    pass


def create_default_preferences(user_id):
    """
    Create default notification preferences for a user.

    Args:
        user_id: The ID of the user
    """
    NotificationPreference.objects.get_or_create(
        user_id=user_id,
        defaults={
            "email_notifications": True,
            "push_notifications": True,
            "notification_types": [
                Notification.NotificationTypes.BUDGET_ALERT,
                Notification.NotificationTypes.EXPENSE_ALERT,
                Notification.NotificationTypes.SYSTEM,
                Notification.NotificationTypes.THRESHOLD_REACHED,
            ],
            "minimum_priority": Notification.Priority.LOW,
        },
    )


@receiver(post_save, sender="users.User")
def create_user_preferences(sender, instance, created, **kwargs):
    """
    Signal handler to create notification preferences for new users.

    Args:
        sender: The model class
        instance: The actual user instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if created:
        create_default_preferences(instance.id)
