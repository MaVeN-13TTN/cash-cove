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
    final box = await Hive.openBox<int>(_blacklistBoxName);
    return TokenManager(storage: storage, blacklistBox: box);
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
      final expiry = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      
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
      final expiry = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      
      // Store token hash in blacklist with expiry
      await _blacklistBox.put(
        _hashToken(token),
        expiry.millisecondsSinceEpoch,
      );

      // Clear if it's the current token
      final currentToken = await getAccessToken();
      if (currentToken == token) {
        await clearTokens();
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to blacklist token', e, stackTrace);
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

  Future<void> cleanupBlacklist() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = _blacklistBox.keys.where(
      (key) => (_blacklistBox.get(key) ?? 0) < now,
    );
    
    await Future.wait(
      expiredKeys.map((key) => _blacklistBox.delete(key)),
    );
  }

  Future<Map<String, dynamic>> getTokenInfo(String token) async {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final expiry = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final issuedAt = DateTime.fromMillisecondsSinceEpoch(decodedToken['iat'] * 1000);
      
      return {
        'isExpired': DateTime.now().isAfter(expiry),
        'isBlacklisted': await isTokenBlacklisted(token),
        'expiresAt': expiry.toIso8601String(),
        'issuedAt': issuedAt.toIso8601String(),
        'claims': decodedToken,
      };
    } catch (e) {
      return {
        'error': 'Invalid token format',
        'isExpired': true,
        'isBlacklisted': false,
      };
    }
  }

  void _scheduleTokenRefresh(String token) {
    _refreshTimer?.cancel();

    try {
      final decodedToken = JwtDecoder.decode(token);
      final expiry = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
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

  int _hashToken(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString().hashCode;
  }

  Future<void> dispose() async {
    await _tokenStreamController.close();
    _refreshTimer?.cancel();
    await _blacklistBox.close();
  }
}
