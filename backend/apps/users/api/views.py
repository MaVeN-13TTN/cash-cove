"""
API views for the users application.
"""

from rest_framework import viewsets, status, generics, mixins
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.request import Request
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
import logging
import rest_framework.serializers as serializers
from django.db import transaction
from django.core.mail import send_mail
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.conf import settings

from ..serializers.users_serializer import (
    UserSerializer,
    UserCreateSerializer,
    UserUpdateSerializer,
    LoginSerializer,
    TokenSerializer,
    PasswordResetSerializer,
    PasswordResetConfirmSerializer,
)
from ..serializers.profile_serializer import ProfileSerializer
from ..services.auth_service import AuthService
from ..services.users_service import UserService
from ..services.profile_service import ProfileService
from ..models import Profile
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

logger = logging.getLogger(__name__)

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
        """
        Handle user registration.

        Creates a new user and returns user details and token.
        """
        serializer = UserCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Create user
        user = serializer.save()
        
        # Automatically mark user as verified
        user.is_verified = True
        user.save(update_fields=['is_verified'])
        
        # Generate tokens
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UserSerializer(user).data
        }, status=status.HTTP_201_CREATED)

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
        serializer = serializers.Serializer(data=request.data)
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
        return Response({"available": not exists})

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


class ProfileViewSet(viewsets.GenericViewSet,
                    mixins.RetrieveModelMixin,
                    mixins.UpdateModelMixin):
    """
    ViewSet for managing user profiles.
    """

    serializer_class = ProfileSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'put', 'patch']

    def get_object(self):
        """Get or create profile for current user."""
        profile, _ = Profile.objects.get_or_create(user=self.request.user)
        return profile

    def retrieve(self, request, *args, **kwargs):
        """Get user profile."""
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    def update(self, request, *args, **kwargs):
        """Update user profile."""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data)

    def partial_update(self, request, *args, **kwargs):
        """Partially update user profile."""
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)

    @action(detail=False, methods=["post"])
    def toggle_2fa(self, request: Request) -> Response:
        """Toggle two-factor authentication."""
        profile = self.get_object()
        new_status = profile.toggle_two_factor()

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
    """View for user registration."""

    serializer_class = UserCreateSerializer
    permission_classes = [AllowAny]

    def create(self, request: Request, *args, **kwargs) -> Response:
        """
        Handle user registration.
        
        Creates a new user and returns user details and token.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            with transaction.atomic():
                # Create user and profile
                user = serializer.save()

                # Generate tokens
                refresh = RefreshToken.for_user(user)
                tokens = {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                }

                # Return response
                response_data = {
                    "user": UserSerializer(user).data,
                    "tokens": tokens,
                    "message": _("Registration successful"),
                }
                return Response(response_data, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response(
                {"error": str(e), "message": _("Registration failed. Please try again.")},
                status=status.HTTP_400_BAD_REQUEST,
            )


class ResetPasswordView(generics.GenericAPIView):
    """View for initiating password reset."""

    serializer_class = PasswordResetSerializer
    permission_classes = [AllowAny]

    def post(self, request: Request) -> Response:
        """
        Initiate password reset process.
        
        Sends password reset instructions to user's email.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data["email"]
        
        try:
            user = User.objects.get(email=email)
            if not user.is_active:
                return Response(
                    {"error": _("Account is deactivated")},
                    status=status.HTTP_400_BAD_REQUEST,
                )
                
            # Generate password reset token
            token = default_token_generator.make_token(user)
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            
            # Send password reset email
            reset_url = f"{settings.FRONTEND_URL}/reset-password?token={token}&uid={uid}"
            send_mail(
                subject=_("Password Reset Request"),
                message=_(
                    f"Click the following link to reset your password: {reset_url}\n"
                    "If you did not request this reset, please ignore this email."
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
            )
            
            return Response(
                {"message": _("Password reset instructions sent to your email")},
                status=status.HTTP_200_OK,
            )
            
        except User.DoesNotExist:
            # Return success even if email doesn't exist for security
            return Response(
                {"message": _("Password reset instructions sent to your email")},
                status=status.HTTP_200_OK,
            )


class ResetPasswordConfirmView(generics.GenericAPIView):
    """View for confirming password reset."""

    serializer_class = PasswordResetConfirmSerializer
    permission_classes = [AllowAny]

    def post(self, request: Request) -> Response:
        """
        Confirm password reset using token and new password.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        token = serializer.validated_data["token"]
        password = serializer.validated_data["password"]
        uid = request.data.get("uid")
        
        try:
            # Decode user ID and get user
            user_id = force_str(urlsafe_base64_decode(uid))
            user = User.objects.get(pk=user_id)
            
            # Verify token
            if not default_token_generator.check_token(user, token):
                return Response(
                    {"error": _("Invalid or expired reset token")},
                    status=status.HTTP_400_BAD_REQUEST,
                )
                
            # Set new password
            user.set_password(password)
            user.save()
            
            return Response(
                {"message": _("Password reset successful")},
                status=status.HTTP_200_OK,
            )
            
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            return Response(
                {"error": _("Invalid reset link")},
                status=status.HTTP_400_BAD_REQUEST,
            )


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
        logger.info(f"Token request received with data: {request.data}")
        
        try:
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
        except serializers.ValidationError as e:
            # Log validation errors
            logger.error(f"Login validation error: {e}")
            raise
        except Exception as e:
            # Log unexpected errors
            logger.error(f"Unexpected error during login: {e}")
            raise
