import 'package:get/get.dart';
import '../../../data/models/shared_expense/shared_expense_model.dart';
import '../../../data/models/shared_expense/shared_expense_enums.dart';
import '../../../data/repositories/shared_expense_repository.dart';
import '../../../data/providers/shared_expense_provider.dart';
import '../../utils/logger_utils.dart';

class SharedExpensesService extends GetxService {
  static SharedExpensesService get to => Get.find();

  final SharedExpenseRepository _repository = Get.find();
  final SharedExpenseProvider _provider = Get.find();

  // Reactive list of shared expenses
  final RxList<SharedExpenseModel> sharedExpenses = <SharedExpenseModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Fetch shared expenses
  Future<void> fetchSharedExpenses({
    String? groupId,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final expenses = await _repository.getSharedExpenses(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        forceRefresh: forceRefresh,
      );

      sharedExpenses.value = expenses;
    } catch (e) {
      LoggerUtils.error('Error fetching shared expenses', e);
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Create a new shared expense
  Future<SharedExpenseModel?> createSharedExpense(
      Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      error.value = '';

      final expense = await _provider.createSharedExpense(data);
      sharedExpenses.add(expense);
      return expense;
    } catch (e) {
      LoggerUtils.error('Error creating shared expense', e);
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Update an existing shared expense
  Future<SharedExpenseModel?> updateSharedExpense(
      String id, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      error.value = '';

      final updatedExpense = await _provider.updateSharedExpense(id, data);

      // Update the expense in the local list
      final index = sharedExpenses.indexWhere((e) => e.id == id);
      if (index != -1) {
        sharedExpenses[index] = updatedExpense;
      }

      return updatedExpense;
    } catch (e) {
      LoggerUtils.error('Error updating shared expense', e);
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete a shared expense
  Future<void> deleteSharedExpense(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      await _provider.deleteSharedExpense(id);

      // Remove from local list
      sharedExpenses.removeWhere((e) => e.id == id);
    } catch (e) {
      LoggerUtils.error('Error deleting shared expense', e);
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Settle a shared expense
  Future<void> settleSharedExpense(String expenseId, String userId) async {
    try {
      isLoading.value = true;
      error.value = '';

      await _provider.settleExpense(expenseId, userId);

      // Update the expense status in local list
      final index = sharedExpenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        final updatedExpense =
            sharedExpenses[index].copyWith(status: SharedExpenseStatus.settled);
        sharedExpenses[index] = updatedExpense;
      }
    } catch (e) {
      LoggerUtils.error('Error settling shared expense', e);
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Calculate shares for a specific expense
  Future<Map<String, double>?> calculateShares(String expenseId) async {
    try {
      isLoading.value = true;
      error.value = '';

      return await _provider.calculateShares(expenseId);
    } catch (e) {
      LoggerUtils.error('Error calculating shares', e);
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Get a specific shared expense by ID
  Future<SharedExpenseModel?> getSharedExpense(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      return await _repository.getSharedExpense(id);
    } catch (e) {
      LoggerUtils.error('Error fetching shared expense', e);
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch pending shared expenses
  Future<List<SharedExpenseModel>?> getPendingSharedExpenses() async {
    try {
      isLoading.value = true;
      error.value = '';

      final pendingExpenses = await _provider.getPendingSharedExpenses();
      return pendingExpenses;
    } catch (e) {
      LoggerUtils.error('Error fetching pending shared expenses', e);
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Filter shared expenses
  List<SharedExpenseModel> filterSharedExpenses({
    String? groupId,
    SharedExpenseStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return sharedExpenses.where((expense) {
      bool matchesGroupId = groupId == null || expense.groupId == groupId;
      bool matchesStatus = status == null || expense.status == status;
      bool matchesStartDate =
          startDate == null || expense.createdAt.isAfter(startDate);
      bool matchesEndDate =
          endDate == null || expense.createdAt.isBefore(endDate);

      return matchesGroupId &&
          matchesStatus &&
          matchesStartDate &&
          matchesEndDate;
    }).toList();
  }

  @override
  void onClose() {
    // Clear the list when the service is closed
    sharedExpenses.clear();
    super.onClose();
  }
}
