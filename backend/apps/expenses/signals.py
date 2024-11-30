"""
Signal handlers for expenses application.
"""

from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.db.models import Sum
from django.utils import timezone
from .models import Expense
from apps.notifications.services import NotificationService


@receiver(pre_save, sender=Expense)
def check_expense_budget(sender, instance, **kwargs):
    """
    Signal to validate expense against budget before saving.

    Args:
        sender: The model class
        instance: The actual expense instance
        **kwargs: Additional keyword arguments
    """
    from django.core.exceptions import ValidationError

    if instance.budget:
        # Check if expense date falls within budget period
        if not (
            instance.budget.start_date <= instance.date <= instance.budget.end_date
        ):
            raise ValidationError("Expense date must fall within the budget period.")

        # Calculate current total excluding this expense if it's being updated
        current_total = (
            instance.budget.expenses.exclude(id=instance.id).aggregate(
                total=Sum("amount")
            )["total"]
            or 0
        )

        # Check if this expense would exceed budget
        if (current_total + instance.amount) > instance.budget.amount:
            NotificationService.send_budget_exceeded_notification(instance.budget)


@receiver(post_save, sender=Expense)
def update_budget_utilization(sender, instance, created, **kwargs):
    """
    Signal to update budget utilization after expense save.

    Args:
        sender: The model class
        instance: The actual expense instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if instance.budget:
        total_expenses = (
            instance.budget.expenses.aggregate(total=Sum("amount"))["total"] or 0
        )

        utilization_percentage = (total_expenses / instance.budget.amount) * 100

        if utilization_percentage >= instance.budget.notification_threshold:
            NotificationService.send_budget_threshold_notification(instance.budget)


@receiver(post_save, sender=Expense)
def handle_recurring_expense(sender, instance, created, **kwargs):
    """
    Signal to handle recurring expense logic.

    Args:
        sender: The model class
        instance: The actual expense instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if created and instance.is_recurring:
        # Create next recurring expense based on metadata
        recurrence_type = instance.metadata.get("recurrence_type")
        if recurrence_type:
            from datetime import timedelta

            if recurrence_type == "DAILY":
                next_date = instance.date + timedelta(days=1)
            elif recurrence_type == "WEEKLY":
                next_date = instance.date + timedelta(days=7)
            elif recurrence_type == "MONTHLY":
                # Get the same day next month
                if instance.date.month == 12:
                    next_date = instance.date.replace(
                        year=instance.date.year + 1, month=1
                    )
                else:
                    next_date = instance.date.replace(month=instance.date.month + 1)
            elif recurrence_type == "YEARLY":
                next_date = instance.date.replace(year=instance.date.year + 1)
            else:
                return

            # Only create next expense if it's in the future
            if next_date > timezone.now().date():
                Expense.objects.create(
                    user=instance.user,
                    title=instance.title,
                    amount=instance.amount,
                    category=instance.category,
                    date=next_date,
                    payment_method=instance.payment_method,
                    budget=instance.budget,
                    notes=instance.notes,
                    location=instance.location,
                    is_recurring=True,
                    tags=instance.tags,
                    metadata=instance.metadata,
                )
