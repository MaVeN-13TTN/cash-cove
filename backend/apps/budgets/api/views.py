"""
API views for the budgets application.
"""

from datetime import datetime
from typing import Any
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils.translation import gettext_lazy as _

from ..models import Budget
from ..serializers.budgets_serializer import (
    BudgetSerializer,
    BudgetCreateSerializer,
    BudgetUpdateSerializer,
    BudgetListSerializer,
)
from ..services.budgets_service import BudgetService


class BudgetViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing budgets.
    """

    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get queryset filtered by user."""
        return Budget.objects.filter(user=self.request.user)

    def get_serializer_class(self):
        """
        Return appropriate serializer class based on action.
        """
        if self.action == "create":
            return BudgetCreateSerializer
        if self.action == "update" or self.action == "partial_update":
            return BudgetUpdateSerializer
        if self.action == "list":
            return BudgetListSerializer
        return BudgetSerializer

    def perform_create(self, serializer):
        """Create budget for current user."""
        serializer.save(user=self.request.user)

    @action(detail=False, methods=["get"])
    def active(self, request: Request) -> Response:
        """
        Get active budgets for current user.
        """
        active_budgets = BudgetService.get_active_budgets(request.user.id)
        serializer = self.get_serializer(active_budgets, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"])
    def category(self, request: Request) -> Response:
        """
        Get budgets by category.
        """
        category = request.query_params.get("category")
        if not category:
            return Response(
                {"error": _("Category parameter is required")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        start_date = request.query_params.get("start_date")
        end_date = request.query_params.get("end_date")

        try:
            if start_date:
                start_date = datetime.strptime(start_date, "%Y-%m-%d").date()
            if end_date:
                end_date = datetime.strptime(end_date, "%Y-%m-%d").date()
        except ValueError:
            return Response(
                {"error": _("Invalid date format. Use YYYY-MM-DD")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        budgets = BudgetService.get_category_budgets(
            user_id=request.user.id,
            category=category,
            start_date=start_date,
            end_date=end_date,
        )
        serializer = self.get_serializer(budgets, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"])
    def forecast(self, request: Request) -> Response:
        """
        Get budget forecast.
        """
        months = request.query_params.get("months", 3)
        try:
            months = int(months)
            if months < 1 or months > 12:
                raise ValueError
        except ValueError:
            return Response(
                {"error": _("Months must be a number between 1 and 12")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        forecast = BudgetService.calculate_budget_forecast(
            user_id=request.user.id, months_ahead=months
        )
        return Response(forecast)

    @action(detail=False, methods=["get"])
    def summary(self, request: Request) -> Response:
        """
        Get summary of all active budgets.
        """
        active_budgets = BudgetService.get_active_budgets(request.user.id)
        summaries = [
            BudgetService.get_budget_summary(budget) for budget in active_budgets
        ]
        return Response(summaries)
