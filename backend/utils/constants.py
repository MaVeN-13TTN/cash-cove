"""
Constants used throughout the application.
"""

from django.utils.translation import gettext_lazy as _

# User related constants
MAX_LOGIN_ATTEMPTS = 5
LOGIN_COOLDOWN_MINUTES = 15
PASSWORD_RESET_TIMEOUT_DAYS = 1
EMAIL_VERIFICATION_TIMEOUT_DAYS = 3

# Budget related constants
MAX_BUDGETS_PER_USER = 10
DEFAULT_CURRENCY = "USD"
SUPPORTED_CURRENCIES = [
    ("USD", _("US Dollar")),
    ("EUR", _("Euro")),
    ("GBP", _("British Pound")),
    ("JPY", _("Japanese Yen")),
    ("KES", _("Kenyan Shilling")),
]

# Expense related constants
EXPENSE_CATEGORIES = [
    ("FOOD", _("Food & Dining")),
    ("TRANSPORT", _("Transportation")),
    ("HOUSING", _("Housing & Utilities")),
    ("HEALTHCARE", _("Healthcare")),
    ("ENTERTAINMENT", _("Entertainment")),
    ("SHOPPING", _("Shopping")),
    ("EDUCATION", _("Education")),
    ("SAVINGS", _("Savings & Investments")),
    ("DEBT", _("Debt Payments")),
    ("OTHER", _("Other")),
]

# Analytics related constants
MAX_FORECAST_MONTHS = 12
TREND_ANALYSIS_DEFAULT_MONTHS = 6
INSIGHT_GENERATION_THRESHOLD = 30  # minimum days of data needed

# Notification related constants
NOTIFICATION_TYPES = [
    ("BUDGET_ALERT", _("Budget Alert")),
    ("EXPENSE_ALERT", _("Expense Alert")),
    ("SHARED_EXPENSE", _("Shared Expense")),
    ("SYSTEM", _("System Notification")),
]

NOTIFICATION_PRIORITIES = [
    ("HIGH", _("High")),
    ("MEDIUM", _("Medium")),
    ("LOW", _("Low")),
]

# Cache timeouts (in seconds)
CACHE_TIMEOUT = {
    "analytics": 3600,  # 1 hour
    "user_profile": 1800,  # 30 minutes
    "expense_categories": 86400,  # 24 hours
    "budget_summary": 300,  # 5 minutes
}