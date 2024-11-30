"""
API views for the users application.
"""

from rest_framework import viewsets, status, generics
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.request import Request
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _

from ..serializers.users_serializer import (
    UserSerializer,
    UserCreateSerializer,
    UserUpdateSerializer,
    LoginSerializer,
    TokenSerializer,
    PasswordResetSerializer,
    PasswordResetConfirmSerializer,
    EmailVerificationSerializer,
)
from ..serializers.profile_serializer import ProfileSerializer
from ..services.auth_service import AuthService
from ..services.users_service import UserService
from ..services.profile_service import ProfileService
from ..models import Profile

User = get_user_model()


class UserViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing users.
    """

    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get queryset for users."""
        if self.request.user.is_staff:
            return User.objects.all()
        return User.objects.filter(id=self.request.user.id)

    def get_serializer_class(self):
        """Get appropriate serializer class."""
        if self.action == "create":
            return UserCreateSerializer
        if self.action in ["update", "partial_update"]:
            return UserUpdateSerializer
        return UserSerializer

    def get_permissions(self):
        """Get appropriate permissions."""
        if self.action in ["create", "reset_password"]:
            return [AllowAny()]
        return super().get_permissions()

    @action(detail=False, methods=["post"])
    def login(self, request: Request) -> Response:
        """Login user."""
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = User.objects.get(email=serializer.validated_data["email"])
            if user.check_password(serializer.validated_data["password"]):
                tokens = AuthService.get_tokens_for_user(user)
                return Response(TokenSerializer(tokens).data)
            raise User.DoesNotExist
        except User.DoesNotExist:
            return Response(
                {"error": _("Invalid credentials")}, status=status.HTTP_401_UNAUTHORIZED
            )

    @action(detail=False, methods=["post"])
    def register(self, request: Request) -> Response:
        """Register new user."""
        serializer = UserCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user, _ = AuthService.register_user(serializer.validated_data)
        tokens = AuthService.get_tokens_for_user(user)

        return Response(
            {"user": UserSerializer(user).data, "tokens": tokens},
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=["post"])
    def reset_password(self, request: Request) -> Response:
        """Initiate password reset."""
        serializer = PasswordResetSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        AuthService.initiate_password_reset(serializer.validated_data["email"])

        return Response({"message": _("Password reset email sent if account exists.")})

    @action(detail=False, methods=["post"])
    def reset_password_confirm(self, request: Request) -> Response:
        """Confirm password reset."""
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        uid = request.query_params.get("uid")
        if not uid:
            return Response(
                {"error": _("Missing uid parameter")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        success = AuthService.reset_password(
            uid=uid,
            token=serializer.validated_data["token"],
            password=serializer.validated_data["password"],
        )

        if success:
            return Response({"message": _("Password reset successful")})
        return Response(
            {"error": _("Invalid token")}, status=status.HTTP_400_BAD_REQUEST
        )

    @action(detail=False, methods=["post"])
    def verify_email(self, request: Request) -> Response:
        """Verify email address."""
        serializer = EmailVerificationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        uid = request.query_params.get("uid")
        if not uid:
            return Response(
                {"error": _("Missing uid parameter")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        success = AuthService.verify_email(
            uid=uid, token=serializer.validated_data["token"]
        )

        if success:
            return Response({"message": _("Email verified successfully")})
        return Response(
            {"error": _("Invalid token")}, status=status.HTTP_400_BAD_REQUEST
        )

    @action(detail=True, methods=["post"])
    def deactivate(self, request: Request) -> Response:
        """Deactivate user account."""
        password = request.data.get("password")
        if not password:
            return Response(
                {"error": _("Password is required")}, status=status.HTTP_400_BAD_REQUEST
            )

        try:
            UserService.deactivate_account(user=request.user, password=password)
            return Response({"message": _("Account deactivated successfully")})
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class ProfileViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing user profiles.
    """

    serializer_class = ProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get queryset for profiles."""
        if self.request.user.is_staff:
            return Profile.objects.all()
        return Profile.objects.filter(user=self.request.user)

    def get_object(self):
        """Get or create profile for current user."""
        return ProfileService.get_or_create_profile(self.request.user)

    @action(detail=True, methods=["post"])
    def toggle_2fa(self, request: Request) -> Response:
        """Toggle two-factor authentication."""
        profile = self.get_object()
        new_status = ProfileService.toggle_two_factor(profile)

        return Response(
            {
                "two_factor_enabled": new_status,
                "message": _("2FA enabled" if new_status else "2FA disabled"),
            }
        )
