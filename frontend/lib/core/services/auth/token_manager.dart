import 'dart:async';
import 'package:hive/hive.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../storage/secure_storage.dart';
import '../../utils/logger_utils.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TokenManager {
  static const String _blacklistBoxName = 'token_blacklist';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const Duration _refreshThreshold = Duration(minutes: 5);

  final SecureStorage _storage;
  final Box<int> _blacklistBox;
  final _tokenStreamController = StreamController<String?>.broadcast();
  Timer? _refreshTimer;
  DateTime? _lastRefreshAttempt;
  bool _isRefreshing = false;

  Stream<String?> get tokenStream => _tokenStreamController.stream;
  bool get isRefreshing => _isRefreshing;
  DateTime? get lastRefreshAttempt => _lastRefreshAttempt;

  TokenManager({
    required SecureStorage storage,
    required Box<int> blacklistBox,
  })  : _storage = storage,
        _blacklistBox = blacklistBox;

  static Future<TokenManager> initialize(SecureStorage storage) async {
    try {
      if (!Hive.isBoxOpen(_blacklistBoxName)) {
        throw HiveError('Token blacklist box must be initialized before TokenManager');
      }

      final box = Hive.box<int>(_blacklistBoxName);
      return TokenManager(storage: storage, blacklistBox: box);
    } catch (e) {
      throw HiveError('Failed to initialize token blacklist: $e');
    }
  }

  int _hashToken(String token) {
    // Fix potential hash collisions by using string hash directly
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.bytes.sublist(0, 8).fold<int>(0, (a, b) => (a << 8) | b);
  }

  Future<void> cleanupBlacklist() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<int> expiredHashes = [];

    _blacklistBox.toMap().forEach((hash, expiry) {
      if (expiry < now) expiredHashes.add(hash);
    });

    await Future.wait(expiredHashes.map((hash) => _blacklistBox.delete(hash)));
  }

  Future<void> dispose() async {
    await cleanupBlacklist();
    _refreshTimer?.cancel();
    await _tokenStreamController.close();
    if (_blacklistBox.isOpen) {
      await _blacklistBox.compact(); // Optimize storage
      await _blacklistBox.close();
    }
  }

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    bool scheduleRefresh = true,
  }) async {
    // Store tokens
    await Future.wait([
      _storage.write(_tokenKey, accessToken),
      _storage.write(_refreshTokenKey, refreshToken),
    ]);

    // Notify listeners
    _tokenStreamController.add(accessToken);

    // Schedule refresh if needed
    if (scheduleRefresh) {
      _scheduleTokenRefresh(accessToken);
    }
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(_tokenKey);
    if (token == null) return null;

    // Check if token is blacklisted
    if (await isTokenBlacklisted(token)) {
      await clearTokens();
      return null;
    }

    // Check if token is expired
    try {
      final decodedToken = JwtDecoder.decode(token);
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);

      if (DateTime.now().isAfter(expiry)) {
        await clearTokens();
        return null;
      }
    } catch (e) {
      await clearTokens();
      return null;
    }

    return token;
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(_tokenKey),
      _storage.delete(_refreshTokenKey),
    ]);
    _tokenStreamController.add(null);
    _refreshTimer?.cancel();
  }

  Future<void> blacklistToken(String token) async {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);

      final hash = _hashToken(token);
      await _blacklistBox.put(hash, expiry.millisecondsSinceEpoch);
    } catch (e) {
      LoggerUtils.error('Failed to blacklist token', e);
    }
  }

  Future<bool> isTokenBlacklisted(String token) async {
    final hash = _hashToken(token);
    final expiry = _blacklistBox.get(hash);

    if (expiry == null) return false;

    // Remove expired entries
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      await _blacklistBox.delete(hash);
      return false;
    }

    return true;
  }

  void _scheduleTokenRefresh(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final refreshAt = expiry.subtract(_refreshThreshold);
      final now = DateTime.now();

      if (refreshAt.isAfter(now)) {
        _refreshTimer = Timer(refreshAt.difference(now), () async {
          _isRefreshing = true;
          _lastRefreshAttempt = DateTime.now();
          _tokenStreamController.add(null); // Trigger refresh
          _isRefreshing = false;
        });
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to schedule token refresh', e, stackTrace);
    }
  }

  Future<void> refreshTokens() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      // Refresh logic here
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) throw Exception('No refresh token available');

      // Call API to refresh tokens
      // Assume refreshTokensAPI returns a Map with new tokens
      final newTokens = await refreshTokensAPI(refreshToken);
      await setTokens(
        accessToken: newTokens['accessToken']!,
        refreshToken: newTokens['refreshToken']!,
      );
    } catch (e) {
      // Handle refresh error
      await clearTokens();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Map<String, String>> refreshTokensAPI(String refreshToken) async {
    // Mock API call
    await Future.delayed(const Duration(seconds: 2));
    return {
      'accessToken': 'new_access_token',
      'refreshToken': 'new_refresh_token',
    };
  }
}
