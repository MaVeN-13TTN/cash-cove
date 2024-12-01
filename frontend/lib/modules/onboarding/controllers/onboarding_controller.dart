import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/constants/storage_constants.dart';
import '../../../app/config/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final SharedPreferences _prefs;
  final RxInt currentPage = 0.obs;

  OnboardingController(this._prefs);

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> skipOnboarding() async {
    await _prefs.setBool(StorageConstants.hasSeenOnboarding, true);
    Get.offNamed(AppRoutes.login);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(StorageConstants.hasSeenOnboarding, true);
    Get.offNamed(AppRoutes.login);
  }
}
