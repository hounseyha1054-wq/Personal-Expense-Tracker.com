import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/analytics_repository.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/category_repository.dart';

class DashboardController extends GetxController {
  final AnalyticsRepository _analyticsRepo = Get.find<AnalyticsRepository>();
  final BudgetRepository _budgetRepo = Get.find<BudgetRepository>();
  final CategoryRepository _categoryRepo = Get.find<CategoryRepository>();

  final RxInt selectedNavIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString selectedCurrency = 'USD'.obs; // 1-tap fast currency toggle on dashboard
  final RxBool isBalanceHidden = false.obs; // Privacy mode: hide balance in public places

  final Rx<DashboardSummaryModel?> summary = Rx<DashboardSummaryModel?>(null);
  final Rx<BudgetSummaryModel?> budgetSummary = Rx<BudgetSummaryModel?>(null);
  final RxList<CategorySpendingModel> categoryBreakdown = <CategorySpendingModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Default to user's preferred currency if available
    if (Get.isRegistered<AuthController>()) {
      final pref = Get.find<AuthController>().userModel.value?.preferredCurrency;
      if (pref != null && pref.isNotEmpty) {
        selectedCurrency.value = pref;
      }
    }
    loadDashboardData();
  }

  void toggleBalanceVisibility() {
    isBalanceHidden.value = !isBalanceHidden.value;
  }

  void setCurrency(String curr) {
    if (selectedCurrency.value == curr) return;
    selectedCurrency.value = curr;
    loadDashboardData();
  }

  void changeNavIndex(int index) {
    selectedNavIndex.value = index;
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      error.value = '';

      final currency = selectedCurrency.value;

      final results = await Future.wait([
        _analyticsRepo.getSummary(currency: currency),
        _budgetRepo.getBudgets(),
        _analyticsRepo.getCategories(type: 'expense', currency: currency),
        _categoryRepo.getCategories(),
      ]);

      summary.value = results[0] as DashboardSummaryModel;
      budgetSummary.value = results[1] as BudgetSummaryModel;
      categoryBreakdown.assignAll(results[2] as List<CategorySpendingModel>);
      categories.assignAll(results[3] as List<CategoryModel>);
    } catch (e) {
      error.value = 'Failed to load dashboard data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }
}
