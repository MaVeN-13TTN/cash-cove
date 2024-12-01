import 'package:get/get.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/repositories/budget_repository.dart';
import '../controllers/budget_controller.dart';

class BudgetBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure ApiProvider is registered first
    Get.lazyPut<ApiProvider>(() => ApiProvider(baseUrl: 'https://your-api-base-url'));

    // Register BudgetProvider with the ApiProvider
    Get.lazyPut<BudgetProvider>(() => BudgetProvider(Get.find<ApiProvider>()));
    
    // Register BudgetRepository with BudgetProvider
    Get.lazyPut<BudgetRepository>(() => BudgetRepository(Get.find<BudgetProvider>()));
    
    // Register BudgetController with BudgetRepository
    Get.lazyPut<BudgetController>(() => BudgetController(
      repository: Get.find<BudgetRepository>(),
    ));
  }
}