import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/card_container.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/transaction_model.dart';
import '../controllers/transaction_controller.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  final TransactionController controller = Get.find<TransactionController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (controller.currentPage.value < controller.totalPages.value &&
          !controller.isLoading.value) {
        controller.fetchNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('transactions'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'sort_by'.tr,
            onPressed: () => _showSortModal(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'filter_date_range'.tr,
            onPressed: () => _pickDateRange(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'search_description'.tr,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        controller.setSearch('');
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                controller.setSearch(val);
              },
            ),
          ),

          // Currency Filter Segmented Switcher (All / USD / KHR)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Obx(
                () => Row(
                  children: [
                    _buildCurrencyFilterSegment(
                        controller, '', 'all_currencies'.tr, isDark),
                    _buildCurrencyFilterSegment(
                        controller, 'USD', '\$ USD', isDark),
                    _buildCurrencyFilterSegment(
                        controller, 'KHR', '៛ KHR', isDark),
                  ],
                ),
              ),
            ),
          ),

          // Filter Chips (All Types, Income, Expense, Category)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Obx(
              () => Row(
                children: [
                  ChoiceChip(
                    label: Text('all_types'.tr),
                    selected: controller.selectedType.value.isEmpty,
                    onSelected: (selected) {
                      if (selected) controller.setTypeFilter('');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('income'.tr),
                    selected: controller.selectedType.value == 'income',
                    selectedColor: AppColors.incomeLight,
                    onSelected: (selected) {
                      controller.setTypeFilter(selected ? 'income' : '');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('expenses'.tr),
                    selected: controller.selectedType.value == 'expense',
                    selectedColor: AppColors.expenseLight,
                    onSelected: (selected) {
                      controller.setTypeFilter(selected ? 'expense' : '');
                    },
                  ),
                  const SizedBox(width: 8),
                  // Category Dropdown Filter Chip
                  ActionChip(
                    avatar: const Icon(Icons.filter_list, size: 16),
                    label: Text(
                      controller.selectedCategoryId.value.isEmpty
                          ? 'category'.tr
                          : controller.categories
                              .firstWhere(
                                (c) =>
                                    c.id == controller.selectedCategoryId.value,
                                orElse: () => controller.categories.first,
                              )
                              .name,
                    ),
                    onPressed: () =>
                        _showCategoryFilterModal(context, controller),
                  ),
                  if (controller.selectedStartDate.value != null) ...[
                    const SizedBox(width: 8),
                    InputChip(
                      label: Text(
                        '${DateFormatter.formatShortDate(controller.selectedStartDate.value!)} - ${controller.selectedEndDate.value != null ? DateFormatter.formatShortDate(controller.selectedEndDate.value!) : ''}',
                      ),
                      onDeleted: () {
                        controller.setDateRange(null, null);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Transactions List with Date Grouping & Infinite Scroll
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.transactions.isEmpty) {
                return const LoadingIndicator(
                    message: 'Loading transactions...');
              }

              if (controller.transactions.isEmpty) {
                return EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'no_transactions_found'.tr,
                  description: 'no_transactions_desc'.tr,
                  actionText: 'add_transaction'.tr,
                  onAction: () => Get.toNamed(Routes.addEditTransaction),
                );
              }

              final grouped = _groupTransactions(controller.transactions);

              return RefreshIndicator(
                onRefresh: () => controller.fetchTransactions(refresh: true),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: grouped.length +
                      (controller.currentPage.value <
                              controller.totalPages.value
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (index == grouped.length) {
                      // Bottom loading spinner when fetching next page
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      );
                    }

                    final group = grouped[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 4, top: 10, bottom: 4),
                          child: Text(
                            group.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        ...group.items.map((tx) =>
                            _buildTransactionCard(tx, controller, isDark)),
                      ],
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Group transactions by date
  List<_DateGroup> _groupTransactions(List<TransactionModel> txns) {
    final Map<String, List<TransactionModel>> map = {};
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    for (final tx in txns) {
      final d = tx.transactionDate;
      final dStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      String label;
      if (dStr == todayStr) {
        label = 'today'.tr;
      } else if (dStr == yesterdayStr) {
        label = 'yesterday'.tr;
      } else {
        label = DateFormatter.formatShortDate(d);
      }
      map.putIfAbsent(label, () => []).add(tx);
    }

    return map.entries
        .map((e) => _DateGroup(label: e.key, items: e.value))
        .toList();
  }

  Widget _buildTransactionCard(
    TransactionModel tx,
    TransactionController controller,
    bool isDark,
  ) {
    final isIncome = tx.isIncome;
    final isKhr = tx.currency == 'KHR';
    final amountColor =
        isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return CardContainer(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {
        Get.toNamed(Routes.transactionDetail, arguments: tx.id)?.then((_) {
          controller.fetchTransactions();
        });
      },
      child: Row(
        children: [
          // Squircle Category Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tx.category?.displayColor.withValues(alpha: 0.12) ??
                  (isIncome
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFEF4444).withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tx.category?.displayIcon ??
                  (isIncome
                      ? Icons.attach_money_rounded
                      : Icons.shopping_bag_rounded),
              color: tx.category?.displayColor ?? amountColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Category details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      tx.category?.name ?? 'General',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    if (tx.paymentMethod.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tx.paymentMethod,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Amount & Currency Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amountMinor, currency: tx.currency)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isKhr
                      ? const Color(0xFFEA580C).withValues(alpha: 0.12)
                      : const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx.currency,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isKhr
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyFilterSegment(
    TransactionController controller,
    String code,
    String label,
    bool isDark,
  ) {
    final isSelected = controller.selectedCurrency.value == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setCurrency(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  void _showSortModal(BuildContext context, TransactionController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'sort_by'.tr,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Date (Newest First)'),
                  trailing: controller.sortBy.value == 'transactionDate' &&
                          controller.sortOrder.value == 'desc'
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.sortBy.value = 'transactionDate';
                    controller.sortOrder.value = 'desc';
                    controller.fetchTransactions(refresh: true);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date (Oldest First)'),
                  trailing: controller.sortBy.value == 'transactionDate' &&
                          controller.sortOrder.value == 'asc'
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.sortBy.value = 'transactionDate';
                    controller.sortOrder.value = 'asc';
                    controller.fetchTransactions(refresh: true);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_upward_rounded),
                  title: const Text('Amount (Highest First)'),
                  trailing: controller.sortBy.value == 'amountMinor' &&
                          controller.sortOrder.value == 'desc'
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.sortBy.value = 'amountMinor';
                    controller.sortOrder.value = 'desc';
                    controller.fetchTransactions(refresh: true);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_downward_rounded),
                  title: const Text('Amount (Lowest First)'),
                  trailing: controller.sortBy.value == 'amountMinor' &&
                          controller.sortOrder.value == 'asc'
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.sortBy.value = 'amountMinor';
                    controller.sortOrder.value = 'asc';
                    controller.fetchTransactions(refresh: true);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryFilterModal(
    BuildContext context,
    TransactionController controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Filter by Category',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.all_inclusive_rounded),
                  title: const Text('All Categories'),
                  trailing: controller.selectedCategoryId.value.isEmpty
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.setCategoryFilter('');
                    Navigator.of(ctx).pop();
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.categories.length,
                    itemBuilder: (_, index) {
                      final cat = controller.categories[index];
                      final isSelected =
                          controller.selectedCategoryId.value == cat.id;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cat.displayColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.displayIcon,
                              color: cat.displayColor, size: 20),
                        ),
                        title: Text(cat.name),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.primary)
                            : null,
                        onTap: () {
                          controller.setCategoryFilter(cat.id);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    TransactionController controller,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: controller.selectedStartDate.value != null &&
              controller.selectedEndDate.value != null
          ? DateTimeRange(
              start: controller.selectedStartDate.value!,
              end: controller.selectedEndDate.value!,
            )
          : null,
    );

    if (picked != null) {
      controller.setDateRange(picked.start, picked.end);
    }
  }
}

class _DateGroup {
  final String label;
  final List<TransactionModel> items;

  _DateGroup({required this.label, required this.items});
}
