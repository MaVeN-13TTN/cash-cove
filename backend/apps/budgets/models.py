"""
Models for the budgets application.
"""

from datetime import date, timedelta
from decimal import Decimal
from typing import Optional
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from django.utils.translation import gettext_lazy as _


class Budget(models.Model):
    """
    Model for tracking user budgets.
    """

    class RecurrenceChoices(models.TextChoices):
        """Budget recurrence choices."""

        NONE = "NONE", _("No Recurrence")
        DAILY = "DAILY", _("Daily")
        WEEKLY = "WEEKLY", _("Weekly")
        MONTHLY = "MONTHLY", _("Monthly")
        YEARLY = "YEARLY", _("Yearly")

    class CategoryChoices(models.TextChoices):
        """Default budget category choices."""

        FOOD = "FOOD", _("Food & Dining")
        TRANSPORT = "TRANSPORT", _("Transportation")
        HOUSING = "HOUSING", _("Housing & Utilities")
        HEALTHCARE = "HEALTHCARE", _("Healthcare")
        ENTERTAINMENT = "ENTERTAINMENT", _("Entertainment")
        SHOPPING = "SHOPPING", _("Shopping")
        EDUCATION = "EDUCATION", _("Education")
        OTHER = "OTHER", _("Other")

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="budgets",
        verbose_name=_("User"),
    )
    name = models.CharField(_("Name"), max_length=100)
    amount = models.DecimalField(
        _("Amount"),
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0.01"))],
    )
    category = models.CharField(
        _("Category"),
        max_length=100,
        choices=CategoryChoices.choices,
        default=CategoryChoices.OTHER,
    )
    start_date = models.DateField(_("Start Date"))
    end_date = models.DateField(_("End Date"))
    recurrence = models.CharField(
        _("Recurrence"),
        max_length=10,
        choices=RecurrenceChoices.choices,
        default=RecurrenceChoices.NONE,
    )
    notification_threshold = models.DecimalField(
        _("Notification Threshold"),
        max_digits=5,
        decimal_places=2,
        default=80.00,
        help_text=_("Percentage at which to send notifications"),
        validators=[
            MinValueValidator(Decimal("0.01")),
            MaxValueValidator(Decimal("100.00")),
        ],
    )
    is_active = models.BooleanField(_("Active"), default=True)
    description = models.TextField(_("Description"), blank=True)
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)
    color = models.CharField(
        _("Color"),
        max_length=7,
        default="#3B82F6",  # Default blue color
        help_text=_("Hex color code for the budget display"),
    )
    notes = models.JSONField(
        _("Notes"),
        default=dict,
        blank=True,
        help_text=_("Additional metadata for the budget"),
    )

    class Meta:
        """
        Meta options for Budget model.
        """

        verbose_name = _("Budget")
        verbose_name_plural = _("Budgets")
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "category"]),
            models.Index(fields=["start_date", "end_date"]),
            models.Index(fields=["is_active", "recurrence"]),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(end_date__gte=models.F("start_date")),
                name="budget_end_date_gte_start_date",
            ),
            models.CheckConstraint(
                check=models.Q(amount__gt=0), name="budget_amount_positive"
            ),
        ]

    def __str__(self) -> str:
        """String representation of the budget."""
        return f"{self.name} - {self.category} ({self.start_date} to {self.end_date})"

    def clean(self) -> None:
        """
        Custom validation for Budget model.
        Ensures end_date is not before start_date.
        """
        from django.core.exceptions import ValidationError

        if self.end_date and self.start_date and self.end_date < self.start_date:
            raise ValidationError(_("End date must not be before start date."))

    def save(self, *args, **kwargs):
        """
        Override save to perform custom validation.
        """
        self.full_clean()
        super().save(*args, **kwargs)

    @property
    def is_expired(self) -> bool:
        """Check if the budget has expired."""
        return timezone.now().date() > self.end_date

    @property
    def remaining_amount(self) -> Decimal:
        """Calculate remaining budget amount."""
        from apps.expenses.models import Expense

        total_expenses = Expense.objects.filter(
            user=self.user,
            category=self.category,
            date__range=(self.start_date, self.end_date),
        ).aggregate(total=models.Sum("amount"))["total"] or Decimal("0")
        return self.amount - total_expenses

    @property
    def utilization_percentage(self) -> Decimal:
        """Calculate budget utilization percentage."""
        if self.amount == 0:
            return Decimal("0.00")
        utilized = self.amount - self.remaining_amount
        return (utilized / self.amount * 100).quantize(Decimal("0.01"))

    def calculate_next_end_date(self) -> date:
        """
        Calculate the end date for the next recurring period.
        """
        start_date = self.end_date + timedelta(days=1)

        if self.recurrence == self.RecurrenceChoices.DAILY:
            return start_date

        elif self.recurrence == self.RecurrenceChoices.WEEKLY:
            return start_date + timedelta(days=6)

        elif self.recurrence == self.RecurrenceChoices.MONTHLY:
            if start_date.month == 12:
                next_month = date(start_date.year + 1, 1, start_date.day)
            else:
                next_month = date(start_date.year, start_date.month + 1, start_date.day)
            return next_month - timedelta(days=1)

        elif self.recurrence == self.RecurrenceChoices.YEARLY:
            next_year = date(start_date.year + 1, start_date.month, start_date.day)
            return next_year - timedelta(days=1)

        return self.end_date

    @property
    def days_remaining(self) -> int:
        """Calculate number of days remaining in the budget period."""
        return (self.end_date - timezone.now().date()).days

    @property
    def daily_target(self) -> Decimal:
        """Calculate daily target amount for even spending."""
        total_days = (self.end_date - self.start_date).days + 1
        if total_days <= 0:
            return Decimal("0.00")
        return (self.amount / total_days).quantize(Decimal("0.01"))

    def get_category_display_data(self) -> dict:
        """Get category display information."""
        return {
            "name": self.get_category_display(),
            "color": self.color,
            "icon": self.notes.get("icon", "default-icon"),
        }

    def get_period_description(self) -> str:
        """Get human-readable period description."""
        if self.recurrence == self.RecurrenceChoices.NONE:
            return _("One-time budget")
        return f"{self.get_recurrence_display()} budget"

    def is_within_period(self, target_date: Optional[date] = None) -> bool:
        """
        Check if a date falls within the budget period.

        Args:
            target_date: Date to check, defaults to current date

        Returns:
            bool: True if date is within budget period
        """
        check_date = target_date or timezone.now().date()
        return self.start_date <= check_date <= self.end_date
