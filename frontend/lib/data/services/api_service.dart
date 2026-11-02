import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../models/analytics_model.dart';

class ApiService {
  final ApiClient _apiClient;

  ApiService(this._apiClient);

  Dio get _dio => _apiClient.dio;

  // --- Auth & User ---
  Future<UserModel> syncUser({String? name, String? photoURL, String? preferredCurrency}) async {
    final response = await _dio.post(
      ApiConstants.authSync,
      data: {
        if (name != null) 'name': name,
        if (photoURL != null) 'photoURL': photoURL,
        if (preferredCurrency != null) 'preferredCurrency': preferredCurrency,
      },
    );
    return UserModel.fromJson(response.data['data']);
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiConstants.authMe);
    return UserModel.fromJson(response.data['data']);
  }

  Future<UserModel> updateProfile({String? name, String? photoURL}) async {
    final response = await _dio.put(
      ApiConstants.usersProfile,
      data: {
        if (name != null) 'name': name,
        if (photoURL != null) 'photoURL': photoURL,
      },
    );
    return UserModel.fromJson(response.data['data']);
  }

  Future<UserModel> uploadAvatar(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final subType = (ext == 'png') ? 'png' : ((ext == 'webp') ? 'webp' : 'jpeg');

    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        file.path,
        filename: fileName.isNotEmpty ? fileName : 'avatar.jpg',
        contentType: DioMediaType('image', subType),
      ),
    });
    final response = await _dio.post(
      ApiConstants.usersAvatar,
      data: formData,
    );
    return UserModel.fromJson(response.data['data']);
  }

  Future<UserModel> updatePreferences({required String preferredCurrency}) async {
    final response = await _dio.put(
      ApiConstants.usersPreferences,
      data: {'preferredCurrency': preferredCurrency},
    );
    return UserModel.fromJson(response.data['data']);
  }

  // --- Transactions ---
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
    final response = await _dio.get(
      ApiConstants.transactions,
      queryParameters: {
        if (type != null && type.isNotEmpty) 'type': type,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      },
    );

    final List<dynamic> list = response.data['data'] ?? [];
    final transactions = list.map((e) => TransactionModel.fromJson(e)).toList();

    return {
      'transactions': transactions,
      'pagination': response.data['pagination'],
    };
  }

  Future<TransactionModel> getTransaction(String id) async {
    final response = await _dio.get('${ApiConstants.transactions}/$id');
    return TransactionModel.fromJson(response.data['data']);
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.transactions, data: data);
    return TransactionModel.fromJson(response.data['data']);
  }

  Future<TransactionModel> updateTransaction(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.transactions}/$id', data: data);
    return TransactionModel.fromJson(response.data['data']);
  }

  Future<void> deleteTransaction(String id) async {
    await _dio.delete('${ApiConstants.transactions}/$id');
  }

  // --- Categories ---
  Future<List<CategoryModel>> getCategories({String? type}) async {
    final response = await _dio.get(
      ApiConstants.categories,
      queryParameters: {
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    final List<dynamic> list = response.data['data'] ?? [];
    return list.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.categories, data: data);
    return CategoryModel.fromJson(response.data['data']);
  }

  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.categories}/$id', data: data);
    return CategoryModel.fromJson(response.data['data']);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('${ApiConstants.categories}/$id');
  }

  // --- Budgets ---
  Future<BudgetSummaryModel> getBudgets({String? month}) async {
    final response = await _dio.get(
      ApiConstants.budgets,
      queryParameters: {
        if (month != null && month.isNotEmpty) 'month': month,
      },
    );
    return BudgetSummaryModel.fromJson(response.data['data']);
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.budgets, data: data);
    return BudgetModel.fromJson(response.data['data']);
  }

  Future<BudgetModel> updateBudget(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.budgets}/$id', data: data);
    return BudgetModel.fromJson(response.data['data']);
  }

  Future<void> deleteBudget(String id) async {
    await _dio.delete('${ApiConstants.budgets}/$id');
  }

  // --- Analytics ---
  Future<DashboardSummaryModel> getAnalyticsSummary({
    String currency = 'USD',
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      ApiConstants.analyticsSummary,
      queryParameters: {
        'currency': currency,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return DashboardSummaryModel.fromJson(response.data['data']);
  }

  Future<List<MonthlyStatModel>> getAnalyticsMonthly({
    int? months,
    int? year,
    String currency = 'USD',
  }) async {
    final response = await _dio.get(
      ApiConstants.analyticsMonthly,
      queryParameters: {
        'currency': currency,
        if (months != null) 'months': months,
        if (year != null) 'year': year,
      },
    );
    final List<dynamic> list = response.data['data'] ?? [];
    return list.map((e) => MonthlyStatModel.fromJson(e)).toList();
  }

  Future<List<CategorySpendingModel>> getAnalyticsCategories({
    String type = 'expense',
    String currency = 'USD',
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      ApiConstants.analyticsCategories,
      queryParameters: {
        'type': type,
        'currency': currency,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    final List<dynamic> list = response.data['data']['breakdown'] ?? [];
    return list.map((e) => CategorySpendingModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getAnalyticsTrends({String currency = 'USD'}) async {
    final response = await _dio.get(
      ApiConstants.analyticsTrends,
      queryParameters: {'currency': currency},
    );
    return response.data['data'] ?? {};
  }
}
