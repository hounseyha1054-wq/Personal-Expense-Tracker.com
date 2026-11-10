import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/card_container.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/analytics_model.dart';
import '../controllers/analytics_controller.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'financial_analytics'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Currency Switcher (USD vs KHR) - strictly separated analysis
          Obx(() {
            final activeCur = controller.selectedCurrency.value;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCurrencyToggleItem(
                      'USD', '\$ USD', activeCur == 'USD', isDark),
                  _buildCurrencyToggleItem(
                      'KHR', '៛ KHR', activeCur == 'KHR', isDark),
                ],
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Select Month & Year',
            onPressed: () => _showMonthYearPickerModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Analytics',
            onPressed: () => controller.loadData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child:
                LoadingIndicator(message: 'Analyzing your financial data...'),
          );
        }

        if (controller.error.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    controller.error.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => controller.loadData(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final currency = controller.selectedCurrency.value;
        final monthlyStats = controller.monthlyStats;
        final breakdown = controller.categoryBreakdown;

        return RefreshIndicator(
          onRefresh: () => controller.loadData(),
          child: ResponsiveContainer(
            maxWidth: 1280,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Year Switcher
                        _buildYearSwitcher(isDark, context),
                        const SizedBox(height: 12),

                        // 2. 12-Month Selector Bar
                        _buildMonthSelectorBar(isDark),
                        const SizedBox(height: 16),

                        // 3. Cash Flow Overview Card
                        _buildAbaCashFlowCard(currency, isDark),
                        const SizedBox(height: 24),

                        // 4. Two-Column Charts Row (Bar Trends & Donut Breakdown)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _build12MonthBarChartSection(
                                  monthlyStats, currency, isDark),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: _buildCategoryBreakdownSection(
                                  breakdown, currency, isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                }

                // Mobile 1-Column Layout
                return ListView(
                  children: [
                    _buildYearSwitcher(isDark, context),
                    const SizedBox(height: 12),
                    _buildMonthSelectorBar(isDark),
                    const SizedBox(height: 16),
                    _buildAbaCashFlowCard(currency, isDark),
                    const SizedBox(height: 20),
                    _build12MonthBarChartSection(monthlyStats, currency, isDark),
                    const SizedBox(height: 24),
                    _buildCategoryBreakdownSection(breakdown, currency, isDark),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        );
      }),
    );
  }

  // --- 1. Year Switcher ---
  Widget _buildYearSwitcher(bool isDark, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                visualDensity: VisualDensity.compact,
                tooltip: 'Previous Year',
                onPressed: () => controller.previousYear(),
              ),
              GestureDetector(
                onTap: () => _showMonthYearPickerModal(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${controller.selectedYear.value}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                visualDensity: VisualDensity.compact,
                tooltip: 'Next Year',
                onPressed: () => controller.nextYear(),
              ),
            ],
          ),
          // Current selected period chip
          InkWell(
            onTap: () => _showMonthYearPickerModal(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    controller.selectedPeriodTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Month Selector Horizontal Carousel (Jan - Dec + All) ---
  Widget _buildMonthSelectorBar(bool isDark) {
    final currentMonth = controller.selectedMonth.value;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 13, // 0 = All, 1..12 = Jan..Dec
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = currentMonth == index;
          final title = AnalyticsController.localizedMonthNamesShort[index];

          return GestureDetector(
            onTap: () => controller.selectMonth(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: index == 0 ? 16 : 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 3. ABA Overview Cash Flow Card ---
  Widget _buildAbaCashFlowCard(String currency, bool isDark) {
    final income = controller.periodIncomeMinor;
    final expense = controller.periodExpenseMinor;
    final balance = controller.periodNetBalanceMinor;
    final savingsRate = controller.periodSavingsRate;
    final isPositive = balance >= 0;
    final dailyAvg = controller.dailyAverageExpenseMinor;
    final txCount = controller.periodTransactionCount;

    return CardContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'net_cash_flow'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.income.withValues(alpha: 0.15)
                      : AppColors.expense.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: isPositive ? AppColors.income : AppColors.expense,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive
                          ? '+${savingsRate.toStringAsFixed(1)}% ${'saved'.tr}'
                          : '${savingsRate.toStringAsFixed(1)}% ${'deficit'.tr}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            isPositive ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}${CurrencyFormatter.format(balance, currency: currency)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isPositive ? AppColors.income : AppColors.expense,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Split columns: Cash In & Cash Out
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_downward_rounded,
                            size: 16, color: AppColors.income),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'cash_in'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(income,
                                    currency: currency),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.income,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                            size: 16, color: AppColors.expense),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'cash_out'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(expense,
                                    currency: currency),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Additional ABA Insight: Daily avg & Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.speed_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${'avg_per_day'.tr}: ${CurrencyFormatter.format(dailyAvg, currency: currency)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.receipt_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$txCount ${'transactions_count'.tr}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. All 12 Months Bar Chart ---
  Widget _build12MonthBarChartSection(
    List<MonthlyStatModel> stats,
    String currency,
    bool isDark,
  ) {
    final activeMonthIndex =
        controller.selectedMonth.value; // 0 for All, 1..12 for Jan..Dec

    // Calculate active month's specific numbers for the live price banner
    int activeMonthIncome = 0;
    int activeMonthExpense = 0;
    String activeMonthTitle = '';

    if (activeMonthIndex == 0) {
      activeMonthTitle = '${'all_12m'.tr} (${controller.selectedYear.value})';
      activeMonthIncome = stats.fold<int>(0, (sum, s) => sum + s.incomeMinor);
      activeMonthExpense = stats.fold<int>(0, (sum, s) => sum + s.expenseMinor);
    } else {
      activeMonthTitle =
          '${AnalyticsController.localizedMonthNamesFull[activeMonthIndex]} ${controller.selectedYear.value}';
      if (activeMonthIndex - 1 < stats.length) {
        final stat = stats[activeMonthIndex - 1];
        activeMonthIncome = stat.incomeMinor;
        activeMonthExpense = stat.expenseMinor;
      }
    }
    final activeMonthNet = activeMonthIncome - activeMonthExpense;
    final isNetPositive = activeMonthNet >= 0;
    final hasAnyData =
        stats.any((s) => s.incomeMinor > 0 || s.expenseMinor > 0);
    final maxY = _calculateMaxY(stats, currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cashflow_graph_12m'.tr,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'tap_inspect_month'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            // Legend
            Row(
              children: [
                _buildLegendItem('in_legend'.tr, AppColors.income),
                const SizedBox(width: 12),
                _buildLegendItem('out_legend'.tr, AppColors.expense),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        CardContainer(
          padding: const EdgeInsets.fromLTRB(10, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Price Header for the inspected month
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.touch_app_rounded,
                                size: 15, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              activeMonthTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          '${'net_label'.tr}: ${isNetPositive ? '+' : ''}${CurrencyFormatter.format(activeMonthNet, currency: currency)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isNetPositive
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Cash In price box
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.income.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_downward_rounded,
                                    size: 14, color: AppColors.income),
                                const SizedBox(width: 4),
                                Text(
                                  '${'in_legend'.tr}: ',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.income,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    CurrencyFormatter.format(activeMonthIncome,
                                        currency: currency),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.income,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cash Out price box
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.expense.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_upward_rounded,
                                    size: 14, color: AppColors.expense),
                                const SizedBox(width: 4),
                                Text(
                                  '${'out_legend'.tr}: ',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.expense,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    CurrencyFormatter.format(activeMonthExpense,
                                        currency: currency),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.expense,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
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

              if (stats.isEmpty)
                const SizedBox(
                  height: 180,
                  child: Center(child: Text('No historical monthly records')),
                )
              else
                SizedBox(
                  height: 230,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchCallback: (event, response) {
                          if (event is FlTapUpEvent && response?.spot != null) {
                            final groupIndex =
                                response!.spot!.touchedBarGroupIndex;
                            if (groupIndex >= 0 && groupIndex < stats.length) {
                              final tappedMonth = groupIndex + 1;
                              controller.selectMonth(tappedMonth);
                            }
                          }
                        },
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex < 0 || groupIndex >= stats.length)
                              return null;
                            final month = stats[groupIndex];
                            final isIncomeRod = rodIndex == 0;
                            final amountMinor = isIncomeRod
                                ? month.incomeMinor
                                : month.expenseMinor;
                            final label = isIncomeRod ? 'Cash In' : 'Cash Out';

                            return BarTooltipItem(
                              '${month.label} (${controller.selectedYear.value})\n$label: ${CurrencyFormatter.format(amountMinor, currency: currency)}\nNet: ${CurrencyFormatter.format(month.netSavingsMinor, currency: currency)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        // Left Y-Axis Price Numbers
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            interval: _calculateInterval(stats, currency),
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  _formatCompactCurrency(value, currency),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Bottom Month Labels
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= stats.length) {
                                return const SizedBox.shrink();
                              }
                              final stat = stats[index];
                              final isMonthActive =
                                  activeMonthIndex == (index + 1);

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  stat.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMonthActive
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                    fontWeight: isMonthActive
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calculateInterval(stats, currency),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(stats.length, (index) {
                        final stat = stats[index];
                        final incomeMajor = currency == 'KHR'
                            ? stat.incomeMinor.toDouble()
                            : (stat.incomeMinor / 100.0);
                        final expenseMajor = currency == 'KHR'
                            ? stat.expenseMinor.toDouble()
                            : (stat.expenseMinor / 100.0);
                        final isMonthActive = activeMonthIndex == (index + 1);

                        return BarChartGroupData(
                          x: index,
                          showingTooltipIndicators: [],
                          barRods: [
                            BarChartRodData(
                              toY: incomeMajor > 0 ? incomeMajor : 0.0,
                              color: isMonthActive
                                  ? AppColors.income
                                  : AppColors.income.withValues(alpha: 0.8),
                              width: 7,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: isDark
                                    ? const Color(0xFF334155)
                                        .withValues(alpha: 0.22)
                                    : const Color(0xFFF1F5F9),
                              ),
                            ),
                            BarChartRodData(
                              toY: expenseMajor > 0 ? expenseMajor : 0.0,
                              color: isMonthActive
                                  ? AppColors.expense
                                  : AppColors.expense.withValues(alpha: 0.8),
                              width: 7,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: isDark
                                    ? const Color(0xFF334155)
                                        .withValues(alpha: 0.22)
                                    : const Color(0xFFF1F5F9),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

              // Helper notice if user has no transactions for the year yet
              if (!hasAnyData) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'no_records_for_year'.tr,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Get.toNamed(Routes.addEditTransaction, arguments: {
                          'currency': currency,
                        }),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text('add_txn'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- 5. Category Breakdown Section ---
  Widget _buildCategoryBreakdownSection(
    List<CategorySpendingModel> breakdown,
    String currency,
    bool isDark,
  ) {
    final isExpense = controller.selectedCategoryType.value == 'expense';
    final totalMinor =
        breakdown.fold<int>(0, (sum, cat) => sum + cat.totalAmountMinor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'category_breakdown'.tr,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  controller.selectedPeriodTitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            // Toggle Expense / Income
            Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _buildTypeTab('expense', 'expense'.tr, isExpense),
                  _buildTypeTab('income', 'income'.tr, !isExpense),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CardContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (controller.isCategoryLoading.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child:
                          LoadingIndicator(message: 'Updating breakdown...')),
                )
              else if (breakdown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 48,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No ${isExpense ? 'expense' : 'income'} transactions in ${controller.selectedPeriodTitle}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Donut Chart
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 54,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                controller.touchedCategoryIndex.value = -1;
                                return;
                              }
                              controller.touchedCategoryIndex.value =
                                  pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                            },
                          ),
                          sections: List.generate(breakdown.length, (i) {
                            final cat = breakdown[i];
                            final isTouched =
                                i == controller.touchedCategoryIndex.value;
                            final radius = isTouched ? 48.0 : 40.0;
                            final color = cat.displayColor;

                            return PieChartSectionData(
                              color: color,
                              value: cat.percentage > 0 ? cat.percentage : 1.0,
                              title: isTouched
                                  ? '${cat.percentage.toStringAsFixed(0)}%'
                                  : '',
                              radius: radius,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }),
                        ),
                      ),
                      // Center Display
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isExpense ? 'Total Out' : 'Total In',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(totalMinor,
                                currency: currency),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Ranked ABA Category Breakdown List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: breakdown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = breakdown[index];
                    final itemColor = item.displayColor;
                    final percent = item.percentage.clamp(0.0, 100.0);
                    final isTouched =
                        index == controller.touchedCategoryIndex.value;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isTouched
                            ? itemColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Rank indicator
                              Container(
                                width: 22,
                                alignment: Alignment.center,
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: index == 0
                                        ? const Color(0xFFF59E0B)
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Category Icon Container
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: itemColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.displayIcon,
                                  size: 18,
                                  color: itemColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Name and transaction count
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.categoryName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${item.transactionCount} transaction${item.transactionCount != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Amount and Percentage Badge
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(
                                        item.totalAmountMinor,
                                        currency: currency),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: itemColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${percent.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: itemColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent / 100.0,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(itemColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- Modal for Month & Year Selection (ABA Grid Style) ---
  void _showMonthYearPickerModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonth = controller.selectedMonth.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final tempYear = controller.selectedYear.value;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Analysis Period',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Year Navigation row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          controller.previousYear();
                          setModalState(() {});
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$tempYear',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () {
                          controller.nextYear();
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // "Whole Year" option button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: currentMonth == 0
                            ? AppColors.primary
                            : Colors.transparent,
                        side: BorderSide(
                          color: currentMonth == 0
                              ? AppColors.primary
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        controller.selectMonth(0);
                        Navigator.of(modalContext).pop();
                      },
                      child: Text(
                        'All 12 Months ($tempYear)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currentMonth == 0
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 12 Months Grid (3 columns x 4 rows)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, i) {
                      final monthNum = i + 1;
                      final isSelected = currentMonth == monthNum;
                      final monthName = AnalyticsController
                          .localizedMonthNamesShort[monthNum];

                      return InkWell(
                        onTap: () {
                          controller.selectMonth(monthNum);
                          Navigator.of(modalContext).pop();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Helpers ---
  Widget _buildTypeTab(String type, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.setCategoryType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCurrencyToggleItem(
      String code, String label, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => controller.setCurrency(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY(List<MonthlyStatModel> stats, String currency) {
    double maxVal = 0;
    final isKhr = currency == 'KHR';
    for (final s in stats) {
      final inc = isKhr ? s.incomeMinor.toDouble() : (s.incomeMinor / 100.0);
      final exp = isKhr ? s.expenseMinor.toDouble() : (s.expenseMinor / 100.0);
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    return maxVal > 0 ? (maxVal * 1.25) : (isKhr ? 1000000.0 : 500.0);
  }

  double _calculateInterval(List<MonthlyStatModel> stats, String currency) {
    final max = _calculateMaxY(stats, currency);
    final interval = max / 4;
    return interval > 0 ? interval : (currency == 'KHR' ? 250000.0 : 100.0);
  }

  String _formatCompactCurrency(double value, String currency) {
    final prefix = currency == 'KHR' ? '' : '\$';
    final suffix = currency == 'KHR' ? ' ៛' : '';

    if (value >= 1000000) {
      return '$prefix${(value / 1000000).toStringAsFixed(1)}M$suffix';
    } else if (value >= 1000) {
      return '$prefix${(value / 1000).toStringAsFixed(0)}k$suffix';
    } else {
      return '$prefix${value.toStringAsFixed(0)}$suffix';
    }
  }
}
