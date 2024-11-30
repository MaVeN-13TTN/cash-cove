"""
Signal handlers for analytics app.
"""

from decimal import Decimal
from django.db.models.signals import post_save
from django.db import models
from django.dispatch import receiver
from django.utils import timezone
from apps.expenses.models import Expense
from .models import SpendingAnalytics, BudgetUtilization
from .services.analytics_service import AnalyticsService


@receiver(post_save, sender=Expense)
def update_analytics_on_expense(sender, instance, created, **kwargs):
    """
    Update analytics when an expense is created or updated.

    Args:
        sender: The model class (Expense)
        instance: The actual expense instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if created or instance.amount != instance.amount:  # Check if amount changed
        # Get or create analytics for the day
        analytics, _ = SpendingAnalytics.objects.get_or_create(
            user=instance.user,
            date=instance.date,
            category=instance.category,
            defaults={
                "total_amount": Decimal("0"),
                "transaction_count": 0,
                "average_amount": Decimal("0"),
            },
        )

        # Calculate new totals
        expenses_for_day = Expense.objects.filter(
            user=instance.user, date=instance.date, category=instance.category
        )

        total_amount = expenses_for_day.aggregate(total=models.Sum("amount"))[
            "total"
        ] or Decimal("0")

        transaction_count = expenses_for_day.count()
        average_amount = (
            total_amount / transaction_count if transaction_count > 0 else Decimal("0")
        )

        # Update analytics
        analytics.total_amount = total_amount
        analytics.transaction_count = transaction_count
        analytics.average_amount = average_amount
        analytics.save()

        # Update budget utilization
        AnalyticsService.update_budget_utilization(
            user_id=instance.user.id, month=instance.date.replace(day=1)
        )
