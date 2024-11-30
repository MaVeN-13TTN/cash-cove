"""
Service layer for budget operations.
"""

from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Dict, List, Optional, Union
from django.db.models import Q, Sum
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

from ..models import Budget
from apps.expenses.models import Expense
from apps.notifications.services import NotificationService


class BudgetService:
    """
    Service class for handling budget operations.
    """

    @staticmethod
    def create_budget(data: Dict) -> Budget:
        """
        Create a new budget.

        Args:
            data: Dictionary containing budget data

        Returns:
            Budget: Created budget instance

        Raises:
            ValidationError: If budget data is invalid
        """
        try:
            budget = Budget.objects.create(**data)
            return budget
        except ValidationError as e:
            raise ValidationError(_("Invalid budget data: {0}").format(str(e)))

    @staticmethod
    def update_budget(budget: Budget, data: Dict) -> Budget:
        """
        Update an existing budget.

        Args:
            budget: Budget instance to update
            data: Dictionary containing update data

        Returns:
            Budget: Updated budget instance

        Raises:
            ValidationError: If update data is invalid
        """
        try:
            for key, value in data.items():
                setattr(budget, key, value)
            budget.save()
            return budget
        except ValidationError as e:
            raise ValidationError(_("Invalid update data: {0}").format(str(e)))

    @staticmethod
    def get_active_budgets(user_id: int) -> List[Budget]:
        """
        Get active budgets for a user.

        Args:
            user_id: User ID

        Returns:
            List[Budget]: List of active budgets
        """
        return Budget.objects.filter(
            user_id=user_id, is_active=True, end_date__gte=timezone.now().date()
        )

    @staticmethod
    def get_budget_summary(budget: Budget) -> Dict:
        """
        Get summary of budget utilization.

        Args:
            budget: Budget instance

        Returns:
            Dict: Budget summary data
        """
        return {
            "id": budget.id,
            "name": budget.name,
            "category": budget.category,
            "amount": budget.amount,
            "remaining_amount": budget.remaining_amount,
            "utilization_percentage": budget.utilization_percentage,
            "is_expired": budget.is_expired,
            "days_remaining": (budget.end_date - timezone.now().date()).days,
        }

    @staticmethod
    def check_budget_thresholds(user_id: int) -> None:
        """
        Check budget thresholds and send notifications if needed.

        Args:
            user_id: User ID
        """
        active_budgets = BudgetService.get_active_budgets(user_id)
        for budget in active_budgets:
            utilization = budget.utilization_percentage
            if utilization >= budget.notification_threshold:
                NotificationService.send_budget_threshold_notification(budget)

    @staticmethod
    def copy_budget(budget: Budget, start_date: date) -> Budget:
        """
        Create a copy of a budget with new dates.

        Args:
            budget: Budget to copy
            start_date: New start date

        Returns:
            Budget: New budget instance
        """
        duration = (budget.end_date - budget.start_date).days
        new_budget = Budget.objects.create(
            user=budget.user,
            name=f"{budget.name} (Copy)",
            amount=budget.amount,
            category=budget.category,
            start_date=start_date,
            end_date=start_date + timedelta(days=duration),
            recurrence=budget.recurrence,
            notification_threshold=budget.notification_threshold,
            description=budget.description,
        )
        return new_budget

    @staticmethod
    def get_category_budgets(
        user_id: int,
        category: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> List[Budget]:
        """
        Get budgets for a specific category and date range.

        Args:
            user_id: User ID
            category: Budget category
            start_date: Optional start date
            end_date: Optional end date

        Returns:
            List[Budget]: List of matching budgets
        """
        query = Q(user_id=user_id, category=category)
        if start_date and end_date:
            query &= Q(start_date__lte=end_date, end_date__gte=start_date)

        return Budget.objects.filter(query)

    @staticmethod
    def rollover_recurring_budgets() -> None:
        """
        Create new budgets for recurring budgets that are ending.
        """
        tomorrow = timezone.now().date() + timedelta(days=1)
        ending_budgets = Budget.objects.filter(
            is_active=True,
            end_date=timezone.now().date(),
            recurrence__in=["DAILY", "WEEKLY", "MONTHLY", "YEARLY"],
        )

        for budget in ending_budgets:
            # Calculate new dates based on recurrence
            if budget.recurrence == "DAILY":
                new_start = tomorrow
                new_end = tomorrow
            elif budget.recurrence == "WEEKLY":
                new_start = tomorrow
                new_end = new_start + timedelta(days=6)
            elif budget.recurrence == "MONTHLY":
                new_start = tomorrow
                # Set to last day of next month
                next_month = new_start.replace(day=28) + timedelta(days=4)
                new_end = next_month - timedelta(days=next_month.day)
            else:  # YEARLY
                new_start = tomorrow
                new_end = new_start.replace(year=new_start.year + 1) - timedelta(days=1)

            # Create new budget
            Budget.objects.create(
                user=budget.user,
                name=budget.name,
                amount=budget.amount,
                category=budget.category,
                start_date=new_start,
                end_date=new_end,
                recurrence=budget.recurrence,
                notification_threshold=budget.notification_threshold,
                description=budget.description,
                is_active=True,
            )

    @staticmethod
    def calculate_budget_forecast(user_id: int, months_ahead: int = 3) -> List[Dict]:
        """
        Calculate budget forecast based on current spending patterns.

        Args:
            user_id: User ID
            months_ahead: Number of months to forecast

        Returns:
            List[Dict]: Forecast data for each category
        """
        # Get active budgets and their categories
        active_budgets = BudgetService.get_active_budgets(user_id)
        categories = active_budgets.values_list("category", flat=True).distinct()

        forecasts = []
        today = timezone.now().date()

        for category in categories:
            # Get average monthly spending for this category
            three_months_ago = today - timedelta(days=90)
            expenses = Expense.objects.filter(
                user_id=user_id, category=category, date__gte=three_months_ago
            )

            monthly_avg = expenses.aggregate(avg=Sum("amount") / 3)["avg"] or Decimal(
                "0"
            )

            # Project spending for future months
            for month in range(1, months_ahead + 1):
                forecast_date = today + timedelta(days=30 * month)
                budget = active_budgets.filter(
                    category=category,
                    start_date__lte=forecast_date,
                    end_date__gte=forecast_date,
                ).first()

                forecasts.append(
                    {
                        "category": category,
                        "month": forecast_date,
                        "projected_spending": monthly_avg,
                        "budget_amount": budget.amount if budget else Decimal("0"),
                        "projected_status": (
                            "OVER"
                            if monthly_avg > (budget.amount if budget else 0)
                            else "UNDER"
                        ),
                    }
                )

        return forecasts
