"""
URL configuration for budget_tracker project.
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/users/", include("apps.users.api.urls")),
    path("api/budgets/", include("apps.budgets.api.urls")),
    path("api/expenses/", include("apps.expenses.api.urls")),
    path("api/analytics/", include("apps.analytics.api.urls")),
    path("api/notifications/", include("apps.notifications.api.urls")),
    path("api/shared-expenses/", include("apps.shared_expenses.api.urls")),
]

# Add debug toolbar URLs in development
if settings.DEBUG:
    try:
        import debug_toolbar

        urlpatterns = [
            path("__debug__/", include(debug_toolbar.urls)),
        ] + urlpatterns

    # Handle case where debug_toolbar is not installed
    except ImportError:
        pass

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
