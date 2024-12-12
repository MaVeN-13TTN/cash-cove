"""
Apps configuration for notifications app.
"""

from django.apps import AppConfig


class NotificationsConfig(AppConfig):
    """Configuration for notifications app."""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.notifications'
    
    def ready(self):
        """Register signals when app is ready."""
        import apps.notifications.signals  # noqa
