"""
Celery configuration for the budget tracker project.
"""

import os
from celery import Celery
from django.conf import settings
from celery.schedules import crontab

# Set the default Django settings module
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings.local")

# Create the Celery app
app = Celery("budget_tracker")

# Namespace for celery settings in Django settings
app.config_from_object("django.conf:settings", namespace="CELERY")

# Load tasks from all registered Django apps
app.autodiscover_tasks(lambda: settings.INSTALLED_APPS)

# Configure Celery beat schedule for periodic tasks
app.conf.beat_schedule = {
    # Budget related tasks
    "check-budget-limits": {
        "task": "apps.budgets.tasks.check_budget_limits",
        "schedule": 3600.0,  # Run hourly
    },
    "check-budget-thresholds": {
        "task": "apps.notifications.tasks.check_budget_thresholds",
        "schedule": 3600.0,  # Run hourly
    },
    
    # Notification tasks
    "send-weekly-summaries": {
        "task": "apps.notifications.tasks.send_weekly_summaries",
        "schedule": crontab(hour=8, minute=0, day_of_week=1),  # Monday at 8 AM
    },
    "send-expense-reminders": {
        "task": "apps.notifications.tasks.send_expense_reminders",
        "schedule": crontab(hour=9, minute=0),  # Daily at 9 AM
    },
}


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """
    Debug task for testing Celery worker.

    Args:
        self: Task instance
    """
    print(f"Request: {self.request!r}")
