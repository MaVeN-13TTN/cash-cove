# apps/users/admin.py
"""
Admin configuration for users application.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User, Profile


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """
    Admin configuration for User model.
    """

    list_display = (
        "email",
        "username",
        "first_name",
        "last_name",
        "is_active",
        "is_verified",
        "date_joined",
    )
    list_filter = ("is_active", "is_verified", "is_staff", "date_joined")
    search_fields = ("email", "username", "first_name", "last_name", "phone_number")
    ordering = ("-date_joined",)

    fieldsets = (
        (None, {"fields": ("email", "password")}),
        (
            _("Personal info"),
            {
                "fields": (
                    "username",
                    "first_name",
                    "last_name",
                    "phone_number",
                    "date_of_birth",
                    "avatar",
                    "bio",
                )
            },
        ),
        (_("Status"), {"fields": ("is_active", "is_verified", "last_login_ip")}),
        (_("Preferences"), {"fields": ("preferences",)}),
        (
            _("Permissions"),
            {"fields": ("is_staff", "is_superuser", "groups", "user_permissions")},
        ),
        (_("Important dates"), {"fields": ("last_login", "date_joined")}),
    )

    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "username", "password1", "password2"),
            },
        ),
    )


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    """
    Admin configuration for Profile model.
    """

    list_display = (
        "user",
        "theme",
        "default_currency",
        "language",
        "timezone",
        "two_factor_enabled",
    )
    list_filter = ("theme", "default_currency", "language", "two_factor_enabled")
    search_fields = ("user__email", "user__username")
    raw_id_fields = ("user",)

    fieldsets = (
        (None, {"fields": ("user",)}),
        (
            _("Preferences"),
            {"fields": ("theme", "default_currency", "language", "timezone")},
        ),
        (
            _("Notifications"),
            {"fields": ("notification_emails", "activity_emails", "marketing_emails")},
        ),
        (_("Security"), {"fields": ("two_factor_enabled",)}),
        (
            _("Timestamps"),
            {"fields": ("created_at", "updated_at"), "classes": ("collapse",)},
        ),
    )
    readonly_fields = ("created_at", "updated_at")
