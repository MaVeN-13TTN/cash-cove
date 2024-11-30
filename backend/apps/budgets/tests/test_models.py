"""
Tests for budget models.
"""

from datetime import date, timedelta
from decimal import Decimal
from django.test import TestCase
from django.core.exceptions import ValidationError
from django.contrib.auth import get_user_model
from apps.expenses.models import Expense
from ..models import Budget

User = get_user_model()


class BudgetModelTests(TestCase):
    """Test cases for Budget model."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.today = date.today()
        self.budget = Budget.objects.create(
            user=self.user,
            name="Test Budget",
            amount=Decimal("1000.00"),
            category="Food",
            start_date=self.today,
            end_date=self.today + timedelta(days=30),
            notification_threshold=Decimal("80.00"),
            description="Test budget description",
        )

    def test_budget_creation(self):
        """Test creating a budget."""
        self.assertEqual(self.budget.name, "Test Budget")
        self.assertEqual(self.budget.amount, Decimal("1000.00"))
        self.assertEqual(self.budget.category, "Food")
        self.assertEqual(self.budget.start_date, self.today)
        self.assertEqual(self.budget.notification_threshold, Decimal("80.00"))
        self.assertTrue(self.budget.is_active)

    def test_budget_string_representation(self):
        """Test budget string representation."""
        expected = (
            f"Test Budget - Food ({self.today} to {self.today + timedelta(days=30)})"
        )
        self.assertEqual(str(self.budget), expected)

    def test_budget_invalid_dates(self):
        """Test budget with invalid dates."""
        with self.assertRaises(ValidationError):
            Budget.objects.create(
                user=self.user,
                name="Invalid Budget",
                amount=Decimal("1000.00"),
                category="Food",
                start_date=self.today,
                end_date=self.today - timedelta(days=1),
            )

    def test_budget_negative_amount(self):
        """Test budget with negative amount."""
        with self.assertRaises(ValidationError):
            Budget.objects.create(
                user=self.user,
                name="Invalid Budget",
                amount=Decimal("-100.00"),
                category="Food",
                start_date=self.today,
                end_date=self.today + timedelta(days=30),
            )

    def test_budget_remaining_amount(self):
        """Test budget remaining amount calculation."""
        # Create some expenses
        Expense.objects.create(
            user=self.user, amount=Decimal("300.00"), category="Food", date=self.today
        )
        Expense.objects.create(
            user=self.user, amount=Decimal("200.00"), category="Food", date=self.today
        )

        self.assertEqual(self.budget.remaining_amount, Decimal("500.00"))

    def test_budget_utilization_percentage(self):
        """Test budget utilization percentage calculation."""
        Expense.objects.create(
            user=self.user, amount=Decimal("750.00"), category="Food", date=self.today
        )

        self.assertEqual(self.budget.utilization_percentage, Decimal("75.00"))

    def test_budget_is_expired(self):
        """Test budget expiration check."""
        # Create an expired budget
        expired_budget = Budget.objects.create(
            user=self.user,
            name="Expired Budget",
            amount=Decimal("1000.00"),
            category="Food",
            start_date=self.today - timedelta(days=60),
            end_date=self.today - timedelta(days=30),
        )

        self.assertTrue(expired_budget.is_expired)
        self.assertFalse(self.budget.is_expired)

    def test_budget_recurrence_choices(self):
        """Test budget recurrence choices."""
        budget = Budget.objects.create(
            user=self.user,
            name="Recurring Budget",
            amount=Decimal("1000.00"),
            category="Food",
            start_date=self.today,
            end_date=self.today + timedelta(days=30),
            recurrence=Budget.RecurrenceChoices.MONTHLY,
        )

        self.assertEqual(budget.recurrence, "MONTHLY")
        self.assertIn(budget.recurrence, dict(Budget.RecurrenceChoices.choices).keys())
