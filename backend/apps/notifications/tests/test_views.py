"""
Tests for notification views.
"""

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from ..models import Notification, NotificationPreference

User = get_user_model()


class NotificationViewTests(APITestCase):
    """Test cases for notification views."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.client.force_authenticate(user=self.user)

        self.notification = Notification.objects.create(
            user=self.user,
            title="Test Notification",
            message="Test message",
            notification_type="SYSTEM",
        )

    def test_list_notifications(self):
        """Test listing notifications."""
        url = reverse("notification-list")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_mark_all_read(self):
        """Test marking all notifications as read."""
        url = reverse("notification-mark-all-read")
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            Notification.objects.filter(user=self.user, is_read=True).count(), 1
        )

    def test_bulk_actions(self):
        """Test bulk actions on notifications."""
        url = reverse("notification-bulk-action")
        data = {"notification_ids": [self.notification.id], "action": "mark_read"}
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.notification.refresh_from_db()
        self.assertTrue(self.notification.is_read)

    def test_notification_counts(self):
        """Test getting notification counts."""
        url = reverse("notification-counts")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["total"], 1)

    def test_unauthorized_access(self):
        """Test unauthorized access to notifications."""
        self.client.force_authenticate(user=None)
        url = reverse("notification-list")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
