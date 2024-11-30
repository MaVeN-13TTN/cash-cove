"""
Tests for expense views.
"""

from datetime import date, timedelta
from decimal import Decimal
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from apps.budgets.models import Budget
from ..models import Expense

User = get_user_model()


class ExpenseViewSetTests(APITestCase):
    """Test cases for ExpenseViewSet."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.client.force_authenticate(user=self.user)

        self.today = date.today()

        self.budget = Budget.objects.create(
            user=self.user,
            name="Test Budget",
            amount=Decimal("1000.00"),
            category=Expense.CategoryChoices.FOOD,
            start_date=self.today,
            end_date=self.today + timedelta(days=30),
        )

        self.expense_data = {
            "title": "Test Expense",
            "amount": "50.00",
            "category": Expense.CategoryChoices.FOOD,
            "date": self.today.isoformat(),
            "payment_method": Expense.PaymentMethod.CASH,
            "notes": "Test notes",
            "tags": ["test", "api"],
            "metadata": {"key": "value"},
        }

        self.expense = Expense.objects.create(
            user=self.user,
            budget=self.budget,
            **{
                k: v
                for k, v in self.expense_data.items()
                if k != "tags" and k != "metadata"
            }
        )

    def test_create_expense(self):
        """Test creating an expense through API."""
        url = reverse("expense-list")
        response = self.client.post(url, self.expense_data)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Expense.objects.count(), 2)
        self.assertEqual(response.data["title"], "Test Expense")

    def test_list_expenses(self):
        """Test listing expenses."""
        url = reverse("expense-list")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_retrieve_expense(self):
        """Test retrieving a single expense."""
        url = reverse("expense-detail", args=[self.expense.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], self.expense.title)

    def test_update_expense(self):
        """Test updating an expense."""
        url = reverse("expense-detail", args=[self.expense.id])
        update_data = {"title": "Updated Expense", "amount": "75.00"}
        response = self.client.patch(url, update_data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Updated Expense")
        self.assertEqual(response.data["amount"], "75.00")

    def test_delete_expense(self):
        """Test deleting an expense."""
        url = reverse("expense-detail", args=[self.expense.id])
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Expense.objects.count(), 0)

    def test_expense_summary(self):
        """Test getting expense summary."""
        url = reverse("expense-summary")
        response = self.client.get(
            url,
            {"start_date": self.today.isoformat(), "end_date": self.today.isoformat()},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)  # One category
        self.assertEqual(response.data[0]["category"], Expense.CategoryChoices.FOOD)

    def test_monthly_trend(self):
        """Test getting monthly trends."""
        url = reverse("expense-monthly-trend")
        response = self.client.get(url, {"months": 6})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(isinstance(response.data, list))

    def test_category_distribution(self):
        """Test getting category distribution."""
        url = reverse("expense-category-distribution")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(isinstance(response.data, list))

    def test_create_recurring_expense(self):
        """Test creating recurring expenses."""
        url = reverse("expense-create-recurring")
        recurring_data = {
            "expense_data": self.expense_data,
            "start_date": self.today.isoformat(),
            "end_date": (self.today + timedelta(days=2)).isoformat(),
            "frequency": "DAILY",
        }
        response = self.client.post(url, recurring_data, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(len(response.data), 3)  # 3 days of expenses

    def test_expense_forecast(self):
        """Test getting expense forecast."""
        url = reverse("expense-forecast")
        response = self.client.get(url, {"months": 3})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(isinstance(response.data, list))
        self.assertEqual(len(response.data), 3)  # 3 months forecast

    def test_expense_insights(self):
        """Test getting expense insights."""
        url = reverse("expense-insights")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("current_period_total", response.data)
        self.assertIn("top_categories", response.data)

    def test_duplicate_expense(self):
        """Test duplicating an expense."""
        url = reverse("expense-duplicate", args=[self.expense.id])
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Expense.objects.count(), 2)
        self.assertIn("(Copy)", response.data["title"])

    def test_attach_to_budget(self):
        """Test attaching expense to budget."""
        new_budget = Budget.objects.create(
            user=self.user,
            name="New Budget",
            amount=Decimal("500.00"),
            category=Expense.CategoryChoices.FOOD,
            start_date=self.today,
            end_date=self.today + timedelta(days=30),
        )

        url = reverse("expense-attach-to-budget", args=[self.expense.id])
        response = self.client.post(url, {"budget_id": new_budget.id})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["budget"], new_budget.id)

    def test_filter_expenses(self):
        """Test filtering expenses."""
        url = reverse("expense-list")

        # Test category filter
        response = self.client.get(url, {"category": Expense.CategoryChoices.FOOD})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

        # Test date range filter
        response = self.client.get(
            url,
            {"start_date": self.today.isoformat(), "end_date": self.today.isoformat()},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

        # Test amount range filter
        response = self.client.get(url, {"min_amount": "40.00", "max_amount": "60.00"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_invalid_filters(self):
        """Test invalid filter parameters."""
        url = reverse("expense-list")

        # Invalid date format
        response = self.client.get(url, {"start_date": "invalid-date"})
        self.assertEqual(
            response.status_code, status.HTTP_200_OK
        )  # Should ignore invalid filter

        # Invalid amount
        response = self.client.get(url, {"min_amount": "invalid-amount"})
        self.assertEqual(
            response.status_code, status.HTTP_200_OK
        )  # Should ignore invalid filter

    def test_unauthorized_access(self):
        """Test unauthorized access to expense endpoints."""
        self.client.force_authenticate(user=None)

        # Test various endpoints
        urls = [
            reverse("expense-list"),
            reverse("expense-detail", args=[self.expense.id]),
            reverse("expense-summary"),
            reverse("expense-monthly-trend"),
            reverse("expense-category-distribution"),
            reverse("expense-insights"),
        ]

        for url in urls:
            response = self.client.get(url)
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
