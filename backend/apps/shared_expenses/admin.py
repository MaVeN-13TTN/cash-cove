"""
Admin configuration for the shared expenses application.
"""

from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import SharedExpense, ParticipantShare


class ParticipantShareInline(admin.TabularInline):
    """
    Inline admin for ParticipantShare model.
    """

    model = ParticipantShare
    extra = 0
    readonly_fields = ("created_at", "updated_at")
    fields = (
        "participant",
        "amount",
        "amount_paid",
        "percentage",
        "shares",
        "notes",
        "last_reminded",
    )


@admin.register(SharedExpense)
class SharedExpenseAdmin(admin.ModelAdmin):
    """
    Admin configuration for SharedExpense model.
    """

    list_display = (
        "title",
        "creator",
        "amount",
        "category",
        "status",
        "split_method",
        "created_at",
    )

    list_filter = ("status", "split_method", "category", "created_at")

    search_fields = ("title", "creator__username", "creator__email", "description")

    readonly_fields = ("created_at", "updated_at")

    inlines = [ParticipantShareInline]

    fieldsets = (
        (None, {"fields": ("creator", "title", "amount", "category")}),
        (
            _("Split Details"),
            {"fields": ("split_method", "status", "expense", "due_date")},
        ),
        (
            _("Additional Information"),
            {
                "fields": ("description", "reminder_frequency", "metadata"),
                "classes": ("collapse",),
            },
        ),
        (
            _("Timestamps"),
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )

    def get_queryset(self, request):
        """
        Override queryset to include related fields.
        """
        return super().get_queryset(request).select_related("creator", "expense")


@admin.register(ParticipantShare)
class ParticipantShareAdmin(admin.ModelAdmin):
    """
    Admin configuration for ParticipantShare model.
    """

    list_display = (
        "participant",
        "shared_expense",
        "amount",
        "amount_paid",
        "percentage",
        "shares",
        "created_at",
    )

    list_filter = ("shared_expense__status", "created_at")

    search_fields = (
        "participant__username",
        "participant__email",
        "shared_expense__title",
        "notes",
    )

    readonly_fields = ("created_at", "updated_at")

    fieldsets = (
        (None, {"fields": ("shared_expense", "participant", "amount", "amount_paid")}),
        (_("Split Details"), {"fields": ("percentage", "shares")}),
        (_("Additional Information"), {"fields": ("notes", "last_reminded")}),
        (
            _("Timestamps"),
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )

    def get_queryset(self, request):
        """
        Override queryset to include related fields.
        """
        return (
            super()
            .get_queryset(request)
            .select_related("shared_expense", "participant")
        )
