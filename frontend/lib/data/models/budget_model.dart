import 'category_model.dart';

class BudgetModel {
  final String id;
  final String firebaseUid;
  final String categoryId;
  final CategoryModel? category;
  final int amountMinor;
  final String currency;
  final String month; // YYYY-MM
  final int spentMinor;
  final int remainingMinor;
  final int percentageUsed;
  final bool isWarning;
  final bool isOverBudget;

  BudgetModel({
    required this.id,
    required this.firebaseUid,
    required this.categoryId,
    this.category,
    required this.amountMinor,
    this.currency = 'USD',
    required this.month,
    this.spentMinor = 0,
    this.remainingMinor = 0,
    this.percentageUsed = 0,
    this.isWarning = false,
    this.isOverBudget = false,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    CategoryModel? cat;
    String catId = '';

    if (json['categoryId'] is Map<String, dynamic>) {
      cat = CategoryModel.fromJson(json['categoryId']);
      catId = cat.id;
    } else if (json['categoryId'] != null) {
      catId = json['categoryId'].toString();
    }

    return BudgetModel(
      id: json['_id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      categoryId: catId,
      category: cat,
      amountMinor: json['amountMinor'] ?? 0,
      currency: json['currency'] ?? 'USD',
      month: json['month'] ?? '',
      spentMinor: json['spentMinor'] ?? 0,
      remainingMinor: json['remainingMinor'] ?? 0,
      percentageUsed: json['percentageUsed'] ?? 0,
      isWarning: json['isWarning'] ?? false,
      isOverBudget: json['isOverBudget'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'amountMinor': amountMinor,
      'currency': currency,
      'month': month,
    };
  }
}

class BudgetSummaryModel {
  final String month;
  final int totalBudgetMinor;
  final int totalSpentMinor;
  final int remainingMinor;
  final int percentageUsed;
  final bool isWarning;
  final bool isOverBudget;
  final List<BudgetModel> budgets;

  BudgetSummaryModel({
    required this.month,
    required this.totalBudgetMinor,
    required this.totalSpentMinor,
    required this.remainingMinor,
    required this.percentageUsed,
    required this.isWarning,
    required this.isOverBudget,
    required this.budgets,
  });

  factory BudgetSummaryModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? {};
    final list = (json['budgets'] as List<dynamic>? ?? [])
        .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return BudgetSummaryModel(
      month: json['month'] ?? '',
      totalBudgetMinor: summary['totalBudgetMinor'] ?? 0,
      totalSpentMinor: summary['totalSpentMinor'] ?? 0,
      remainingMinor: summary['remainingMinor'] ?? 0,
      percentageUsed: summary['percentageUsed'] ?? 0,
      isWarning: summary['isWarning'] ?? false,
      isOverBudget: summary['isOverBudget'] ?? false,
      budgets: list,
    );
  }
}
