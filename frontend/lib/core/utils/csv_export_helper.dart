import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import 'currency_formatter.dart';
import 'csv_downloader/csv_downloader.dart';

class CsvExportHelper {
  /// Converts a list of transactions into an RFC 4180 compliant CSV string
  static String generateCsv(List<TransactionModel> transactions) {
    final List<List<String>> rows = [];

    // Header row
    rows.add([
      'Date',
      'Time',
      'Type',
      'Category',
      'Description',
      'Amount',
      'Currency',
      'Payment Method',
      'Note',
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    for (final tx in transactions) {
      final amountFormatted = CurrencyFormatter.minorToFormString(
        tx.amountMinor,
        currency: tx.currency,
      );

      rows.add([
        dateFormat.format(tx.transactionDate),
        timeFormat.format(tx.transactionDate),
        tx.type.toUpperCase(),
        tx.category?.name ?? 'General',
        tx.description,
        '${tx.isIncome ? '+' : '-'}$amountFormatted',
        tx.currency,
        tx.paymentMethod,
        tx.note,
      ]);
    }

    return rows.map((row) {
      return row.map((field) {
        final str = field.replaceAll('"', '""');
        if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
          return '"$str"';
        }
        return str;
      }).join(',');
    }).join('\r\n');
  }

  /// Writes CSV content and triggers native OS Share (mobile) or Direct File Download (web)
  static Future<void> shareCsvFile({
    required String csvContent,
    required String fileName,
    String? subject,
  }) async {
    await platformExportCsv(
      csvContent: csvContent,
      fileName: fileName,
      subject: subject,
    );
  }

  /// Copies the CSV text directly to the system clipboard
  static Future<void> copyToClipboard(String csvContent) async {
    await Clipboard.setData(ClipboardData(text: csvContent));
  }

  /// Date range calculations
  static DateTime getStartOfWeek(DateTime now) {
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }

  static DateTime getStartOfMonth(DateTime now) {
    return DateTime(now.year, now.month, 1);
  }

  static DateTime getStartOfYear(DateTime now) {
    return DateTime(now.year, 1, 1);
  }
}

