"""
Signals for the notifications application.
"""

from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from .models import NotificationPreference, Notification

User = get_user_model()


@receiver(post_save, sender=User)
def create_notification_preferences(sender, instance, created, **kwargs):
    """
    Create notification preferences for new users.
    """
    if created and not hasattr(instance, 'notification_preferences'):
        NotificationPreference.objects.create(
            user=instance,
            email_notifications=True,
            push_notifications=True,
            notification_frequency='immediate'
        )


@receiver(post_save, sender=User)
def save_notification_preferences(sender, instance, **kwargs):
    """
    Save notification preferences for existing users.
    """
    if hasattr(instance, 'notification_preferences'):
        instance.notification_preferences.save()
