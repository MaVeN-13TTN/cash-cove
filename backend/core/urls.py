"""
URL configuration for budget_tracker project.
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/auth/", include("apps.users.api.auth_urls")),
    path("api/v1/users/", include("apps.users.api.urls")),
    path("api/v1/budgets/", include("apps.budgets.api.urls")),
    path("api/v1/expenses/", include("apps.expenses.api.urls")),
    path("api/v1/analytics/", include("apps.analytics.api.urls")),
    path("api/v1/notifications/", include("apps.notifications.api.urls")),
    path("api/v1/shared-expenses/", include("apps.shared_expenses.api.urls")),
    
    # API Schema and Documentation
    path("api/v1/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/v1/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/v1/redoc/", SpectacularRedocView.as_view(url_name="schema"), name="redoc"),
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
