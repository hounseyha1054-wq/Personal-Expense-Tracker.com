import '../models/category_model.dart';
import '../services/api_service.dart';

class CategoryRepository {
  final ApiService _apiService;

  static final List<Map<String, dynamic>> defaultCategoryData = [
    {'name': 'Food & Drinks', 'type': 'expense', 'icon': 'restaurant', 'color': '#EF4444'},
    {'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '#F59E0B'},
    {'name': 'Transportation', 'type': 'expense', 'icon': 'directions_car', 'color': '#3B82F6'},
    {'name': 'Bills', 'type': 'expense', 'icon': 'receipt_long', 'color': '#8B5CF6'},
    {'name': 'Entertainment', 'type': 'expense', 'icon': 'sports_esports', 'color': '#EC4899'},
    {'name': 'Education', 'type': 'expense', 'icon': 'school', 'color': '#10B981'},
    {'name': 'Health', 'type': 'expense', 'icon': 'favorite', 'color': '#E11D48'},
    {'name': 'Travel', 'type': 'expense', 'icon': 'flight', 'color': '#06B6D4'},
    {'name': 'Other', 'type': 'expense', 'icon': 'more_horiz', 'color': '#64748B'},
    {'name': 'Salary', 'type': 'income', 'icon': 'payments', 'color': '#10B981'},
    {'name': 'Freelance', 'type': 'income', 'icon': 'laptop_mac', 'color': '#059669'},
    {'name': 'Business', 'type': 'income', 'icon': 'store', 'color': '#2563EB'},
    {'name': 'Gift', 'type': 'income', 'icon': 'card_giftcard', 'color': '#D97706'},
    {'name': 'Investment', 'type': 'income', 'icon': 'trending_up', 'color': '#7C3AED'},
    {'name': 'Other Income', 'type': 'income', 'icon': 'attach_money', 'color': '#64748B'},
  ];

  CategoryRepository(this._apiService);

  Future<List<CategoryModel>> getCategories({String? type}) async {
    try {
      final list = await _apiService.getCategories(type: type);
      if (list.isNotEmpty) {
        return list;
      }

      // If backend has 0 categories, auto-seed defaults into backend
      for (final cat in defaultCategoryData) {
        try {
          await _apiService.createCategory(cat);
        } catch (_) {}
      }

      final seededList = await _apiService.getCategories(type: type);
      if (seededList.isNotEmpty) {
        return seededList;
      }
    } catch (_) {}

    // Fallback if offline or network unavailable
    return defaultCategoryData
        .where((c) => type == null || c['type'] == type)
        .map((c) => CategoryModel(
              id: c['name'],
              firebaseUid: '',
              name: c['name'],
              type: c['type'],
              icon: c['icon'],
              color: c['color'],
              isDefault: true,
            ))
        .toList();
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> data) async {
    return await _apiService.createCategory(data);
  }

  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> data) async {
    return await _apiService.updateCategory(id, data);
  }

  Future<void> deleteCategory(String id) async {
    await _apiService.deleteCategory(id);
  }
}
