"""
Celery tasks for shared expenses application.
"""

from celery import shared_task
from django.utils import timezone
from django.core.cache import cache
from django.conf import settings
from .models import SharedExpense, ParticipantShare


@shared_task
def send_payment_reminders():
    """
    Send reminders to participants who haven't paid their share.
    """
    now = timezone.now()
    reminder_threshold = now - timezone.timedelta(days=7)  # Send reminder every 7 days

    # Get all active shared expenses with unpaid shares
    unpaid_shares = ParticipantShare.objects.filter(
        shared_expense__status=SharedExpense.Status.ACTIVE,
        amount_paid__lt=models.F('amount'),
        last_reminded__lt=reminder_threshold
    ).select_related('participant', 'shared_expense')

    for share in unpaid_shares:
        # Send reminder notification (implement notification logic)
        share.last_reminded = now
        share.save(update_fields=['last_reminded'])


@shared_task
def update_expense_statistics():
    """
    Update cached statistics for shared expenses.
    """
    from django.db.models import Sum, Count, Avg
    
    # Calculate overall statistics
    stats = {
        'total_active_expenses': SharedExpense.objects.filter(
            status=SharedExpense.Status.ACTIVE
        ).count(),
        'total_amount': SharedExpense.objects.filter(
            status=SharedExpense.Status.ACTIVE
        ).aggregate(total=Sum('amount'))['total'] or 0,
        'avg_participants': SharedExpense.objects.filter(
            status=SharedExpense.Status.ACTIVE
        ).annotate(
            participant_count=Count('participant_shares')
        ).aggregate(avg=Avg('participant_count'))['avg'] or 0
    }
    
    # Cache the results
    cache.set('shared_expense_stats', stats, settings.CACHE_TTL)


@shared_task
def clean_cancelled_expenses():
    """
    Clean up old cancelled expenses.
    """
    cleanup_threshold = timezone.now() - timezone.timedelta(days=30)
    SharedExpense.objects.filter(
        status=SharedExpense.Status.CANCELLED,
        updated_at__lt=cleanup_threshold
    ).delete()
