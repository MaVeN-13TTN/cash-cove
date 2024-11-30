"""
Admin configuration for the expenses application.
"""

from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import Expense


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    """Admin configuration for Expense model."""

    list_display = (
        "title",
        "user",
        "amount",
        "category",
        "date",
        "payment_method",
        "is_recurring",
    )

    list_filter = (
        "category",
        "payment_method",
        "is_recurring",
        "date",
        ("budget", admin.RelatedOnlyFieldListFilter),
    )

    search_fields = (
        "title",
        "category",
        "notes",
        "user__username",
        "user__email",
        "location",
    )

    date_hierarchy = "date"

    readonly_fields = ("created_at", "updated_at")

    fieldsets = (
        (None, {"fields": ("user", "title", "amount", "category", "date")}),
        (
            _("Additional Information"),
            {"fields": ("payment_method", "budget", "notes", "location")},
        ),
        (_("Receipt"), {"fields": ("receipt_image",), "classes": ("collapse",)}),
        (_("Recurrence & Tags"), {"fields": ("is_recurring", "tags")}),
        (_("Metadata"), {"fields": ("metadata",), "classes": ("collapse",)}),
        (
            _("Timestamps"),
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )

    def get_queryset(self, request):
        """
        Override queryset to include related fields.
        """
        return super().get_queryset(request).select_related("user", "budget")

    def save_model(self, request, obj, form, change):
        """
        Override save_model to handle any custom saving logic.
        """
        if not change:  # If this is a new object
            if not obj.user_id:  # If user is not set
                obj.user = request.user
        super().save_model(request, obj, form, change)
