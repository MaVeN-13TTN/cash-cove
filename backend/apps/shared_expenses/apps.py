"""
Apps configuration for the shared expenses application.
"""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class SharedExpensesConfig(AppConfig):
    """
    Configuration for shared expenses application.
    """

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.shared_expenses"
    verbose_name = _("Shared Expenses")

    def ready(self):
        """
        Initialize app when it's ready.
        Import signals to register them with Django.
        """
        try:
            import apps.shared_expenses.signals  # pylint: disable=unused-import,import-outside-toplevel
        except ImportError:
            pass
