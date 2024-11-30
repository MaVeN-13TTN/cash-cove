import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import '../../utils/logger_utils.dart';
import 'package:get/get.dart';

class BiometricAuthService extends GetxService {
  final LocalAuthentication _auth;
  bool? _isBiometricsAvailable;
  final _isAuthenticating = false.obs;
  final _lastAuthTime = Rxn<DateTime>();
  final _availableBiometrics = <BiometricType>[].obs;

  BiometricAuthService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  static Future<BiometricAuthService> initialize() async {
    final service = BiometricAuthService();
    await service.checkBiometrics();
    Get.put(service);
    return service;
  }

  bool get isAuthenticating => _isAuthenticating.value;
  DateTime? get lastAuthTime => _lastAuthTime.value;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  Future<bool> get isBiometricsAvailable async {
    if (_isBiometricsAvailable != null) return _isBiometricsAvailable!;
    return checkBiometrics();
  }

  Future<bool> checkBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = await _auth.isDeviceSupported();
      _isBiometricsAvailable = canAuthenticateWithBiometrics && canAuthenticate;
      
      if (_isBiometricsAvailable!) {
        _availableBiometrics.value = await _auth.getAvailableBiometrics();
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to check biometrics availability', e, stackTrace);
      _isBiometricsAvailable = false;
      _availableBiometrics.clear();
    }
    
    return _isBiometricsAvailable!;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      _availableBiometrics.value = biometrics;
      return biometrics;
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to get available biometrics', e, stackTrace);
      return [];
    }
  }

  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = true,
    Duration? authTimeout,
  }) async {
    if (!await isBiometricsAvailable) return false;
    if (_isAuthenticating.value) return false;

    try {
      _isAuthenticating.value = true;

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
          useErrorDialogs: useErrorDialogs,
        ),
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Authentication Required',
            cancelButton: 'Cancel',
            biometricHint: 'Verify your identity',
            biometricNotRecognized: 'Biometric not recognized. Please try again.',
            biometricSuccess: 'Biometric authentication successful',
            deviceCredentialsSetupDescription: 'Please set up biometric authentication',
          ),
        ],
      );

      if (authenticated) {
        _lastAuthTime.value = DateTime.now();
      }

      return authenticated;
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to authenticate with biometrics', e, stackTrace);
      return false;
    } finally {
      _isAuthenticating.value = false;
    }
  }

  Future<bool> authenticateWithTimeout(Duration timeout) async {
    return authenticate(authTimeout: timeout);
  }

  Future<void> stopAuthentication() async {
    if (_isAuthenticating.value) {
      await _auth.stopAuthentication();
      _isAuthenticating.value = false;
    }
  }

  String getBiometricStatus() {
    if (_isBiometricsAvailable == null) return 'Not checked';
    if (!_isBiometricsAvailable!) return 'Not available';
    if (_availableBiometrics.isEmpty) return 'No biometrics configured';
    return _availableBiometrics.join(', ');
  }

  @override
  void onClose() {
    _isAuthenticating.close();
    _lastAuthTime.close();
    _availableBiometrics.close();
    super.onClose();
  }
}
