"""
Tests for shared expenses models.
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.utils import timezone
from apps.expenses.models import Expense
from ..models import SharedExpense, ParticipantShare

User = get_user_model()


class SharedExpenseModelTests(TestCase):
    """Test cases for SharedExpense model."""

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
        self.expense = Expense.objects.create(
            user=self.user,
            title="Test Expense",
            amount=Decimal("100.00"),
            category=Expense.CategoryChoices.FOOD,
            date=timezone.now().date(),
        )
        self.shared_expense = SharedExpense.objects.create(
            creator=self.user,
            title="Test Shared Expense",
            amount=Decimal("100.00"),
            split_method=SharedExpense.SplitMethod.EQUAL,
            category=SharedExpense.CategoryChoices.FOOD,
            expense=self.expense,
        )
        self.participant_share = ParticipantShare.objects.create(
            shared_expense=self.shared_expense,
            participant=self.participant,
            amount=Decimal("50.00"),
        )

    def test_shared_expense_creation(self):
        """Test creating a shared expense."""
        self.assertEqual(self.shared_expense.title, "Test Shared Expense")
        self.assertEqual(self.shared_expense.amount, Decimal("100.00"))
        self.assertEqual(self.shared_expense.status, SharedExpense.Status.PENDING)
        self.assertFalse(self.shared_expense.is_settled)

    def test_total_shares(self):
        """Test total shares calculation."""
        # Create another participant
        second_participant = User.objects.create_user(
            username="participant2",
            email="participant2@example.com",
            password="testpass123",
        )
        ParticipantShare.objects.create(
            shared_expense=self.shared_expense,
            participant=second_participant,
            amount=Decimal("50.00"),
        )

        self.assertEqual(self.shared_expense.total_shares, 2)

    def test_total_paid(self):
        """Test total paid calculation."""
        self.participant_share.record_payment(Decimal("30.00"))
        self.assertEqual(self.shared_expense.total_paid, Decimal("30.00"))

    def test_remaining_amount(self):
        """Test remaining amount calculation."""
        self.participant_share.record_payment(Decimal("30.00"))
        self.assertEqual(self.shared_expense.remaining_amount, Decimal("70.00"))

    def test_invalid_status_transition(self):
        """Test invalid status transition."""
        self.shared_expense.status = SharedExpense.Status.SETTLED
        with self.assertRaises(ValidationError):
            self.shared_expense.save()


class ParticipantShareModelTests(TestCase):
    """Test cases for ParticipantShare model."""

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
        self.shared_expense = SharedExpense.objects.create(
            creator=self.user,
            title="Test Shared Expense",
            amount=Decimal("100.00"),
            split_method=SharedExpense.SplitMethod.EQUAL,
        )
        self.participant_share = ParticipantShare.objects.create(
            shared_expense=self.shared_expense,
            participant=self.participant,
            amount=Decimal("50.00"),
        )

    def test_participant_share_creation(self):
        """Test creating a participant share."""
        self.assertEqual(self.participant_share.amount, Decimal("50.00"))
        self.assertEqual(self.participant_share.amount_paid, Decimal("0.00"))
        self.assertFalse(self.participant_share.is_paid)

    def test_record_payment(self):
        """Test recording a payment."""
        self.participant_share.record_payment(Decimal("30.00"))
        self.assertEqual(self.participant_share.amount_paid, Decimal("30.00"))
        self.assertEqual(self.participant_share.remaining_amount, Decimal("20.00"))

    def test_is_paid(self):
        """Test is_paid property."""
        self.participant_share.record_payment(Decimal("50.00"))
        self.assertTrue(self.participant_share.is_paid)

    def test_overpayment_prevention(self):
        """Test prevention of overpayment."""
        with self.assertRaises(ValidationError):
            self.participant_share.record_payment(Decimal("60.00"))

    def test_remaining_amount(self):
        """Test remaining amount calculation."""
        self.participant_share.record_payment(Decimal("30.00"))
        self.assertEqual(self.participant_share.remaining_amount, Decimal("20.00"))

    def test_unique_participant_constraint(self):
        """Test unique participant constraint."""
        with self.assertRaises(Exception):  # Could be IntegrityError or ValidationError
            ParticipantShare.objects.create(
                shared_expense=self.shared_expense,
                participant=self.participant,
                amount=Decimal("50.00"),
            )
