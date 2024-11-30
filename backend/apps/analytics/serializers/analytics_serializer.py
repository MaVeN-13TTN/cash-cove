"""
Serializers for the analytics application.
"""

from rest_framework import serializers
from ..models import SpendingAnalytics, BudgetUtilization


class SpendingAnalyticsSerializer(serializers.ModelSerializer):
    """
    Serializer for SpendingAnalytics model.
    """

    class Meta:
        """
        Meta options for SpendingAnalyticsSerializer.
        """

        model = SpendingAnalytics
        fields = [
            "id",
            "date",
            "category",
            "total_amount",
            "transaction_count",
            "average_amount",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]


class BudgetUtilizationSerializer(serializers.ModelSerializer):
    """
    Serializer for BudgetUtilization model.
    """

    class Meta:
        """
        Meta options for BudgetUtilizationSerializer.
        """

        model = BudgetUtilization
        fields = [
            "id",
            "category",
            "month",
            "budget_amount",
            "spent_amount",
            "utilization_percentage",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]


class SpendingTrendSerializer(serializers.Serializer):
    """
    Serializer for spending trend data.
    """

    month = serializers.DateField()
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    transaction_count = serializers.IntegerField()
    average_amount = serializers.DecimalField(max_digits=12, decimal_places=2)


class CategoryInsightSerializer(serializers.Serializer):
    """
    Serializer for category insight data.
    """

    category = serializers.CharField()
    total = serializers.DecimalField(max_digits=12, decimal_places=2)


class UtilizationInsightSerializer(serializers.Serializer):
    """
    Serializer for utilization insight data.
    """

    category = serializers.CharField()
    avg_utilization = serializers.DecimalField(max_digits=5, decimal_places=2)


class SpendingInsightsSerializer(serializers.Serializer):
    """
    Serializer for spending insights data.
    """

    top_categories = CategoryInsightSerializer(many=True)
    utilization_summary = UtilizationInsightSerializer(many=True)
