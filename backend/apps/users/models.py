"""
Models for the users application.
"""

from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils.translation import gettext_lazy as _
from django.core.validators import RegexValidator


class User(AbstractUser):
    """
    Custom user model extending Django's AbstractUser.
    """

    phone_regex = RegexValidator(
        regex=r"^\+?1?\d{9,15}$",
        message=_(
            "Phone number must be entered in format: '+999999999'. Up to 15 digits allowed."
        ),
    )

    email = models.EmailField(_("Email Address"), unique=True)
    phone_number = models.CharField(
        _("Phone Number"), max_length=16, validators=[phone_regex], blank=True
    )
    date_of_birth = models.DateField(_("Date of Birth"), null=True, blank=True)
    avatar = models.ImageField(_("Avatar"), upload_to="avatars/", null=True, blank=True)
    bio = models.TextField(_("Bio"), max_length=500, blank=True)
    is_verified = models.BooleanField(_("Verified"), default=False)
    last_login_ip = models.GenericIPAddressField(
        _("Last Login IP"), null=True, blank=True
    )
    preferences = models.JSONField(_("Preferences"), default=dict, blank=True)

    class Meta:
        """
        Meta options for User model.
        """

        verbose_name = _("User")
        verbose_name_plural = _("Users")
        ordering = ["-date_joined"]

    def __str__(self) -> str:
        """String representation of user."""
        return self.email

    def get_full_name(self) -> str:
        """
        Get user's full name.

        Returns:
            str: Full name or email if no name set
        """
        full_name = super().get_full_name()
        return full_name if full_name else self.email

    def update_last_login_ip(self, ip_address: str) -> None:
        """
        Update user's last login IP address.

        Args:
            ip_address: IP address to set
        """
        self.last_login_ip = ip_address
        self.save(update_fields=["last_login_ip"])

    def get_preference(self, key: str, default: any = None) -> any:
        """
        Get a user preference value.

        Args:
            key: Preference key
            default: Default value if key not found

        Returns:
            Value of preference or default
        """
        return self.preferences.get(key, default)

    def set_preference(self, key: str, value: any) -> None:
        """
        Set a user preference value.

        Args:
            key: Preference key
            value: Value to set
        """
        self.preferences[key] = value
        self.save(update_fields=["preferences"])


class Profile(models.Model):
    """
    Additional user profile information.
    """

    class ThemeChoices(models.TextChoices):
        """Theme choices."""

        LIGHT = "LIGHT", _("Light")
        DARK = "DARK", _("Dark")
        SYSTEM = "SYSTEM", _("System Default")

    class CurrencyChoices(models.TextChoices):
        """Currency choices."""

        USD = "USD", _("US Dollar")
        EUR = "EUR", _("Euro")
        GBP = "GBP", _("British Pound")
        JPY = "JPY", _("Japanese Yen")
        AUD = "AUD", _("Australian Dollar")
        CAD = "CAD", _("Canadian Dollar")
        CHF = "CHF", _("Swiss Franc")
        CNY = "CNY", _("Chinese Yuan")
        INR = "INR", _("Indian Rupee")

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="profile", verbose_name=_("User")
    )
    theme = models.CharField(
        _("Theme"),
        max_length=10,
        choices=ThemeChoices.choices,
        default=ThemeChoices.SYSTEM,
    )
    default_currency = models.CharField(
        _("Default Currency"),
        max_length=3,
        choices=CurrencyChoices.choices,
        default=CurrencyChoices.USD,
    )
    language = models.CharField(_("Language"), max_length=10, default="en")
    timezone = models.CharField(_("Timezone"), max_length=50, default="UTC")
    notification_emails = models.BooleanField(_("Email Notifications"), default=True)
    activity_emails = models.BooleanField(_("Activity Emails"), default=True)
    marketing_emails = models.BooleanField(_("Marketing Emails"), default=False)
    two_factor_enabled = models.BooleanField(_("2FA Enabled"), default=False)
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)

    class Meta:
        """
        Meta options for Profile model.
        """

        verbose_name = _("Profile")
        verbose_name_plural = _("Profiles")

    def __str__(self) -> str:
        """String representation of profile."""
        return f"{self.user.email}'s Profile"

    def toggle_two_factor(self) -> bool:
        """
        Toggle 2FA status.

        Returns:
            bool: New 2FA status
        """
        self.two_factor_enabled = not self.two_factor_enabled
        self.save(update_fields=["two_factor_enabled", "updated_at"])
        return self.two_factor_enabled
