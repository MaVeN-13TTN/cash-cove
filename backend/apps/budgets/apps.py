# apps/budgets/apps.py
"""
Apps configuration for the budgets application.
"""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class BudgetsConfig(AppConfig):
    """Configuration for budgets application."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.budgets"
    verbose_name = _("Budgets")

    def ready(self):
        """
        Initialize app when it's ready.
        Import signals to register them with Django.
        """
        try:
            import apps.budgets.signals  # pylint: disable=unused-import,import-outside-toplevel
        except ImportError:
            pass
