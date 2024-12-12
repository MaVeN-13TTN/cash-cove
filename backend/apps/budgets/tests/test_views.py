"""
Tests for budget views.
"""

from datetime import date, timedelta
from decimal import Decimal
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from ..models import Budget

User = get_user_model()


class BudgetViewSetTests(APITestCase):
    """Test cases for BudgetViewSet."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.client.force_authenticate(user=self.user)

        self.today = date.today()
        self.budget_data = {
            "name": "Test Budget",
            "amount": "1000.00",
            "category": "Food",
            "start_date": self.today.isoformat(),
            "end_date": (self.today + timedelta(days=30)).isoformat(),
            "notification_threshold": "80.00",
            "description": "Test budget description",
        }

        self.budget = Budget.objects.create(
            user=self.user,
            **{
                k: v
                for k, v in self.budget_data.items()
                if k != "start_date" and k != "end_date"
            },
            start_date=self.today,
            end_date=self.today + timedelta(days=30)
        )

    def test_create_budget(self):
        """Test creating a budget through API."""
        url = reverse("budget-list")
        response = self.client.post(url, self.budget_data, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Budget.objects.count(), 2)
        self.assertEqual(response.data["name"], "Test Budget")

    def test_list_budgets(self):
        """Test listing budgets."""
        url = reverse("budget-list")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_retrieve_budget(self):
        """Test retrieving a single budget."""
        url = reverse("budget-detail", args=[self.budget.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], self.budget.name)

    def test_update_budget(self):
        """Test updating a budget."""
        url = reverse("budget-detail", args=[self.budget.id])
        update_data = {"name": "Updated Budget", "amount": "1500.00"}
        response = self.client.patch(url, update_data, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "Updated Budget")
        self.assertEqual(response.data["amount"], "1500.00")

    def test_delete_budget(self):
        """Test deleting a budget."""
        url = reverse("budget-detail", args=[self.budget.id])
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Budget.objects.count(), 0)

    def test_active_budgets(self):
        """Test getting active budgets."""
        url = reverse("budget-active")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_category_budgets(self):
        """Test getting budgets by category."""
        url = reverse("budget-category")
        response = self.client.get(url, {"category": "Food"})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["category"], "Food")

    def test_category_budgets_invalid_date(self):
        """Test getting budgets by category with invalid date."""
        url = reverse("budget-category")
        response = self.client.get(
            url, {"category": "Food", "start_date": "invalid-date"}
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("error", response.data)

    def test_forecast(self):
        """Test budget forecast endpoint."""
        url = reverse("budget-forecast")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)

    def test_forecast_invalid_months(self):
        """Test budget forecast with invalid months parameter."""
        url = reverse("budget-forecast")
        response = self.client.get(url, {"months": "invalid"})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("error", response.data)

    def test_summary(self):
        """Test budget summary endpoint."""
        url = reverse("budget-summary")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)
        self.assertEqual(len(response.data), 1)

    def test_unauthorized_access(self):
        """Test unauthorized access to budget endpoints."""
        self.client.force_authenticate(user=None)

        # Test various endpoints
        urls = [
            reverse("budget-list"),
            reverse("budget-detail", args=[self.budget.id]),
            reverse("budget-active"),
            reverse("budget-category"),
            reverse("budget-forecast"),
            reverse("budget-summary"),
        ]

        for url in urls:
            response = self.client.get(url)
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_budget_validation(self):
        """Test budget validation in creation."""
        url = reverse("budget-list")
        invalid_data = self.budget_data.copy()
        invalid_data["amount"] = "-100.00"  # Negative amount

        response = self.client.post(url, invalid_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        invalid_data = self.budget_data.copy()
        invalid_data["end_date"] = self.today.isoformat()  # End date same as start
        invalid_data["start_date"] = (self.today + timedelta(days=1)).isoformat()

        response = self.client.post(url, invalid_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
