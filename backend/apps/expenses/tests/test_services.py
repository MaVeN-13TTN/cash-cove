"""
Tests for expense services.
"""

from datetime import date, timedelta
from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.exceptions import ValidationError
from apps.budgets.models import Budget
from ..models import Expense
from ..services.expenses_service import ExpenseService

User = get_user_model()


class ExpenseServiceTests(TestCase):
    """Test cases for ExpenseService."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.today = timezone.now().date()

        self.budget = Budget.objects.create(
            user=self.user,
            name="Test Budget",
            amount=Decimal("1000.00"),
            category=Expense.CategoryChoices.FOOD,
            start_date=self.today,
            end_date=self.today + timedelta(days=30),
        )

        # Create test expenses
        self.expenses = []
        amounts = [50, 75, 100]
        for amount in amounts:
            expense = Expense.objects.create(
                user=self.user,
                title=f"Test Expense {amount}",
                amount=Decimal(str(amount)),
                category=Expense.CategoryChoices.FOOD,
                date=self.today,
                budget=self.budget,
            )
            self.expenses.append(expense)

    def test_create_recurring_expenses(self):
        """Test creating recurring expenses."""
        expense_data = {
            "user": self.user,
            "title": "Recurring Expense",
            "amount": Decimal("100.00"),
            "category": Expense.CategoryChoices.FOOD,
            "payment_method": Expense.PaymentMethod.CASH,
        }

        start_date = self.today
        end_date = start_date + timedelta(days=3)

        recurring_expenses = ExpenseService.create_recurring_expenses(
            expense_data=expense_data,
            start_date=start_date,
            end_date=end_date,
            frequency="DAILY",
        )

        self.assertEqual(len(recurring_expenses), 4)  # 4 days inclusive
        self.assertEqual(recurring_expenses[0].title, "Recurring Expense")
        self.assertTrue(all(e.is_recurring for e in recurring_expenses))

    def test_get_expense_summary(self):
        """Test getting expense summary."""
        summary = ExpenseService.get_expense_summary(
            user_id=self.user.id, start_date=self.today, end_date=self.today
        )

        self.assertEqual(len(summary), 1)  # One category
        self.assertEqual(summary[0]["category"], Expense.CategoryChoices.FOOD)
        self.assertEqual(
            summary[0]["total_amount"], Decimal("225.00")
        )  # Sum of 50, 75, 100
        self.assertEqual(summary[0]["transaction_count"], 3)

    def test_get_monthly_trend(self):
        """Test getting monthly trends."""
        # Create expenses for previous month
        prev_month = self.today - timedelta(days=30)
        Expense.objects.create(
            user=self.user,
            title="Previous Month Expense",
            amount=Decimal("150.00"),
            category=Expense.CategoryChoices.FOOD,
            date=prev_month,
        )

        trends = ExpenseService.get_monthly_trend(user_id=self.user.id, months=2)

        self.assertEqual(len(trends), 2)  # Two months of data
        self.assertTrue(
            all(
                "total_amount" in month and "transaction_count" in month
                for month in trends
            )
        )

    def test_get_category_distribution(self):
        """Test getting category distribution."""
        # Create expense in different category
        Expense.objects.create(
            user=self.user,
            title="Entertainment Expense",
            amount=Decimal("75.00"),
            category=Expense.CategoryChoices.ENTERTAINMENT,
            date=self.today,
        )

        distribution = ExpenseService.get_category_distribution(
            user_id=self.user.id, start_date=self.today, end_date=self.today
        )

        self.assertEqual(len(distribution), 2)  # Two categories
        self.assertTrue(all("percentage" in category for category in distribution))

    def test_get_recurring_expenses_forecast(self):
        """Test getting recurring expenses forecast."""
        # Create recurring expense
        Expense.objects.create(
            user=self.user,
            title="Monthly Recurring",
            amount=Decimal("100.00"),
            category=Expense.CategoryChoices.FOOD,
            date=self.today,
            is_recurring=True,
            metadata={"recurrence_type": "MONTHLY"},
        )

        forecast = ExpenseService.get_recurring_expenses_forecast(
            user_id=self.user.id, months_ahead=3
        )

        self.assertEqual(len(forecast), 3)  # Three months forecast
        self.assertTrue(
            all("month" in month and "total_amount" in month for month in forecast)
        )

    def test_get_expense_insights(self):
        """Test getting expense insights."""
        insights = ExpenseService.get_expense_insights(user_id=self.user.id)

        self.assertIn("current_period_total", insights)
        self.assertIn("previous_period_total", insights)
        self.assertIn("change_percentage", insights)
        self.assertIn("top_categories", insights)
        self.assertTrue(isinstance(insights["top_categories"], list))

    def test_validate_expense_against_budget(self):
        """Test expense validation against budget."""
        # Create expense that would exceed budget
        expense = Expense(
            user=self.user,
            title="Large Expense",
            amount=Decimal("2000.00"),  # Exceeds budget
            category=Expense.CategoryChoices.FOOD,
            date=self.today,
            budget=self.budget,
        )

        with self.assertRaises(ValidationError):
            ExpenseService.validate_expense_against_budget(expense)

        # Create expense outside budget period
        expense = Expense(
            user=self.user,
            title="Outside Period",
            amount=Decimal("50.00"),
            category=Expense.CategoryChoices.FOOD,
            date=self.today + timedelta(days=60),  # Outside period
            budget=self.budget,
        )

        with self.assertRaises(ValidationError):
            ExpenseService.validate_expense_against_budget(expense)
