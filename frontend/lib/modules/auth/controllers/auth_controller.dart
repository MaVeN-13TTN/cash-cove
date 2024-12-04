import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/utils/storage_utils.dart';

class AuthController extends GetxController {
  final DioClient _dioClient;

  AuthController({required DioClient dioClient}) : _dioClient = dioClient;

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

      final response = await _dioClient.dio.post('/auth/login/', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.saveAccessToken(tokens['access']);
        await StorageUtils.saveRefreshToken(tokens['refresh']);
        await checkAuthStatus();
      }
    } catch (e) {
      Get.snackbar(
        'Login Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signup(String name, String email, String password, String confirmPassword, String username, bool termsAccepted) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _dioClient.dio.post('/auth/register/', data: {
        'name': name,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'username': username,
        'terms_accepted': termsAccepted,
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.saveAccessToken(tokens['access']);
        await StorageUtils.saveRefreshToken(tokens['refresh']);
        await checkAuthStatus();
      }
    } catch (e) {
      Get.snackbar(
        'Signup Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final response = await _dioClient.dio.post('/auth/google/', data: {
        // Add necessary Google sign-in data
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.saveAccessToken(tokens['access']);
        await StorageUtils.saveRefreshToken(tokens['refresh']);
        await checkAuthStatus();
      }
    } catch (e) {
      Get.snackbar(
        'Google Sign-In Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      final response = await _dioClient.dio.post('/auth/facebook/', data: {
        // Add necessary Facebook sign-in data
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.saveAccessToken(tokens['access']);
        await StorageUtils.saveRefreshToken(tokens['refresh']);
        await checkAuthStatus();
      }
    } catch (e) {
      Get.snackbar(
        'Facebook Sign-In Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      final response = await _dioClient.dio.post('/auth/apple/', data: {
        // Add necessary Apple sign-in data
      });

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.saveAccessToken(tokens['access']);
        await StorageUtils.saveRefreshToken(tokens['refresh']);
        await checkAuthStatus();
      }
    } catch (e) {
      Get.snackbar(
        'Apple Sign-In Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
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

      final response = await _dioClient.dio.post('/auth/reset-password/', data: {
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

      final response = await _dioClient.dio.post('/auth/reset-password-confirm/', data: {
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

      final response = await _dioClient.dio.post('/auth/forgot-password/', data: {
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
        await StorageUtils.saveAccessToken(tokens['access']);
        await StorageUtils.saveRefreshToken(tokens['refresh']);
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

  Future<void> getUserProfile() async {
    try {
      final response = await _dioClient.dio.get('/auth/profile/');

      if (response.statusCode == 200) {
        _user.value = response.data;
        _isAuthenticated.value = true;
        _isEmailVerified.value = response.data['is_email_verified'] ?? false;
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Error fetching user profile', e, stackTrace);
      await logout();
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

  void _handleAuthError(dynamic error, String context) {
    LoggerUtils.error(context, error);
    _error.value = 'An error occurred. Please try again.';
  }

  Future<String> _getGoogleAuthToken() async {
    // TODO: Implement Google Sign-In
    throw UnimplementedError('Google Sign-In not yet implemented');
  }

  Future<String> _getFacebookAuthToken() async {
    // TODO: Implement Facebook Sign-In
    throw UnimplementedError('Facebook Sign-In not yet implemented');
  }

  Future<String> _getAppleAuthToken() async {
    // TODO: Implement Apple Sign-In
    throw UnimplementedError('Apple Sign-In not yet implemented');
  }
}
