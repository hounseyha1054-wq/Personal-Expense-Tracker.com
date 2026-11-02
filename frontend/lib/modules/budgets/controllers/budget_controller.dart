import 'package:get/get.dart';

import '../../../data/models/budget_model.dart';
import '../../../data/repositories/budget_repository.dart';

class BudgetController extends GetxController {
  final BudgetRepository _budgetRepository = Get.find<BudgetRepository>();

  final Rx<BudgetSummaryModel?> summary = Rx<BudgetSummaryModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    isLoading.value = true;
    error.value = '';

    try {
      summary.value = await _budgetRepository.getBudgets();
    } catch (e) {
      error.value = 'Unable to load budgets: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
