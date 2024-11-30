# apps/users/signals.py
"""
Signal handlers for users application.
"""

from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import Profile

User = get_user_model()


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    """
    Signal to create user profile on user creation.

    Args:
        sender: The model class
        instance: The actual user instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if created:
        Profile.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    """
    Signal to save user profile on user save.

    Args:
        sender: The model class
        instance: The actual user instance
        **kwargs: Additional keyword arguments
    """
    if not hasattr(instance, "profile"):
        Profile.objects.create(user=instance)
    else:
        instance.profile.save()


@receiver(pre_save, sender=User)
def update_user_activity(sender, instance, **kwargs):
    """
    Signal to update user activity timestamps.

    Args:
        sender: The model class
        instance: The actual user instance
        **kwargs: Additional keyword arguments
    """
    if instance.pk:  # Existing user
        old_instance = User.objects.get(pk=instance.pk)
        # Update last_login if it's different
        if instance.last_login != old_instance.last_login:
            instance.last_activity = timezone.now()


@receiver(post_save, sender=Profile)
def handle_two_factor_change(sender, instance, **kwargs):
    """
    Signal to handle two-factor authentication changes.

    Args:
        sender: The model class
        instance: The actual profile instance
        **kwargs: Additional keyword arguments
    """
    if instance.pk:
        old_instance = Profile.objects.get(pk=instance.pk)
        if instance.two_factor_enabled != old_instance.two_factor_enabled:
            if instance.two_factor_enabled:
                # Send 2FA enabled notification
                from apps.notifications.services import NotificationService

                NotificationService.create_notification(
                    user_id=instance.user.id,
                    title="Two-Factor Authentication Enabled",
                    message="Two-factor authentication has been enabled for your account.",
                    notification_type="SECURITY",
                    priority="HIGH",
                )
            else:
                # Send 2FA disabled notification
                from apps.notifications.services import NotificationService

                NotificationService.create_notification(
                    user_id=instance.user.id,
                    title="Two-Factor Authentication Disabled",
                    message="Two-factor authentication has been disabled for your account.",
                    notification_type="SECURITY",
                    priority="HIGH",
                )
