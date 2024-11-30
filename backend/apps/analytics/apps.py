# apps/analytics/apps.py
"""
Apps configuration for the analytics application.
"""

import logging
from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _

logger = logging.getLogger(__name__)


class AnalyticsConfig(AppConfig):
    """
    Configuration for the analytics application.
    """

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.analytics"
    verbose_name = _("Analytics")

    def ready(self):
        """
        Perform initialization when the app is ready.
        Import signals to register them with Django.
        """
        try:
            import apps.analytics.signals  # pylint: disable=unused-import,import-outside-toplevel

            logger.debug("Successfully imported analytics signals")
        except ImportError as e:
            logger.warning("Could not import analytics signals: %s", str(e))
