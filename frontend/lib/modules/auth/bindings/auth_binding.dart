import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/signup_controller.dart';
import '../../../core/services/api/api_client.dart';
import '../../../core/services/storage/secure_storage.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Core dependencies
    Get.put<ApiClient>(Get.find<ApiClient>());
    Get.put<SecureStorage>(Get.find<SecureStorage>());

    // Auth controllers
    Get.lazyPut<AuthController>(
      () => AuthController(
        apiClient: Get.find<ApiClient>(),
      ),
    );

    // Feature controllers
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<SignupController>(() => SignupController());
  }
}
