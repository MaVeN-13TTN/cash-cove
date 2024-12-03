import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/constants/storage_constants.dart';
import '../../../app/config/routes/app_routes.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/services/storage/secure_storage.dart';
import '../../../modules/auth/controllers/auth_controller.dart';

class SplashController extends GetxController {
  final RxBool isInitializing = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    LoggerUtils.debug('SplashController initialized');

    // Ensure initialization happens after widget rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      LoggerUtils.debug('Starting app initialization');

      // Get initialized dependencies
      final SharedPreferences prefs = Get.find<SharedPreferences>();
      final secureStorage = Get.find<SecureStorage>();

      LoggerUtils.debug('Core dependencies found');

      // Check onboarding status
      final bool hasSeenOnboarding =
          prefs.getBool(StorageConstants.hasSeenOnboarding) ?? false;
      LoggerUtils.debug(
          'Onboarding status: ${hasSeenOnboarding ? "Completed" : "Not seen"}');

      // First-time user flow
      if (!hasSeenOnboarding) {
        await Future.delayed(const Duration(milliseconds: 1500));
        LoggerUtils.debug('Navigating to onboarding');
        Get.offAllNamed(AppRoutes.onboarding);
        return;
      }

      // Check authentication status
      final String? token = await secureStorage.getToken();
      LoggerUtils.debug(
          'Access token status: ${token != null ? "Found" : "Not found"}');

      // If token exists, verify authentication
      if (token != null) {
        try {
          final authController = Get.find<AuthController>();
          final bool isAuthenticated = await authController.checkAuthStatus();

          await Future.delayed(const Duration(milliseconds: 1500));

          if (isAuthenticated) {
            LoggerUtils.debug('Token verified - routing to home');
            Get.offAllNamed(AppRoutes.home);
            return;
          }
        } catch (e) {
          LoggerUtils.error('Error verifying token', e);
        }
      }

      // No token, invalid token, or authentication failed
      // Route to login for returning users
      await Future.delayed(const Duration(milliseconds: 1500));
      LoggerUtils.debug('Routing to login');
      Get.offAllNamed(AppRoutes.login);
    } catch (e, stackTrace) {
      LoggerUtils.error('Critical error during initialization', e, stackTrace);
      errorMessage.value = 'Failed to initialize app. Please restart.';
      isInitializing.value = false;
    } finally {
      isInitializing.value = false;
    }
  }

  @override
  void onClose() {
    LoggerUtils.debug('SplashController closing');
    super.onClose();
  }
}
