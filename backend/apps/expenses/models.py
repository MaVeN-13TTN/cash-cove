"""
Models for the expenses application.
"""

from decimal import Decimal
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator
from django.utils.translation import gettext_lazy as _
from apps.budgets.models import Budget


class Expense(models.Model):
    """
    Model for tracking user expenses.
    """

    class CategoryChoices(models.TextChoices):
        """Default expense category choices."""

        FOOD = "FOOD", _("Food & Dining")
        TRANSPORT = "TRANSPORT", _("Transportation")
        HOUSING = "HOUSING", _("Housing & Utilities")
        HEALTHCARE = "HEALTHCARE", _("Healthcare")
        ENTERTAINMENT = "ENTERTAINMENT", _("Entertainment")
        SHOPPING = "SHOPPING", _("Shopping")
        EDUCATION = "EDUCATION", _("Education")
        OTHER = "OTHER", _("Other")

    class PaymentMethod(models.TextChoices):
        """Payment method choices."""

        CASH = "CASH", _("Cash")
        CREDIT_CARD = "CREDIT_CARD", _("Credit Card")
        DEBIT_CARD = "DEBIT_CARD", _("Debit Card")
        BANK_TRANSFER = "BANK_TRANSFER", _("Bank Transfer")
        MOBILE_PAYMENT = "MOBILE_PAYMENT", _("Mobile Payment")
        OTHER = "OTHER", _("Other")

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="expenses",
        verbose_name=_("User"),
    )
    title = models.CharField(
        _("Title"), max_length=255, help_text=_("Brief description of the expense")
    )
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
    date = models.DateField(_("Date"))
    payment_method = models.CharField(
        _("Payment Method"),
        max_length=50,
        choices=PaymentMethod.choices,
        default=PaymentMethod.CASH,
    )
    budget = models.ForeignKey(
        Budget,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="expenses",
        verbose_name=_("Budget"),
    )
    notes = models.TextField(
        _("Notes"), blank=True, help_text=_("Additional details about the expense")
    )
    receipt_image = models.ImageField(
        _("Receipt Image"), upload_to="receipts/%Y/%m/", null=True, blank=True
    )
    location = models.CharField(
        _("Location"),
        max_length=255,
        blank=True,
        help_text=_("Where the expense was incurred"),
    )
    is_recurring = models.BooleanField(
        _("Is Recurring"),
        default=False,
        help_text=_("Whether this is a recurring expense"),
    )
    tags = models.JSONField(
        _("Tags"), default=list, blank=True, help_text=_("Custom tags for the expense")
    )
    metadata = models.JSONField(
        _("Metadata"),
        default=dict,
        blank=True,
        help_text=_("Additional metadata for the expense"),
    )
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)

    class Meta:
        """
        Meta options for Expense model.
        """

        verbose_name = _("Expense")
        verbose_name_plural = _("Expenses")
        ordering = ["-date", "-created_at"]
        indexes = [
            models.Index(fields=["user", "category"]),
            models.Index(fields=["date"]),
            models.Index(fields=["is_recurring"]),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(amount__gt=0), name="expense_amount_positive"
            )
        ]

    def __str__(self) -> str:
        """String representation of the expense."""
        return f"{self.title} - {self.amount} ({self.date})"

    def clean(self) -> None:
        """
        Custom validation for Expense model.
        """
        from django.core.exceptions import ValidationError
        from django.utils import timezone

        if self.date and self.date > timezone.now().date():
            raise ValidationError(_("Expense date cannot be in the future."))

    def save(self, *args, **kwargs):
        """
        Override save to perform custom validation.
        """
        self.full_clean()
        super().save(*args, **kwargs)

    @property
    def month_year(self) -> str:
        """Get month and year of the expense."""
        return self.date.strftime("%B %Y")

    @property
    def is_recent(self) -> bool:
        """Check if expense is from last 30 days."""
        from django.utils import timezone

        return (timezone.now().date() - self.date).days <= 30

    def get_budget_status(self) -> dict:
        """
        Get budget status for this expense's category.

        Returns:
            dict: Budget status information
        """
        if not self.budget:
            return {"has_budget": False, "budget_name": None, "utilization": None}

        return {
            "has_budget": True,
            "budget_name": self.budget.name,
            "utilization": self.budget.utilization_percentage,
        }

    def get_category_info(self) -> dict:
        """
        Get category display information.

        Returns:
            dict: Category information
        """
        return {
            "name": self.get_category_display(),
            "icon": self.metadata.get("category_icon", "default-icon"),
            "color": self.metadata.get("category_color", "#000000"),
        }
