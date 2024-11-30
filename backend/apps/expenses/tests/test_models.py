"""
Tests for expense models.
"""

from datetime import date, timedelta
from decimal import Decimal
from django.test import TestCase
from django.core.exceptions import ValidationError
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.budgets.models import Budget
from ..models import Expense

User = get_user_model()


class ExpenseModelTests(TestCase):
    """Test cases for Expense model."""

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

        self.expense = Expense.objects.create(
            user=self.user,
            title="Test Expense",
            amount=Decimal("50.00"),
            category=Expense.CategoryChoices.FOOD,
            date=self.today,
            budget=self.budget,
            payment_method=Expense.PaymentMethod.CASH,
        )

    def test_expense_creation(self):
        """Test creating an expense."""
        self.assertEqual(self.expense.title, "Test Expense")
        self.assertEqual(self.expense.amount, Decimal("50.00"))
        self.assertEqual(self.expense.category, Expense.CategoryChoices.FOOD)
        self.assertEqual(self.expense.payment_method, Expense.PaymentMethod.CASH)
        self.assertFalse(self.expense.is_recurring)

    def test_expense_string_representation(self):
        """Test expense string representation."""
        expected = f"Test Expense - 50.00 ({self.today})"
        self.assertEqual(str(self.expense), expected)

    def test_expense_future_date(self):
        """Test expense with future date."""
        with self.assertRaises(ValidationError):
            Expense.objects.create(
                user=self.user,
                title="Future Expense",
                amount=Decimal("50.00"),
                category=Expense.CategoryChoices.FOOD,
                date=self.today + timedelta(days=1),
            )

    def test_expense_negative_amount(self):
        """Test expense with negative amount."""
        with self.assertRaises(ValidationError):
            Expense.objects.create(
                user=self.user,
                title="Invalid Expense",
                amount=Decimal("-50.00"),
                category=Expense.CategoryChoices.FOOD,
                date=self.today,
            )

    def test_expense_categories(self):
        """Test expense categories."""
        self.assertIn(self.expense.category, dict(Expense.CategoryChoices.choices))
        self.assertEqual(self.expense.get_category_display(), "Food & Dining")

    def test_expense_payment_methods(self):
        """Test expense payment methods."""
        self.assertIn(self.expense.payment_method, dict(Expense.PaymentMethod.choices))
        self.assertEqual(self.expense.get_payment_method_display(), "Cash")

    def test_expense_budget_relationship(self):
        """Test expense-budget relationship."""
        self.assertEqual(self.expense.budget, self.budget)
        self.assertIn(self.expense, self.budget.expenses.all())

    def test_expense_json_fields(self):
        """Test JSON fields in expense."""
        expense = Expense.objects.create(
            user=self.user,
            title="JSON Test Expense",
            amount=Decimal("75.00"),
            category=Expense.CategoryChoices.FOOD,
            date=self.today,
            tags=["test", "json"],
            metadata={"key": "value"},
        )

        self.assertEqual(expense.tags, ["test", "json"])
        self.assertEqual(expense.metadata, {"key": "value"})

    def test_expense_month_year(self):
        """Test month_year property."""
        month_year = self.expense.month_year
        expected = self.today.strftime("%B %Y")
        self.assertEqual(month_year, expected)

    def test_expense_is_recent(self):
        """Test is_recent property."""
        # Current expense should be recent
        self.assertTrue(self.expense.is_recent)

        # Create old expense
        old_expense = Expense.objects.create(
            user=self.user,
            title="Old Expense",
            amount=Decimal("25.00"),
            category=Expense.CategoryChoices.FOOD,
            date=self.today - timedelta(days=31),
        )
        self.assertFalse(old_expense.is_recent)

    def test_expense_budget_status(self):
        """Test get_budget_status method."""
        status = self.expense.get_budget_status()
        self.assertTrue(status["has_budget"])
        self.assertEqual(status["budget_name"], self.budget.name)

        # Test expense without budget
        expense_no_budget = Expense.objects.create(
            user=self.user,
            title="No Budget Expense",
            amount=Decimal("25.00"),
            category=Expense.CategoryChoices.FOOD,
            date=self.today,
        )
        status = expense_no_budget.get_budget_status()
        self.assertFalse(status["has_budget"])

    def test_expense_category_info(self):
        """Test get_category_info method."""
        info = self.expense.get_category_info()
        self.assertEqual(info["name"], "Food & Dining")
        self.assertIn("icon", info)
        self.assertIn("color", info)
