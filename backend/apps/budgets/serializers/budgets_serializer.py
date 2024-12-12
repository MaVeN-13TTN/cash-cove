"""
Serializers for the budgets application.
"""

from rest_framework import serializers
from django.utils.translation import gettext_lazy as _
from ..models import Budget
from django.db import models


class BudgetSerializer(serializers.ModelSerializer):
    """
    Serializer for Budget model with calculated fields.
    """

    remaining_amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    utilization_percentage = serializers.DecimalField(
        max_digits=5, decimal_places=2, read_only=True
    )
    is_expired = serializers.BooleanField(read_only=True)

    class Meta:
        """
        Meta options for BudgetSerializer.
        """

        model = Budget
        fields = [
            "id",
            "name",
            "amount",
            "category",
            "start_date",
            "end_date",
            "recurrence",
            "notification_threshold",
            "is_active",
            "description",
            "remaining_amount",
            "utilization_percentage",
            "is_expired",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def validate(self, data):
        """
        Validate budget data.
        """
        if data.get("end_date") and data.get("start_date"):
            if data["end_date"] < data["start_date"]:
                raise serializers.ValidationError(
                    {"end_date": _("End date must not be before start date.")}
                )
        return data


class BudgetCreateSerializer(BudgetSerializer):
    """
    Serializer for creating budgets with additional validation.
    """

    class Meta(BudgetSerializer.Meta):
        """
        Meta options for BudgetCreateSerializer.
        """

        fields = BudgetSerializer.Meta.fields + ["user"]
        read_only_fields = BudgetSerializer.Meta.read_only_fields

    def validate(self, data):
        """
        Validate budget creation data.
        Ensures no overlapping budgets for the same category.
        Automatically activates the budget if no overlapping active budget exists.
        """
        data = super().validate(data)

        # Check for overlapping budgets in the same category
        overlapping_budgets = Budget.objects.filter(
            user=data["user"], category=data["category"], is_active=True
        ).filter(
            models.Q(start_date__lte=data["end_date"], end_date__gte=data["start_date"])
        )

        # Logging for debugging
        print("Overlapping budgets:", overlapping_budgets)

        if self.instance:
            overlapping_budgets = overlapping_budgets.exclude(pk=self.instance.pk)

        if overlapping_budgets.exists():
            raise serializers.ValidationError(
                {
                    "category": _(
                        "An active budget already exists for this category "
                        "during the specified period."
                    )
                }
            )

        # Automatically activate the budget if no overlapping active budget exists
        if not overlapping_budgets.exists():
            data["is_active"] = True

        return data


class BudgetUpdateSerializer(BudgetSerializer):
    """
    Serializer for updating budgets with specific validation.
    """

    class Meta(BudgetSerializer.Meta):
        """
        Meta options for BudgetUpdateSerializer.
        """

        read_only_fields = BudgetSerializer.Meta.read_only_fields + ["user", "category"]

    def validate_amount(self, value):
        """
        Validate amount changes.
        Prevents reducing budget below spent amount.
        """
        if self.instance and value < self.instance.amount:
            spent_amount = self.instance.amount - self.instance.remaining_amount
            if value < spent_amount:
                raise serializers.ValidationError(
                    _("Cannot reduce budget below spent amount.")
                )
        return value


class BudgetListSerializer(BudgetSerializer):
    """
    Simplified serializer for listing budgets.
    """

    class Meta(BudgetSerializer.Meta):
        """
        Meta options for BudgetListSerializer.
        """

        fields = [
            "id",
            "name",
            "category",
            "amount",
            "remaining_amount",
            "utilization_percentage",
            "is_active",
            "is_expired",
        ]
