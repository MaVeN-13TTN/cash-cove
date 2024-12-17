import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../core/services/dialog/dialog_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthController extends GetxController {
  final DioClient _dioClient;
  final DialogService _dialogService;

  AuthController({
    required DioClient dioClient,
    required DialogService dialogService,
  })  : _dioClient = dioClient,
        _dialogService = dialogService;

  final _isAuthenticated = false.obs;
  final _user = Rxn<Map<String, dynamic>>();
  final _isLoading = false.obs;
  final _error = ''.obs;
  final _isEmailVerified = false.obs;
  final _securityStatus = Rxn<Map<String, dynamic>>();
  final _is2FAEnabled = false.obs;

  bool get isAuthenticated => _isAuthenticated.value;
  Map<String, dynamic>? get user => _user.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isEmailVerified => _isEmailVerified.value;
  Map<String, dynamic>? get securityStatus => _securityStatus.value;
  bool get is2FAEnabled => _is2FAEnabled.value;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<bool> checkAuthStatus() async {
    try {
      final accessToken = await StorageUtils.getAccessToken();
      if (accessToken != null) {
        await getUserProfile();
        await getSecurityStatus();
        _isAuthenticated.value = true;
        return true;
      }
      _isAuthenticated.value = false;
      return false;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error checking auth status', e, stackTrace);
      _isAuthenticated.value = false;
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _dioClient.dio.post('/auth/token/', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.setAccessToken(tokens['access']);
        await StorageUtils.setRefreshToken(tokens['refresh']);
        await checkAuthStatus();
      }
    } catch (e) {
      _dialogService.showError(
        title: 'Login Error',
        message: e.toString(),
      );
      LoggerUtils.error('Login Error', e);
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String username,
    required bool termsAccepted,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      // Step 1: Register User
      final registrationResponse =
          await _dioClient.dio.post('/auth/register/', data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'username': username,
        'terms_accepted': termsAccepted,
      });

      if (registrationResponse.statusCode == 201) {
        // Update authentication state
        await checkAuthStatus();
      } else {
        throw Exception(
            'Signup failed with status code: ${registrationResponse.statusCode}');
      }
    } catch (e) {
      _error.value = 'Signup failed. Please try again.';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return;

      // Get auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send token to backend
      final response = await _dioClient.dio.post('/auth/google/', data: {
        'token': googleAuth.idToken,
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.setAccessToken(tokens['access']);
        await StorageUtils.setRefreshToken(tokens['refresh']);
        await StorageUtils.setUserData(response.data['user']);
        await checkAuthStatus();
      }
    } catch (e) {
      _error.value = 'Google sign in failed';
      LoggerUtils.error('Google Sign In Error', e);
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      _isLoading.value = true;

      // Initialize Facebook Login
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw 'Facebook login failed';
      }

      // Get user data
      final userData = await FacebookAuth.instance.getUserData();

      // Send token to backend
      final response = await _dioClient.dio.post('/auth/facebook/', data: {
        'token': result.accessToken?.token,
        'userData': userData,
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.setAccessToken(tokens['access']);
        await StorageUtils.setRefreshToken(tokens['refresh']);
        await StorageUtils.setUserData(response.data['user']);
        await checkAuthStatus();
      }
    } catch (e) {
      _error.value = 'Facebook sign in failed';
      LoggerUtils.error('Facebook Sign In Error', e);
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signInWithApple() async {
    try {
      _isLoading.value = true;

      // Get Apple credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Send credentials to backend
      final response = await _dioClient.dio.post('/auth/apple/', data: {
        'identityToken': credential.identityToken,
        'authorizationCode': credential.authorizationCode,
        'givenName': credential.givenName,
        'familyName': credential.familyName,
        'email': credential.email,
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.setAccessToken(tokens['access']);
        await StorageUtils.setRefreshToken(tokens['refresh']);
        await StorageUtils.setUserData(response.data['user']);
        await checkAuthStatus();
      }
    } catch (e) {
      _error.value = 'Apple sign in failed';
      LoggerUtils.error('Apple Sign In Error', e);
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _dioClient.dio.post('/auth/verify-email/', data: {
        'token': token,
      });

      if (response.statusCode == 200) {
        _isEmailVerified.value = true;
        Get.snackbar(
          'Success',
          'Email verified successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Email Verification Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      await _dioClient.dio.post('/auth/send-verification-email/');
      Get.snackbar(
        'Success',
        'Verification email sent',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      LoggerUtils.error('Error sending verification email', e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response =
          await _dioClient.dio.post('/auth/reset-password/', data: {
        'email': email,
      });

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Password reset instructions sent to your email',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Password Reset Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> confirmPasswordReset(String token, String newPassword) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response =
          await _dioClient.dio.post('/auth/reset-password-confirm/', data: {
        'token': token,
        'new_password': newPassword,
      });

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Password reset successful. Please login with your new password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAllNamed('/login');
      }
    } catch (e) {
      Get.snackbar(
        'Password Reset Confirmation Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response =
          await _dioClient.dio.post('/auth/forgot-password/', data: {
        'email': email,
      });

      if (response.statusCode == 200) {
        // No need to handle response data since we just show success message
      }
    } catch (e) {
      Get.snackbar(
        'Password Reset Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> toggle2FA() async {
    try {
      _isLoading.value = true;
      final response = await _dioClient.dio.post('/auth/toggle-2fa/');

      if (response.statusCode == 200) {
        _is2FAEnabled.value = response.data['is_2fa_enabled'];

        Get.snackbar(
          'Success',
          _is2FAEnabled.value ? '2FA enabled' : '2FA disabled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        '2FA Toggle Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> verify2FA(String code, String email) async {
    try {
      _isLoading.value = true;
      final response = await _dioClient.dio.post('/auth/verify-2fa/', data: {
        'code': code,
        'email': email,
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.setAccessToken(tokens['access']);
        await StorageUtils.setRefreshToken(tokens['refresh']);
        await checkAuthStatus();
      }
    } catch (e) {
      Get.snackbar(
        '2FA Verification Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> getSecurityStatus() async {
    try {
      final response = await _dioClient.dio.get('/auth/security-status/');

      if (response.statusCode == 200) {
        _securityStatus.value = response.data;
        _is2FAEnabled.value = response.data['is_2fa_enabled'] ?? false;
        _isEmailVerified.value = response.data['is_email_verified'] ?? false;
      }
    } catch (e) {
      LoggerUtils.error('Error fetching security status', e);
    }
  }

  Future<void> setUserData(Map<String, dynamic> userData) async {
    LoggerUtils.info('Setting user data');
    try {
      _user.value = userData;
      await StorageUtils.setUserData(userData);
      _isAuthenticated.value = true;
      LoggerUtils.info('User data set successfully');
    } catch (e) {
      LoggerUtils.error('Error setting user data: $e');
      throw Exception('Failed to set user data');
    }
  }

  Future<void> getUserProfile() async {
    LoggerUtils.info('Fetching user profile');
    try {
      final response = await _dioClient.dio.get('/auth/profile/');
      await setUserData(response.data);
      LoggerUtils.info('User profile fetched successfully');
    } catch (e) {
      LoggerUtils.error('Error fetching user profile: $e');
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      _isLoading.value = true;
      final response = await _dioClient.dio.put('/auth/profile/', data: data);

      if (response.statusCode == 200) {
        await getUserProfile();
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Profile Update Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await StorageUtils.clearTokens();
      _isAuthenticated.value = false;
      _user.value = null;
      _isEmailVerified.value = false;
      _securityStatus.value = null;
      _is2FAEnabled.value = false;
      Get.offAllNamed('/login');
    } catch (e, stackTrace) {
      LoggerUtils.error('Error during logout', e, stackTrace);
    }
  }

  Future<void> updateRegistrationState({
    required String email,
    required bool requiresVerification,
  }) async {
    try {
      LoggerUtils.info('Updating registration state for: $email');

      // Store temporary email for login
      await StorageUtils.setTemporaryEmail(email);

      // Update verification status
      _isEmailVerified.value = !requiresVerification;

      // Store verification requirement
      await StorageUtils.setVerificationRequired(requiresVerification);

      // Update user data with registration info
      _user.value = {
        'email': email,
        'email_verified': !requiresVerification,
        'registration_completed': true,
      };

      LoggerUtils.info('Registration state updated successfully');
    } catch (e) {
      LoggerUtils.error('Error updating registration state', e);
      rethrow;
    }
  }
}
