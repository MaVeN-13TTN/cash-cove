"""
Test cases for notification models.
"""

from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.notifications.models import Notification, NotificationPreference

User = get_user_model()


class NotificationModelTest(TestCase):
    """Test cases for Notification model."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123",
        )
        self.notification = Notification.objects.create(
            user=self.user,
            title="Test Notification",
            message="This is a test notification",
            notification_type=Notification.NotificationTypes.SYSTEM,
            priority=Notification.Priority.MEDIUM,
        )

    def test_notification_creation(self):
        """Test notification creation."""
        self.assertEqual(self.notification.title, "Test Notification")
        self.assertEqual(self.notification.message, "This is a test notification")
        self.assertEqual(
            self.notification.notification_type,
            Notification.NotificationTypes.SYSTEM,
        )
        self.assertEqual(self.notification.priority, Notification.Priority.MEDIUM)
        self.assertFalse(self.notification.is_read)
        self.assertIsNone(self.notification.read_at)

    def test_notification_mark_as_read(self):
        """Test marking notification as read."""
        self.notification.mark_as_read()
        self.assertTrue(self.notification.is_read)
        self.assertIsNotNone(self.notification.read_at)

    def test_notification_str_method(self):
        """Test notification string representation."""
        expected_str = f"{self.notification.title} - {self.notification.user.username}"
        self.assertEqual(str(self.notification), expected_str)

    def test_notification_ordering(self):
        """Test notification ordering."""
        older_notification = Notification.objects.create(
            user=self.user,
            title="Older Notification",
            message="This is an older notification",
            notification_type=Notification.NotificationTypes.SYSTEM,
            priority=Notification.Priority.LOW,
        )
        notifications = Notification.objects.all()
        self.assertEqual(notifications[0], self.notification)
        self.assertEqual(notifications[1], older_notification)


class NotificationPreferenceModelTest(TestCase):
    """Test cases for NotificationPreference model."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123",
        )
        self.preferences = NotificationPreference.objects.create(
            user=self.user,
            budget_alerts=True,
            expense_alerts=True,
            system_notifications=True,
            reminders=True,
            budget_exceeded_alerts=True,
            recurring_expense_alerts=True,
            threshold_alerts=True,
            email_notifications=True,
            push_notifications=True,
            notification_frequency="immediate",
        )

    def test_preference_creation(self):
        """Test notification preference creation."""
        self.assertTrue(self.preferences.budget_alerts)
        self.assertTrue(self.preferences.expense_alerts)
        self.assertTrue(self.preferences.system_notifications)
        self.assertTrue(self.preferences.email_notifications)
        self.assertTrue(self.preferences.push_notifications)
        self.assertEqual(self.preferences.notification_frequency, "immediate")

    def test_preference_update(self):
        """Test updating notification preferences."""
        self.preferences.budget_alerts = False
        self.preferences.email_notifications = False
        self.preferences.notification_frequency = "daily"
        self.preferences.save()

        updated_preferences = NotificationPreference.objects.get(user=self.user)
        self.assertFalse(updated_preferences.budget_alerts)
        self.assertFalse(updated_preferences.email_notifications)
        self.assertEqual(updated_preferences.notification_frequency, "daily")

    def test_preference_str_method(self):
        """Test preference string representation."""
        expected_str = f"Notification Preferences for {self.user.username}"
        self.assertEqual(str(self.preferences), expected_str)
