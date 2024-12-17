import 'package:get/get.dart';
import 'package:budget_tracker/core/network/dio_client.dart';
import 'package:budget_tracker/core/services/storage/secure_storage.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/repositories/budget_repository.dart';
import '../controllers/budget_controller.dart';

class BudgetBinding extends Bindings {
  @override
  void dependencies() {
    final dioClient = Get.find<DioClient>();
    final secureStorage = Get.find<SecureStorage>();

    // Register ApiProvider with DioClient and SecureStorage
    Get.lazyPut<ApiProvider>(() => ApiProvider(
          dio: dioClient.dio,
          storage: secureStorage,
        ));

    // Register BudgetProvider with ApiProvider
    Get.lazyPut<BudgetProvider>(() => BudgetProvider(Get.find<ApiProvider>()));
    
    // Register BudgetRepository with BudgetProvider
    Get.lazyPut<BudgetRepository>(() => BudgetRepository(Get.find<BudgetProvider>()));
    
    // Register BudgetController with BudgetRepository
    Get.lazyPut<BudgetController>(() => BudgetController(
      repository: Get.find<BudgetRepository>(),
    ));
  }
}