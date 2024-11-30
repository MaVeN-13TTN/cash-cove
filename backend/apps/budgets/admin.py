"""
Admin configuration for the budgets application.
"""

from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import Budget


@admin.register(Budget)
class BudgetAdmin(admin.ModelAdmin):
    """Admin configuration for Budget model."""

    list_display = (
        "name",
        "user",
        "category",
        "amount",
        "start_date",
        "end_date",
        "is_active",
        "recurrence",
    )

    list_filter = ("is_active", "recurrence", "category", "start_date", "end_date")

    search_fields = ("name", "category", "user__username", "user__email")

    date_hierarchy = "start_date"

    readonly_fields = ("created_at", "updated_at")

    fieldsets = (
        (None, {"fields": ("user", "name", "category", "amount", "description")}),
        (_("Dates"), {"fields": ("start_date", "end_date")}),
        (
            _("Settings"),
            {"fields": ("recurrence", "notification_threshold", "is_active")},
        ),
        (
            _("Timestamps"),
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )

    def get_queryset(self, request):
        """
        Override queryset to include calculated fields.
        """
        queryset = super().get_queryset(request)
        return queryset.select_related("user")

    def save_model(self, request, obj, form, change):
        """
        Override save_model to handle any custom saving logic.
        """
        if not change:  # If this is a new object
            if not obj.user_id:  # If user is not set
                obj.user = request.user
        super().save_model(request, obj, form, change)
