"""
Tests for notification services.
"""

from datetime import timedelta
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from ..models import Notification, NotificationPreference
from ..services.notifications_service import NotificationService

User = get_user_model()


class NotificationServiceTests(TestCase):
    """Test cases for NotificationService."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.preferences = NotificationPreference.objects.create(
            user=self.user, notification_types=["SYSTEM", "BUDGET_ALERT"]
        )

    def test_create_notification(self):
        """Test creating notification through service."""
        notification = NotificationService.create_notification(
            user_id=self.user.id,
            title="Test Notification",
            message="Test message",
            notification_type="SYSTEM",
        )

        self.assertIsNotNone(notification)
        self.assertEqual(notification.title, "Test Notification")

    def test_get_user_notifications(self):
        """Test getting user notifications."""
        # Create test notifications
        Notification.objects.create(
            user=self.user,
            title="Test 1",
            message="Message 1",
            notification_type="SYSTEM",
        )
        Notification.objects.create(
            user=self.user,
            title="Test 2",
            message="Message 2",
            notification_type="BUDGET_ALERT",
            is_read=True,
        )

        # Test all notifications
        notifications = NotificationService.get_user_notifications(self.user.id)
        self.assertEqual(len(notifications), 2)

        # Test unread only
        unread = NotificationService.get_user_notifications(
            self.user.id, unread_only=True
        )
        self.assertEqual(len(unread), 1)

    def test_mark_all_as_read(self):
        """Test marking all notifications as read."""
        # Create test notifications
        Notification.objects.create(user=self.user, title="Test 1", message="Message 1")
        Notification.objects.create(user=self.user, title="Test 2", message="Message 2")

        count = NotificationService.mark_all_as_read(self.user.id)
        self.assertEqual(count, 2)
        self.assertEqual(
            Notification.objects.filter(user=self.user, is_read=False).count(), 0
        )

    def test_notification_counts(self):
        """Test getting notification counts."""
        # Create test notifications
        Notification.objects.create(
            user=self.user, title="Test 1", notification_type="SYSTEM"
        )
        Notification.objects.create(
            user=self.user, title="Test 2", notification_type="BUDGET_ALERT"
        )

        counts = NotificationService.get_notification_count(self.user.id)
        self.assertEqual(counts["SYSTEM"], 1)
        self.assertEqual(counts["BUDGET_ALERT"], 1)
        self.assertEqual(counts["total"], 2)
