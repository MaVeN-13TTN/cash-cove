# apps/users/tests/test_services.py
"""
Tests for user services.
"""

from django.test import TestCase
from django.core import mail
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from ..models import Profile
from ..services.auth_service import AuthService
from ..services.users_service import UserService
from ..services.profile_service import ProfileService

User = get_user_model()


class AuthServiceTests(TestCase):
    """Test cases for AuthService."""

    def setUp(self):
        """Set up test data."""
        self.user_data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "testpass123",
            "first_name": "Test",
            "last_name": "User",
        }

    def test_register_user(self):
        """Test user registration."""
        user, profile = AuthService.register_user(self.user_data)

        self.assertIsInstance(user, User)
        self.assertIsInstance(profile, Profile)
        self.assertEqual(user.email, self.user_data["email"])
        self.assertEqual(len(mail.outbox), 1)  # Verification email sent

    def test_get_tokens(self):
        """Test getting authentication tokens."""
        user, _ = AuthService.register_user(self.user_data)
        tokens = AuthService.get_tokens_for_user(user)

        self.assertIn("access", tokens)
        self.assertIn("refresh", tokens)

    def test_verify_email(self):
        """Test email verification."""
        user, _ = AuthService.register_user(self.user_data)
        token = AuthService.get_verification_token(user)

        success = AuthService.verify_email(str(user.pk), token)
        self.assertTrue(success)

        user.refresh_from_db()
        self.assertTrue(user.is_verified)

    def test_password_reset(self):
        """Test password reset process."""
        user, _ = AuthService.register_user(self.user_data)
        AuthService.initiate_password_reset(user.email)

        self.assertEqual(len(mail.outbox), 2)  # Registration + reset emails

        # Test reset confirmation
        token = AuthService.get_password_reset_token(user)
        new_password = "newpass123"
        success = AuthService.reset_password(str(user.pk), token, new_password)

        self.assertTrue(success)
        user.refresh_from_db()
        self.assertTrue(user.check_password(new_password))


class UserServiceTests(TestCase):
    """Test cases for UserService."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            email="test@example.com", username="testuser", password="testpass123"
        )

    def test_update_user(self):
        """Test updating user data."""
        update_data = {"first_name": "Updated", "last_name": "Name"}
        updated_user = UserService.update_user(self.user, update_data)

        self.assertEqual(updated_user.first_name, update_data["first_name"])
        self.assertEqual(updated_user.last_name, update_data["last_name"])

    def test_update_preferences(self):
        """Test updating user preferences."""
        preferences = {"theme": "dark", "language": "es"}
        updated_user = UserService.update_preferences(self.user, preferences)

        self.assertEqual(updated_user.get_preference("theme"), preferences["theme"])

    def test_deactivate_account(self):
        """Test account deactivation."""
        # Test with correct password
        success = UserService.deactivate_account(self.user, "testpass123")
        self.assertTrue(success)
        self.user.refresh_from_db()
        self.assertFalse(self.user.is_active)

        # Test with wrong password
        with self.assertRaises(ValidationError):
            UserService.deactivate_account(self.user, "wrongpass")


class ProfileServiceTests(TestCase):
    """Test cases for ProfileService."""

    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            email="test@example.com", username="testuser", password="testpass123"
        )
        self.profile = self.user.profile

    def test_update_profile(self):
        """Test updating profile data."""
        update_data = {
            "theme": Profile.ThemeChoices.DARK,
            "default_currency": Profile.CurrencyChoices.EUR,
        }
        updated_profile = ProfileService.update_profile(self.profile, update_data)

        self.assertEqual(updated_profile.theme, update_data["theme"])
        self.assertEqual(
            updated_profile.default_currency, update_data["default_currency"]
        )

    def test_toggle_two_factor(self):
        """Test toggling 2FA."""
        initial_state = self.profile.two_factor_enabled
        new_state = ProfileService.toggle_two_factor(self.profile)

        self.assertNotEqual(initial_state, new_state)
        self.profile.refresh_from_db()
        self.assertEqual(self.profile.two_factor_enabled, new_state)

    def test_get_or_create_profile(self):
        """Test getting or creating profile."""
        # Test getting existing profile
        profile = ProfileService.get_or_create_profile(self.user)
        self.assertEqual(profile, self.profile)

        # Test creating new profile
        new_user = User.objects.create_user(
            email="new@example.com", username="newuser", password="pass123"
        )
        new_profile = ProfileService.get_or_create_profile(new_user)

        self.assertIsInstance(new_profile, Profile)
        self.assertEqual(new_profile.user, new_user)
