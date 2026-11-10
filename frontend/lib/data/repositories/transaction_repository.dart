import '../models/transaction_model.dart';
import '../services/api_service.dart';

class TransactionRepository {
  final ApiService _apiService;

  TransactionRepository(this._apiService);

  Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? categoryId,
    String? currency,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int limit = 20,
    String sortBy = 'transactionDate',
    String sortOrder = 'desc',
  }) async {
    return await _apiService.getTransactions(
      type: type,
      categoryId: categoryId,
      currency: currency,
      startDate: startDate,
      endDate: endDate,
      search: search,
      page: page,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  Future<TransactionModel> getTransaction(String id) async {
    return await _apiService.getTransaction(id);
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    return await _apiService.createTransaction(data);
  }

  Future<TransactionModel> updateTransaction(String id, Map<String, dynamic> data) async {
    return await _apiService.updateTransaction(id, data);
  }

  Future<void> deleteTransaction(String id) async {
    await _apiService.deleteTransaction(id);
  }

  Future<List<TransactionModel>> exportTransactions({
    String? type,
    String? currency,
    String? startDate,
    String? endDate,
  }) async {
    return await _apiService.exportTransactions(
      type: type,
      currency: currency,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
