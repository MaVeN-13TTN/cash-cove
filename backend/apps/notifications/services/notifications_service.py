"""
Service layer for notification operations.
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional
from django.db.models import Q
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.conf import settings
from ..models import Notification, NotificationPreference

User = get_user_model()


class NotificationService:
    """
    Service class for handling notification operations.
    """

    @staticmethod
    def create_notification(
        user_id: int,
        title: str,
        message: str,
        notification_type: str,
        priority: str = Notification.Priority.MEDIUM,
        action_url: str = "",
        data: Dict = None,
        expires_at: Optional[datetime] = None,
    ) -> Notification:
        """
        Create a new notification.

        Args:
            user_id: ID of the user
            title: Notification title
            message: Notification message
            notification_type: Type of notification
            priority: Priority level
            action_url: Optional action URL
            data: Additional data
            expires_at: Expiration datetime

        Returns:
            Notification: Created notification
        """
        user = User.objects.get(id=user_id)

        # Check notification preferences
        try:
            preferences = user.notification_preferences
            
            # Check if this type of notification is enabled
            if notification_type == 'BUDGET_ALERT' and not preferences.budget_alerts:
                return None
            elif notification_type == 'EXPENSE_ALERT' and not preferences.expense_alerts:
                return None
            elif notification_type == 'SYSTEM' and not preferences.system_notifications:
                return None
            elif notification_type == 'REMINDER' and not preferences.reminders:
                return None
            elif notification_type == 'BUDGET_EXCEEDED' and not preferences.budget_exceeded_alerts:
                return None
            elif notification_type == 'RECURRING_EXPENSE' and not preferences.recurring_expense_alerts:
                return None
            elif notification_type == 'THRESHOLD_REACHED' and not preferences.threshold_alerts:
                return None
                
        except NotificationPreference.DoesNotExist:
            pass  # No preferences set, proceed with notification

        notification = Notification.objects.create(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            priority=priority,
            action_url=action_url,
            data=data or {},
            expires_at=expires_at,
        )

        # Handle email notifications
        if (
            not hasattr(user, "notification_preferences")
            or user.notification_preferences.email_notifications
        ):
            NotificationService._send_email_notification(notification)

        return notification

    @staticmethod
    def _send_email_notification(notification: Notification) -> None:
        """
        Send email notification.

        Args:
            notification: Notification instance
        """
        subject = f"[Budget Tracker] {notification.title}"
        message = f"{notification.message}\n\n"
        if notification.action_url:
            message += f"Action required: {notification.action_url}\n"

        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[notification.user.email],
            fail_silently=True,
        )

    @staticmethod
    def get_user_notifications(
        user_id: int,
        unread_only: bool = False,
        include_expired: bool = False,
        notification_type: Optional[str] = None,
    ) -> List[Notification]:
        """
        Get notifications for a user.

        Args:
            user_id: ID of the user
            unread_only: Filter for unread notifications
            include_expired: Include expired notifications
            notification_type: Filter by notification type

        Returns:
            List[Notification]: List of notifications
        """
        query = Q(user_id=user_id)

        if unread_only:
            query &= Q(is_read=False)

        if not include_expired:
            query &= Q(expires_at__isnull=True) | Q(expires_at__gt=timezone.now())

        if notification_type:
            query &= Q(notification_type=notification_type)

        return Notification.objects.filter(query).order_by("-created_at")

    @staticmethod
    def mark_all_as_read(user_id: int) -> int:
        """
        Mark all notifications as read for a user.

        Args:
            user_id: ID of the user

        Returns:
            int: Number of notifications marked as read
        """
        return Notification.objects.filter(user_id=user_id, is_read=False).update(
            is_read=True, read_at=timezone.now()
        )

    @staticmethod
    def bulk_delete_notifications(user_id: int, notification_ids: List[int]) -> int:
        """
        Delete multiple notifications.

        Args:
            user_id: ID of the user
            notification_ids: List of notification IDs

        Returns:
            int: Number of notifications deleted
        """
        return Notification.objects.filter(
            user_id=user_id, id__in=notification_ids
        ).delete()[0]

    @staticmethod
    def clear_expired_notifications() -> int:
        """
        Clear expired notifications.

        Returns:
            int: Number of notifications deleted
        """
        return Notification.objects.filter(expires_at__lt=timezone.now()).delete()[0]

    @staticmethod
    def get_notification_count(
        user_id: int, unread_only: bool = True
    ) -> Dict[str, int]:
        """
        Get notification counts by type.

        Args:
            user_id: ID of the user
            unread_only: Count only unread notifications

        Returns:
            Dict[str, int]: Counts by notification type
        """
        query = Q(user_id=user_id)
        if unread_only:
            query &= Q(is_read=False)

        notifications = Notification.objects.filter(query)
        counts = {}

        for notification_type in Notification.NotificationTypes.values:
            counts[notification_type] = notifications.filter(
                notification_type=notification_type
            ).count()

        counts["total"] = sum(counts.values())
        return counts

    @staticmethod
    def send_budget_threshold_notification(budget) -> Notification:
        """
        Send notification when budget threshold is reached.

        Args:
            budget: Budget instance that reached threshold

        Returns:
            Notification: Created notification
        """
        return NotificationService.create_notification(
            user_id=budget.user.id,
            title=f"Budget Threshold Alert: {budget.name}",
            message=(
                f"Your budget for {budget.category} has reached "
                f"{budget.notification_threshold}% utilization."
            ),
            notification_type=Notification.NotificationTypes.THRESHOLD_REACHED,
            priority=Notification.Priority.HIGH,
            data={"budget_id": budget.id},
        )

    @staticmethod
    def send_budget_exceeded_notification(budget) -> Notification:
        """
        Send notification when budget is exceeded.

        Args:
            budget: Budget instance that was exceeded

        Returns:
            Notification: Created notification
        """
        return NotificationService.create_notification(
            user_id=budget.user.id,
            title=f"Budget Exceeded: {budget.name}",
            message=(f"Your budget for {budget.category} has been exceeded."),
            notification_type=Notification.NotificationTypes.BUDGET_EXCEEDED,
            priority=Notification.Priority.URGENT,
            data={"budget_id": budget.id},
        )

    @staticmethod
    def send_recurring_expense_notification(expense) -> Notification:
        """
        Send notification for recurring expense.

        Args:
            expense: Expense instance

        Returns:
            Notification: Created notification
        """
        return NotificationService.create_notification(
            user_id=expense.user.id,
            title="Recurring Expense Reminder",
            message=(
                f"Recurring expense of {expense.amount} for "
                f"{expense.title} is due today."
            ),
            notification_type=Notification.NotificationTypes.RECURRING_EXPENSE,
            priority=Notification.Priority.MEDIUM,
            data={"expense_id": expense.id},
        )

    @staticmethod
    def send_budget_creation_notification(budget):
        """
        Send a notification to the user when a new budget is created.

        Args:
            budget: The budget instance that was created
        """
        title = "New Budget Created"
        message = f"Your budget '{budget.name}' has been successfully created."
        NotificationService.create_notification(
            user_id=budget.user.id,
            title=title,
            message=message,
            notification_type="BUDGET_ALERT",
            priority=Notification.Priority.HIGH,
        )

    @staticmethod
    def update_user_preferences(
        user_id: int, preferences_data: Dict
    ) -> NotificationPreference:
        """
        Update user notification preferences.

        Args:
            user_id: ID of the user
            preferences_data: New preference data

        Returns:
            NotificationPreference: Updated preferences
        """
        preferences, created = NotificationPreference.objects.get_or_create(
            user_id=user_id
        )

        for field, value in preferences_data.items():
            setattr(preferences, field, value)

        preferences.save()
        return preferences
