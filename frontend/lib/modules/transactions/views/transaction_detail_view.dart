import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/card_container.dart';
import '../controllers/transaction_controller.dart';

class TransactionDetailView extends StatelessWidget {
  const TransactionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final String transactionId = Get.arguments as String;
    final TransactionController controller = Get.find<TransactionController>();

    final tx = controller.transactions.firstWhereOrNull((t) => t.id == transactionId);

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(title: Text('transaction_details'.tr)),
        body: const Center(child: Text('Transaction not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('transaction_details'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'edit_transaction'.tr,
            onPressed: () {
              Get.toNamed(Routes.addEditTransaction, arguments: tx);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expense),
            tooltip: 'delete_transaction'.tr,
            onPressed: () => _confirmDelete(context, controller, tx.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      color: tx.category?.displayColor.withValues(alpha: 0.12) ??
                          (tx.isExpense ? AppColors.expenseLight : AppColors.incomeLight),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tx.category?.displayIcon ?? (tx.isExpense ? Icons.shopping_bag : Icons.attach_money),
                      color: tx.category?.displayColor ?? (tx.isExpense ? AppColors.expense : AppColors.income),
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
                    tx.description,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: tx.isIncome ? AppColors.incomeLight : AppColors.expenseLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tx.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: tx.isIncome ? AppColors.income : AppColors.expense,
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
                  _buildDetailRow('Category', tx.category?.name ?? 'General', Icons.category_outlined),
                  const Divider(),
                  _buildDetailRow('Date', DateFormatter.formatFullDate(tx.transactionDate), Icons.calendar_today_outlined),
                  const Divider(),
                  _buildDetailRow('Time', DateFormatter.formatTime(tx.transactionDate), Icons.access_time_outlined),
                  const Divider(),
                  _buildDetailRow('Payment Method', tx.paymentMethod, Icons.payment_outlined),
                  if (tx.note.isNotEmpty) ...[
                    const Divider(),
                    _buildDetailRow('Note', tx.note, Icons.notes_outlined),
                  ],
                ],
              ),
            ),
          ],
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
            style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
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

  void _confirmDelete(BuildContext context, TransactionController controller, String txId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_transaction'.tr),
        content: Text('confirm_delete'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteTransaction(txId);
            },
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}
