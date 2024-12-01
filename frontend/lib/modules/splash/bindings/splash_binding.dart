import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure SharedPreferences is available
    Get.putAsync<SharedPreferences>(() async => await SharedPreferences.getInstance());
    
    // Create SplashController
    Get.lazyPut<SplashController>(() => SplashController());
  }
}
