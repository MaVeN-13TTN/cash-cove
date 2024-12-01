import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/services/settings/settings_service.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize settings service if not already initialized
    if (!Get.isRegistered<SettingsService>()) {
      Get.put(SettingsService(), permanent: true);
    }
    
    // Initialize settings controller
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}