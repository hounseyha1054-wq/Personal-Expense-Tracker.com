import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../analytics/controllers/analytics_controller.dart';

class TransactionController extends GetxController {
  final TransactionRepository _transactionRepo =
      Get.find<TransactionRepository>();
  final CategoryRepository _categoryRepo = Get.find<CategoryRepository>();

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString selectedType = ''.obs; // '' for all, 'income', 'expense'
  final RxString selectedCategoryId = ''.obs;
  final RxString selectedCurrency = ''.obs; // '' for all, 'USD', 'KHR'
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;
  final RxString sortBy = 'transactionDate'.obs;
  final RxString sortOrder = 'desc'.obs;

  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();

    // Default to user's preferred currency if available
    if (Get.isRegistered<AuthController>()) {
      final pref =
          Get.find<AuthController>().userModel.value?.preferredCurrency;
      if (pref != null && pref.isNotEmpty) {
        selectedCurrency.value = pref;
      }
    }

    loadCategories();
    fetchTransactions();

    // Debounce search input by 350ms to prevent hammering backend on every keystroke
    debounce(searchQuery, (_) => fetchTransactions(refresh: true),
        time: const Duration(milliseconds: 350));
  }

  void setCurrency(String curr) {
    if (selectedCurrency.value == curr) return;
    selectedCurrency.value = curr;
    fetchTransactions(refresh: true);
  }

  Future<void> fetchNextPage() async {
    if (isLoading.value) return;
    if (currentPage.value >= totalPages.value) return;
    currentPage.value++;
    await fetchTransactions(refresh: false);
  }

  Future<void> loadCategories() async {
    try {
      final list = await _categoryRepo.getCategories();
      categories.assignAll(list);
    } catch (_) {}
  }

  Future<void> fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
    }
    try {
      isLoading.value = true;
      final result = await _transactionRepo.getTransactions(
        type: selectedType.value.isNotEmpty ? selectedType.value : null,
        categoryId: selectedCategoryId.value.isNotEmpty
            ? selectedCategoryId.value
            : null,
        currency:
            selectedCurrency.value.isNotEmpty ? selectedCurrency.value : null,
        startDate: selectedStartDate.value?.toIso8601String(),
        endDate: selectedEndDate.value?.toIso8601String(),
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        page: currentPage.value,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      final List<TransactionModel> fetched = result['transactions'];
      if (currentPage.value == 1) {
        transactions.assignAll(fetched);
      } else {
        transactions.addAll(fetched);
      }

      final pagination = result['pagination'];
      if (pagination != null) {
        totalPages.value = pagination['totalPages'] ?? 1;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load transactions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setTypeFilter(String type) {
    selectedType.value = type;
    fetchTransactions(refresh: true);
  }

  void setCategoryFilter(String catId) {
    selectedCategoryId.value = catId;
    fetchTransactions(refresh: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    selectedStartDate.value = start;
    selectedEndDate.value = end;
    fetchTransactions(refresh: true);
  }

  void setSearch(String query) {
    searchQuery.value = query;
    // Handled smoothly via debounce worker!
  }

  void toggleSort(String field) {
    if (sortBy.value == field) {
      sortOrder.value = sortOrder.value == 'desc' ? 'asc' : 'desc';
    } else {
      sortBy.value = field;
      sortOrder.value = 'desc';
    }
    fetchTransactions(refresh: true);
  }

  Future<void> createTransaction(Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      await _transactionRepo.createTransaction(data);
      Get.back();
      await fetchTransactions(refresh: true);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      if (Get.isRegistered<AnalyticsController>()) {
        Get.find<AnalyticsController>().loadData();
      }
      Get.snackbar(
        'Success',
        'Transaction recorded successfully',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to create transaction: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final existing = transactions.firstWhereOrNull((t) => t.id == id);
    if (existing != null) return existing;

    try {
      final fetched = await _transactionRepo.getTransaction(id);
      return fetched;
    } catch (e) {
      debugPrint('[TransactionController] Error fetching transaction $id: $e');
      return null;
    }
  }

  Future<TransactionModel?> updateTransaction(String id, Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final updated = await _transactionRepo.updateTransaction(id, data);
      
      final index = transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        transactions[index] = updated;
      }

      Get.back(result: updated);
      await fetchTransactions(refresh: true);

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      if (Get.isRegistered<AnalyticsController>()) {
        Get.find<AnalyticsController>().loadData();
      }
      Get.snackbar(
        'Success',
        'Transaction updated successfully',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
      return updated;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update transaction: $e');
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteTransaction(String id, {bool closeScreen = false}) async {
    try {
      isSubmitting.value = true;
      await _transactionRepo.deleteTransaction(id);
      transactions.removeWhere((t) => t.id == id);

      if (closeScreen) {
        Get.back();
      }

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      if (Get.isRegistered<AnalyticsController>()) {
        Get.find<AnalyticsController>().loadData();
      }

      Get.snackbar(
        'delete'.tr,
        'transaction_deleted_success'.tr,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete transaction: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
