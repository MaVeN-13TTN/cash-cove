"""
API views for the expenses application.
"""

from datetime import datetime
from typing import Any
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils.translation import gettext_lazy as _
from django.db.models import Q
from django.utils import timezone

from ..models import Expense
from ..serializers.expenses_serializer import (
    ExpenseSerializer,
    ExpenseCreateSerializer,
    ExpenseUpdateSerializer,
    ExpenseListSerializer,
    ExpenseSummarySerializer,
    ExpenseRecurrenceSerializer,
)
from ..services.expenses_service import ExpenseService


class ExpenseViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing expenses.
    """

    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get queryset filtered by user and optional parameters."""
        queryset = Expense.objects.filter(user=self.request.user)

        # Apply filters from query parameters
        category = self.request.query_params.get("category")
        start_date = self.request.query_params.get("start_date")
        end_date = self.request.query_params.get("end_date")
        is_recurring = self.request.query_params.get("is_recurring")
        min_amount = self.request.query_params.get("min_amount")
        max_amount = self.request.query_params.get("max_amount")

        if category:
            queryset = queryset.filter(category=category)

        try:
            if start_date:
                start_date = datetime.strptime(start_date, "%Y-%m-%d").date()
                queryset = queryset.filter(date__gte=start_date)
            if end_date:
                end_date = datetime.strptime(end_date, "%Y-%m-%d").date()
                queryset = queryset.filter(date__lte=end_date)
        except ValueError:
            pass  # Invalid date format, ignore filter

        if is_recurring is not None:
            queryset = queryset.filter(is_recurring=is_recurring.lower() == "true")

        if min_amount:
            try:
                queryset = queryset.filter(amount__gte=float(min_amount))
            except ValueError:
                pass

        if max_amount:
            try:
                queryset = queryset.filter(amount__lte=float(max_amount))
            except ValueError:
                pass

        return queryset.select_related("budget")

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == "create":
            return ExpenseCreateSerializer
        if self.action in ["update", "partial_update"]:
            return ExpenseUpdateSerializer
        if self.action == "list":
            return ExpenseListSerializer
        return ExpenseSerializer

    def perform_create(self, serializer):
        """Create expense for current user."""
        serializer.save(user=self.request.user)

    @action(detail=False, methods=["get"])
    def summary(self, request: Request) -> Response:
        """
        Get expense summary.
        """
        start_date = request.query_params.get("start_date")
        end_date = request.query_params.get("end_date")
        category = request.query_params.get("category")

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

        summary = ExpenseService.get_expense_summary(
            user_id=request.user.id,
            start_date=start_date,
            end_date=end_date,
            category=category,
        )
        serializer = ExpenseSummarySerializer(summary, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"])
    def monthly_trend(self, request: Request) -> Response:
        """
        Get monthly expense trends.
        """
        months = request.query_params.get("months", 12)
        category = request.query_params.get("category")

        try:
            months = int(months)
            if months < 1 or months > 24:
                raise ValueError
        except ValueError:
            return Response(
                {"error": _("Months must be between 1 and 24")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        trends = ExpenseService.get_monthly_trend(
            user_id=request.user.id, months=months, category=category
        )
        return Response(trends)

    @action(detail=False, methods=["get"])
    def category_distribution(self, request: Request) -> Response:
        """
        Get expense distribution by category.
        """
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

        distribution = ExpenseService.get_category_distribution(
            user_id=request.user.id, start_date=start_date, end_date=end_date
        )
        return Response(distribution)

    @action(detail=False, methods=["post"])
    def create_recurring(self, request: Request) -> Response:
        """
        Create recurring expenses.
        """
        serializer = ExpenseRecurrenceSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        recurring_expenses = ExpenseService.create_recurring_expenses(
            expense_data={
                **serializer.validated_data["expense_data"],
                "user": request.user,
                "is_recurring": True,
            },
            start_date=serializer.validated_data["start_date"],
            end_date=serializer.validated_data["end_date"],
            frequency=serializer.validated_data["frequency"],
        )

        response_serializer = self.get_serializer(recurring_expenses, many=True)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=["get"])
    def forecast(self, request: Request) -> Response:
        """
        Get recurring expenses forecast.
        """
        months = request.query_params.get("months", 3)
        try:
            months = int(months)
            if months < 1 or months > 12:
                raise ValueError
        except ValueError:
            return Response(
                {"error": _("Months must be between 1 and 12")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        forecast = ExpenseService.get_recurring_expenses_forecast(
            user_id=request.user.id, months_ahead=months
        )
        return Response(forecast)

    @action(detail=False, methods=["get"])
    def insights(self, request: Request) -> Response:
        """
        Get expense insights.
        """
        insights = ExpenseService.get_expense_insights(user_id=request.user.id)
        return Response(insights)

    @action(detail=True, methods=["post"])
    def duplicate(self, request: Request, pk: Any = None) -> Response:
        """
        Duplicate an expense.
        """
        expense = self.get_object()
        new_expense = Expense.objects.create(
            user=request.user,
            title=f"{expense.title} (Copy)",
            amount=expense.amount,
            category=expense.category,
            date=timezone.now().date(),
            payment_method=expense.payment_method,
            budget=expense.budget,
            notes=expense.notes,
            location=expense.location,
            is_recurring=False,
            tags=expense.tags,
            metadata=expense.metadata,
        )
        serializer = self.get_serializer(new_expense)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"])
    def attach_to_budget(self, request: Request, pk: Any = None) -> Response:
        """
        Attach expense to a budget.
        """
        expense = self.get_object()
        budget_id = request.data.get("budget_id")

        if not budget_id:
            return Response(
                {"error": _("budget_id is required")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            from apps.budgets.models import Budget

            budget = Budget.objects.get(
                id=budget_id, user=request.user, category=expense.category
            )

            ExpenseService.validate_expense_against_budget(expense)
            expense.budget = budget
            expense.save()

            serializer = self.get_serializer(expense)
            return Response(serializer.data)

        except Budget.DoesNotExist:
            return Response(
                {"error": _("Invalid budget selected")},
                status=status.HTTP_400_BAD_REQUEST,
            )
        except ValidationError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
