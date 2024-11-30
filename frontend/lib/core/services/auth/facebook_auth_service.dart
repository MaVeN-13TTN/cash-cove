import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/utils/storage_utils.dart';

class FacebookAuthService {
  static final FacebookAuth _facebookAuth = FacebookAuth.instance;

  // Singleton instance
  static FacebookAuthService? _instance;
  static FacebookAuthService get instance {
    _instance ??= FacebookAuthService._();
    return _instance!;
  }

  FacebookAuthService._();

  // Track authentication state
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Current access token
  AccessToken? _currentAccessToken;
  AccessToken? get currentAccessToken => _currentAccessToken;

  // Current user data
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  /// Initialize the Facebook Auth service
  Future<void> initialize() async {
    try {
      // Check if a user is already logged in
      final accessToken = await _facebookAuth.accessToken;
      _currentAccessToken = accessToken;
      _isAuthenticated = accessToken != null;

      if (_isAuthenticated) {
        // Get user data if authenticated
        await _getUserData();
        LoggerUtils.info('Facebook Auth: User already logged in');
      }
    } catch (e) {
      LoggerUtils.error('Facebook Auth initialization failed', e);
      _isAuthenticated = false;
      _currentAccessToken = null;
      _userData = null;
    }
  }

  /// Sign in with Facebook
  Future<LoginResult> signIn() async {
    try {
      // Request login with permissions
      final result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      switch (result.status) {
        case LoginStatus.success:
          _currentAccessToken = result.accessToken;
          _isAuthenticated = true;
          
          // Store token securely
          if (_currentAccessToken != null) {
            await StorageUtils.saveSecure(
              'facebook_access_token',
              _currentAccessToken!.token,
            );
          }
          
          // Get user data
          await _getUserData();
          LoggerUtils.info('Facebook Sign In successful');
          break;

        case LoginStatus.cancelled:
          LoggerUtils.info('Facebook Sign In cancelled by user');
          _isAuthenticated = false;
          break;

        case LoginStatus.failed:
          LoggerUtils.error('Facebook Sign In failed', result.message);
          _isAuthenticated = false;
          break;

        case LoginStatus.operationInProgress:
          LoggerUtils.info('Facebook Sign In operation in progress');
          break;
      }

      return result;
    } catch (e) {
      LoggerUtils.error('Facebook Sign In failed', e);
      _isAuthenticated = false;
      rethrow;
    }
  }

  /// Sign out from Facebook
  Future<void> signOut() async {
    try {
      await _facebookAuth.logOut();
      await StorageUtils.deleteSecure('facebook_access_token');
      _isAuthenticated = false;
      _currentAccessToken = null;
      _userData = null;
      LoggerUtils.info('Facebook Sign Out successful');
    } catch (e) {
      LoggerUtils.error('Facebook Sign Out failed', e);
      rethrow;
    }
  }

  /// Get current access token
  Future<AccessToken?> getCurrentAccessToken() async {
    try {
      final token = await _facebookAuth.accessToken;
      _currentAccessToken = token;
      _isAuthenticated = token != null;
      return token;
    } catch (e) {
      LoggerUtils.error('Failed to get Facebook access token', e);
      return null;
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      _userData = await _facebookAuth.getUserData();
      return _userData;
    } catch (e) {
      LoggerUtils.error('Failed to get Facebook user data', e);
      return null;
    }
  }

  /// Check if a user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await _facebookAuth.accessToken;
      return accessToken != null && !accessToken.isExpired;
    } catch (e) {
      LoggerUtils.error('Failed to check Facebook login status', e);
      return false;
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    if (!_isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    try {
      final userData = await _getUserData();
      if (userData == null) {
        throw Exception('Failed to get user profile data');
      }
      return userData;
    } catch (e) {
      LoggerUtils.error('Failed to get Facebook user profile', e);
      rethrow;
    }
  }

  /// Request additional permissions
  Future<LoginResult> requestPermissions(List<String> permissions) async {
    try {
      final result = await _facebookAuth.login(permissions: permissions);
      return result;
    } catch (e) {
      LoggerUtils.error('Failed to request Facebook permissions', e);
      rethrow;
    }
  }

  /// Check if user has granted specific permissions
  Future<bool> hasPermissions(List<String> permissions) async {
    try {
      final accessToken = await _facebookAuth.accessToken;
      if (accessToken == null) return false;
      
      return permissions.every(
        (permission) => accessToken.grantedPermissions?.contains(permission) ?? false,
      );
    } catch (e) {
      LoggerUtils.error('Failed to check Facebook permissions', e);
      return false;
    }
  }
}