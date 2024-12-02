"""
Models for the shared expenses application.
"""

from decimal import Decimal
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator
from django.utils.translation import gettext_lazy as _
from apps.expenses.models import Expense


class SharedExpense(models.Model):
    """
    Model for tracking shared expenses between users.
    """

    class SplitMethod(models.TextChoices):
        """Split method choices."""

        EQUAL = "EQUAL", _("Split Equally")
        PERCENTAGE = "PERCENTAGE", _("Split by Percentage")
        CUSTOM = "CUSTOM", _("Custom Split")
        SHARES = "SHARES", _("Split by Shares")

    class Status(models.TextChoices):
        """Status choices for shared expense."""

        PENDING = "PENDING", _("Pending")
        ACTIVE = "ACTIVE", _("Active")
        SETTLED = "SETTLED", _("Settled")
        CANCELLED = "CANCELLED", _("Cancelled")
        DISPUTED = "DISPUTED", _("Disputed")

    creator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="created_shared_expenses",
        verbose_name=_("Creator"),
    )
    title = models.CharField(_("Title"), max_length=255)
    description = models.TextField(_("Description"), blank=True)
    amount = models.DecimalField(
        _("Total Amount"),
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0.01"))],
    )
    split_method = models.CharField(
        _("Split Method"),
        max_length=20,
        choices=SplitMethod.choices,
        default=SplitMethod.EQUAL,
    )
    status = models.CharField(
        _("Status"), max_length=20, choices=Status.choices, default=Status.PENDING
    )
    expense = models.OneToOneField(
        Expense,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="shared_expense",
        verbose_name=_("Related Expense"),
    )
    due_date = models.DateField(_("Due Date"), null=True, blank=True)
    category = models.CharField(
        _("Category"),
        max_length=100,
        choices=Expense.CategoryChoices.choices,
        default=Expense.CategoryChoices.OTHER,
    )
    reminder_frequency = models.IntegerField(
        _("Reminder Frequency (days)"),
        default=7,
        help_text=_("Frequency of payment reminders in days"),
    )
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)
    metadata = models.JSONField(_("Metadata"), default=dict, blank=True)

    class Meta:
        """
        Meta options for SharedExpense model.
        """

        verbose_name = _("Shared Expense")
        verbose_name_plural = _("Shared Expenses")
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["creator"]),
            models.Index(fields=["status"]),
            models.Index(fields=["created_at"]),
            models.Index(fields=["creator", "status"]),
            models.Index(fields=["creator", "created_at"]),
        ]

    def __str__(self) -> str:
        """String representation of the shared expense."""
        return f"{self.title} - {self.amount} ({self.get_status_display()})"

    @property
    def is_settled(self) -> bool:
        """Check if expense is settled."""
        return self.status == self.Status.SETTLED

    @property
    def total_shares(self) -> int:
        """Get total number of shares."""
        if self.split_method == self.SplitMethod.SHARES:
            return sum(share.shares for share in self.participant_shares.all())
        return len(self.participant_shares.all())

    @property
    def total_paid(self) -> Decimal:
        """Get total amount paid."""
        return sum(share.amount_paid for share in self.participant_shares.all())

    @property
    def remaining_amount(self) -> Decimal:
        """Get remaining amount to be paid."""
        return self.amount - self.total_paid


class ParticipantShare(models.Model):
    """
    Model for tracking individual shares in a shared expense.
    """

    shared_expense = models.ForeignKey(
        SharedExpense,
        on_delete=models.CASCADE,
        related_name="participant_shares",
        verbose_name=_("Shared Expense"),
    )
    participant = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="expense_shares",
        verbose_name=_("Participant"),
    )
    percentage = models.DecimalField(
        _("Percentage Share"),
        max_digits=5,
        decimal_places=2,
        default=Decimal("0.00"),
        validators=[MinValueValidator(Decimal("0.00"))],
    )
    shares = models.PositiveIntegerField(
        _("Number of Shares"), default=1, validators=[MinValueValidator(1)]
    )
    amount = models.DecimalField(
        _("Share Amount"),
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0.01"))],
    )
    amount_paid = models.DecimalField(
        _("Amount Paid"),
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00"),
        validators=[MinValueValidator(Decimal("0.00"))],
    )
    notes = models.TextField(_("Notes"), blank=True)
    last_reminded = models.DateTimeField(_("Last Reminded"), null=True, blank=True)
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)

    class Meta:
        """
        Meta options for ParticipantShare model.
        """

        verbose_name = _("Participant Share")
        verbose_name_plural = _("Participant Shares")
        unique_together = ("shared_expense", "participant")
        ordering = ["created_at"]
        indexes = [
            models.Index(fields=["shared_expense", "participant"]),
        ]

    def __str__(self) -> str:
        """String representation of the participant share."""
        return f"{self.participant.username}'s share in " f"{self.shared_expense.title}"

    @property
    def is_paid(self) -> bool:
        """Check if share is fully paid."""
        return self.amount_paid >= self.amount

    @property
    def remaining_amount(self) -> Decimal:
        """Get remaining amount to be paid."""
        return max(Decimal("0.00"), self.amount - self.amount_paid)

    def record_payment(self, amount: Decimal) -> None:
        """
        Record a payment towards this share.

        Args:
            amount: Amount being paid
        """
        self.amount_paid = min(self.amount, self.amount_paid + amount)
        self.save(update_fields=["amount_paid", "updated_at"])
