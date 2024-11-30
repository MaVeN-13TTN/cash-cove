"""
Signal handlers for shared expenses application.
"""

from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver
from django.db import transaction
from django.utils import timezone
from apps.notifications.services import NotificationService
from .models import SharedExpense, ParticipantShare


@receiver(pre_save, sender=SharedExpense)
def validate_shared_expense(sender, instance, **kwargs):
    """
    Signal to validate shared expense before saving.

    Args:
        sender: The model class
        instance: The actual shared expense instance
        **kwargs: Additional keyword arguments
    """
    from django.core.exceptions import ValidationError

    # Validate status transitions
    if instance.pk:  # Existing instance
        old_instance = SharedExpense.objects.get(pk=instance.pk)
        if old_instance.status != instance.status:
            valid_transitions = {
                SharedExpense.Status.PENDING: [
                    SharedExpense.Status.ACTIVE,
                    SharedExpense.Status.CANCELLED,
                ],
                SharedExpense.Status.ACTIVE: [
                    SharedExpense.Status.SETTLED,
                    SharedExpense.Status.DISPUTED,
                ],
            }
            if (
                old_instance.status in valid_transitions
                and instance.status not in valid_transitions[old_instance.status]
            ):
                raise ValidationError(
                    f"Invalid status transition from {old_instance.status} to {instance.status}"
                )


@receiver(post_save, sender=SharedExpense)
def handle_shared_expense_status(sender, instance, created, **kwargs):
    """
    Signal to handle shared expense status changes.

    Args:
        sender: The model class
        instance: The actual shared expense instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    if created:
        if instance.status == SharedExpense.Status.PENDING:
            # Notify creator
            NotificationService.create_notification(
                user_id=instance.creator.id,
                title="Shared Expense Created",
                message=f"Shared expense '{instance.title}' has been created successfully",
                notification_type="SHARED_EXPENSE",
                data={"shared_expense_id": instance.id},
            )
    else:  # Updated
        # Notify participants of status change
        for share in instance.participant_shares.all():
            NotificationService.create_notification(
                user_id=share.participant.id,
                title="Shared Expense Updated",
                message=(
                    f"Shared expense '{instance.title}' status "
                    f"has been updated to {instance.get_status_display()}"
                ),
                notification_type="SHARED_EXPENSE",
                data={"shared_expense_id": instance.id},
            )


@receiver(post_save, sender=ParticipantShare)
def handle_participant_share_changes(sender, instance, created, **kwargs):
    """
    Signal to handle participant share changes.

    Args:
        sender: The model class
        instance: The actual participant share instance
        created: Boolean indicating if this is a new instance
        **kwargs: Additional keyword arguments
    """
    with transaction.atomic():
        shared_expense = instance.shared_expense
        if created:
            # Notify new participant
            NotificationService.create_notification(
                user_id=instance.participant.id,
                title="Added to Shared Expense",
                message=(
                    f"You have been added to shared expense '{shared_expense.title}' "
                    f"with a share amount of {instance.amount}"
                ),
                notification_type="SHARED_EXPENSE",
                data={"shared_expense_id": shared_expense.id, "share_id": instance.id},
            )
        else:
            # Check if share was just paid
            if instance.is_paid:
                # Notify creator
                NotificationService.create_notification(
                    user_id=shared_expense.creator.id,
                    title="Share Payment Completed",
                    message=(
                        f"{instance.participant.username} has completed their payment "
                        f"for '{shared_expense.title}'"
                    ),
                    notification_type="SHARED_EXPENSE",
                    data={"shared_expense_id": shared_expense.id},
                )

                # Check if all shares are paid
                if all(
                    share.is_paid for share in shared_expense.participant_shares.all()
                ):
                    shared_expense.status = SharedExpense.Status.SETTLED
                    shared_expense.save()


@receiver(pre_save, sender=ParticipantShare)
def validate_participant_share(sender, instance, **kwargs):
    """
    Signal to validate participant share before saving.

    Args:
        sender: The model class
        instance: The actual participant share instance
        **kwargs: Additional keyword arguments
    """
    from django.core.exceptions import ValidationError

    if instance.amount_paid > instance.amount:
        raise ValidationError("Amount paid cannot exceed share amount")


@receiver(post_delete, sender=SharedExpense)
def handle_shared_expense_deletion(sender, instance, **kwargs):
    """
    Signal to handle cleanup after shared expense deletion.

    Args:
        sender: The model class
        instance: The actual shared expense instance
        **kwargs: Additional keyword arguments
    """
    # Notify all participants
    participant_ids = instance.participant_shares.values_list(
        "participant_id", flat=True
    )
    for participant_id in participant_ids:
        NotificationService.create_notification(
            user_id=participant_id,
            title="Shared Expense Deleted",
            message=f"Shared expense '{instance.title}' has been deleted",
            notification_type="SHARED_EXPENSE",
        )

    # Delete related expense if exists
    if instance.expense:
        instance.expense.delete()
