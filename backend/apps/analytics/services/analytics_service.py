"""
Service layer for analytics operations.
"""

from datetime import datetime
from decimal import Decimal
from typing import Dict, List, Optional
from django.db.models import Sum, Avg, Count
from django.db.models.functions import TruncMonth
from apps.expenses.models import Expense
from apps.budgets.models import Budget
from ..models import SpendingAnalytics, BudgetUtilization


class AnalyticsService:
    """
    Service class for handling analytics operations.
    """

    @staticmethod
    def calculate_spending_analytics(
        user_id: int, start_date: datetime, end_date: datetime
    ) -> List[Dict]:
        """
        Calculate spending analytics for a given date range.

        Args:
            user_id: The ID of the user
            start_date: Start date for analysis
            end_date: End date for analysis

        Returns:
            List of spending analytics data
        """
        analytics = (
            SpendingAnalytics.objects.filter(
                user_id=user_id, date__range=(start_date, end_date)
            )
            .values("category")
            .annotate(
                total_amount=Sum("total_amount"),
                avg_amount=Avg("average_amount"),
                total_transactions=Sum("transaction_count"),
            )
        )

        return list(analytics)

    @staticmethod
    def update_budget_utilization(user_id: int, month: datetime) -> None:
        """
        Update budget utilization metrics for a given month.

        Args:
            user_id: The ID of the user
            month: The month to calculate utilization for
        """
        # Get all budgets for the user
        budgets = Budget.objects.filter(
            user_id=user_id, start_date__lte=month, end_date__gte=month
        )

        for budget in budgets:
            # Calculate spent amount
            spent_amount = Expense.objects.filter(
                user_id=user_id,
                category=budget.category,
                date__year=month.year,
                date__month=month.month,
            ).aggregate(total=Sum("amount"))["total"] or Decimal("0")

            # Calculate utilization percentage
            utilization = (
                spent_amount / budget.amount * 100
                if budget.amount > 0
                else Decimal("0")
            )

            # Update or create utilization record
            BudgetUtilization.objects.update_or_create(
                user_id=user_id,
                category=budget.category,
                month=month,
                defaults={
                    "budget_amount": budget.amount,
                    "spent_amount": spent_amount,
                    "utilization_percentage": utilization,
                },
            )

    @staticmethod
    def get_category_trends(user_id: int, category: str, months: int = 6) -> List[Dict]:
        """
        Get spending trends for a specific category.

        Args:
            user_id: The ID of the user
            category: The category to analyze
            months: Number of months to analyze

        Returns:
            List of monthly spending data
        """
        trends = (
            Expense.objects.filter(user_id=user_id, category=category)
            .annotate(month=TruncMonth("date"))
            .values("month")
            .annotate(
                total_amount=Sum("amount"),
                transaction_count=Count("id"),
                average_amount=Avg("amount"),
            )
            .order_by("-month")[:months]
        )

        return list(trends)

    @staticmethod
    def get_spending_insights(user_id: int) -> Dict:
        """
        Get spending insights for the user.

        Args:
            user_id: The ID of the user

        Returns:
            Dictionary containing spending insights
        """
        return {
            "top_categories": SpendingAnalytics.objects.filter(user_id=user_id)
            .values("category")
            .annotate(total=Sum("total_amount"))
            .order_by("-total")[:5],
            "utilization_summary": BudgetUtilization.objects.filter(user_id=user_id)
            .values("category")
            .annotate(avg_utilization=Avg("utilization_percentage"))
            .order_by("-avg_utilization"),
        }
