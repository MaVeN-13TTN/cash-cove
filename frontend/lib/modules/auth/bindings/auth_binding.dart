import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/signup_controller.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/storage/secure_storage.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Core dependencies
    Get.put<DioClient>(Get.find<DioClient>());
    Get.put<SecureStorage>(Get.find<SecureStorage>());

    // Auth controllers
    Get.lazyPut<AuthController>(
      () => AuthController(
        dioClient: Get.find<DioClient>(),
      ),
    );

    // Feature controllers
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<SignupController>(() => SignupController());
  }
}
