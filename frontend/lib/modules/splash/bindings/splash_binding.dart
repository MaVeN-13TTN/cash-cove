import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../app/config/routes/app_routes.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Only create SplashController if we're on the splash route
    if (Get.currentRoute == AppRoutes.splash) {
      Get.put<SplashController>(SplashController());
    }
  }
}
