"""
API views for the notifications application.
"""

from typing import Any
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils.translation import gettext_lazy as _

from ..models import Notification, NotificationPreference
from ..serializers.notifications_serializer import (
    NotificationSerializer,
    NotificationCreateSerializer,
    NotificationListSerializer,
    NotificationPreferenceSerializer,
    NotificationBulkActionSerializer,
)
from ..services.notifications_service import NotificationService


class NotificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing notifications.
    """

    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get queryset filtered by user and optional parameters."""
        unread_only = self.request.query_params.get("unread", "false").lower() == "true"
        include_expired = (
            self.request.query_params.get("include_expired", "false").lower() == "true"
        )
        notification_type = self.request.query_params.get("type")

        return NotificationService.get_user_notifications(
            user_id=self.request.user.id,
            unread_only=unread_only,
            include_expired=include_expired,
            notification_type=notification_type,
        )

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == "create":
            return NotificationCreateSerializer
        if self.action == "list":
            return NotificationListSerializer
        return NotificationSerializer

    def perform_create(self, serializer):
        """Create notification for current user."""
        serializer.save(user=self.request.user)

    @action(detail=False, methods=["post"])
    def mark_all_read(self, request: Request) -> Response:
        """
        Mark all notifications as read.
        """
        count = NotificationService.mark_all_as_read(request.user.id)
        return Response({"marked_read": count})

    @action(detail=False, methods=["post"])
    def bulk_action(self, request: Request) -> Response:
        """
        Perform bulk actions on notifications.
        """
        serializer = NotificationBulkActionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        notification_ids = serializer.validated_data["notification_ids"]
        action = serializer.validated_data["action"]

        if action == "mark_read":
            Notification.objects.filter(
                user=request.user, id__in=notification_ids, is_read=False
            ).update(is_read=True)
            return Response({"status": "notifications marked as read"})

        elif action == "mark_unread":
            Notification.objects.filter(
                user=request.user, id__in=notification_ids, is_read=True
            ).update(is_read=False)
            return Response({"status": "notifications marked as unread"})

        elif action == "delete":
            count = NotificationService.bulk_delete_notifications(
                user_id=request.user.id, notification_ids=notification_ids
            )
            return Response({"deleted": count})

    @action(detail=False, methods=["get"])
    def counts(self, request: Request) -> Response:
        """
        Get notification counts by type.
        """
        unread_only = request.query_params.get("unread", "true").lower() == "true"
        counts = NotificationService.get_notification_count(
            user_id=request.user.id, unread_only=unread_only
        )
        return Response(counts)


class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing notification preferences.
    """
    serializer_class = NotificationPreferenceSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Get the queryset for notification preferences."""
        return NotificationPreference.objects.filter(user=self.request.user)
    
    def get_object(self):
        """Get the notification preferences object for the current user."""
        queryset = self.get_queryset()
        obj, created = NotificationPreference.objects.get_or_create(user=self.request.user)
        return obj
    
    def perform_update(self, serializer):
        """Update notification preferences."""
        serializer.save(user=self.request.user)

    @action(detail=False, methods=["post"])
    def update_preferences(self, request: Request) -> Response:
        """
        Update user notification preferences.
        """
        preferences = NotificationService.update_user_preferences(
            user_id=request.user.id, preferences_data=request.data
        )
        serializer = self.get_serializer(preferences)
        return Response(serializer.data)
