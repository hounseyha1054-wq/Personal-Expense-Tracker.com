import 'package:flutter/material.dart';
import 'transaction_model.dart';

class DashboardSummaryModel {
  final String currency;
  final int totalBalanceMinor;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final int totalTransactions;
  final CurrentMonthSummary currentMonth;
  final PeriodSummary? periodSummary;
  final List<TransactionModel> recentTransactions;

  DashboardSummaryModel({
    required this.currency,
    required this.totalBalanceMinor,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.totalTransactions,
    required this.currentMonth,
    this.periodSummary,
    required this.recentTransactions,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final recent = (json['recentTransactions'] as List<dynamic>? ?? [])
        .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();

    return DashboardSummaryModel(
      currency: json['currency'] ?? 'USD',
      totalBalanceMinor: json['totalBalanceMinor'] ?? 0,
      totalIncomeMinor: json['totalIncomeMinor'] ?? 0,
      totalExpenseMinor: json['totalExpenseMinor'] ?? 0,
      totalTransactions: json['totalTransactions'] ?? 0,
      currentMonth: CurrentMonthSummary.fromJson(json['currentMonth'] ?? {}),
      periodSummary: json['periodSummary'] != null
          ? PeriodSummary.fromJson(json['periodSummary'])
          : null,
      recentTransactions: recent,
    );
  }
}

class CurrentMonthSummary {
  final String monthString;
  final int incomeMinor;
  final int expenseMinor;
  final int balanceMinor;

  CurrentMonthSummary({
    required this.monthString,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.balanceMinor,
  });

  factory CurrentMonthSummary.fromJson(Map<String, dynamic> json) {
    return CurrentMonthSummary(
      monthString: json['monthString'] ?? '',
      incomeMinor: json['incomeMinor'] ?? 0,
      expenseMinor: json['expenseMinor'] ?? 0,
      balanceMinor: json['balanceMinor'] ?? 0,
    );
  }
}

class PeriodSummary {
  final String? startDate;
  final String? endDate;
  final int incomeMinor;
  final int expenseMinor;
  final int balanceMinor;
  final int transactionCount;

  PeriodSummary({
    this.startDate,
    this.endDate,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.balanceMinor,
    required this.transactionCount,
  });

  factory PeriodSummary.fromJson(Map<String, dynamic> json) {
    return PeriodSummary(
      startDate: json['startDate'],
      endDate: json['endDate'],
      incomeMinor: json['incomeMinor'] ?? 0,
      expenseMinor: json['expenseMinor'] ?? 0,
      balanceMinor: json['balanceMinor'] ?? 0,
      transactionCount: json['transactionCount'] ?? 0,
    );
  }
}

class MonthlyStatModel {
  final String month;
  final int? monthIndex;
  final String label;
  final int incomeMinor;
  final int expenseMinor;
  final int netSavingsMinor;

  MonthlyStatModel({
    required this.month,
    this.monthIndex,
    required this.label,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.netSavingsMinor,
  });

  factory MonthlyStatModel.fromJson(Map<String, dynamic> json) {
    return MonthlyStatModel(
      month: json['month'] ?? '',
      monthIndex: json['monthIndex'],
      label: json['label'] ?? '',
      incomeMinor: json['incomeMinor'] ?? 0,
      expenseMinor: json['expenseMinor'] ?? 0,
      netSavingsMinor: json['netSavingsMinor'] ?? 0,
    );
  }
}

class CategorySpendingModel {
  final String categoryId;
  final String categoryName;
  final String icon;
  final String color;
  final String type;
  final int totalAmountMinor;
  final int transactionCount;
  final double percentage;

  CategorySpendingModel({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.type,
    required this.totalAmountMinor,
    required this.transactionCount,
    required this.percentage,
  });

  factory CategorySpendingModel.fromJson(Map<String, dynamic> json) {
    return CategorySpendingModel(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#4F46E5',
      type: json['type'] ?? 'expense',
      totalAmountMinor: json['totalAmountMinor'] ?? 0,
      transactionCount: json['transactionCount'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Color get displayColor {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  IconData get displayIcon {
    switch (icon) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'laptop_mac':
        return Icons.laptop_mac_rounded;
      case 'store':
        return Icons.store_rounded;
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'attach_money':
        return Icons.attach_money_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'local_hospital':
        return Icons.local_hospital_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'home':
        return Icons.home_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
