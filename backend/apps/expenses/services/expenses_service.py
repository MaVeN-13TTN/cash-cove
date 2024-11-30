"""
Service layer for expense operations.
"""

from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Dict, List, Optional
from django.db.models import Sum, Avg, Count, Q, F
from django.db.models.functions import TruncMonth, ExtractYear, ExtractMonth
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from ..models import Expense


class ExpenseService:
    """
    Service class for handling expense operations.
    """

    @staticmethod
    def create_recurring_expenses(
        expense_data: Dict, start_date: date, end_date: date, frequency: str
    ) -> List[Expense]:
        """
        Create recurring expenses.

        Args:
            expense_data: Base expense data
            start_date: Start date for recurrence
            end_date: End date for recurrence
            frequency: Frequency of recurrence

        Returns:
            List[Expense]: Created expenses
        """
        expenses = []
        current_date = start_date

        while current_date <= end_date:
            expense_data["date"] = current_date
            expense = Expense.objects.create(**expense_data)
            expenses.append(expense)

            # Calculate next date based on frequency
            if frequency == "DAILY":
                current_date += timedelta(days=1)
            elif frequency == "WEEKLY":
                current_date += timedelta(weeks=1)
            elif frequency == "MONTHLY":
                # Handle month increment
                if current_date.month == 12:
                    current_date = current_date.replace(
                        year=current_date.year + 1, month=1
                    )
                else:
                    current_date = current_date.replace(month=current_date.month + 1)
            else:  # YEARLY
                current_date = current_date.replace(year=current_date.year + 1)

        return expenses

    @staticmethod
    def get_expense_summary(
        user_id: int,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        category: Optional[str] = None,
    ) -> List[Dict]:
        """
        Get expense summary with aggregated data.

        Args:
            user_id: User ID
            start_date: Optional start date for filtering
            end_date: Optional end date for filtering
            category: Optional category for filtering

        Returns:
            List[Dict]: Summary data
        """
        query = Q(user_id=user_id)

        if start_date and end_date:
            query &= Q(date__range=(start_date, end_date))
        if category:
            query &= Q(category=category)

        return (
            Expense.objects.filter(query)
            .values("category")
            .annotate(
                total_amount=Sum("amount"),
                transaction_count=Count("id"),
                average_amount=Avg("amount"),
            )
            .order_by("-total_amount")
        )

    @staticmethod
    def get_monthly_trend(
        user_id: int, months: int = 12, category: Optional[str] = None
    ) -> List[Dict]:
        """
        Get monthly expense trends.

        Args:
            user_id: User ID
            months: Number of months to analyze
            category: Optional category filter

        Returns:
            List[Dict]: Monthly trend data
        """
        start_date = timezone.now().date() - timedelta(days=30 * months)
        query = Q(user_id=user_id, date__gte=start_date)

        if category:
            query &= Q(category=category)

        return (
            Expense.objects.filter(query)
            .annotate(month=TruncMonth("date"))
            .values("month")
            .annotate(
                total_amount=Sum("amount"),
                transaction_count=Count("id"),
                average_amount=Avg("amount"),
            )
            .order_by("month")
        )

    @staticmethod
    def get_category_distribution(
        user_id: int, start_date: Optional[date] = None, end_date: Optional[date] = None
    ) -> List[Dict]:
        """
        Get expense distribution by category.

        Args:
            user_id: User ID
            start_date: Optional start date
            end_date: Optional end date

        Returns:
            List[Dict]: Category distribution data
        """
        query = Q(user_id=user_id)
        if start_date and end_date:
            query &= Q(date__range=(start_date, end_date))

        total_expenses = Expense.objects.filter(query).aggregate(total=Sum("amount"))[
            "total"
        ] or Decimal("0")

        distribution = (
            Expense.objects.filter(query)
            .values("category")
            .annotate(
                total_amount=Sum("amount"),
                percentage=Sum("amount") * 100.0 / total_expenses,
            )
            .order_by("-total_amount")
        )

        return list(distribution)

    @staticmethod
    def get_recurring_expenses_forecast(
        user_id: int, months_ahead: int = 3
    ) -> List[Dict]:
        """
        Forecast recurring expenses.

        Args:
            user_id: User ID
            months_ahead: Number of months to forecast

        Returns:
            List[Dict]: Forecast data
        """
        recurring_expenses = Expense.objects.filter(user_id=user_id, is_recurring=True)

        forecast = []
        today = timezone.now().date()

        for month in range(months_ahead):
            forecast_date = today + timedelta(days=30 * month)
            month_total = Decimal("0")

            for expense in recurring_expenses:
                # Check if expense should recur this month
                should_recur = (
                    expense.metadata.get("recurrence_type") == "MONTHLY"
                ) or (
                    expense.metadata.get("recurrence_type") == "YEARLY"
                    and expense.date.month == forecast_date.month
                )
                if should_recur:
                    month_total += expense.amount

            forecast.append({"month": forecast_date, "total_amount": month_total})

        return forecast

    @staticmethod
    def get_expense_insights(user_id: int) -> Dict:
        """
        Get insights about user's spending patterns.

        Args:
            user_id: User ID

        Returns:
            Dict: Spending insights
        """
        today = timezone.now().date()
        thirty_days_ago = today - timedelta(days=30)
        previous_thirty_days = thirty_days_ago - timedelta(days=30)

        # Current period expenses
        current_period = Expense.objects.filter(
            user_id=user_id, date__range=(thirty_days_ago, today)
        )
        current_total = current_period.aggregate(total=Sum("amount"))[
            "total"
        ] or Decimal("0")

        # Previous period expenses
        previous_period = Expense.objects.filter(
            user_id=user_id, date__range=(previous_thirty_days, thirty_days_ago)
        )
        previous_total = previous_period.aggregate(total=Sum("amount"))[
            "total"
        ] or Decimal("0")

        # Calculate change
        if previous_total > 0:
            change_percentage = (
                (current_total - previous_total) / previous_total
            ) * 100
        else:
            change_percentage = 100 if current_total > 0 else 0

        return {
            "current_period_total": current_total,
            "previous_period_total": previous_total,
            "change_percentage": change_percentage,
            "top_categories": list(
                current_period.values("category")
                .annotate(total=Sum("amount"))
                .order_by("-total")[:5]
            ),
            "largest_expense": current_period.order_by("-amount").first(),
            "most_frequent_category": current_period.values("category")
            .annotate(count=Count("id"))
            .order_by("-count")
            .first(),
        }

    @staticmethod
    def validate_expense_against_budget(expense: Expense) -> None:
        """
        Validate expense against associated budget.

        Args:
            expense: Expense instance to validate

        Raises:
            ValidationError: If budget validation fails
        """
        if expense.budget:
            # Check if expense date falls within budget period
            if not (
                expense.budget.start_date <= expense.date <= expense.budget.end_date
            ):
                raise ValidationError(
                    _("Expense date must fall within the budget period.")
                )

            # Check if expense would exceed budget
            current_total = expense.budget.expenses.aggregate(total=Sum("amount"))[
                "total"
            ] or Decimal("0")

            if (current_total + expense.amount) > expense.budget.amount:
                raise ValidationError(_("This expense would exceed the budget limit."))
