class ApiConstants {
  // Allow overriding at build/run time via:
  // flutter run --dart-define=API_BASE_URL=http://localhost:5000/api/v1
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Production Render Backend URL
  static const String productionBaseUrl =
      'https://personal-expense-tracker-com-1.onrender.com/api/v1';

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl;
    }

    return productionBaseUrl;
  }

  static String get serverBaseUrl => baseUrl.replaceAll('/api/v1', '');

  /// Resolves relative upload paths (e.g. `/uploads/avatars/...`) to complete URLs
  static String resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final url = rawUrl.trim();
    if (url.startsWith('/uploads')) {
      return '$serverBaseUrl$url';
    }
    return url;
  }

  // Endpoints
  static const String authSync = '/auth/sync';
  static const String authMe = '/auth/me';
  
  static const String usersProfile = '/users/profile';
  static const String usersAvatar = '/users/avatar';
  static const String usersPreferences = '/users/preferences';

  static const String transactions = '/transactions';
  static const String categories = '/categories';
  static const String budgets = '/budgets';

  static const String analyticsSummary = '/analytics/summary';
  static const String analyticsMonthly = '/analytics/monthly';
  static const String analyticsCategories = '/analytics/categories';
  static const String analyticsTrends = '/analytics/trends';
}
