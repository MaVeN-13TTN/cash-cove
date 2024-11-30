"""
Services for the notifications application.
"""

from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from django.utils import timezone
from .models import Notification

class NotificationService:
    @staticmethod
    def send_notification(user, title, message, notification_type, priority="MEDIUM"):
        """
        Send a notification to a user through both database and WebSocket.
        
        Args:
            user: User to send notification to
            title: Notification title
            message: Notification message
            notification_type: Type of notification (from Notification.NotificationTypes)
            priority: Priority level (from Notification.Priority)
        """
        # Check user notification preferences
        preferences = user.notification_preferences.first()
        if preferences and not preferences.can_notify(notification_type, priority):
            return None

        # Create notification in database
        notification = Notification.objects.create(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            priority=priority,
            created_at=timezone.now()
        )

        # Send real-time notification if push notifications are enabled
        if preferences and preferences.push_notifications:
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f"user_{user.id}_notifications",
                {
                    "type": "notification_message",
                    "message": {
                        "id": notification.id,
                        "title": title,
                        "message": message,
                        "type": notification_type,
                        "priority": priority,
                        "created_at": notification.created_at.isoformat()
                    }
                }
            )

        return notification

    @staticmethod
    def send_budget_alert(user, budget, current_spending, threshold_percentage):
        """
        Send a budget alert notification.
        
        Args:
            user: User to notify
            budget: Budget object
            current_spending: Current spending amount
            threshold_percentage: Percentage of budget used
        """
        title = "Budget Alert"
        message = f"You've used {threshold_percentage}% of your {budget.category} budget. " \
                 f"Current spending: ${current_spending} of ${budget.amount}"
        
        return NotificationService.send_notification(
            user=user,
            title=title,
            message=message,
            notification_type=Notification.NotificationTypes.BUDGET_ALERT,
            priority=Notification.Priority.HIGH
        )

    @staticmethod
    def send_expense_reminder(user, expense):
        """
        Send a reminder for recurring expenses.
        
        Args:
            user: User to notify
            expense: Expense object
        """
        title = "Expense Reminder"
        message = f"Reminder: Recurring expense of ${expense.amount} " \
                 f"for {expense.category} is due"
        
        return NotificationService.send_notification(
            user=user,
            title=title,
            message=message,
            notification_type=Notification.NotificationTypes.REMINDER,
            priority=Notification.Priority.MEDIUM
        )

    @staticmethod
    def send_weekly_summary(user, total_spending, budget_status):
        """
        Send weekly spending summary.
        
        Args:
            user: User to notify
            total_spending: Total amount spent
            budget_status: Dictionary of budget statuses
        """
        title = "Weekly Spending Summary"
        message = f"Your total spending this week: ${total_spending}\n"
        for category, status in budget_status.items():
            message += f"\n{category}: ${status['spent']} of ${status['budget']}"
        
        return NotificationService.send_notification(
            user=user,
            title=title,
            message=message,
            notification_type=Notification.NotificationTypes.SYSTEM,
            priority=Notification.Priority.LOW
        )
