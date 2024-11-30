"""
Tests for shared expenses views.
"""

from decimal import Decimal
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from ..models import SharedExpense, ParticipantShare

User = get_user_model()


class SharedExpenseViewTests(APITestCase):
    """Test cases for shared expense views."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.participant = User.objects.create_user(
            username="participant",
            email="participant@example.com",
            password="testpass123",
        )
        self.client.force_authenticate(user=self.user)

        self.shared_expense = SharedExpense.objects.create(
            creator=self.user,
            title="Test Shared Expense",
            amount=Decimal("100.00"),
            split_method=SharedExpense.SplitMethod.EQUAL,
            category=SharedExpense.CategoryChoices.FOOD,
        )
        self.participant_share = ParticipantShare.objects.create(
            shared_expense=self.shared_expense,
            participant=self.participant,
            amount=Decimal("50.00"),
        )

    def test_create_shared_expense(self):
        """Test creating a shared expense through API."""
        url = reverse("shared-expense-list")
        data = {
            "title": "New Shared Expense",
            "amount": "150.00",
            "split_method": SharedExpense.SplitMethod.EQUAL,
            "category": SharedExpense.CategoryChoices.FOOD,
            "participants": [self.participant.id],
        }
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(SharedExpense.objects.count(), 2)
        self.assertEqual(response.data["title"], "New Shared Expense")

    def test_create_shared_expense_percentage_split(self):
        """Test creating a shared expense with percentage split."""
        url = reverse("shared-expense-list")
        data = {
            "title": "Percentage Split Expense",
            "amount": "100.00",
            "split_method": SharedExpense.SplitMethod.PERCENTAGE,
            "category": SharedExpense.CategoryChoices.FOOD,
            "participants": [self.participant.id],
            "percentages": {str(self.participant.id): "100.00"},
        }
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["participant_shares"][0]["amount"], "100.00")

    def test_list_shared_expenses(self):
        """Test listing shared expenses."""
        url = reverse("shared-expense-list")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_list_shared_expenses_with_filters(self):
        """Test listing shared expenses with filters."""
        url = reverse("shared-expense-list")

        # Test category filter
        response = self.client.get(
            url, {"category": SharedExpense.CategoryChoices.FOOD}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

        # Test status filter
        response = self.client.get(url, {"status": SharedExpense.Status.PENDING})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_retrieve_shared_expense(self):
        """Test retrieving a single shared expense."""
        url = reverse("shared-expense-detail", args=[self.shared_expense.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Test Shared Expense")
        self.assertEqual(len(response.data["participant_shares"]), 1)

    def test_update_shared_expense(self):
        """Test updating a shared expense."""
        url = reverse("shared-expense-detail", args=[self.shared_expense.id])
        data = {"title": "Updated Title", "description": "New description"}
        response = self.client.patch(url, data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Updated Title")

    def test_delete_shared_expense(self):
        """Test deleting a shared expense."""
        url = reverse("shared-expense-detail", args=[self.shared_expense.id])
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(SharedExpense.objects.count(), 0)

    def test_record_payment(self):
        """Test recording a payment."""
        url = reverse("shared-expense-record-payment", args=[self.shared_expense.id])
        data = {"amount": "30.00", "notes": "Test payment"}

        # Login as participant
        self.client.force_authenticate(user=self.participant)
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.participant_share.refresh_from_db()
        self.assertEqual(self.participant_share.amount_paid, Decimal("30.00"))

    def test_invalid_payment_amount(self):
        """Test recording invalid payment amount."""
        url = reverse("shared-expense-record-payment", args=[self.shared_expense.id])
        data = {"amount": "60.00", "notes": "Invalid payment"}  # More than share amount

        self.client.force_authenticate(user=self.participant)
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_get_summary(self):
        """Test getting shared expenses summary."""
        url = reverse("shared-expense-summary")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("total_created", response.data)
        self.assertIn("total_owed", response.data)
        self.assertIn("total_paid", response.data)

    def test_get_statistics(self):
        """Test getting shared expense statistics."""
        url = reverse("shared-expense-statistics", args=[self.shared_expense.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("total_amount", response.data)
        self.assertIn("payment_progress", response.data)
        self.assertIn("participant_count", response.data)

    def test_get_balance_sheet(self):
        """Test getting balance sheet."""
        url = reverse("shared-expense-balance-sheet")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("owed_to_user", response.data)
        self.assertIn("user_owes", response.data)
        self.assertIn("by_category", response.data)

    def test_settle_expense(self):
        """Test settling a shared expense."""
        url = reverse("shared-expense-settle", args=[self.shared_expense.id])

        # Record full payment
        self.participant_share.amount_paid = self.participant_share.amount
        self.participant_share.save()

        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.shared_expense.refresh_from_db()
        self.assertEqual(self.shared_expense.status, SharedExpense.Status.SETTLED)

    def test_cancel_expense(self):
        """Test cancelling a shared expense."""
        url = reverse("shared-expense-cancel", args=[self.shared_expense.id])
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.shared_expense.refresh_from_db()
        self.assertEqual(self.shared_expense.status, SharedExpense.Status.CANCELLED)

    def test_unauthorized_access(self):
        """Test unauthorized access to shared expenses."""
        self.client.force_authenticate(user=None)
        urls = [
            reverse("shared-expense-list"),
            reverse("shared-expense-detail", args=[self.shared_expense.id]),
            reverse("shared-expense-summary"),
            reverse("shared-expense-balance-sheet"),
        ]

        for url in urls:
            response = self.client.get(url)
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_permission_checks(self):
        """Test permission checks for various actions."""
        other_user = User.objects.create_user(
            username="otheruser", email="other@example.com", password="testpass123"
        )
        self.client.force_authenticate(user=other_user)

        # Try to update someone else's expense
        url = reverse("shared-expense-detail", args=[self.shared_expense.id])
        response = self.client.patch(url, {"title": "Unauthorized Update"})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # Try to settle someone else's expense
        url = reverse("shared-expense-settle", args=[self.shared_expense.id])
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
