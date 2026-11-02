import '../models/analytics_model.dart';
import '../services/api_service.dart';

class AnalyticsRepository {
  final ApiService _apiService;

  AnalyticsRepository(this._apiService);

  Future<DashboardSummaryModel> getSummary({
    String currency = 'USD',
    String? startDate,
    String? endDate,
  }) async {
    return await _apiService.getAnalyticsSummary(
      currency: currency,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<MonthlyStatModel>> getMonthly({
    int? months,
    int? year,
    String currency = 'USD',
  }) async {
    return await _apiService.getAnalyticsMonthly(
      months: months,
      year: year,
      currency: currency,
    );
  }

  Future<List<CategorySpendingModel>> getCategories({
    String type = 'expense',
    String currency = 'USD',
    String? startDate,
    String? endDate,
  }) async {
    return await _apiService.getAnalyticsCategories(
      type: type,
      currency: currency,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Map<String, dynamic>> getTrends({String currency = 'USD'}) async {
    return await _apiService.getAnalyticsTrends(currency: currency);
  }
}
