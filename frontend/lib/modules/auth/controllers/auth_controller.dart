import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api/api_client.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/utils/storage_utils.dart';

class AuthController extends GetxController {
  final ApiClient _apiClient;

  AuthController({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

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

  Future<void> checkAuthStatus() async {
    try {
      final token = await StorageUtils.getToken();
      if (token != null) {
        await getUserProfile();
        await getSecurityStatus();
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Error checking auth status', e, stackTrace);
      _isAuthenticated.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['requires_2fa'] == true) {
        Get.toNamed('/2fa-verification', arguments: {'email': email});
        return;
      }

      await _handleAuthResponse(response.data);
    } catch (e, stackTrace) {
      LoggerUtils.error('Error during login', e, stackTrace);
      _error.value = 'An error occurred during login';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiClient.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      await _handleAuthResponse(response.data);
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, 'signup');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiClient.post('/auth/google', data: {
        'token': await _getGoogleAuthToken(),
      });

      await _handleAuthResponse(response.data);
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, 'Google sign-in');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiClient.post('/auth/facebook', data: {
        'token': await _getFacebookAuthToken(),
      });

      await _handleAuthResponse(response.data);
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, 'Facebook sign-in');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signInWithApple() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiClient.post('/auth/apple', data: {
        'token': await _getAppleAuthToken(),
      });

      await _handleAuthResponse(response.data);
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, 'Apple sign-in');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      await _apiClient.post('/auth/verify-email', data: {
        'token': token,
      });

      _isEmailVerified.value = true;
      Get.snackbar(
        'Success',
        'Email verified successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, 'Email verification error');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      await _apiClient.post('/auth/send-verification-email');
      Get.snackbar(
        'Success',
        'Verification email sent',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      LoggerUtils.error('Error sending verification email', e, stackTrace);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      await _apiClient.post('/auth/reset-password', data: {
        'email': email,
      });

      Get.snackbar(
        'Success',
        'Password reset instructions sent to your email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, 'Password reset error');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> confirmPasswordReset(String token, String newPassword) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      await _apiClient.post('/auth/reset-password-confirm', data: {
        'token': token,
        'new_password': newPassword,
      });

      Get.snackbar(
        'Success',
        'Password reset successful. Please login with your new password.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed('/login');
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, 'Password reset confirmation error');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      await _apiClient.post('/auth/forgot-password', data: {
        'email': email,
      });
      
      // No need to handle response data since we just show success message
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, 'Password reset');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> toggle2FA() async {
    try {
      _isLoading.value = true;
      final response = await _apiClient.post('/auth/toggle-2fa');
      _is2FAEnabled.value = response.data['is_2fa_enabled'];
      
      Get.snackbar(
        'Success',
        _is2FAEnabled.value ? '2FA enabled' : '2FA disabled',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, '2FA toggle error');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> verify2FA(String code, String email) async {
    try {
      _isLoading.value = true;
      final response = await _apiClient.post('/auth/verify-2fa', data: {
        'code': code,
        'email': email,
      });

      await _handleAuthResponse(response.data);
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, '2FA verification error');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> getSecurityStatus() async {
    try {
      final response = await _apiClient.get('/auth/security-status');
      _securityStatus.value = response.data;
      _is2FAEnabled.value = response.data['is_2fa_enabled'] ?? false;
      _isEmailVerified.value = response.data['is_email_verified'] ?? false;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error fetching security status', e, stackTrace);
    }
  }

  Future<void> getUserProfile() async {
    try {
      final response = await _apiClient.get('/auth/profile');
      _user.value = response.data;
      _isAuthenticated.value = true;
      _isEmailVerified.value = response.data['is_email_verified'] ?? false;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error fetching user profile', e, stackTrace);
      await logout();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      _isLoading.value = true;
      await _apiClient.put('/auth/profile', data: data);
      await getUserProfile();
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace, 'Profile update error');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await StorageUtils.deleteToken();
      _isAuthenticated.value = false;
      _user.value = null;
      _isEmailVerified.value = false;
      _securityStatus.value = null;
      _is2FAEnabled.value = false;
      Get.offAllNamed('/login');
    } catch (e, stackTrace) {
      LoggerUtils.error('Error during logout', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    try {
      if (data['token'] != null) {
        await StorageUtils.saveToken(data['token']);
        _isAuthenticated.value = true;
        await getUserProfile();
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Error handling auth response', e, stackTrace);
      rethrow;
    }
  }

  void _handleAuthError(dynamic error, StackTrace stackTrace, String context) {
    LoggerUtils.error(context, error, stackTrace);
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