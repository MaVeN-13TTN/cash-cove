"""
Tests for notification models.
"""

from datetime import timedelta
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from ..models import Notification, NotificationPreference

User = get_user_model()


class NotificationModelTests(TestCase):
    """Test cases for Notification model."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.notification = Notification.objects.create(
            user=self.user,
            title="Test Notification",
            message="Test message",
            notification_type=Notification.NotificationTypes.SYSTEM,
            priority=Notification.Priority.MEDIUM,
        )

    def test_notification_creation(self):
        """Test creating a notification."""
        self.assertEqual(self.notification.title, "Test Notification")
        self.assertEqual(self.notification.message, "Test message")
        self.assertFalse(self.notification.is_read)
        self.assertIsNone(self.notification.read_at)

    def test_mark_as_read(self):
        """Test marking notification as read."""
        self.notification.mark_as_read()
        self.assertTrue(self.notification.is_read)
        self.assertIsNotNone(self.notification.read_at)

    def test_mark_as_unread(self):
        """Test marking notification as unread."""
        self.notification.mark_as_read()
        self.notification.mark_as_unread()
        self.assertFalse(self.notification.is_read)
        self.assertIsNone(self.notification.read_at)

    def test_notification_expiry(self):
        """Test notification expiry."""
        # Create expired notification
        expired_notification = Notification.objects.create(
            user=self.user,
            title="Expired Notification",
            message="Expired message",
            expires_at=timezone.now() - timedelta(days=1),
        )
        self.assertTrue(expired_notification.is_expired)

        # Non-expired notification
        self.assertFalse(self.notification.is_expired)

    def test_age_in_minutes(self):
        """Test age calculation."""
        age = self.notification.age_in_minutes
        self.assertGreaterEqual(age, 0)


class NotificationPreferenceTests(TestCase):
    """Test cases for NotificationPreference model."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.preferences = NotificationPreference.objects.create(
            user=self.user,
            email_notifications=True,
            push_notifications=True,
            notification_types=["SYSTEM", "BUDGET_ALERT"],
            minimum_priority=Notification.Priority.LOW,
        )

    def test_preference_creation(self):
        """Test creating notification preferences."""
        self.assertTrue(self.preferences.email_notifications)
        self.assertTrue(self.preferences.push_notifications)
        self.assertEqual(len(self.preferences.notification_types), 2)

    def test_can_notify(self):
        """Test notification permission check."""
        # Test allowed notification
        can_notify = self.preferences.can_notify("SYSTEM", Notification.Priority.MEDIUM)
        self.assertTrue(can_notify)

        # Test disabled notification type
        can_notify = self.preferences.can_notify(
            "REMINDER", Notification.Priority.MEDIUM
        )
        self.assertFalse(can_notify)

        # Test priority below minimum
        self.preferences.minimum_priority = Notification.Priority.HIGH
        self.preferences.save()
        can_notify = self.preferences.can_notify("SYSTEM", Notification.Priority.MEDIUM)
        self.assertFalse(can_notify)
