"""
Test cases for notification services.
"""

from django.test import TestCase
from django.contrib.auth import get_user_model
from apps.notifications.models import Notification, NotificationPreference
from apps.notifications.services.notifications_service import NotificationService

User = get_user_model()


class NotificationServiceTest(TestCase):
    """Test cases for NotificationService."""

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

    def test_create_notification(self):
        """Test creating a notification."""
        notification = NotificationService.create_notification(
            user_id=self.user.id,
            title="Test Notification",
            message="This is a test notification",
            notification_type=Notification.NotificationTypes.SYSTEM,
            priority=Notification.Priority.MEDIUM,
        )

        self.assertEqual(notification.title, "Test Notification")
        self.assertEqual(notification.message, "This is a test notification")
        self.assertEqual(
            notification.notification_type, Notification.NotificationTypes.SYSTEM
        )
        self.assertEqual(notification.priority, Notification.Priority.MEDIUM)
        self.assertEqual(notification.user, self.user)

    def test_get_user_notifications(self):
        """Test retrieving user notifications."""
        # Create test notifications
        NotificationService.create_notification(
            user_id=self.user.id,
            title="Test Notification 1",
            message="This is test notification 1",
            notification_type=Notification.NotificationTypes.SYSTEM,
            priority=Notification.Priority.LOW,
        )
        NotificationService.create_notification(
            user_id=self.user.id,
            title="Test Notification 2",
            message="This is test notification 2",
            notification_type=Notification.NotificationTypes.BUDGET_ALERT,
            priority=Notification.Priority.HIGH,
        )

        # Get notifications
        notifications = NotificationService.get_user_notifications(self.user.id)
        self.assertEqual(len(notifications), 2)

    def test_mark_notification_as_read(self):
        """Test marking a notification as read."""
        notification = NotificationService.create_notification(
            user_id=self.user.id,
            title="Test Notification",
            message="This is a test notification",
            notification_type=Notification.NotificationTypes.SYSTEM,
            priority=Notification.Priority.MEDIUM,
        )

        NotificationService.mark_as_read(notification.id)
        updated_notification = Notification.objects.get(id=notification.id)
        self.assertTrue(updated_notification.is_read)
        self.assertIsNotNone(updated_notification.read_at)

    def test_delete_notification(self):
        """Test deleting a notification."""
        notification = NotificationService.create_notification(
            user_id=self.user.id,
            title="Test Notification",
            message="This is a test notification",
            notification_type=Notification.NotificationTypes.SYSTEM,
            priority=Notification.Priority.MEDIUM,
        )

        NotificationService.delete_notification(notification.id)
        with self.assertRaises(Notification.DoesNotExist):
            Notification.objects.get(id=notification.id)
