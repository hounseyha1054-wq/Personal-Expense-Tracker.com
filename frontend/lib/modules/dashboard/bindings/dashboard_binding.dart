import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../../categories/controllers/category_controller.dart';
import '../../budgets/controllers/budget_controller.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
    Get.lazyPut<TransactionController>(() => TransactionController(), fenix: true);
    Get.lazyPut<CategoryController>(() => CategoryController(), fenix: true);
    Get.lazyPut<BudgetController>(() => BudgetController(), fenix: true);
    Get.lazyPut<AnalyticsController>(() => AnalyticsController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
  }
}
