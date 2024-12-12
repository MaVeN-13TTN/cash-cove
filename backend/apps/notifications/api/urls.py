"""
URL patterns for notifications app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import NotificationViewSet, NotificationPreferenceViewSet

app_name = 'notifications'

router = DefaultRouter()
router.register('', NotificationViewSet, basename='notification')

urlpatterns = [
    # Custom action URLs
    path('mark-all-read/', NotificationViewSet.as_view({'post': 'mark_all_read'}), name='mark-all-read'),
    path('bulk-action/', NotificationViewSet.as_view({'post': 'bulk_action'}), name='bulk-action'),
    path('counts/', NotificationViewSet.as_view({'get': 'counts'}), name='counts'),
    
    # Notification preferences
    path('preferences/', NotificationPreferenceViewSet.as_view({
        'get': 'retrieve',
        'put': 'update',
        'patch': 'partial_update'
    }), name='notification-preferences'),
    
    # Default router URLs
    path('', include(router.urls)),
]
