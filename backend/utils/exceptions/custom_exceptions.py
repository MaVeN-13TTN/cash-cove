"""
Custom exceptions for the application.
"""

from rest_framework.exceptions import APIException
from rest_framework import status
from django.utils.translation import gettext_lazy as _


class BudgetLimitExceeded(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = _("Budget limit exceeded")
    default_code = "budget_limit_exceeded"


class InsufficientFunds(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = _("Insufficient funds in budget")
    default_code = "insufficient_funds"


class InvalidCurrency(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = _("Invalid currency specified")
    default_code = "invalid_currency"


class ExpenseNotFound(APIException):
    status_code = status.HTTP_404_NOT_FOUND
    default_detail = _("Expense not found")
    default_code = "expense_not_found"


class BudgetNotFound(APIException):
    status_code = status.HTTP_404_NOT_FOUND
    default_detail = _("Budget not found")
    default_code = "budget_not_found"


class InvalidDateRange(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = _("Invalid date range specified")
    default_code = "invalid_date_range"


class InvalidSharePercentage(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = _("Invalid share percentage")
    default_code = "invalid_share_percentage"


class DuplicateExpense(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = _("Duplicate expense detected")
    default_code = "duplicate_expense"


class InvalidAnalyticsPeriod(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = _("Invalid analytics period specified")
    default_code = "invalid_analytics_period"


class NotificationDeliveryFailed(APIException):
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_detail = _("Failed to deliver notification")
    default_code = "notification_delivery_failed"