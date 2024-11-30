"""
Service layer for shared expenses operations.
"""

from datetime import datetime, timedelta
from decimal import Decimal
from typing import Dict, List, Optional
from django.db.models import Q, Sum, Count, Avg
from django.utils import timezone
from django.db import transaction
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

from apps.notifications.services import NotificationService
from apps.expenses.models import Expense
from ..models import SharedExpense, ParticipantShare


class SharedExpenseService:
    """
    Service class for handling shared expense operations.
    """

    @staticmethod
    def create_shared_expense(data: Dict) -> SharedExpense:
        """
        Create a new shared expense.

        Args:
            data: Dictionary containing shared expense data

        Returns:
            SharedExpense: Created shared expense instance
        """
        with transaction.atomic():
            # Create the base expense if provided
            expense_data = data.pop("expense_data", None)
            if expense_data:
                expense = Expense.objects.create(**expense_data)
                data["expense"] = expense

            shared_expense = SharedExpense.objects.create(**data)

            # Send notifications to participants
            for share in shared_expense.participant_shares.all():
                NotificationService.create_notification(
                    user_id=share.participant.id,
                    title=_("New Shared Expense"),
                    message=_(
                        f"You've been added to a shared expense: {shared_expense.title}"
                    ),
                    notification_type="SHARED_EXPENSE",
                    data={"shared_expense_id": shared_expense.id},
                )

            return shared_expense

    @staticmethod
    def update_shared_expense(
        shared_expense: SharedExpense, data: Dict
    ) -> SharedExpense:
        """
        Update a shared expense.

        Args:
            shared_expense: SharedExpense instance to update
            data: Dictionary containing update data

        Returns:
            SharedExpense: Updated shared expense instance
        """
        with transaction.atomic():
            # Update the expense if exists
            if shared_expense.expense and "expense_data" in data:
                expense_data = data.pop("expense_data")
                for key, value in expense_data.items():
                    setattr(shared_expense.expense, key, value)
                shared_expense.expense.save()

            # Update shared expense fields
            for key, value in data.items():
                setattr(shared_expense, key, value)
            shared_expense.save()

            if shared_expense.status == SharedExpense.Status.CANCELLED:
                # Notify all participants
                for share in shared_expense.participant_shares.all():
                    NotificationService.create_notification(
                        user_id=share.participant.id,
                        title=_("Shared Expense Cancelled"),
                        message=_(
                            f"Shared expense '{shared_expense.title}' has been cancelled"
                        ),
                        notification_type="SHARED_EXPENSE",
                        data={"shared_expense_id": shared_expense.id},
                    )

            return shared_expense

    @staticmethod
    def get_user_shared_expenses(
        user_id: int,
        status: Optional[str] = None,
        include_participated: bool = True,
        category: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> List[SharedExpense]:
        """
        Get shared expenses for a user.

        Args:
            user_id: User ID
            status: Optional status filter
            include_participated: Include expenses where user is participant
            category: Optional category filter
            start_date: Optional start date filter
            end_date: Optional end date filter

        Returns:
            List[SharedExpense]: List of shared expenses
        """
        query = Q(creator_id=user_id)
        if include_participated:
            query |= Q(participant_shares__participant_id=user_id)

        if status:
            query &= Q(status=status)

        if category:
            query &= Q(category=category)

        if start_date:
            query &= Q(created_at__gte=start_date)

        if end_date:
            query &= Q(created_at__lte=end_date)

        return SharedExpense.objects.filter(query).distinct()

    @staticmethod
    def record_payment(
        share_id: int, amount: Decimal, notes: str = ""
    ) -> ParticipantShare:
        """
        Record a payment for a participant share.

        Args:
            share_id: ID of the participant share
            amount: Amount being paid
            notes: Optional payment notes

        Returns:
            ParticipantShare: Updated share instance
        """
        with transaction.atomic():
            share = ParticipantShare.objects.select_for_update().get(id=share_id)

            if amount > share.remaining_amount:
                raise ValidationError(
                    _("Payment amount cannot exceed remaining balance.")
                )

            share.record_payment(amount)
            share.notes = notes
            share.save()

            # Check if expense is fully settled
            shared_expense = share.shared_expense
            if all(s.is_paid for s in shared_expense.participant_shares.all()):
                shared_expense.status = SharedExpense.Status.SETTLED
                shared_expense.save()

                # Notify creator
                NotificationService.create_notification(
                    user_id=shared_expense.creator_id,
                    title=_("Shared Expense Settled"),
                    message=_(
                        f"Shared expense '{shared_expense.title}' has been fully settled"
                    ),
                    notification_type="SHARED_EXPENSE",
                    data={"shared_expense_id": shared_expense.id},
                )

            return share

    @staticmethod
    def send_reminders() -> int:
        """
        Send reminders for pending payments.

        Returns:
            int: Number of reminders sent
        """
        current_time = timezone.now()
        reminder_count = 0

        shares = ParticipantShare.objects.filter(
            shared_expense__status=SharedExpense.Status.ACTIVE, is_paid=False
        ).select_related("shared_expense")

        for share in shares:
            # Check if reminder is due based on frequency
            if not share.last_reminded or (
                current_time - share.last_reminded
            ) >= timedelta(days=share.shared_expense.reminder_frequency):

                NotificationService.create_notification(
                    user_id=share.participant_id,
                    title=_("Payment Reminder"),
                    message=_(
                        f"You have a pending payment of {share.remaining_amount} "
                        f"for '{share.shared_expense.title}'"
                    ),
                    notification_type="PAYMENT_REMINDER",
                    priority="HIGH",
                    data={"shared_expense_id": share.shared_expense.id},
                )

                share.last_reminded = current_time
                share.save(update_fields=["last_reminded"])
                reminder_count += 1

        return reminder_count

    @staticmethod
    def get_user_summary(user_id: int, period: Optional[str] = None) -> Dict:
        """
        Get summary of user's shared expenses.

        Args:
            user_id: User ID
            period: Optional period filter (month, year)

        Returns:
            Dict: Summary information
        """
        query = Q()
        if period == "month":
            query = Q(created_at__month=timezone.now().month)
        elif period == "year":
            query = Q(created_at__year=timezone.now().year)

        # Get created expenses
        created_expenses = SharedExpense.objects.filter(creator_id=user_id).filter(
            query
        )

        created_total = created_expenses.aggregate(total=Sum("amount"))[
            "total"
        ] or Decimal("0")

        # Get participated expenses
        participated_shares = ParticipantShare.objects.filter(
            participant_id=user_id
        ).filter(query)

        owed_total = participated_shares.aggregate(total=Sum("amount"))[
            "total"
        ] or Decimal("0")

        paid_total = participated_shares.aggregate(total=Sum("amount_paid"))[
            "total"
        ] or Decimal("0")

        return {
            "total_created": created_total,
            "total_owed": owed_total,
            "total_paid": paid_total,
            "remaining_balance": owed_total - paid_total,
            "active_expenses": participated_shares.filter(
                shared_expense__status=SharedExpense.Status.ACTIVE
            ).count(),
            "settled_expenses": participated_shares.filter(
                shared_expense__status=SharedExpense.Status.SETTLED
            ).count(),
            "average_share": participated_shares.aggregate(avg=Avg("amount"))["avg"]
            or Decimal("0"),
            "most_common_category": created_expenses.values("category")
            .annotate(count=Count("id"))
            .order_by("-count")
            .first(),
        }

    @staticmethod
    def get_expense_statistics(shared_expense_id: int) -> Dict:
        """
        Get detailed statistics for a shared expense.

        Args:
            shared_expense_id: ID of the shared expense

        Returns:
            Dict: Statistical information
        """
        shared_expense = SharedExpense.objects.get(id=shared_expense_id)
        shares = shared_expense.participant_shares.all()

        return {
            "total_amount": shared_expense.amount,
            "total_paid": shared_expense.total_paid,
            "remaining_amount": shared_expense.remaining_amount,
            "participant_count": shares.count(),
            "paid_count": shares.filter(is_paid=True).count(),
            "average_share": shared_expense.amount / shares.count(),
            "payment_progress": (
                shared_expense.total_paid / shared_expense.amount * 100
                if shared_expense.amount > 0
                else Decimal("0")
            ),
            "days_active": (
                timezone.now().date() - shared_expense.created_at.date()
            ).days,
            "days_until_due": (
                (shared_expense.due_date - timezone.now().date()).days
                if shared_expense.due_date
                else None
            ),
        }

    @staticmethod
    def get_user_balance_sheet(user_id: int) -> Dict:
        """
        Get detailed balance sheet for a user.

        Args:
            user_id: User ID

        Returns:
            Dict: Balance sheet information
        """
        # Amounts owed to user
        created_expenses = SharedExpense.objects.filter(
            creator_id=user_id, status=SharedExpense.Status.ACTIVE
        )
        owed_to_user = (
            ParticipantShare.objects.filter(shared_expense__in=created_expenses)
            .exclude(participant_id=user_id)
            .aggregate(total=Sum("amount"), paid=Sum("amount_paid"))
        )

        # Amounts user owes
        user_shares = ParticipantShare.objects.filter(
            participant_id=user_id, shared_expense__status=SharedExpense.Status.ACTIVE
        ).exclude(shared_expense__creator_id=user_id)

        return {
            "owed_to_user": {
                "total": owed_to_user["total"] or Decimal("0"),
                "received": owed_to_user["paid"] or Decimal("0"),
                "pending": (owed_to_user["total"] or Decimal("0"))
                - (owed_to_user["paid"] or Decimal("0")),
            },
            "user_owes": {
                "total": user_shares.aggregate(total=Sum("amount"))["total"]
                or Decimal("0"),
                "paid": user_shares.aggregate(paid=Sum("amount_paid"))["paid"]
                or Decimal("0"),
                "pending": user_shares.aggregate(pending=Sum("remaining_amount"))[
                    "pending"
                ]
                or Decimal("0"),
            },
            "by_category": user_shares.values("shared_expense__category").annotate(
                total=Sum("amount"),
                paid=Sum("amount_paid"),
                pending=Sum("remaining_amount"),
            ),
        }
