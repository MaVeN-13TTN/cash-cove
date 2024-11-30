"""
Apps configuration for the notifications application.
"""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class NotificationsConfig(AppConfig):
    """Configuration for notifications application."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.notifications"
    verbose_name = _("Notifications")

    def ready(self):
        """
        Initialize app when it's ready.
        Import signals to register them with Django.
        """
        try:
            import apps.notifications.signals  # pylint: disable=unused-import,import-outside-toplevel
        except ImportError:
            pass
