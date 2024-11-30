"""
Tests for analytics services.
"""

from datetime import datetime, timedelta
from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from apps.budgets.models import Budget
from apps.expenses.models import Expense
from ..models import SpendingAnalytics, BudgetUtilization
from ..services.analytics_service import AnalyticsService

User = get_user_model()


class AnalyticsServiceTests(TestCase):
    """Test cases for AnalyticsService."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.today = datetime.now().date()

        # Create test budget
        self.budget = Budget.objects.create(
            user=self.user,
            category="Food",
            amount=Decimal("500.00"),
            start_date=self.today - timedelta(days=30),
            end_date=self.today + timedelta(days=30),
        )

        # Create test expenses
        self.expense = Expense.objects.create(
            user=self.user, category="Food", amount=Decimal("100.00"), date=self.today
        )

    def test_calculate_spending_analytics(self):
        """Test calculating spending analytics."""
        analytics = AnalyticsService.calculate_spending_analytics(
            user_id=self.user.id,
            start_date=self.today - timedelta(days=30),
            end_date=self.today,
        )
        self.assertTrue(len(analytics) > 0)
        self.assertEqual(analytics[0]["category"], "Food")

    def test_update_budget_utilization(self):
        """Test updating budget utilization."""
        AnalyticsService.update_budget_utilization(
            user_id=self.user.id, month=self.today
        )
        utilization = BudgetUtilization.objects.filter(
            user=self.user, category="Food"
        ).first()
        self.assertIsNotNone(utilization)
        self.assertEqual(utilization.spent_amount, Decimal("100.00"))
