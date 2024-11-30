"""
Date helper functions.
"""

from datetime import datetime, date, timedelta
from typing import Tuple, List
from django.utils import timezone
from dateutil.relativedelta import relativedelta
from ..exceptions.custom_exceptions import InvalidDateRange


def get_date_range(
    start_date: date = None,
    end_date: date = None,
    months: int = None
) -> Tuple[date, date]:
    """
    Get start and end dates for a range.
    If no dates provided, defaults to current month.
    """
    if months and (start_date or end_date):
        raise InvalidDateRange("Cannot specify both date range and months")
    
    today = timezone.localdate()
    
    if months:
        end_date = today
        start_date = today - relativedelta(months=months)
    elif not start_date and not end_date:
        start_date = today.replace(day=1)
        end_date = (start_date + relativedelta(months=1)) - timedelta(days=1)
    elif not end_date:
        end_date = today
    elif not start_date:
        start_date = end_date - relativedelta(months=1)
    
    if start_date > end_date:
        raise InvalidDateRange("Start date cannot be after end date")
    
    return start_date, end_date


def get_month_start_end(date_obj: date = None) -> Tuple[date, date]:
    """
    Get start and end dates for a month.
    """
    if not date_obj:
        date_obj = timezone.localdate()
    
    start_date = date_obj.replace(day=1)
    end_date = (start_date + relativedelta(months=1)) - timedelta(days=1)
    
    return start_date, end_date


def get_weekday_name(date_obj: date) -> str:
    """
    Get weekday name for a date.
    """
    return date_obj.strftime("%A")


def get_month_name(date_obj: date) -> str:
    """
    Get month name for a date.
    """
    return date_obj.strftime("%B")


def get_month_year(date_obj: date) -> str:
    """
    Get month and year string.
    """
    return date_obj.strftime("%B %Y")


def get_date_periods(
    start_date: date,
    end_date: date,
    period: str = "month"
) -> List[Tuple[date, date]]:
    """
    Get list of date periods between start and end date.
    Period can be 'month', 'week', or 'day'.
    """
    periods = []
    current = start_date
    
    if period == "month":
        while current <= end_date:
            period_start = current.replace(day=1)
            period_end = (period_start + relativedelta(months=1)) - timedelta(days=1)
            if period_end > end_date:
                period_end = end_date
            periods.append((period_start, period_end))
            current = period_end + timedelta(days=1)
    
    elif period == "week":
        while current <= end_date:
            period_start = current - timedelta(days=current.weekday())
            period_end = period_start + timedelta(days=6)
            if period_end > end_date:
                period_end = end_date
            periods.append((period_start, period_end))
            current = period_end + timedelta(days=1)
    
    else:  # day
        while current <= end_date:
            periods.append((current, current))
            current += timedelta(days=1)
    
    return periods


def is_future_date(date_obj: date) -> bool:
    """
    Check if date is in the future.
    """
    return date_obj > timezone.localdate()


def is_past_date(date_obj: date) -> bool:
    """
    Check if date is in the past.
    """
    return date_obj < timezone.localdate()


def format_date(date_obj: date, format_str: str = "%Y-%m-%d") -> str:
    """
    Format date as string.
    """
    return date_obj.strftime(format_str)