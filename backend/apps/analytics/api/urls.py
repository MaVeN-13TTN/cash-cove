"""
URL configuration for the analytics application.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    SpendingAnalyticsViewSet,
    BudgetUtilizationViewSet,
    SpendingTrendsView,
    SpendingInsightsView,
)

router = DefaultRouter()
router.register(r"spending", SpendingAnalyticsViewSet, basename="spending-analytics")
router.register(r"utilization", BudgetUtilizationViewSet, basename="budget-utilization")

urlpatterns = [
    path("", include(router.urls)),
    path("trends/", SpendingTrendsView.as_view(), name="spending-trends"),
    path("insights/", SpendingInsightsView.as_view(), name="spending-insights"),
]
