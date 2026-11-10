import 'package:get/get.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/repositories/analytics_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class AnalyticsController extends GetxController {
  final AnalyticsRepository _analyticsRepository = Get.find<AnalyticsRepository>();

  final RxBool isLoading = false.obs;
  final RxBool isCategoryLoading = false.obs;
  final RxString error = ''.obs;

  final Rx<DashboardSummaryModel?> summary = Rx<DashboardSummaryModel?>(null);
  final RxList<MonthlyStatModel> monthlyStats = <MonthlyStatModel>[].obs;
  final RxList<CategorySpendingModel> categoryBreakdown = <CategorySpendingModel>[].obs;

  // Selected filters
  final RxString selectedCurrency = 'USD'.obs; // 'USD' or 'KHR' - strictly isolated
  final RxInt selectedYear = DateTime.now().year.obs;
  final RxInt selectedMonth = DateTime.now().month.obs; // 0 = Whole Year, 1..12 = Jan..Dec
  final RxString selectedCategoryType = 'expense'.obs; // 'expense' or 'income'
  final RxInt touchedCategoryIndex = (-1).obs;
  final RxInt touchedBarIndex = (-1).obs;

  static const List<String> monthNamesShort = [
    'All',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> monthNamesFull = [
    'Whole Year',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static List<String> get localizedMonthNamesShort => [
        'all_12m'.tr,
        'month_jan'.tr,
        'month_feb'.tr,
        'month_mar'.tr,
        'month_apr'.tr,
        'month_may'.tr,
        'month_jun'.tr,
        'month_jul'.tr,
        'month_aug'.tr,
        'month_sep'.tr,
        'month_oct'.tr,
        'month_nov'.tr,
        'month_dec'.tr,
      ];

  static List<String> get localizedMonthNamesFull => [
        'whole_year'.tr,
        'month_full_jan'.tr,
        'month_full_feb'.tr,
        'month_full_mar'.tr,
        'month_full_apr'.tr,
        'month_full_may'.tr,
        'month_full_jun'.tr,
        'month_full_jul'.tr,
        'month_full_aug'.tr,
        'month_full_sep'.tr,
        'month_full_oct'.tr,
        'month_full_nov'.tr,
        'month_full_dec'.tr,
      ];

  @override
  void onInit() {
    super.onInit();

    // Initialize with user's preferred currency from settings if available
    if (Get.isRegistered<AuthController>()) {
      final authCtrl = Get.find<AuthController>();
      final pref = authCtrl.userModel.value?.preferredCurrency;
      if (pref != null && pref.isNotEmpty) {
        selectedCurrency.value = pref;
      }

      // Automatically react when user changes default currency in Settings
      ever(authCtrl.userModel, (user) {
        if (user != null &&
            user.preferredCurrency.isNotEmpty &&
            user.preferredCurrency != selectedCurrency.value) {
          setCurrency(user.preferredCurrency);
        }
      });
    }

    loadData();
  }

  /// Switch active currency (USD vs KHR) - strictly separated analysis
  Future<void> setCurrency(String currency) async {
    if (selectedCurrency.value == currency && !isLoading.value) return;
    selectedCurrency.value = currency;
    touchedCategoryIndex.value = -1;
    await loadData();
  }

  /// Load monthly trends for the selected year and category breakdown for the selected period & currency
  Future<void> loadData() async {
    isLoading.value = true;
    error.value = '';

    try {
      final range = _getDateRange(selectedYear.value, selectedMonth.value);

      final results = await Future.wait([
        _analyticsRepository.getMonthly(
          year: selectedYear.value,
          currency: selectedCurrency.value,
        ),
        _analyticsRepository.getCategories(
          type: selectedCategoryType.value,
          currency: selectedCurrency.value,
          startDate: range['startDate'],
          endDate: range['endDate'],
        ),
        _analyticsRepository.getSummary(
          currency: selectedCurrency.value,
          startDate: range['startDate'],
          endDate: range['endDate'],
        ),
      ]);

      monthlyStats.assignAll(results[0] as List<MonthlyStatModel>);
      categoryBreakdown.assignAll(results[1] as List<CategorySpendingModel>);
      summary.value = results[2] as DashboardSummaryModel;
    } catch (e) {
      error.value = 'Unable to load analytics: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a specific month (0 for whole year, 1..12 for specific month)
  Future<void> selectMonth(int month) async {
    if (selectedMonth.value == month) return;
    selectedMonth.value = month;
    touchedCategoryIndex.value = -1;
    await _reloadPeriodBreakdown();
  }

  /// Change selected year
  Future<void> selectYear(int year) async {
    if (selectedYear.value == year) return;
    selectedYear.value = year;
    await loadData();
  }

  void previousYear() {
    selectYear(selectedYear.value - 1);
  }

  void nextYear() {
    selectYear(selectedYear.value + 1);
  }

  /// Switch category breakdown between Expense and Income
  Future<void> setCategoryType(String type) async {
    if (selectedCategoryType.value == type) return;
    selectedCategoryType.value = type;
    touchedCategoryIndex.value = -1;
    await _reloadPeriodBreakdown();
  }

  /// Re-fetch only category breakdown and period summary for fast responsiveness
  Future<void> _reloadPeriodBreakdown() async {
    isCategoryLoading.value = true;
    try {
      final range = _getDateRange(selectedYear.value, selectedMonth.value);
      final results = await Future.wait([
        _analyticsRepository.getCategories(
          type: selectedCategoryType.value,
          currency: selectedCurrency.value,
          startDate: range['startDate'],
          endDate: range['endDate'],
        ),
        _analyticsRepository.getSummary(
          currency: selectedCurrency.value,
          startDate: range['startDate'],
          endDate: range['endDate'],
        ),
      ]);

      categoryBreakdown.assignAll(results[0] as List<CategorySpendingModel>);
      summary.value = results[1] as DashboardSummaryModel;
    } catch (_) {
      // Keep existing data on transient error
    } finally {
      isCategoryLoading.value = false;
    }
  }

  Map<String, String> _getDateRange(int year, int month) {
    if (month == 0) {
      // Whole year
      return {
        'startDate': '$year-01-01',
        'endDate': '$year-12-31',
      };
    }

    final monthStr = month.toString().padLeft(2, '0');
    final lastDay = DateTime(year, month + 1, 0).day;
    return {
      'startDate': '$year-$monthStr-01',
      'endDate': '$year-$monthStr-$lastDay',
    };
  }

  // --- Computed Metrics for ABA Display ---

  String get activeCurrency => selectedCurrency.value;

  String get selectedPeriodTitle {
    if (selectedMonth.value == 0) {
      return '${'whole_year'.tr} ${selectedYear.value}';
    }
    return '${localizedMonthNamesFull[selectedMonth.value]} ${selectedYear.value}';
  }

  int get periodIncomeMinor {
    if (selectedMonth.value == 0) {
      return monthlyStats.fold<int>(0, (sum, m) => sum + m.incomeMinor);
    }
    final targetMonthStr = '${selectedYear.value}-${selectedMonth.value.toString().padLeft(2, '0')}';
    final stat = monthlyStats.firstWhereOrNull((m) => m.month == targetMonthStr);
    if (stat != null) return stat.incomeMinor;
    return summary.value?.periodSummary?.incomeMinor ?? 0;
  }

  int get periodExpenseMinor {
    if (selectedMonth.value == 0) {
      return monthlyStats.fold<int>(0, (sum, m) => sum + m.expenseMinor);
    }
    final targetMonthStr = '${selectedYear.value}-${selectedMonth.value.toString().padLeft(2, '0')}';
    final stat = monthlyStats.firstWhereOrNull((m) => m.month == targetMonthStr);
    if (stat != null) return stat.expenseMinor;
    return summary.value?.periodSummary?.expenseMinor ?? 0;
  }

  int get periodNetBalanceMinor {
    return periodIncomeMinor - periodExpenseMinor;
  }

  double get periodSavingsRate {
    if (periodIncomeMinor <= 0) return 0.0;
    final net = periodIncomeMinor - periodExpenseMinor;
    return (net / periodIncomeMinor) * 100;
  }

  int get dailyAverageExpenseMinor {
    int days;
    if (selectedMonth.value == 0) {
      final isLeapYear = (selectedYear.value % 4 == 0 && selectedYear.value % 100 != 0) || (selectedYear.value % 400 == 0);
      days = isLeapYear ? 366 : 365;
    } else {
      days = DateTime(selectedYear.value, selectedMonth.value + 1, 0).day;
    }
    if (days <= 0 || periodExpenseMinor <= 0) return 0;
    return (periodExpenseMinor / days).round();
  }

  int get periodTransactionCount {
    if (summary.value?.periodSummary != null) {
      return summary.value!.periodSummary!.transactionCount;
    }
    return categoryBreakdown.fold<int>(0, (sum, c) => sum + c.transactionCount);
  }

  CategorySpendingModel? get topCategory {
    if (categoryBreakdown.isEmpty) return null;
    return categoryBreakdown.first;
  }
}
