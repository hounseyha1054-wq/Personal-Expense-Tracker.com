import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/card_container.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();
    final AuthController authController = Get.find<AuthController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            // User Avatar with Status Indicator
            Obx(() {
              final profileUser = Get.isRegistered<ProfileController>()
                  ? Get.find<ProfileController>().profile.value
                  : null;
              final String rawPhoto = (profileUser?.photoURL.isNotEmpty == true)
                  ? profileUser!.photoURL
                  : (authController.userModel.value?.photoURL.isNotEmpty == true
                      ? authController.userModel.value!.photoURL
                      : (authController.firebaseUser.value?.photoURL ?? ''));

              final photo = ApiConstants.resolveImageUrl(rawPhoto);

              final displayName = (profileUser?.name.isNotEmpty == true)
                  ? profileUser!.name
                  : (authController.userModel.value?.name.isNotEmpty == true
                      ? authController.userModel.value!.name
                      : (authController.firebaseUser.value?.displayName ?? ''));

              final initial = displayName.isNotEmpty
                  ? displayName[0].toUpperCase()
                  : (authController.firebaseUser.value?.email?.isNotEmpty ==
                          true
                      ? authController.firebaseUser.value!.email![0]
                          .toUpperCase()
                      : 'U');

              return GestureDetector(
                onTap: () {
                  controller.changeNavIndex(4);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage:
                            photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? const Color(0xFF0F172A) : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final profileUser = Get.isRegistered<ProfileController>()
                        ? Get.find<ProfileController>().profile.value
                        : null;
                    final name = (profileUser?.name.isNotEmpty == true)
                        ? profileUser!.name
                        : (authController.userModel.value?.name.isNotEmpty ==
                                true
                            ? authController.userModel.value!.name
                            : (authController.firebaseUser.value?.displayName ??
                                'User'));
                    return Text(
                      '${'hello'.tr}, $name',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                  Text(
                    'welcome_back'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 24),
                tooltip: 'Notifications',
                onPressed: () => _showNotificationsSheet(context, isDark),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 24),
            tooltip: 'Refresh',
            onPressed: controller.refreshDashboard,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.summary.value == null) {
          return const LoadingIndicator(
              message: 'Loading financial records...');
        }

        final summary = controller.summary.value;
        final currency = controller.selectedCurrency.value;
        final isHidden = controller.isBalanceHidden.value;

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: ResponsiveContainer(
            maxWidth: 1300,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return _buildWebDashboardGrid(
                    context,
                    controller,
                    summary,
                    currency,
                    isHidden,
                    isDark,
                  );
                }
                return _buildMobileDashboardStack(
                  context,
                  controller,
                  summary,
                  currency,
                  isHidden,
                  isDark,
                );
              },
            ),
          ),
        );
      }),
    );
  }

  /// -------------------------------------------------------------------------
  /// Web & Desktop 2-Column Responsive Dashboard Grid
  /// -------------------------------------------------------------------------
  Widget _buildWebDashboardGrid(
    BuildContext context,
    DashboardController controller,
    dynamic summary,
    String currency,
    bool isHidden,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Wallet Card + Quick Actions + Monthly Budget (58% width)
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDigitalWalletCard(
                    summary: summary,
                    currency: currency,
                    isHidden: isHidden,
                    controller: controller,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 18),
                  _buildQuickActionsRow(currency, controller, isDark),
                  const SizedBox(height: 24),
                  if (controller.budgetSummary.value != null &&
                      controller.budgetSummary.value!.budgets.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'monthly_budget'.tr,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => _showBudgetOverviewSheet(
                              context, controller, currency, isDark),
                          child: Text(
                            'view_all'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildBudgetProgressCard(
                        controller.budgetSummary.value!, currency, isDark),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Right Column: Recent Transactions Activity (42% width)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'recent_transactions'.tr,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          controller.changeNavIndex(1); // Jump to transactions tab
                        },
                        child: Text(
                          'view_all'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (summary?.recentTransactions == null ||
                      summary!.recentTransactions.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    _buildGroupedTransactions(
                        summary.recentTransactions, controller, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// Mobile 1-Column Vertical Dashboard Stack
  /// -------------------------------------------------------------------------
  Widget _buildMobileDashboardStack(
    BuildContext context,
    DashboardController controller,
    dynamic summary,
    String currency,
    bool isHidden,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Digital Wallet Card
          _buildDigitalWalletCard(
            summary: summary,
            currency: currency,
            isHidden: isHidden,
            controller: controller,
            isDark: isDark,
          ),
          const SizedBox(height: 18),

          // 2. Quick Actions Row
          _buildQuickActionsRow(currency, controller, isDark),
          const SizedBox(height: 20),

          // 3. Monthly Budget Overview
          if (controller.budgetSummary.value != null &&
              controller.budgetSummary.value!.budgets.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'monthly_budget'.tr,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _showBudgetOverviewSheet(
                      context, controller, currency, isDark),
                  child: Text(
                    'view_all'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildBudgetProgressCard(
                controller.budgetSummary.value!, currency, isDark),
            const SizedBox(height: 20),
          ],

          // 4. Recent Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'recent_transactions'.tr,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  controller.changeNavIndex(1); // Jump to transactions tab
                },
                child: Text(
                  'view_all'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (summary?.recentTransactions == null ||
              summary!.recentTransactions.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildGroupedTransactions(
                summary.recentTransactions, controller, isDark),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ==========================================================================
  // 1. DIGITAL WALLET CARD COMPONENT
  // ==========================================================================
  Widget _buildDigitalWalletCard({
    required dynamic summary,
    required String currency,
    required bool isHidden,
    required DashboardController controller,
    required bool isDark,
  }) {
    final balanceMinor = summary?.totalBalanceMinor ?? 0;
    final incomeMinor = summary?.totalIncomeMinor ?? 0;
    final expenseMinor = summary?.totalExpenseMinor ?? 0;

    final balanceFormatted = isHidden
        ? '••••••••'
        : CurrencyFormatter.format(balanceMinor, currency: currency);

    final incomeFormatted = isHidden
        ? '••••••'
        : CurrencyFormatter.format(incomeMinor, currency: currency);

    final expenseFormatted = isHidden
        ? '••••••'
        : CurrencyFormatter.format(expenseMinor, currency: currency);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B), // Deep Midnight Indigo
            Color(0xFF312E81),
            Color(0xFF4338CA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle decorative background card aura
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Total Balance label + Privacy Eye + 1-Tap Currency Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'total_balance'.tr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Eye Toggle for Balance Privacy
                        InkWell(
                          onTap: controller.toggleBalanceVisibility,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              isHidden
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 17,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 1-Tap Currency Switcher [$ USD | ៛ KHR]
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCurrencyPill(
                            label: '\$ USD',
                            isSelected: currency == 'USD',
                            onTap: () => controller.setCurrency('USD'),
                          ),
                          _buildCurrencyPill(
                            label: '៛ KHR',
                            isSelected: currency == 'KHR',
                            onTap: () => controller.setCurrency('KHR'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Hero Balance Display
                Text(
                  balanceFormatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom Glassmorphic Card Strip (Income vs Expense)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Income Column
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.south_west_rounded,
                                color: Color(0xFF34D399),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'income'.tr,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    incomeFormatted,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(width: 12),

                      // Expense Column
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.north_east_rounded,
                                color: Color(0xFFF87171),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'expenses'.tr,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    expenseFormatted,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
            color: isSelected ? const Color(0xFF1E1B4B) : Colors.white70,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 2. COMMERCIAL 4-ACTION QUICK BUTTONS ROW
  // ==========================================================================
  Widget _buildQuickActionsRow(
    String currency,
    DashboardController controller,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Action 1: Add Income
        _buildActionItem(
          label: 'quick_action_income'.tr,
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFF10B981),
          bgColor: const Color(0xFF10B981).withValues(alpha: 0.12),
          isDark: isDark,
          onTap: () {
            Get.toNamed(Routes.addEditTransaction, arguments: {
              'type': 'income',
              'currency': currency,
            })?.then((_) => controller.refreshDashboard());
          },
        ),

        // Action 2: Add Expense
        _buildActionItem(
          label: 'quick_action_expense'.tr,
          icon: Icons.remove_circle_outline_rounded,
          color: const Color(0xFFEF4444),
          bgColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
          isDark: isDark,
          onTap: () {
            Get.toNamed(Routes.addEditTransaction, arguments: {
              'type': 'expense',
              'currency': currency,
            })?.then((_) => controller.refreshDashboard());
          },
        ),

        // Action 3: Analytics Tab
        _buildActionItem(
          label: 'quick_action_analytics'.tr,
          icon: Icons.bar_chart_rounded,
          color: AppColors.primary,
          bgColor: AppColors.primary.withValues(alpha: 0.12),
          isDark: isDark,
          onTap: () {
            controller.changeNavIndex(3); // Jump to Analytics tab
          },
        ),

        // Action 4: Budget / Goals
        _buildActionItem(
          label: 'quick_action_budget'.tr,
          icon: Icons.track_changes_rounded,
          color: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
          isDark: isDark,
          onTap: () {
            _showBudgetOverviewSheet(
                Get.context!, controller, currency, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 3. MONTHLY BUDGET CARD
  // ==========================================================================
  Widget _buildBudgetProgressCard(
    BudgetSummaryModel budgetSummary,
    String currency,
    bool isDark,
  ) {
    final double percent =
        (budgetSummary.percentageUsed / 100.0).clamp(0.0, 1.0);
    final Color progressColor = budgetSummary.isOverBudget
        ? const Color(0xFFEF4444)
        : (budgetSummary.isWarning
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981));

    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shield_outlined,
                        color: progressColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Budget: ${CurrencyFormatter.format(budgetSummary.totalBudgetMinor, currency: currency)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${budgetSummary.percentageUsed}% used',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyFormatter.format(budgetSummary.totalSpentMinor, currency: currency)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              Text(
                budgetSummary.isOverBudget
                    ? 'Over by ${CurrencyFormatter.format(budgetSummary.totalSpentMinor - budgetSummary.totalBudgetMinor, currency: currency)}'
                    : 'Remaining: ${CurrencyFormatter.format(budgetSummary.remainingMinor, currency: currency)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: budgetSummary.isOverBudget
                      ? const Color(0xFFEF4444)
                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 4. GROUPED RECENT TRANSACTIONS (Real App Date Grouping)
  // ==========================================================================
  Widget _buildGroupedTransactions(
    List<TransactionModel> txns,
    DashboardController controller,
    bool isDark,
  ) {
    // Group transactions by Date label (Today, Yesterday, Date)
    final Map<String, List<TransactionModel>> grouped = {};
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
      grouped.putIfAbsent(label, () => []).add(tx);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 10, bottom: 6),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            ),
            ...entry.value
                .map((tx) => _buildTransactionCard(tx, controller, isDark)),
          ],
        );
      }).toList(),
    );
  }

  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    TransactionModel tx,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  onPressed: () => Navigator.pop(ctx, false),
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
                  onPressed: () => Navigator.pop(ctx, true),
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

    return confirmed ?? false;
  }

  Widget _buildTransactionCard(
    TransactionModel tx,
    DashboardController controller,
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
        Get.toNamed(Routes.transactionDetail, arguments: tx)?.then((_) {
          controller.refreshDashboard();
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
                  tx.description.isEmpty
                      ? (tx.category?.name ?? 'Transaction')
                      : tx.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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

          const SizedBox(width: 4),

          // 3-dots popup options menu (Edit & Delete Forever)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            onSelected: (action) async {
              if (action == 'edit') {
                Get.toNamed(Routes.addEditTransaction, arguments: tx)
                    ?.then((_) {
                  controller.refreshDashboard();
                });
              } else if (action == 'delete') {
                final confirm =
                    await _showDeleteConfirmationDialog(Get.context!, tx);
                if (confirm) {
                  final txCtrl = Get.isRegistered<TransactionController>()
                      ? Get.find<TransactionController>()
                      : Get.put(TransactionController());
                  await txCtrl.deleteTransaction(tx.id, closeScreen: false);
                  controller.refreshDashboard();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text('edit_transaction'.tr,
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever_rounded,
                        size: 18, color: AppColors.expense),
                    const SizedBox(width: 10),
                    Text(
                      'delete_forever'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.expense,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return CardContainer(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'no_transactions_yet'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'quick_add_hint'.tr,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BUDGET BOTTOM SHEET MODAL (Prevents Broken Route)
  // ==========================================================================
  void _showBudgetOverviewSheet(
    BuildContext context,
    DashboardController controller,
    String currency,
    bool isDark,
  ) {
    final summary = controller.budgetSummary.value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'monthly_budget'.tr,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (summary == null || summary.budgets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No budget limits configured for this month.',
                        style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  )
                else ...[
                  _buildBudgetProgressCard(summary, currency, isDark),
                  const SizedBox(height: 16),
                  const Text(
                    'Category Limits',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: summary.budgets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final b = summary.budgets[index];
                        return CardContainer(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    b.category?.name ?? 'Category',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${b.percentageUsed}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: b.isOverBudget
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (b.percentageUsed / 100.0)
                                      .clamp(0.0, 1.0),
                                  minHeight: 6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    b.isOverBudget
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'notifications'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildNotificationItem(
                        icon: Icons.shield_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'notification_budget_title'.tr,
                        body: 'notification_budget_body'.tr,
                        time: '10m ago',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildNotificationItem(
                        icon: Icons.currency_exchange_rounded,
                        iconColor: const Color(0xFF2563EB),
                        title: 'notification_currency_title'.tr,
                        body: 'notification_currency_body'.tr,
                        time: '2h ago',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildNotificationItem(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'notification_security_title'.tr,
                        body: 'notification_security_body'.tr,
                        time: '1d ago',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
