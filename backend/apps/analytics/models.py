"""
Models for the analytics application.
"""

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _


class SpendingAnalytics(models.Model):
    """
    Model to store aggregated spending analytics data.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="spending_analytics",
    )
    date = models.DateField(_("Date"))
    category = models.CharField(_("Category"), max_length=100)
    total_amount = models.DecimalField(
        _("Total Amount"), max_digits=12, decimal_places=2
    )
    transaction_count = models.PositiveIntegerField(_("Transaction Count"))
    average_amount = models.DecimalField(
        _("Average Amount"), max_digits=12, decimal_places=2
    )
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)

    class Meta:
        """
        Meta options for SpendingAnalytics model.
        """

        verbose_name = _("Spending Analytics")
        verbose_name_plural = _("Spending Analytics")
        unique_together = ("user", "date", "category")
        indexes = [
            models.Index(fields=["user", "date"]),
            models.Index(fields=["category"]),
        ]

    def __str__(self) -> str:
        """String representation of the spending analytics."""
        return f"{self.user.username} - {self.category} - {self.date}"


class BudgetUtilization(models.Model):
    """
    Model to track budget utilization metrics.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="budget_utilization",
    )
    category = models.CharField(_("Category"), max_length=100)
    month = models.DateField(_("Month"))
    budget_amount = models.DecimalField(
        _("Budget Amount"), max_digits=12, decimal_places=2
    )
    spent_amount = models.DecimalField(
        _("Spent Amount"), max_digits=12, decimal_places=2
    )
    utilization_percentage = models.DecimalField(
        _("Utilization Percentage"), max_digits=5, decimal_places=2
    )
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)

    class Meta:
        """
        Meta options for BudgetUtilization model.
        """

        verbose_name = _("Budget Utilization")
        verbose_name_plural = _("Budget Utilizations")
        unique_together = ("user", "category", "month")
        indexes = [
            models.Index(fields=["user", "month"]),
            models.Index(fields=["category"]),
        ]

    def __str__(self) -> str:
        """String representation of the budget utilization."""
        return f"{self.user.username} - {self.category} - {self.month}"
