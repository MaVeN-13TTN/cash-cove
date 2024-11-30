"""
Tests for shared expenses services.
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.exceptions import ValidationError
from ..models import SharedExpense, ParticipantShare
from ..services.shared_expenses_service import SharedExpenseService

User = get_user_model()


class SharedExpenseServiceTests(TestCase):
    """Test cases for SharedExpenseService."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.participant1 = User.objects.create_user(
            username="participant1",
            email="participant1@example.com",
            password="testpass123",
        )
        self.participant2 = User.objects.create_user(
            username="participant2",
            email="participant2@example.com",
            password="testpass123",
        )
        self.expense_data = {
            "creator": self.user,
            "title": "Test Shared Expense",
            "amount": Decimal("100.00"),
            "split_method": SharedExpense.SplitMethod.EQUAL,
            "category": SharedExpense.CategoryChoices.FOOD,
            "status": SharedExpense.Status.PENDING,
        }

    def test_create_shared_expense(self):
        """Test creating shared expense through service."""
        data = {
            **self.expense_data,
            "participants": [self.participant1.id, self.participant2.id],
        }
        shared_expense = SharedExpenseService.create_shared_expense(data)

        self.assertEqual(shared_expense.title, "Test Shared Expense")
        self.assertEqual(shared_expense.participant_shares.count(), 2)
        self.assertEqual(
            shared_expense.participant_shares.first().amount, Decimal("50.00")
        )

    def test_create_shared_expense_with_percentages(self):
        """Test creating shared expense with percentage splits."""
        data = {
            **self.expense_data,
            "split_method": SharedExpense.SplitMethod.PERCENTAGE,
            "participants": [self.participant1.id, self.participant2.id],
            "percentages": {
                str(self.participant1.id): Decimal("60"),
                str(self.participant2.id): Decimal("40"),
            },
        }
        shared_expense = SharedExpenseService.create_shared_expense(data)

        shares = shared_expense.participant_shares.order_by("amount")
        self.assertEqual(shares[0].amount, Decimal("40.00"))
        self.assertEqual(shares[1].amount, Decimal("60.00"))

    def test_get_user_shared_expenses(self):
        """Test getting user shared expenses."""
        # Create test expenses
        shared_expense1 = SharedExpenseService.create_shared_expense(
            {**self.expense_data, "participants": [self.participant1.id]}
        )
        shared_expense2 = SharedExpenseService.create_shared_expense(
            {**self.expense_data, "participants": [self.participant2.id]}
        )

        # Test creator's view
        creator_expenses = SharedExpenseService.get_user_shared_expenses(
            user_id=self.user.id
        )
        self.assertEqual(len(creator_expenses), 2)

        # Test participant's view
        participant_expenses = SharedExpenseService.get_user_shared_expenses(
            user_id=self.participant1.id
        )
        self.assertEqual(len(participant_expenses), 1)

    def test_get_user_shared_expenses_with_filters(self):
        """Test getting user shared expenses with filters."""
        data = {**self.expense_data, "participants": [self.participant1.id]}
        # Create expenses with different statuses
        shared_expense1 = SharedExpenseService.create_shared_expense(data)
        shared_expense1.status = SharedExpense.Status.ACTIVE
        shared_expense1.save()

        shared_expense2 = SharedExpenseService.create_shared_expense(data)
        shared_expense2.status = SharedExpense.Status.SETTLED
        shared_expense2.save()

        # Test status filter
        active_expenses = SharedExpenseService.get_user_shared_expenses(
            user_id=self.user.id, status=SharedExpense.Status.ACTIVE
        )
        self.assertEqual(len(active_expenses), 1)
        self.assertEqual(active_expenses[0].status, SharedExpense.Status.ACTIVE)

    def test_record_payment(self):
        """Test recording a payment."""
        shared_expense = SharedExpenseService.create_shared_expense(
            {**self.expense_data, "participants": [self.participant1.id]}
        )
        share = shared_expense.participant_shares.first()

        updated_share = SharedExpenseService.record_payment(
            share_id=share.id, amount=Decimal("30.00"), notes="Test payment"
        )

        self.assertEqual(updated_share.amount_paid, Decimal("30.00"))
        self.assertEqual(updated_share.remaining_amount, Decimal("70.00"))
        self.assertFalse(updated_share.is_paid)

    def test_record_payment_with_settlement(self):
        """Test recording a payment that settles the expense."""
        shared_expense = SharedExpenseService.create_shared_expense(
            {**self.expense_data, "participants": [self.participant1.id]}
        )
        share = shared_expense.participant_shares.first()

        updated_share = SharedExpenseService.record_payment(
            share_id=share.id, amount=share.amount, notes="Full payment"
        )

        self.assertTrue(updated_share.is_paid)
        shared_expense.refresh_from_db()
        self.assertEqual(shared_expense.status, SharedExpense.Status.SETTLED)

    def test_send_reminders(self):
        """Test sending reminders for pending payments."""
        shared_expense = SharedExpenseService.create_shared_expense(
            {
                **self.expense_data,
                "status": SharedExpense.Status.ACTIVE,
                "participants": [self.participant1.id, self.participant2.id],
            }
        )

        reminder_count = SharedExpenseService.send_reminders()
        self.assertEqual(reminder_count, 2)  # Both participants get reminders

    def test_get_user_summary(self):
        """Test getting user summary."""
        # Create some test expenses
        SharedExpenseService.create_shared_expense(
            {**self.expense_data, "participants": [self.participant1.id]}
        )
        SharedExpenseService.create_shared_expense(
            {**self.expense_data, "participants": [self.participant2.id]}
        )

        # Get creator's summary
        creator_summary = SharedExpenseService.get_user_summary(self.user.id)
        self.assertEqual(creator_summary["total_created"], Decimal("200.00"))

        # Get participant's summary
        participant_summary = SharedExpenseService.get_user_summary(
            self.participant1.id
        )
        self.assertEqual(participant_summary["total_owed"], Decimal("100.00"))

    def test_get_expense_statistics(self):
        """Test getting expense statistics."""
        shared_expense = SharedExpenseService.create_shared_expense(
            {
                **self.expense_data,
                "participants": [self.participant1.id, self.participant2.id],
            }
        )

        # Record some payments
        share = shared_expense.participant_shares.first()
        SharedExpenseService.record_payment(share_id=share.id, amount=Decimal("30.00"))

        stats = SharedExpenseService.get_expense_statistics(shared_expense.id)
        self.assertEqual(stats["total_amount"], Decimal("100.00"))
        self.assertEqual(stats["total_paid"], Decimal("30.00"))
        self.assertEqual(stats["participant_count"], 2)
        self.assertEqual(stats["payment_progress"], Decimal("30.00"))

    def test_get_user_balance_sheet(self):
        """Test getting user balance sheet."""
        # Create expenses where user is creator
        SharedExpenseService.create_shared_expense(
            {
                **self.expense_data,
                "participants": [self.participant1.id, self.participant2.id],
            }
        )

        # Create expenses where user is participant
        SharedExpenseService.create_shared_expense(
            {
                "creator": self.participant1,
                "title": "Test Shared Expense 2",
                "amount": Decimal("50.00"),
                "split_method": SharedExpense.SplitMethod.EQUAL,
                "participants": [self.user.id],
            }
        )

        balance_sheet = SharedExpenseService.get_user_balance_sheet(self.user.id)
        self.assertIn("owed_to_user", balance_sheet)
        self.assertIn("user_owes", balance_sheet)
        self.assertIn("by_category", balance_sheet)

    def test_invalid_payment_amount(self):
        """Test recording invalid payment amount."""
        shared_expense = SharedExpenseService.create_shared_expense(
            {**self.expense_data, "participants": [self.participant1.id]}
        )
        share = shared_expense.participant_shares.first()

        with self.assertRaises(ValidationError):
            SharedExpenseService.record_payment(
                share_id=share.id, amount=Decimal("200.00")  # More than share amount
            )

    def test_update_shared_expense(self):
        """Test updating shared expense."""
        shared_expense = SharedExpenseService.create_shared_expense(
            {**self.expense_data, "participants": [self.participant1.id]}
        )

        updated_expense = SharedExpenseService.update_shared_expense(
            shared_expense=shared_expense,
            data={"title": "Updated Title", "status": SharedExpense.Status.ACTIVE},
        )

        self.assertEqual(updated_expense.title, "Updated Title")
        self.assertEqual(updated_expense.status, SharedExpense.Status.ACTIVE)
