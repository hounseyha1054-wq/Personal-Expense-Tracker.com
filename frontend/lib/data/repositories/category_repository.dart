import '../models/category_model.dart';
import '../services/api_service.dart';

class CategoryRepository {
  final ApiService _apiService;

  CategoryRepository(this._apiService);

  Future<List<CategoryModel>> getCategories({String? type}) async {
    return await _apiService.getCategories(type: type);
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
