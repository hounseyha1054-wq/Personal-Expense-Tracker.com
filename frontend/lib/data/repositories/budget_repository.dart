import '../models/budget_model.dart';
import '../services/api_service.dart';

class BudgetRepository {
  final ApiService _apiService;

  BudgetRepository(this._apiService);

  Future<BudgetSummaryModel> getBudgets({String? month}) async {
    return await _apiService.getBudgets(month: month);
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    return await _apiService.createBudget(data);
  }

  Future<BudgetModel> updateBudget(String id, Map<String, dynamic> data) async {
    return await _apiService.updateBudget(id, data);
  }

  Future<void> deleteBudget(String id) async {
    await _apiService.deleteBudget(id);
  }
}
