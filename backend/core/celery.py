"""
Celery configuration for budget tracker project.
"""

import os
from celery import Celery
from celery.schedules import crontab
from django.conf import settings

# Set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings.local')

app = Celery('budget_tracker')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django app configs.
app.autodiscover_tasks()

# Configure periodic tasks
app.conf.beat_schedule = {
    'send-payment-reminders': {
        'task': 'apps.shared_expenses.tasks.send_payment_reminders',
        'schedule': crontab(hour=9, minute=0),  # Run daily at 9 AM
    },
    'update-expense-statistics': {
        'task': 'apps.shared_expenses.tasks.update_expense_statistics',
        'schedule': crontab(minute='*/30'),  # Run every 30 minutes
    },
    'clean-cancelled-expenses': {
        'task': 'apps.shared_expenses.tasks.clean_cancelled_expenses',
        'schedule': crontab(hour=0, minute=0),  # Run daily at midnight
    },
}

@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """Debug task to verify Celery is working."""
    print(f'Request: {self.request!r}')
