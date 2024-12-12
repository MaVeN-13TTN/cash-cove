from typing import Dict, Any, TypeVar, Type, TYPE_CHECKING
from django.contrib.auth import get_user_model, password_validation
from rest_framework import serializers
from django.utils.translation import gettext_lazy as _
from django.core.validators import validate_email, ValidationError
from django.db import transaction
from django.core.exceptions import ObjectDoesNotExist
from ..models import Profile

BaseUser = get_user_model()

if TYPE_CHECKING:
    from django.contrib.auth.models import AbstractUser

    UserType = TypeVar("UserType", bound="AbstractUser")
else:
    UserType = TypeVar("UserType", bound=BaseUser)


class UserSerializer(serializers.ModelSerializer[UserType]):
    """Enhanced serializer for User model."""

    full_name = serializers.SerializerMethodField()
    profile = serializers.SerializerMethodField()
    total_expenses = serializers.IntegerField(read_only=True)
    total_budgets = serializers.IntegerField(read_only=True)

    class Meta:
        """Meta options for UserSerializer."""

        model = BaseUser
        fields = [
            "id",
            "email",
            "username",
            "first_name",
            "last_name",
            "full_name",
            "phone_number",
            "date_of_birth",
            "avatar",
            "bio",
            "is_verified",
            "date_joined",
            "last_login",
            "profile",
            "total_expenses",
            "total_budgets",
        ]
        read_only_fields = ["id", "date_joined", "last_login", "is_verified"]
        extra_kwargs = {"password": {"write_only": True}, "email": {"required": True}}

    def get_full_name(self, obj: Type[UserType]) -> str:
        """Get user's full name."""
        return obj.get_full_name()

    def get_profile(self, obj: Type[UserType]) -> Dict[str, Any]:
        """Get user's profile data."""
        return {
            "theme": obj.profile.theme,
            "default_currency": obj.profile.default_currency,
            "language": obj.profile.language,
            "timezone": obj.profile.timezone,
        }

    def validate_email(self, value: str) -> str:
        """
        Validate email format and uniqueness.

        Args:
            value: Email to validate

        Returns:
            str: Validated email
        """
        # Remove email verification logic
        # Validate email format
        if not value:
            raise serializers.ValidationError(_("Email is required."))
        
        # Basic email format validation
        try:
            validate_email(value)
        except ValidationError:
            raise serializers.ValidationError(_("Invalid email format."))
        
        # Convert to lowercase
        value = value.lower()
        
        # Check for existing email (optional, depending on your requirements)
        if BaseUser.objects.filter(email=value).exists():
            raise serializers.ValidationError(_("This email is already in use."))
        
        return value

    def validate_phone_number(self, value: str) -> str:
        """
        Validate phone number format.

        Args:
            value: Phone number to validate

        Returns:
            str: Validated phone number

        Raises:
            serializers.ValidationError: If phone number is invalid
        """
        if not value.isdigit() or len(value) not in [10, 11]:
            raise serializers.ValidationError(_("Invalid phone number format."))
        return value

    def to_representation(self, instance: Type[UserType]) -> Dict[str, Any]:
        """Customize data representation."""
        data = super().to_representation(instance)
        data["total_expenses"] = instance.expenses.count()
        data["total_budgets"] = instance.budgets.count()
        return data


class UserCreateSerializer(UserSerializer):
    """Enhanced serializer for creating users."""

    password = serializers.CharField(
        write_only=True, required=True, style={"input_type": "password"}
    )
    confirm_password = serializers.CharField(
        write_only=True, required=True, style={"input_type": "password"}
    )
    terms_accepted = serializers.BooleanField(required=True)
    first_name = serializers.CharField(required=True)
    last_name = serializers.CharField(required=True)

    class Meta(UserSerializer.Meta):
        """Meta options for UserCreateSerializer."""

        fields = UserSerializer.Meta.fields + [
            "password",
            "confirm_password",
            "terms_accepted",
            "first_name",
            "last_name",
        ]

    def validate_password(self, value: str) -> str:
        """Validate password strength."""
        password_validation.validate_password(value)
        return value

    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate data.

        Args:
            attrs: Data to validate

        Returns:
            Dict[str, Any]: Validated data

        Raises:
            serializers.ValidationError: If validation fails
        """
        # Log incoming data for debugging
        import logging
        logger = logging.getLogger(__name__)
        logger.debug('Validating data: %s', attrs)

        # Check password match
        if attrs['password'] != attrs['confirm_password']:
            raise serializers.ValidationError(_('Passwords do not match.'))

        # Perform additional validations here if needed

        if not attrs["terms_accepted"]:
            raise serializers.ValidationError(_("You must accept the terms and conditions."))

        return attrs

    def create(self, validated_data: Dict[str, Any]) -> BaseUser:
        """
        Create a new user with the validated data.
        
        Args:
            validated_data (dict): Validated data from the serializer
            
        Returns:
            User: Newly created user
        """
        with transaction.atomic():
            # Remove non-user fields
            profile_data = {}
            for field in ['terms_accepted', 'confirm_password']:
                if field in validated_data:
                    profile_data[field] = validated_data.pop(field)

            # Extract password before user creation
            password = validated_data.pop('password')

            # Create base user first
            user = BaseUser(
                email=validated_data['email'],
                username=validated_data.get('username', ''),
                first_name=validated_data.get('first_name', ''),
                last_name=validated_data.get('last_name', ''),
                is_active=True,
                is_verified=True  # Auto verify for now
            )
            
            # Set password properly
            user.set_password(password)
            user.save()

            # Create or get profile
            try:
                profile = Profile.objects.get(user=user)
            except ObjectDoesNotExist:
                profile = Profile.objects.create(
                    user=user,
                    terms_accepted=profile_data.get('terms_accepted', False)
                )

            return user


class UserUpdateSerializer(UserSerializer):
    """Enhanced serializer for updating users."""

    class Meta(UserSerializer.Meta):
        """Meta options for UserUpdateSerializer."""

        fields = [
            "first_name",
            "last_name",
            "phone_number",
            "date_of_birth",
            "avatar",
            "bio",
            "preferences",
        ]

    def update(self, instance: Type[UserType], validated_data: Dict[str, Any]) -> Type[UserType]:
        """Update user data."""
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance


class LoginSerializer(serializers.Serializer):
    """Serializer for user login."""

    email = serializers.EmailField(required=True)
    password = serializers.CharField(
        write_only=True, required=True, style={"input_type": "password"}
    )

    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """Validate login credentials."""
        import logging
        logger = logging.getLogger(__name__)

        email = attrs.get("email", "").lower()
        password = attrs.get("password", "")

        logger.info(f"Login attempt for email: {email}")

        if not email or not password:
            logger.warning("Login attempt with missing email or password")
            raise serializers.ValidationError(_("Please provide both email and password."))

        user = BaseUser.objects.filter(email=email).first()

        if not user:
            logger.warning(f"No user found with email: {email}")
            raise serializers.ValidationError(_("Invalid email or password."))

        logger.info(f"User found: {user.username}, Checking password")
        
        if not user.check_password(password):
            logger.warning(f"Password check failed for user: {user.username}")
            raise serializers.ValidationError(_("Invalid email or password."))

        if not user.is_active:
            logger.warning(f"Inactive user login attempt: {user.username}")
            raise serializers.ValidationError(_("This account is inactive."))

        attrs["user"] = user
        return attrs


class TokenSerializer(serializers.Serializer):
    """Serializer for token authentication."""

    refresh = serializers.CharField(read_only=True)
    access = serializers.CharField(read_only=True)

    def create(self, validated_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create token for user."""
        return validated_data

    def update(self, instance: Any, validated_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update is not supported."""
        raise NotImplementedError("Token update is not supported")


class PasswordResetSerializer(serializers.Serializer):
    """Serializer for password reset request."""

    email = serializers.EmailField(required=True)

    def validate_email(self, value: str) -> str:
        """Validate email."""
        email = value.lower()
        if not BaseUser.objects.filter(email=email).exists():
            raise serializers.ValidationError(_("User with this email does not exist."))
        return email


class PasswordResetConfirmSerializer(serializers.Serializer):
    """Serializer for password reset confirmation."""

    token = serializers.CharField(required=True)
    password = serializers.CharField(
        write_only=True, required=True, style={"input_type": "password"}
    )
    confirm_password = serializers.CharField(
        write_only=True, required=True, style={"input_type": "password"}
    )

    def validate_password(self, value: str) -> str:
        """Validate password strength."""
        password_validation.validate_password(value)
        return value

    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """Validate data."""
        if attrs.get("password") != attrs.get("confirm_password"):
            raise serializers.ValidationError(
                {"password": _("Password fields didn't match.")}
            )
        return attrs
