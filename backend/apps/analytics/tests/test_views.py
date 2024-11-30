"""
Tests for analytics views.
"""

from datetime import datetime, timedelta
from decimal import Decimal
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from ..models import SpendingAnalytics, BudgetUtilization

User = get_user_model()


class SpendingAnalyticsViewTests(APITestCase):
    """Test cases for spending analytics views."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.client.force_authenticate(user=self.user)
        self.analytics = SpendingAnalytics.objects.create(
            user=self.user,
            date=datetime.now().date(),
            category="Food",
            total_amount=Decimal("100.00"),
            transaction_count=5,
            average_amount=Decimal("20.00"),
        )

    def test_list_spending_analytics(self):
        """Test listing spending analytics."""
        url = reverse("spending-analytics-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_by_category_analytics(self):
        """Test getting analytics by category."""
        url = reverse("spending-analytics-by-category")
        params = {
            "start_date": (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d"),
            "end_date": datetime.now().strftime("%Y-%m-%d"),
        }
        response = self.client.get(url, params)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
