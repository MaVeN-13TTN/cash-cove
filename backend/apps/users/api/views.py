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
from django.utils import timezone

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
from rest_framework_simplejwt.tokens import RefreshToken

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
        if self.action in [
            "create",
            "reset_password",
            "check_email",
            "register",
            "login",
        ]:
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

    @action(detail=False, methods=["get", "post"])
    def check_email(self, request: Request) -> Response:
        """Check if email is available."""
        email = request.GET.get("email") or request.data.get("email")
        if not email:
            return Response(
                {"error": _("Email is required")},
                status=status.HTTP_400_BAD_REQUEST,
            )

        exists = User.objects.filter(email=email).exists()
        return Response({"available": exists})

    @action(detail=False, methods=["get"])
    def profile(self, request: Request) -> Response:
        """
        Get or create user profile.
        
        This method ensures a profile exists for the current user
        and returns the profile data.
        """
        # Ensure profile exists
        profile, created = Profile.objects.get_or_create(user=request.user)
        
        # Use the profile serializer to represent the profile
        serializer = ProfileSerializer(profile, context={'request': request})
        
        # If profile was just created, add a flag to indicate first-time setup
        response_data = serializer.data
        response_data['is_first_login'] = created
        
        return Response(response_data)

    @action(detail=False, methods=["get"])
    def security_status(self, request: Request) -> Response:
        """
        Get security status for the current user.
        
        Returns comprehensive security information, 
        creating a profile if it doesn't exist.
        """
        # Ensure profile exists
        profile, created = Profile.objects.get_or_create(user=request.user)
        
        # Prepare security status
        security_status = {
            "two_factor_enabled": profile.two_factor_enabled,
            "email_verified": request.user.is_active,
            "is_first_login": created,
            "activity_status": "inactive" if created else ProfileSerializer(profile).get_activity_status(profile),
            "security_score": 0 if created else ProfileSerializer(profile).get_security_score(profile)
        }
        
        return Response(security_status)

    @action(detail=False, methods=["post"])
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

    @action(detail=False, methods=["put"])
    def update_profile(self, request: Request) -> Response:
        """Update user profile."""
        profile = ProfileService.get_or_create_profile(request.user)
        serializer = ProfileSerializer(profile, data=request.data, partial=True)
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


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


class SecurityStatusViewSet(viewsets.ViewSet):
    """
    ViewSet for managing user security status.
    """

    permission_classes = [IsAuthenticated]

    def list(self, request: Request) -> Response:
        """Return security status for the current user."""
        profile = ProfileService.get_or_create_profile(request.user)
        security_status = {
            "two_factor_enabled": profile.two_factor_enabled,
            "email_verified": request.user.is_active,  # Adjust based on your email verification logic
        }
        return Response(security_status)


class RegisterView(generics.CreateAPIView):
    """
    View for user registration.
    """
    serializer_class = UserCreateSerializer
    permission_classes = [AllowAny]

    def create(self, request: Request, *args, **kwargs) -> Response:
        """
        Handle user registration.
        
        Creates a new user and returns user details and token.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Generate tokens for the new user
        token_serializer = TokenSerializer(data={'user': user})
        token_serializer.is_valid(raise_exception=True)
        
        return Response({
            'user': UserSerializer(user).data,
            'tokens': token_serializer.validated_data
        }, status=status.HTTP_201_CREATED)


class VerifyEmailView(generics.GenericAPIView):
    """
    View for email verification.
    """
    serializer_class = EmailVerificationSerializer
    permission_classes = [AllowAny]

    def post(self, request: Request) -> Response:
        """
        Verify user's email using provided token.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Verify email and activate user
        user = serializer.save()
        
        return Response({
            'detail': _('Email verified successfully.'),
            'user': UserSerializer(user).data
        }, status=status.HTTP_200_OK)


class ResetPasswordView(generics.GenericAPIView):
    """
    View for initiating password reset.
    """
    serializer_class = PasswordResetSerializer
    permission_classes = [AllowAny]

    def post(self, request: Request) -> Response:
        """
        Initiate password reset process.
        
        Sends password reset instructions to user's email.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Send password reset instructions
        serializer.save()
        
        return Response({
            'detail': _('Password reset instructions sent to your email.')
        }, status=status.HTTP_200_OK)


class ResetPasswordConfirmView(generics.GenericAPIView):
    """
    View for confirming password reset.
    """
    serializer_class = PasswordResetConfirmSerializer
    permission_classes = [AllowAny]

    def post(self, request: Request) -> Response:
        """
        Confirm password reset using token and new password.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Reset password
        serializer.save()
        
        return Response({
            'detail': _('Password reset successful.')
        }, status=status.HTTP_200_OK)


class CustomTokenObtainPairView(generics.GenericAPIView):
    """
    Custom token obtain view to handle login with our custom validation.
    """
    serializer_class = LoginSerializer
    permission_classes = [AllowAny]

    def post(self, request: Request) -> Response:
        """
        Handle token generation for login.
        
        Validates credentials and generates JWT tokens.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = serializer.validated_data['user']
        
        # Generate tokens
        refresh = RefreshToken.for_user(user)
        
        # Update last login
        user.last_login = timezone.now()
        user.save(update_fields=['last_login'])
        
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UserSerializer(user).data
        }, status=status.HTTP_200_OK)
