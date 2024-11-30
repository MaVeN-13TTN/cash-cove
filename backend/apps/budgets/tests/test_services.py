"""
Tests for budget services.
"""

from datetime import date, timedelta
from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from apps.expenses.models import Expense
from ..models import Budget
from ..services.budgets_service import BudgetService

User = get_user_model()


class BudgetServiceTests(TestCase):
    """Test cases for BudgetService."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.today = date.today()
        self.budget_data = {
            "user": self.user,
            "name": "Test Budget",
            "amount": Decimal("1000.00"),
            "category": "Food",
            "start_date": self.today,
            "end_date": self.today + timedelta(days=30),
            "notification_threshold": Decimal("80.00"),
        }

    def test_create_budget(self):
        """Test budget creation through service."""
        budget = BudgetService.create_budget(self.budget_data)
        self.assertEqual(budget.name, "Test Budget")
        self.assertEqual(budget.amount, Decimal("1000.00"))

    def test_create_invalid_budget(self):
        """Test creating invalid budget."""
        invalid_data = self.budget_data.copy()
        invalid_data["end_date"] = self.today - timedelta(days=1)
        with self.assertRaises(ValidationError):
            BudgetService.create_budget(invalid_data)

    def test_update_budget(self):
        """Test updating budget through service."""
        budget = Budget.objects.create(**self.budget_data)
        update_data = {"name": "Updated Budget", "amount": Decimal("1500.00")}
        updated_budget = BudgetService.update_budget(budget, update_data)
        self.assertEqual(updated_budget.name, "Updated Budget")
        self.assertEqual(updated_budget.amount, Decimal("1500.00"))

    def test_get_active_budgets(self):
        """Test getting active budgets."""
        # Create active budget
        Budget.objects.create(**self.budget_data)

        # Create expired budget
        Budget.objects.create(
            user=self.user,
            name="Expired Budget",
            amount=Decimal("500.00"),
            category="Food",
            start_date=self.today - timedelta(days=60),
            end_date=self.today - timedelta(days=30),
        )

        active_budgets = BudgetService.get_active_budgets(self.user.id)
        self.assertEqual(len(active_budgets), 1)
        self.assertEqual(active_budgets[0].name, "Test Budget")

    def test_get_budget_summary(self):
        """Test getting budget summary."""
        budget = Budget.objects.create(**self.budget_data)
        Expense.objects.create(
            user=self.user, amount=Decimal("300.00"), category="Food", date=self.today
        )

        summary = BudgetService.get_budget_summary(budget)
        self.assertEqual(summary["amount"], Decimal("1000.00"))
        self.assertEqual(summary["remaining_amount"], Decimal("700.00"))
        self.assertEqual(summary["utilization_percentage"], Decimal("30.00"))

    def test_copy_budget(self):
        """Test copying a budget."""
        original = Budget.objects.create(**self.budget_data)
        new_start_date = self.today + timedelta(days=31)

        copied = BudgetService.copy_budget(original, new_start_date)
        self.assertEqual(copied.amount, original.amount)
        self.assertEqual(copied.category, original.category)
        self.assertEqual(copied.start_date, new_start_date)
        self.assertNotEqual(copied.id, original.id)

    def test_get_category_budgets(self):
        """Test getting budgets by category."""
        # Create test budgets
        Budget.objects.create(**self.budget_data)
        Budget.objects.create(
            user=self.user,
            name="Another Budget",
            amount=Decimal("500.00"),
            category="Entertainment",
            start_date=self.today,
            end_date=self.today + timedelta(days=30),
        )

        food_budgets = BudgetService.get_category_budgets(
            user_id=self.user.id, category="Food"
        )
        self.assertEqual(len(food_budgets), 1)
        self.assertEqual(food_budgets[0].category, "Food")

    def test_calculate_budget_forecast(self):
        """Test budget forecast calculation."""
        budget = Budget.objects.create(**self.budget_data)

        # Create some historical expenses
        for _ in range(3):
            Expense.objects.create(
                user=self.user,
                amount=Decimal("300.00"),
                category="Food",
                date=self.today - timedelta(days=30),
            )

        forecast = BudgetService.calculate_budget_forecast(
            user_id=self.user.id, months_ahead=3
        )

        self.assertEqual(len(forecast), 3)  # 3 months forecast
        self.assertEqual(forecast[0]["category"], "Food")
        self.assertTrue("projected_spending" in forecast[0])
        self.assertTrue("budget_amount" in forecast[0])
