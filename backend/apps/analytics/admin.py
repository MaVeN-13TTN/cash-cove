"""
Admin configuration for the analytics application.
"""

from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import SpendingAnalytics, BudgetUtilization


@admin.register(SpendingAnalytics)
class SpendingAnalyticsAdmin(admin.ModelAdmin):
    """
    Admin configuration for SpendingAnalytics model.
    """

    list_display = (
        "user",
        "date",
        "category",
        "total_amount",
        "transaction_count",
        "average_amount",
    )
    list_filter = ("date", "category", "user")
    search_fields = ("user__username", "category")
    date_hierarchy = "date"
    readonly_fields = ("created_at", "updated_at")
    fieldsets = (
        (None, {"fields": ("user", "date", "category")}),
        (
            _("Metrics"),
            {"fields": ("total_amount", "transaction_count", "average_amount")},
        ),
        (
            _("Timestamps"),
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )


@admin.register(BudgetUtilization)
class BudgetUtilizationAdmin(admin.ModelAdmin):
    """
    Admin configuration for BudgetUtilization model.
    """

    list_display = (
        "user",
        "category",
        "month",
        "budget_amount",
        "spent_amount",
        "utilization_percentage",
    )
    list_filter = ("month", "category", "user")
    search_fields = ("user__username", "category")
    date_hierarchy = "month"
    readonly_fields = ("created_at", "updated_at")
    fieldsets = (
        (None, {"fields": ("user", "category", "month")}),
        (
            _("Budget Information"),
            {"fields": ("budget_amount", "spent_amount", "utilization_percentage")},
        ),
        (
            _("Timestamps"),
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )
