"""
URL configuration for shared expenses application.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SharedExpenseViewSet, ParticipantShareViewSet

router = DefaultRouter()
router.register(r"shared-expenses", SharedExpenseViewSet, basename="shared-expense")
router.register(r"shares", ParticipantShareViewSet, basename="participant-share")

urlpatterns = [
    path("", include(router.urls)),
]
