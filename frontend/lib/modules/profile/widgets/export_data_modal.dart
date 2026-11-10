import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/csv_export_helper.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

enum ExportDatePeriod {
  thisWeek,
  thisMonth,
  thisYear,
  allTime,
  custom,
}

class ExportDataModal extends StatefulWidget {
  final bool isDialog;
  const ExportDataModal({super.key, this.isDialog = false});

  static Future<void> show(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    if (isWide) {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: const ExportDataModal(isDialog: true),
          ),
        ),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ExportDataModal(isDialog: false),
    );
  }

  @override
  State<ExportDataModal> createState() => _ExportDataModalState();
}

class _ExportDataModalState extends State<ExportDataModal> {
  final TransactionRepository _transactionRepo =
      Get.find<TransactionRepository>();

  ExportDatePeriod _selectedPeriod = ExportDatePeriod.thisMonth;
  String _selectedType = ''; // '' for all, 'expense', 'income'
  String _selectedCurrency = ''; // '' for all, 'USD', 'KHR'

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  bool _isLoading = false;
  bool _isExporting = false;
  List<TransactionModel> _matchingTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadPreviewData();
  }

  (DateTime?, DateTime?) _calculateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ExportDatePeriod.thisWeek:
        final start = CsvExportHelper.getStartOfWeek(now);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case ExportDatePeriod.thisMonth:
        final start = CsvExportHelper.getStartOfMonth(now);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case ExportDatePeriod.thisYear:
        final start = CsvExportHelper.getStartOfYear(now);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case ExportDatePeriod.allTime:
        return (null, null);
      case ExportDatePeriod.custom:
        return (_customStartDate, _customEndDate);
    }
  }

  Future<void> _loadPreviewData() async {
    setState(() => _isLoading = true);
    final (start, end) = _calculateDateRange();

    try {
      final list = await _transactionRepo.exportTransactions(
        type: _selectedType.isNotEmpty ? _selectedType : null,
        currency: _selectedCurrency.isNotEmpty ? _selectedCurrency : null,
        startDate: start?.toIso8601String(),
        endDate: end?.toIso8601String(),
      );

      if (mounted) {
        setState(() {
          _matchingTransactions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('[ExportDataModal] Error fetching preview: $e');
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = ExportDatePeriod.custom;
        _customStartDate = picked.start;
        _customEndDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        );
      });
      _loadPreviewData();
    }
  }

  String _getPeriodSlug() {
    switch (_selectedPeriod) {
      case ExportDatePeriod.thisWeek:
        return 'this_week';
      case ExportDatePeriod.thisMonth:
        return 'this_month';
      case ExportDatePeriod.thisYear:
        return 'this_year';
      case ExportDatePeriod.allTime:
        return 'all_time';
      case ExportDatePeriod.custom:
        return 'custom';
    }
  }

  Future<void> _handleExportAndShare() async {
    if (_matchingTransactions.isEmpty) {
      Get.snackbar(
        'export_data'.tr,
        'no_data_to_export'.tr,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    try {
      setState(() => _isExporting = true);
      final csv = CsvExportHelper.generateCsv(_matchingTransactions);
      final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final typeSuffix = _selectedType.isNotEmpty ? '_$_selectedType' : '';
      final fileName =
          'expense_tracker_${_getPeriodSlug()}${typeSuffix}_$dateStamp.csv';

      await CsvExportHelper.shareCsvFile(
        csvContent: csv,
        fileName: fileName,
        subject:
            'Expense Tracker Export (${_matchingTransactions.length} records)',
      );

      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          'export_data'.tr,
          'CSV file exported successfully!',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to export file: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleCopyCsv() async {
    if (_matchingTransactions.isEmpty) {
      Get.snackbar(
        'export_data'.tr,
        'no_data_to_export'.tr,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final csv = CsvExportHelper.generateCsv(_matchingTransactions);
      await CsvExportHelper.copyToClipboard(csv);
      Get.snackbar(
        'copy_csv'.tr,
        'csv_copied'.tr,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.copy_all_rounded, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to copy CSV: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate totals for preview
    int totalIncomeMinor = 0;
    int totalExpenseMinor = 0;
    for (final tx in _matchingTransactions) {
      if (tx.isIncome) {
        totalIncomeMinor += tx.amountMinor;
      } else {
        totalExpenseMinor += tx.amountMinor;
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle (mobile bottom sheet only)
            if (!widget.isDialog) ...[
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              const SizedBox(height: 20),
            ],

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.download_rounded,
                        color: Colors.teal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'export_data'.tr,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'export_subtitle'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Date Range
                    Text(
                      'date_range'.tr,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPeriodChip(
                          ExportDatePeriod.thisWeek,
                          'this_week'.tr,
                          Icons.calendar_view_week_rounded,
                        ),
                        _buildPeriodChip(
                          ExportDatePeriod.thisMonth,
                          'this_month'.tr,
                          Icons.calendar_month_rounded,
                        ),
                        _buildPeriodChip(
                          ExportDatePeriod.thisYear,
                          'this_year'.tr,
                          Icons.calendar_today_rounded,
                        ),
                        _buildPeriodChip(
                          ExportDatePeriod.allTime,
                          'all_time'.tr,
                          Icons.all_inclusive_rounded,
                        ),
                        ActionChip(
                          avatar:
                              const Icon(Icons.edit_calendar_rounded, size: 16),
                          label: Text(
                            _selectedPeriod == ExportDatePeriod.custom &&
                                    _customStartDate != null &&
                                    _customEndDate != null
                                ? '${DateFormatter.formatShortDate(_customStartDate!)} - ${DateFormatter.formatShortDate(_customEndDate!)}'
                                : 'custom_range'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  _selectedPeriod == ExportDatePeriod.custom
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: _selectedPeriod == ExportDatePeriod.custom
                                  ? Colors.teal
                                  : null,
                            ),
                          ),
                          onPressed: _pickCustomRange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 2: Transaction Type
                    Text(
                      'transaction_type'.tr,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeSegment(
                              '', 'all_types'.tr, Icons.swap_horiz_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeSegment(
                            'expense',
                            'expenses_only'.tr,
                            Icons.arrow_upward_rounded,
                            activeColor: AppColors.expense,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeSegment(
                            'income',
                            'income_only'.tr,
                            Icons.arrow_downward_rounded,
                            activeColor: AppColors.income,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Currency Filter
                    Text(
                      'all_currencies'.tr,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildCurrencyFilterChip('', 'all_currencies'.tr),
                        const SizedBox(width: 8),
                        _buildCurrencyFilterChip('USD', '\$ USD'),
                        const SizedBox(width: 8),
                        _buildCurrencyFilterChip('KHR', '៛ KHR'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 4: Live Preview Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.teal.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_matchingTransactions.length} ${'records_found'.tr}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Format: CSV (Spreadsheet)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white54
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Total Income
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.income
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'income'.tr,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '+${CurrencyFormatter.format(totalIncomeMinor, currency: 'USD')}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.income,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Total Expense
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.expense
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'expense'.tr,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '-${CurrencyFormatter.format(totalExpenseMinor, currency: 'USD')}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.expense,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  // Copy CSV Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text('copy_csv'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: _matchingTransactions.isEmpty || _isLoading
                        ? null
                        : _handleCopyCsv,
                  ),
                  const SizedBox(width: 12),
                  // Primary Export & Share Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 20),
                      label: Text(
                        _isExporting ? 'Exporting...' : 'export_csv_btn'.tr,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _matchingTransactions.isEmpty ||
                              _isLoading ||
                              _isExporting
                          ? null
                          : _handleExportAndShare,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
      ExportDatePeriod period, String label, IconData icon) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : null),
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.teal.shade700,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : null,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = period;
          });
          _loadPreviewData();
        }
      },
    );
  }

  Widget _buildTypeSegment(String type, String label, IconData icon,
      {Color? activeColor}) {
    final isSelected = _selectedType == type;
    final color = activeColor ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        _loadPreviewData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyFilterChip(String code, String label) {
    final isSelected = _selectedCurrency == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.teal.shade700,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : null,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCurrency = code;
          });
          _loadPreviewData();
        }
      },
    );
  }
}
