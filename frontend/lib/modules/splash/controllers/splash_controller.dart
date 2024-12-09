import 'package:get/get.dart';
import '../../../app/config/routes/app_routes.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../../../core/utils/storage_utils.dart';

class SplashController extends GetxController {
  final RxBool isInitializing = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    LoggerUtils.debug('SplashController initialized');
    initializeApp();
  }

  Future<void> initializeApp() async {
    try {
      isInitializing.value = true;

      // Simulate app initialization
      await Future.delayed(const Duration(milliseconds: 1500));

      LoggerUtils.debug('Core dependencies found');

      // Check authentication status
      final String? token = await StorageUtils.getAccessToken();
      LoggerUtils.debug('Token status: ${token != null ? 'Valid' : 'Not found'}');

      if (token == null) {
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      // Validate token and user authentication
      final authController = Get.find<AuthController>();
      final isAuthenticated = await authController.checkAuthStatus();

      if (isAuthenticated) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      LoggerUtils.error('Initialization error: $e');
      Get.offAllNamed(AppRoutes.login);
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
