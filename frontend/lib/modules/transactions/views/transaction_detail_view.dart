import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/card_container.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/transaction_model.dart';
import '../controllers/transaction_controller.dart';

class TransactionDetailView extends StatefulWidget {
  const TransactionDetailView({super.key});

  @override
  State<TransactionDetailView> createState() => _TransactionDetailViewState();
}

class _TransactionDetailViewState extends State<TransactionDetailView> {
  late final TransactionController _controller;
  TransactionModel? _transaction;
  bool _isLoading = false;
  String? _transactionId;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<TransactionController>()
        ? Get.find<TransactionController>()
        : Get.put(TransactionController());

    _loadTransactionData();
  }

  void _loadTransactionData() {
    final args = Get.arguments;

    if (args is TransactionModel) {
      _transaction = args;
      _transactionId = args.id;
    } else if (args is String) {
      _transactionId = args;
      // Look in memory first
      _transaction =
          _controller.transactions.firstWhereOrNull((t) => t.id == args);
      if (_transaction == null) {
        _fetchFromApi(args);
      }
    } else if (args is Map) {
      if (args['transaction'] is TransactionModel) {
        _transaction = args['transaction'] as TransactionModel;
        _transactionId = _transaction!.id;
      } else if (args['id'] is String) {
        _transactionId = args['id'] as String;
        _fetchFromApi(_transactionId!);
      }
    }
  }

  Future<void> _fetchFromApi(String id) async {
    setState(() => _isLoading = true);
    final fetched = await _controller.getTransactionById(id);
    if (mounted) {
      setState(() {
        _transaction = fetched;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEdit() async {
    if (_transaction == null) return;
    final result = await Get.toNamed(
      Routes.addEditTransaction,
      arguments: _transaction,
    );

    if (result is TransactionModel && mounted) {
      setState(() {
        _transaction = result;
      });
    } else if (_transactionId != null) {
      // Re-fetch in case it was updated
      final updated = await _controller.getTransactionById(_transactionId!);
      if (updated != null && mounted) {
        setState(() {
          _transaction = updated;
        });
      }
    }
  }

  void _confirmDeleteForever(BuildContext context) {
    if (_transaction == null) return;
    final tx = _transaction!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Danger Warning Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.expense,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'delete_forever'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'delete_warning_msg'.tr,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Item Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tx.isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: tx.isIncome ? AppColors.income : AppColors.expense,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tx.description.isEmpty
                          ? (tx.category?.name ?? 'Transaction')
                          : tx.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${tx.isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amountMinor, currency: tx.currency)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: tx.isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('cancel'.tr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expense,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx); // Close dialog
                    await _controller.deleteTransaction(tx.id,
                        closeScreen: true);
                  },
                  child: Text(
                    'delete_forever'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('transaction_details'.tr)),
        body: const Center(
            child: LoadingIndicator(message: 'Loading details...')),
      );
    }

    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: Text('transaction_details'.tr)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('no_transactions_found'.tr,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
            ],
          ),
        ),
      );
    }

    final tx = _transaction!;

    return Scaffold(
      appBar: AppBar(
        title: Text('transaction_details'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'edit_transaction'.tr,
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded,
                color: AppColors.expense),
            tooltip: 'delete_forever'.tr,
            onPressed: () => _confirmDeleteForever(context),
          ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 640,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
          children: [
            // Hero Amount Card
            CardContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          tx.category?.displayColor.withValues(alpha: 0.12) ??
                              (tx.isExpense
                                  ? AppColors.expenseLight
                                  : AppColors.incomeLight),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tx.category?.displayIcon ??
                          (tx.isExpense
                              ? Icons.shopping_bag
                              : Icons.attach_money),
                      color: tx.category?.displayColor ??
                          (tx.isExpense ? AppColors.expense : AppColors.income),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${tx.isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amountMinor, currency: tx.currency)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: tx.isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tx.description.isEmpty
                        ? (tx.category?.name ?? 'Transaction')
                        : tx.description,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: tx.isIncome
                          ? AppColors.incomeLight
                          : AppColors.expenseLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tx.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            tx.isIncome ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metadata Card
            CardContainer(
              child: Column(
                children: [
                  _buildDetailRow('Category', tx.category?.name ?? 'General',
                      Icons.category_outlined),
                  const Divider(),
                  _buildDetailRow(
                    'Date',
                    DateFormatter.formatFullDate(tx.transactionDate),
                    Icons.calendar_today_outlined,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Time',
                    DateFormatter.formatTime(tx.transactionDate),
                    Icons.access_time_outlined,
                  ),
                  const Divider(),
                  _buildDetailRow('Payment Method', tx.paymentMethod,
                      Icons.payment_outlined),
                  if (tx.note.isNotEmpty) ...[
                    const Divider(),
                    _buildDetailRow('Note', tx.note, Icons.notes_outlined),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Prominent Action Buttons (Edit & Delete Forever)
            Row(
              children: [
                // Edit Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(
                      'edit_transaction'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _navigateToEdit,
                  ),
                ),
                const SizedBox(width: 12),
                // Delete Forever Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: const BorderSide(
                          color: AppColors.expense, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: Text(
                      'delete_forever'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _confirmDeleteForever(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondaryLight),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondaryLight, fontSize: 14),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
