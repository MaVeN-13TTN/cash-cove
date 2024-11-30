# apps/users/apps.py
"""
Apps configuration for users application.
"""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class UsersConfig(AppConfig):
    """
    Configuration for users application.
    """

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.users"
    verbose_name = _("Users")

    def ready(self):
        """
        Initialize app when it's ready.
        Import signals to register them with Django.
        """
        try:
            import apps.users.signals  # pylint: disable=unused-import,import-outside-toplevel
        except ImportError:
            pass  # apps/users/apps.py


"""
Apps configuration for users application.
"""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class UsersConfig(AppConfig):
    """
    Configuration for users application.
    """

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.users"
    verbose_name = _("Users")

    def ready(self):
        """
        Initialize app when it's ready.
        Import signals to register them with Django.
        """
        try:
            import apps.users.signals  # pylint: disable=unused-import,import-outside-toplevel
        except ImportError:
            pass
