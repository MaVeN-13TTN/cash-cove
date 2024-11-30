"""
API views for the analytics application.
"""

from datetime import datetime
from typing import Any
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from ..models import SpendingAnalytics, BudgetUtilization
from ..serializers.analytics_serializer import (
    SpendingAnalyticsSerializer,
    BudgetUtilizationSerializer,
    SpendingTrendSerializer,
    SpendingInsightsSerializer,
)
from ..services.analytics_service import AnalyticsService


class SpendingAnalyticsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing spending analytics.
    """

    serializer_class = SpendingAnalyticsSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Filter queryset for current user.
        """
        return SpendingAnalytics.objects.filter(user=self.request.user)

    @action(detail=False, methods=["get"])
    def by_category(self, request: Request) -> Response:
        """
        Get spending analytics grouped by category.
        """
        start_date = request.query_params.get("start_date")
        end_date = request.query_params.get("end_date")

        try:
            start_date = datetime.strptime(start_date, "%Y-%m-%d").date()
            end_date = datetime.strptime(end_date, "%Y-%m-%d").date()
        except (ValueError, TypeError):
            return Response(
                {"error": "Invalid date format. Use YYYY-MM-DD"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        analytics = AnalyticsService.calculate_spending_analytics(
            user_id=request.user.id, start_date=start_date, end_date=end_date
        )
        return Response(analytics)


class BudgetUtilizationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing budget utilization.
    """

    serializer_class = BudgetUtilizationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Filter queryset for current user.
        """
        return BudgetUtilization.objects.filter(user=self.request.user)

    @action(detail=False, methods=["get"])
    def monthly_summary(self, request: Request) -> Response:
        """
        Get monthly budget utilization summary.
        """
        month = request.query_params.get("month")
        try:
            month_date = datetime.strptime(month, "%Y-%m").date()
        except (ValueError, TypeError):
            return Response(
                {"error": "Invalid month format. Use YYYY-MM"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        AnalyticsService.update_budget_utilization(
            user_id=request.user.id, month=month_date
        )

        utilization = self.get_queryset().filter(month=month_date)
        serializer = self.get_serializer(utilization, many=True)
        return Response(serializer.data)


class SpendingTrendsView(APIView):
    """
    View for analyzing spending trends.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """
        Get spending trends for a category.
        """
        category = request.query_params.get("category")
        months = request.query_params.get("months", 6)

        try:
            months = int(months)
        except (ValueError, TypeError):
            return Response(
                {"error": "Invalid months parameter"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not category:
            return Response(
                {"error": "Category parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        trends = AnalyticsService.get_category_trends(
            user_id=request.user.id, category=category, months=months
        )
        serializer = SpendingTrendSerializer(trends, many=True)
        return Response(serializer.data)


class SpendingInsightsView(APIView):
    """
    View for getting spending insights.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """
        Get spending insights for the user.
        """
        insights = AnalyticsService.get_spending_insights(user_id=request.user.id)
        serializer = SpendingInsightsSerializer(insights)
        return Response(serializer.data)
