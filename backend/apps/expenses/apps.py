# apps/expenses/apps.py
"""
Apps configuration for the expenses application.
"""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class ExpensesConfig(AppConfig):
    """Configuration for expenses application."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.expenses"
    verbose_name = _("Expenses")

    def ready(self):
        """
        Initialize app when it's ready.
        Import signals to register them with Django.
        """
        try:
            import apps.expenses.signals  # pylint: disable=unused-import,import-outside-toplevel
        except ImportError:
            pass
