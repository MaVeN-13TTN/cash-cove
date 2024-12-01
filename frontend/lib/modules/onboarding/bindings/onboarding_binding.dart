import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SharedPreferences>(() => Get.find<SharedPreferences>());
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(Get.find<SharedPreferences>()),
    );
  }
}
