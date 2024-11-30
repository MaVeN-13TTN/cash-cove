import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/utils/storage_utils.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Singleton instance
  static GoogleAuthService? _instance;
  static GoogleAuthService get instance {
    _instance ??= GoogleAuthService._();
    return _instance!;
  }

  GoogleAuthService._();

  // Track authentication state
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Current user account
  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Initialize the Google Sign In service
  Future<void> initialize() async {
    try {
      // Listen for user account changes
      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        _currentUser = account;
        _isAuthenticated = account != null;
        
        if (account != null) {
          LoggerUtils.info('Google Sign In: User changed - ${account.email}');
        }
      });

      // Try to sign in silently with cached credentials
      _currentUser = await _googleSignIn.signInSilently();
      _isAuthenticated = _currentUser != null;
    } catch (e) {
      LoggerUtils.error('Google Sign In initialization failed', e);
      _isAuthenticated = false;
      _currentUser = null;
    }
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        // Get authentication data
        final auth = await account.authentication;
        
        // Store tokens securely
        await StorageUtils.saveSecure('google_access_token', auth.accessToken ?? '');
        if (auth.idToken != null) {
          await StorageUtils.saveSecure('google_id_token', auth.idToken!);
        }
        
        LoggerUtils.info('Google Sign In successful: ${account.email}');
      }
      return account;
    } catch (e) {
      LoggerUtils.error('Google Sign In failed', e);
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await StorageUtils.deleteSecure('google_access_token');
      await StorageUtils.deleteSecure('google_id_token');
      _isAuthenticated = false;
      _currentUser = null;
      LoggerUtils.info('Google Sign Out successful');
    } catch (e) {
      LoggerUtils.error('Google Sign Out failed', e);
    }
  }

  /// Disconnect the Google account
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      await signOut();
      LoggerUtils.info('Google account disconnected');
    } catch (e) {
      LoggerUtils.error('Google disconnect failed', e);
    }
  }

  /// Get user info
  Future<Map<String, dynamic>> getUserInfo() async {
    if (_currentUser == null) {
      throw Exception('No user signed in');
    }

    return {
      'id': _currentUser!.id,
      'email': _currentUser!.email,
      'displayName': _currentUser!.displayName,
      'photoUrl': _currentUser!.photoUrl,
    };
  }

  /// Get authentication tokens
  Future<Map<String, String?>> getTokens() async {
    if (_currentUser == null) {
      throw Exception('No user signed in');
    }

    final auth = await _currentUser!.authentication;
    return {
      'accessToken': auth.accessToken,
      'idToken': auth.idToken,
    };
  }

  /// Check if user has granted requested scopes
  Future<bool> hasScope(String scope) async {
    try {
      return await _googleSignIn.requestScopes([scope]);
    } catch (e) {
      LoggerUtils.error('Scope check failed', e);
      return false;
    }
  }
}