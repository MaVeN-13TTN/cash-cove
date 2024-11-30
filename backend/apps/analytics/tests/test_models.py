"""
Tests for analytics models.
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from ..models import SpendingAnalytics, BudgetUtilization

User = get_user_model()


class SpendingAnalyticsTests(TestCase):
    """Test cases for SpendingAnalytics model."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.analytics = SpendingAnalytics.objects.create(
            user=self.user,
            date=timezone.now().date(),
            category="Food",
            total_amount=Decimal("100.00"),
            transaction_count=5,
            average_amount=Decimal("20.00"),
        )

    def test_spending_analytics_creation(self):
        """Test SpendingAnalytics model creation."""
        self.assertEqual(self.analytics.user, self.user)
        self.assertEqual(self.analytics.category, "Food")
        self.assertEqual(self.analytics.total_amount, Decimal("100.00"))
        self.assertEqual(self.analytics.transaction_count, 5)
        self.assertEqual(self.analytics.average_amount, Decimal("20.00"))

    def test_spending_analytics_str(self):
        """Test SpendingAnalytics string representation."""
        expected = f"{self.user.username} - Food - {self.analytics.date}"
        self.assertEqual(str(self.analytics), expected)
