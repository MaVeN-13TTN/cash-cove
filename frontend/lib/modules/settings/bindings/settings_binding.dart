import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/services/settings/settings_service.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure SettingsService is registered
    if (!Get.isRegistered<SettingsService>()) {
      final settingsService = SettingsService();
      settingsService.onInit(); // Synchronous initialization
      Get.put<SettingsService>(settingsService, permanent: true);
    }
    
    // Initialize settings controller
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}