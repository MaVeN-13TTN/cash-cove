"""
Celery tasks for the notifications application.
"""

from celery import shared_task
from django.utils import timezone
from django.db.models import Sum
from datetime import timedelta
from django.contrib.auth import get_user_model
from apps.expenses.models import Expense
from apps.budgets.models import Budget
from .services import NotificationService

User = get_user_model()

@shared_task
def send_weekly_summaries():
    """Send weekly spending summaries to all users."""
    end_date = timezone.now()
    start_date = end_date - timedelta(days=7)
    
    for user in User.objects.all():
        # Skip users who have disabled notifications
        preferences = user.notification_preferences.first()
        if not preferences or not preferences.can_notify("SYSTEM", "LOW"):
            continue

        # Get total spending
        total_spending = Expense.objects.filter(
            user=user,
            date__range=(start_date, end_date)
        ).aggregate(total=Sum('amount'))['total'] or 0

        # Get budget status for each category
        budget_status = {}
        for budget in Budget.objects.filter(user=user):
            spent = Expense.objects.filter(
                user=user,
                category=budget.category,
                date__range=(start_date, end_date)
            ).aggregate(total=Sum('amount'))['total'] or 0
            
            budget_status[budget.category] = {
                'budget': budget.amount,
                'spent': spent
            }

        NotificationService.send_weekly_summary(user, total_spending, budget_status)

@shared_task
def check_budget_thresholds():
    """Check budget thresholds and send alerts."""
    today = timezone.now()
    start_of_month = today.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    
    for budget in Budget.objects.all():
        current_spending = Expense.objects.filter(
            user=budget.user,
            category=budget.category,
            date__gte=start_of_month
        ).aggregate(total=Sum('amount'))['total'] or 0

        threshold_percentage = (current_spending / budget.amount) * 100
        
        # Alert at 80% and 100% of budget
        if threshold_percentage >= 100:
            NotificationService.send_budget_alert(
                budget.user, budget, current_spending, 100
            )
        elif threshold_percentage >= 80:
            NotificationService.send_budget_alert(
                budget.user, budget, current_spending, 80
            )

@shared_task
def send_expense_reminders():
    """Send reminders for recurring expenses."""
    today = timezone.now().date()
    
    # Get expenses due in the next 3 days
    end_date = today + timedelta(days=3)
    
    for user in User.objects.all():
        upcoming_expenses = Expense.objects.filter(
            user=user,
            is_recurring=True,
            next_due_date__range=(today, end_date)
        )
        
        for expense in upcoming_expenses:
            NotificationService.send_expense_reminder(user, expense)
