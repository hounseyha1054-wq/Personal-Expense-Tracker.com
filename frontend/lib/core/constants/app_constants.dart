class AppConstants {
  static const String appName = 'ExpenseTracker';

  // Supported Currencies
  static const String currencyUSD = 'USD';
  static const String currencyKHR = 'KHR';

  // Storage Keys for non-sensitive preferences (theme, UI choices)
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyPreferredCurrency = 'app_preferred_currency';

  // Transaction Types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Mobile Payment',
    'Other',
  ];
}
