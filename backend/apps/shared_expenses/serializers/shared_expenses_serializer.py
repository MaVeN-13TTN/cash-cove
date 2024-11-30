"""
Serializers for the shared expenses application.
"""

from decimal import Decimal
from typing import Dict, Any
from rest_framework import serializers
from django.utils.translation import gettext_lazy as _
from django.db import transaction
from apps.expenses.models import Expense
from ..models import SharedExpense, ParticipantShare


class ParticipantShareSerializer(serializers.ModelSerializer):
    """
    Serializer for ParticipantShare model.
    """

    participant_name = serializers.CharField(
        source="participant.username", read_only=True
    )
    participant_email = serializers.EmailField(
        source="participant.email", read_only=True
    )
    is_paid = serializers.BooleanField(read_only=True)
    remaining_amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )

    class Meta:
        """
        Meta options for ParticipantShareSerializer.
        """

        model = ParticipantShare
        fields = [
            "id",
            "participant",
            "participant_name",
            "participant_email",
            "percentage",
            "shares",
            "amount",
            "amount_paid",
            "notes",
            "last_reminded",
            "is_paid",
            "remaining_amount",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["last_reminded", "created_at", "updated_at"]


class SharedExpenseSerializer(serializers.ModelSerializer):
    """
    Serializer for SharedExpense model with computed fields.
    """

    participant_shares = ParticipantShareSerializer(many=True, read_only=True)
    creator_name = serializers.CharField(source="creator.username", read_only=True)
    is_settled = serializers.BooleanField(read_only=True)
    total_paid = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    remaining_amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )

    class Meta:
        """
        Meta options for SharedExpenseSerializer.
        """

        model = SharedExpense
        fields = [
            "id",
            "creator",
            "creator_name",
            "title",
            "description",
            "amount",
            "split_method",
            "status",
            "expense",
            "due_date",
            "category",
            "reminder_frequency",
            "metadata",
            "participant_shares",
            "is_settled",
            "total_paid",
            "remaining_amount",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]


class SharedExpenseCreateSerializer(SharedExpenseSerializer):
    """
    Serializer for creating shared expenses with participant shares.
    """

    participants = serializers.ListField(
        child=serializers.IntegerField(), write_only=True
    )
    shares = serializers.DictField(
        child=serializers.IntegerField(min_value=1), required=False, write_only=True
    )
    percentages = serializers.DictField(
        child=serializers.DecimalField(
            max_digits=5,
            decimal_places=2,
            min_value=Decimal("0.01"),
            max_value=Decimal("100.00"),
        ),
        required=False,
        write_only=True,
    )

    class Meta(SharedExpenseSerializer.Meta):
        """
        Meta options for SharedExpenseCreateSerializer.
        """

        fields = SharedExpenseSerializer.Meta.fields + [
            "participants",
            "shares",
            "percentages",
        ]

    def validate(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate shared expense data."""
        split_method = data.get("split_method")
        participants = data.get("participants", [])
        shares = data.get("shares", {})
        percentages = data.get("percentages", {})

        if not participants:
            raise serializers.ValidationError(
                _("At least one participant is required.")
            )

        if split_method == SharedExpense.SplitMethod.SHARES and not shares:
            raise serializers.ValidationError(
                _("Share allocation is required for share-based splitting.")
            )

        if split_method == SharedExpense.SplitMethod.PERCENTAGE:
            if not percentages:
                raise serializers.ValidationError(
                    _(
                        "Percentage allocation is required for percentage-based splitting."
                    )
                )
            total_percentage = sum(percentages.values())
            if total_percentage != Decimal("100.00"):
                raise serializers.ValidationError(_("Percentages must sum to 100."))

        return data

    @transaction.atomic
    def create(self, validated_data: Dict[str, Any]) -> SharedExpense:
        """Create shared expense with participant shares."""
        participants = validated_data.pop("participants", [])
        shares = validated_data.pop("shares", {})
        percentages = validated_data.pop("percentages", {})

        shared_expense = SharedExpense.objects.create(**validated_data)

        # Create participant shares based on split method
        if shared_expense.split_method == SharedExpense.SplitMethod.EQUAL:
            share_amount = shared_expense.amount / len(participants)
            for participant_id in participants:
                ParticipantShare.objects.create(
                    shared_expense=shared_expense,
                    participant_id=participant_id,
                    amount=share_amount,
                )

        elif shared_expense.split_method == SharedExpense.SplitMethod.SHARES:
            total_shares = sum(shares.values())
            for participant_id, num_shares in shares.items():
                share_amount = (
                    shared_expense.amount * Decimal(num_shares) / Decimal(total_shares)
                )
                ParticipantShare.objects.create(
                    shared_expense=shared_expense,
                    participant_id=participant_id,
                    shares=num_shares,
                    amount=share_amount,
                )

        elif shared_expense.split_method == SharedExpense.SplitMethod.PERCENTAGE:
            for participant_id, percentage in percentages.items():
                share_amount = shared_expense.amount * percentage / Decimal("100")
                ParticipantShare.objects.create(
                    shared_expense=shared_expense,
                    participant_id=participant_id,
                    percentage=percentage,
                    amount=share_amount,
                )

        return shared_expense


class SharedExpenseUpdateSerializer(SharedExpenseSerializer):
    """
    Serializer for updating shared expenses.
    """

    class Meta(SharedExpenseSerializer.Meta):
        """
        Meta options for SharedExpenseUpdateSerializer.
        """

        read_only_fields = SharedExpenseSerializer.Meta.read_only_fields + [
            "creator",
            "amount",
            "split_method",
            "expense",
        ]


class ParticipantShareUpdateSerializer(ParticipantShareSerializer):
    """
    Serializer for updating participant shares.
    """

    class Meta(ParticipantShareSerializer.Meta):
        """
        Meta options for ParticipantShareUpdateSerializer.
        """

        read_only_fields = ParticipantShareSerializer.Meta.read_only_fields + [
            "shared_expense",
            "participant",
            "amount",
            "percentage",
            "shares",
        ]


class PaymentRecordSerializer(serializers.Serializer):
    """
    Serializer for recording payments.
    """

    amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, min_value=Decimal("0.01")
    )
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate_amount(self, value: Decimal) -> Decimal:
        """Validate payment amount."""
        participant_share = self.context.get("participant_share")
        if value > participant_share.remaining_amount:
            raise serializers.ValidationError(
                _("Payment amount cannot exceed remaining balance.")
            )
        return value
