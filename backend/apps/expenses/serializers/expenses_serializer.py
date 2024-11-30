"""
Serializers for the expenses application.
"""

from rest_framework import serializers
from django.utils.translation import gettext_lazy as _
from apps.budgets.models import Budget
from ..models import Expense


class ExpenseSerializer(serializers.ModelSerializer):
    """
    Serializer for Expense model with computed fields.
    """

    budget_status = serializers.SerializerMethodField()
    category_info = serializers.SerializerMethodField()
    is_recent = serializers.BooleanField(read_only=True)
    month_year = serializers.CharField(read_only=True)

    class Meta:
        """
        Meta options for ExpenseSerializer.
        """

        model = Expense
        fields = [
            "id",
            "title",
            "amount",
            "category",
            "date",
            "payment_method",
            "budget",
            "notes",
            "receipt_image",
            "location",
            "is_recurring",
            "tags",
            "metadata",
            "budget_status",
            "category_info",
            "is_recent",
            "month_year",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def get_budget_status(self, obj):
        """Get budget status for the expense."""
        return obj.get_budget_status()

    def get_category_info(self, obj):
        """Get category information."""
        return obj.get_category_info()


class ExpenseCreateSerializer(ExpenseSerializer):
    """
    Serializer for creating expenses with additional validation.
    """

    budget_id = serializers.IntegerField(required=False, write_only=True)

    class Meta(ExpenseSerializer.Meta):
        """
        Meta options for ExpenseCreateSerializer.
        """

        fields = ExpenseSerializer.Meta.fields + ["budget_id"]

    def validate_budget_id(self, value):
        """Validate budget exists and belongs to user."""
        if value:
            try:
                budget = Budget.objects.get(id=value, user=self.context["request"].user)
                return budget.id
            except Budget.DoesNotExist:
                raise serializers.ValidationError(_("Invalid budget selected."))
        return value

    def create(self, validated_data):
        """
        Create expense with proper budget assignment.
        """
        budget_id = validated_data.pop("budget_id", None)
        if budget_id:
            budget = Budget.objects.get(id=budget_id)
            validated_data["budget"] = budget
        return super().create(validated_data)


class ExpenseUpdateSerializer(ExpenseSerializer):
    """
    Serializer for updating expenses with specific validation.
    """

    class Meta(ExpenseSerializer.Meta):
        """
        Meta options for ExpenseUpdateSerializer.
        """

        read_only_fields = ExpenseSerializer.Meta.read_only_fields + [
            "user",
            "category",  # Prevent category changes after creation
        ]


class ExpenseListSerializer(ExpenseSerializer):
    """
    Simplified serializer for listing expenses.
    """

    class Meta(ExpenseSerializer.Meta):
        """
        Meta options for ExpenseListSerializer.
        """

        fields = [
            "id",
            "title",
            "amount",
            "category",
            "date",
            "payment_method",
            "is_recurring",
            "category_info",
            "is_recent",
        ]


class ExpenseSummarySerializer(serializers.Serializer):
    """
    Serializer for expense summary data.
    """

    category = serializers.CharField()
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    transaction_count = serializers.IntegerField()
    average_amount = serializers.DecimalField(max_digits=12, decimal_places=2)


class ExpenseRecurrenceSerializer(serializers.Serializer):
    """
    Serializer for handling recurring expense creation.
    """

    start_date = serializers.DateField()
    end_date = serializers.DateField()
    frequency = serializers.ChoiceField(
        choices=[
            ("DAILY", _("Daily")),
            ("WEEKLY", _("Weekly")),
            ("MONTHLY", _("Monthly")),
            ("YEARLY", _("Yearly")),
        ]
    )
    expense_data = ExpenseCreateSerializer()

    def validate(self, data):
        """Validate date range and create recurring expenses."""
        if data["end_date"] < data["start_date"]:
            raise serializers.ValidationError(_("End date must be after start date."))
        return data
