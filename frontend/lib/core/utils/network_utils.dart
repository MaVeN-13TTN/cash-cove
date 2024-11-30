import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static final _connectivity = Connectivity();
  static StreamSubscription<ConnectivityResult>? _subscription;
  static bool _isConnected = true;

  static bool get isConnected => _isConnected;

  static Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = result != ConnectivityResult.none;
    return _isConnected;
  }

  static void startMonitoring(void Function(bool) onConnectivityChanged) {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      _isConnected = isConnected;
      onConnectivityChanged(isConnected);
    });
  }

  static void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  static Future<void> waitForConnection() async {
    if (_isConnected) return;

    final completer = Completer<void>();
    StreamSubscription<ConnectivityResult>? subscription;

    subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        subscription?.cancel();
        completer.complete();
      }
    });

    return completer.future;
  }

  static Future<bool> isHostReachable(String host) async {
    try {
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
