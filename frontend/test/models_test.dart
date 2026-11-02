import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_tracker/core/constants/api_constants.dart';
import 'package:personal_expense_tracker/data/models/category_model.dart';
import 'package:personal_expense_tracker/data/models/transaction_model.dart';

void main() {
  group('CategoryModel Tests', () {
    test('fromJson creates CategoryModel with default values', () {
      final json = {
        '_id': 'cat123',
        'firebaseUid': 'user456',
        'name': 'Food & Dining',
        'type': 'expense',
        'icon': 'restaurant',
        'color': '#FF5733',
        'isDefault': true,
      };

      final category = CategoryModel.fromJson(json);

      expect(category.id, 'cat123');
      expect(category.firebaseUid, 'user456');
      expect(category.name, 'Food & Dining');
      expect(category.type, 'expense');
      expect(category.isDefault, true);
      expect(category.color, '#FF5733');
    });

    test('toJson returns correct map for creating/updating category', () {
      final category = CategoryModel(
        id: 'cat1',
        firebaseUid: 'u1',
        name: 'Salary',
        type: 'income',
        icon: 'attach_money',
        color: '#00AA00',
      );

      final json = category.toJson();
      expect(json['name'], 'Salary');
      expect(json['type'], 'income');
      expect(json['icon'], 'attach_money');
      expect(json['color'], '#00AA00');
    });
  });

  group('TransactionModel Tests', () {
    test('fromJson parses full transaction data accurately', () {
      final json = {
        '_id': 'tx999',
        'firebaseUid': 'uid888',
        'type': 'expense',
        'amountMinor': 1250,
        'currency': 'USD',
        'categoryId': 'cat123',
        'description': 'Grocery Shopping',
        'paymentMethod': 'Credit Card',
        'transactionDate': '2026-10-28T12:00:00.000Z',
        'note': 'Bought fruits',
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.id, 'tx999');
      expect(tx.firebaseUid, 'uid888');
      expect(tx.type, 'expense');
      expect(tx.amountMinor, 1250);
      expect(tx.currency, 'USD');
      expect(tx.description, 'Grocery Shopping');
      expect(tx.paymentMethod, 'Credit Card');
      expect(tx.isExpense, true);
      expect(tx.isIncome, false);
      expect(tx.note, 'Bought fruits');
    });

    test('toJson converts model correctly for API payload', () {
      final tx = TransactionModel(
        id: 'tx1',
        firebaseUid: 'uid1',
        type: 'income',
        amountMinor: 500000,
        categoryId: 'catSalary',
        description: 'Monthly Salary',
        transactionDate: DateTime.parse('2026-10-01T00:00:00.000Z'),
      );

      final json = tx.toJson();

      expect(json['type'], 'income');
      expect(json['amountMinor'], 500000);
      expect(json['categoryId'], 'catSalary');
      expect(json['description'], 'Monthly Salary');
      expect(tx.isIncome, true);
      expect(tx.isExpense, false);
    });
  });

  group('ApiConstants Tests', () {
    test('Base URL is non-empty and contains API prefix', () {
      final url = ApiConstants.baseUrl;
      expect(url.isNotEmpty, true);
      expect(url.contains('/api/v1'), true);
    });

    test('Endpoint paths are correctly formatted', () {
      expect(ApiConstants.authSync, '/auth/sync');
      expect(ApiConstants.transactions, '/transactions');
      expect(ApiConstants.categories, '/categories');
      expect(ApiConstants.budgets, '/budgets');
      expect(ApiConstants.analyticsSummary, '/analytics/summary');
    });
  });
}
