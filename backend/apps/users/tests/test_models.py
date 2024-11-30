# apps/users/tests/test_models.py
"""
Tests for user models.
"""

from django.test import TestCase
from django.core.exceptions import ValidationError
from django.contrib.auth import get_user_model
from ..models import Profile

User = get_user_model()


class UserModelTests(TestCase):
    """Test cases for User model."""

    def setUp(self):
        """Set up test data."""
        self.user_data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "testpass123",
            "first_name": "Test",
            "last_name": "User",
        }
        self.user = User.objects.create_user(**self.user_data)

    def test_user_creation(self):
        """Test creating a user."""
        self.assertEqual(self.user.email, self.user_data["email"])
        self.assertEqual(self.user.username, self.user_data["username"])
        self.assertTrue(self.user.check_password(self.user_data["password"]))
        self.assertTrue(hasattr(self.user, "profile"))

    def test_user_str(self):
        """Test string representation of user."""
        self.assertEqual(str(self.user), self.user_data["email"])

    def test_get_full_name(self):
        """Test getting user's full name."""
        expected = f"{self.user_data['first_name']} {self.user_data['last_name']}"
        self.assertEqual(self.user.get_full_name(), expected)

    def test_email_unique(self):
        """Test email uniqueness."""
        with self.assertRaises(Exception):
            User.objects.create_user(
                email=self.user_data["email"], username="another", password="pass123"
            )

    def test_user_preferences(self):
        """Test user preferences."""
        self.user.set_preference("theme", "dark")
        self.assertEqual(self.user.get_preference("theme"), "dark")
        self.assertIsNone(self.user.get_preference("nonexistent"))

    def test_update_last_login_ip(self):
        """Test updating last login IP."""
        ip = "127.0.0.1"
        self.user.update_last_login_ip(ip)
        self.assertEqual(self.user.last_login_ip, ip)


class ProfileModelTests(TestCase):
    """Test cases for Profile model."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            email="test@example.com", username="testuser", password="testpass123"
        )
        self.profile = self.user.profile

    def test_profile_creation(self):
        """Test profile is created automatically."""
        self.assertIsInstance(self.profile, Profile)
        self.assertEqual(self.profile.user, self.user)

    def test_profile_str(self):
        """Test string representation of profile."""
        expected = f"{self.user.email}'s Profile"
        self.assertEqual(str(self.profile), expected)

    def test_default_values(self):
        """Test profile default values."""
        self.assertEqual(self.profile.theme, Profile.ThemeChoices.SYSTEM)
        self.assertEqual(self.profile.default_currency, Profile.CurrencyChoices.USD)
        self.assertTrue(self.profile.notification_emails)
        self.assertFalse(self.profile.two_factor_enabled)

    def test_toggle_two_factor(self):
        """Test toggling two-factor authentication."""
        initial_state = self.profile.two_factor_enabled
        new_state = self.profile.toggle_two_factor()
        self.assertNotEqual(initial_state, new_state)
        self.assertEqual(self.profile.two_factor_enabled, new_state)

    def test_email_preferences(self):
        """Test email preferences."""
        self.profile.notification_emails = False
        self.profile.activity_emails = False
        self.profile.save()

        self.assertFalse(self.profile.notification_emails)
        self.assertFalse(self.profile.activity_emails)
        self.assertFalse(self.profile.marketing_emails)  # Default False
