import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/constants/storage_constants.dart';
import '../../../app/config/routes/app_routes.dart';
import '../../../core/utils/logger_utils.dart';

class SplashController extends GetxController {
  final Future<SharedPreferences> _prefsInstance = SharedPreferences.getInstance();

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash screen duration

    try {
      final SharedPreferences prefs = await _prefsInstance;

      // Check if user is logged in
      final String? token = prefs.getString(StorageConstants.accessToken);
      
      if (token == null) {
        // User is not logged in
        final bool hasSeenOnboarding = prefs.getBool(StorageConstants.hasSeenOnboarding) ?? false;
        
        if (!hasSeenOnboarding) {
          // First time user - show onboarding with option to skip
          Get.offNamed(AppRoutes.onboarding);
        } else {
          // User has seen onboarding - go to login
          Get.offNamed(AppRoutes.login);
        }
      } else {
        // User is logged in - go to home
        Get.offNamed(AppRoutes.home);
      }
    } catch (e) {
      // Handle preference initialization error
      Get.offNamed(AppRoutes.login); // Default to login on error
      LoggerUtils.error('Error initializing preferences', e);
    }
  }
}
