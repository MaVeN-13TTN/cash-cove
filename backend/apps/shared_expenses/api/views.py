"""
API views for the shared expenses application.
"""

from typing import Any
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils.translation import gettext_lazy as _
from django.db.models import Q

from ..models import SharedExpense, ParticipantShare
from ..serializers.shared_expenses_serializer import (
    SharedExpenseSerializer,
    SharedExpenseCreateSerializer,
    SharedExpenseUpdateSerializer,
    ParticipantShareSerializer,
    ParticipantShareUpdateSerializer,
    PaymentRecordSerializer,
)
from ..services.shared_expenses_service import SharedExpenseService


class SharedExpenseViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing shared expenses.
    """

    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get queryset filtered by user and optional parameters."""
        include_participated = (
            self.request.query_params.get("include_participated", "true").lower()
            == "true"
        )
        status = self.request.query_params.get("status")
        category = self.request.query_params.get("category")

        return SharedExpenseService.get_user_shared_expenses(
            user_id=self.request.user.id,
            status=status,
            include_participated=include_participated,
            category=category,
        )

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == "create":
            return SharedExpenseCreateSerializer
        if self.action in ["update", "partial_update"]:
            return SharedExpenseUpdateSerializer
        return SharedExpenseSerializer

    def perform_create(self, serializer):
        """Create shared expense for current user."""
        serializer.save(creator=self.request.user)

    @action(detail=True, methods=["post"])
    def record_payment(self, request: Request, pk: Any = None) -> Response:
        """
        Record a payment for a participant share.
        """
        shared_expense = self.get_object()

        try:
            participant_share = shared_expense.participant_shares.get(
                participant=request.user
            )
        except ParticipantShare.DoesNotExist:
            return Response(
                {"error": _("You are not a participant in this expense.")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = PaymentRecordSerializer(
            data=request.data, context={"participant_share": participant_share}
        )

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        share = SharedExpenseService.record_payment(
            share_id=participant_share.id,
            amount=serializer.validated_data["amount"],
            notes=serializer.validated_data.get("notes", ""),
        )

        return Response(ParticipantShareSerializer(share).data)

    @action(detail=False, methods=["get"])
    def summary(self, request: Request) -> Response:
        """
        Get user's shared expenses summary.
        """
        period = request.query_params.get("period")
        summary = SharedExpenseService.get_user_summary(
            user_id=request.user.id, period=period
        )
        return Response(summary)

    @action(detail=True, methods=["get"])
    def statistics(self, request: Request, pk: Any = None) -> Response:
        """
        Get detailed statistics for a shared expense.
        """
        stats = SharedExpenseService.get_expense_statistics(shared_expense_id=pk)
        return Response(stats)

    @action(detail=False, methods=["get"])
    def balance_sheet(self, request: Request) -> Response:
        """
        Get user's balance sheet.
        """
        balance_sheet = SharedExpenseService.get_user_balance_sheet(
            user_id=request.user.id
        )
        return Response(balance_sheet)

    @action(detail=True, methods=["post"])
    def settle(self, request: Request, pk: Any = None) -> Response:
        """
        Mark a shared expense as settled.
        """
        shared_expense = self.get_object()

        if shared_expense.creator != request.user:
            return Response(
                {"error": _("Only the creator can settle this expense.")},
                status=status.HTTP_403_FORBIDDEN,
            )

        if shared_expense.remaining_amount > 0:
            return Response(
                {"error": _("Cannot settle expense with pending payments.")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        shared_expense.status = SharedExpense.Status.SETTLED
        shared_expense.save()

        return Response(self.get_serializer(shared_expense).data)

    @action(detail=True, methods=["post"])
    def cancel(self, request: Request, pk: Any = None) -> Response:
        """
        Cancel a shared expense.
        """
        shared_expense = self.get_object()

        if shared_expense.creator != request.user:
            return Response(
                {"error": _("Only the creator can cancel this expense.")},
                status=status.HTTP_403_FORBIDDEN,
            )

        if shared_expense.status != SharedExpense.Status.PENDING:
            return Response(
                {"error": _("Can only cancel pending expenses.")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        shared_expense.status = SharedExpense.Status.CANCELLED
        shared_expense.save()

        return Response(self.get_serializer(shared_expense).data)


class ParticipantShareViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing participant shares.
    """

    serializer_class = ParticipantShareSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get queryset filtered by user."""
        return ParticipantShare.objects.filter(
            Q(participant=self.request.user)
            | Q(shared_expense__creator=self.request.user)
        )
