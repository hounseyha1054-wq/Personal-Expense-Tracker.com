import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format minor currency units into human-readable currency string.
  /// For USD: amountMinor is in cents (e.g. 1550 -> "$15.50").
  /// For KHR: amountMinor is in Riels (e.g. 4000 -> "4,000 ៛").
  static String format(int amountMinor, {String currency = 'USD'}) {
    if (currency == 'KHR') {
      final formatter = NumberFormat('#,##0', 'en_US');
      return '${formatter.format(amountMinor)} ៛';
    } else {
      // Default USD
      final double majorAmount = amountMinor / 100.0;
      final formatter = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
      );
      return formatter.format(majorAmount);
    }
  }

  /// Converts a decimal user input string (e.g. "15.50" for USD, or "4000" for KHR)
  /// into safe integer amountMinor units.
  static int parseToMinor(String input, {String currency = 'USD'}) {
    final cleaned = input.replaceAll(',', '').trim();
    final double val = double.tryParse(cleaned) ?? 0.0;
    if (currency == 'KHR') {
      return val.round();
    } else {
      return (val * 100).round();
    }
  }

  /// Converts minor units into plain decimal string for form editing fields
  static String minorToFormString(int amountMinor, {String currency = 'USD'}) {
    if (currency == 'KHR') {
      return amountMinor.toString();
    } else {
      final double major = amountMinor / 100.0;
      return major.toStringAsFixed(2);
    }
  }
}
