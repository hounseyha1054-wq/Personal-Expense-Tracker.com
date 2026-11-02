import 'category_model.dart';

class TransactionModel {
  final String id;
  final String firebaseUid;
  final String type; // 'income' | 'expense'
  final int amountMinor;
  final String currency;
  final String categoryId;
  final CategoryModel? category;
  final String description;
  final String paymentMethod;
  final DateTime transactionDate;
  final String note;
  final DateTime? createdAt;

  TransactionModel({
    required this.id,
    required this.firebaseUid,
    required this.type,
    required this.amountMinor,
    this.currency = 'USD',
    required this.categoryId,
    this.category,
    required this.description,
    this.paymentMethod = 'Cash',
    required this.transactionDate,
    this.note = '',
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    CategoryModel? cat;
    String catId = '';

    if (json['categoryId'] is Map<String, dynamic>) {
      cat = CategoryModel.fromJson(json['categoryId']);
      catId = cat.id;
    } else if (json['categoryId'] != null) {
      catId = json['categoryId'].toString();
    }

    return TransactionModel(
      id: json['_id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      type: json['type'] ?? 'expense',
      amountMinor: json['amountMinor'] ?? 0,
      currency: json['currency'] ?? 'USD',
      categoryId: catId,
      category: cat,
      description: json['description'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'])
          : DateTime.now(),
      note: json['note'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amountMinor': amountMinor,
      'currency': currency,
      'categoryId': categoryId,
      'description': description,
      'paymentMethod': paymentMethod,
      'transactionDate': transactionDate.toIso8601String(),
      'note': note,
    };
  }

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
}
