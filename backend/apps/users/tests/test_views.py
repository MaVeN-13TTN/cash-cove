# apps/users/tests/test_views.py
"""
Tests for user views.
"""

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from django.core import mail
from ..models import Profile

User = get_user_model()


class UserViewTests(APITestCase):
    """Test cases for user views."""

    def setUp(self):
        """Set up test data."""
        self.user_data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "testpass123",
            "confirm_password": "testpass123",
            "first_name": "Test",
            "last_name": "User",
        }
        self.user = User.objects.create_user(
            email="existinguser@example.com",
            username="existinguser",
            password="testpass123",
        )

    def test_register_user(self):
        """Test user registration."""
        url = reverse("user-register")
        response = self.client.post(url, self.user_data)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("user", response.data)
        self.assertIn("tokens", response.data)
        self.assertEqual(len(mail.outbox), 1)  # Verification email

    def test_register_duplicate_email(self):
        """Test registration with duplicate email."""
        url = reverse("user-register")
        data = self.user_data.copy()
        data["email"] = "existinguser@example.com"
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login(self):
        """Test user login."""
        url = reverse("user-login")
        data = {"email": "existinguser@example.com", "password": "testpass123"}
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

    def test_login_invalid_credentials(self):
        """Test login with invalid credentials."""
        url = reverse("user-login")
        data = {"email": "existinguser@example.com", "password": "wrongpass"}
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_user_detail(self):
        """Test retrieving user details."""
        self.client.force_authenticate(user=self.user)
        url = reverse("user-detail", args=[self.user.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["email"], self.user.email)

    def test_update_user(self):
        """Test updating user details."""
        self.client.force_authenticate(user=self.user)
        url = reverse("user-detail", args=[self.user.id])
        data = {"first_name": "Updated", "last_name": "Name"}
        response = self.client.patch(url, data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["first_name"], data["first_name"])
        self.assertEqual(response.data["last_name"], data["last_name"])

    def test_change_password(self):
        """Test changing user password."""
        self.client.force_authenticate(user=self.user)
        url = reverse("user-detail", args=[self.user.id])
        data = {"current_password": "testpass123", "new_password": "newpass123"}
        response = self.client.patch(url, data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("newpass123"))

    def test_reset_password_request(self):
        """Test password reset request."""
        url = reverse("user-reset-password")
        data = {"email": self.user.email}
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(mail.outbox), 1)  # Password reset email

    def test_deactivate_account(self):
        """Test account deactivation."""
        self.client.force_authenticate(user=self.user)
        url = reverse("user-deactivate", args=[self.user.id])
        data = {"password": "testpass123"}
        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertFalse(self.user.is_active)


class ProfileViewTests(APITestCase):
    """Test cases for profile views."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            email="test@example.com", username="testuser", password="testpass123"
        )
        self.profile = self.user.profile

    def test_get_profile(self):
        """Test retrieving user profile."""
        self.client.force_authenticate(user=self.user)
        url = reverse("profile-detail", args=[self.profile.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["user_email"], self.user.email)

    def test_update_profile(self):
        """Test updating profile."""
        self.client.force_authenticate(user=self.user)
        url = reverse("profile-detail", args=[self.profile.id])
        data = {
            "theme": Profile.ThemeChoices.DARK,
            "default_currency": Profile.CurrencyChoices.EUR,
        }
        response = self.client.patch(url, data)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["theme"], data["theme"])
        self.assertEqual(response.data["default_currency"], data["default_currency"])

    def test_toggle_2fa(self):
        """Test toggling two-factor authentication."""
        self.client.force_authenticate(user=self.user)
        url = reverse("profile-toggle-2fa", args=[self.profile.id])
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.profile.refresh_from_db()
        self.assertTrue(self.profile.two_factor_enabled)

    def test_unauthorized_access(self):
        """Test unauthorized access to profile."""
        url = reverse("profile-detail", args=[self.profile.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_wrong_user_access(self):
        """Test accessing another user's profile."""
        other_user = User.objects.create_user(
            email="other@example.com", username="otheruser", password="testpass123"
        )
        self.client.force_authenticate(user=other_user)
        url = reverse("profile-detail", args=[self.profile.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
