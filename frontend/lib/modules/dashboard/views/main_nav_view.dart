import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'dashboard_view.dart';
import '../../transactions/views/transactions_view.dart';
import '../../analytics/views/analytics_view.dart';
import '../../profile/views/profile_view.dart';

class MainNavView extends StatelessWidget {
  const MainNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    final List<Widget> pages = [
      const DashboardView(),
      const TransactionsView(),
      const SizedBox.shrink(), // Placeholder for mobile center Add button
      const AnalyticsView(),
      const ProfileView(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= ResponsiveBreakpoints.tabletMin;

        if (isWideScreen) {
          return _buildWebDesktopLayout(context, controller, pages, constraints.maxWidth);
        }

        return _buildMobileLayout(context, controller, pages);
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// Mobile Layout (Bottom Navigation Bar + Centered FAB)
  /// -------------------------------------------------------------------------
  Widget _buildMobileLayout(
    BuildContext context,
    DashboardController controller,
    List<Widget> pages,
  ) {
    return Scaffold(
      body: Obx(() {
        final index = controller.selectedNavIndex.value;
        return IndexedStack(
          index: index == 2 ? 0 : index,
          children: pages,
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(Routes.addEditTransaction)?.then((_) {
            controller.refreshDashboard();
          });
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Obx(() {
        final currentIndex = controller.selectedNavIndex.value;
        return NavigationBar(
          selectedIndex: currentIndex == 2 ? 0 : currentIndex,
          onDestinationSelected: (int index) {
            if (index == 2) {
              Get.toNamed(Routes.addEditTransaction)?.then((_) {
                controller.refreshDashboard();
              });
            } else {
              controller.changeNavIndex(index);
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded),
              label: 'nav_home'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long_rounded),
              label: 'nav_transactions'.tr,
            ),
            NavigationDestination(
              icon: const SizedBox(width: 24),
              label: 'nav_add'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart_rounded),
              label: 'nav_analytics'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: 'nav_profile'.tr,
            ),
          ],
        );
      }),
    );
  }

  /// -------------------------------------------------------------------------
  /// Web & Desktop Layout (Modern Sidebar + Fluid Main Content Area)
  /// -------------------------------------------------------------------------
  Widget _buildWebDesktopLayout(
    BuildContext context,
    DashboardController controller,
    List<Widget> pages,
    double screenWidth,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompactSidebar = screenWidth < ResponsiveBreakpoints.desktopMin;
    final sidebarWidth = isCompactSidebar ? 88.0 : 260.0;

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Brand Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactSidebar ? 12 : 20,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: isCompactSidebar
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (!isCompactSidebar) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ExpenseTracker',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Personal Finance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Quick Action: + New Transaction Button
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactSidebar ? 12 : 16,
                      vertical: 4,
                    ),
                    child: isCompactSidebar
                        ? IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                            ),
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            tooltip: 'add_transaction'.tr,
                            onPressed: () {
                              Get.toNamed(Routes.addEditTransaction)?.then((_) {
                                controller.refreshDashboard();
                              });
                            },
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(
                              'add_transaction'.tr,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Get.toNamed(Routes.addEditTransaction)?.then((_) {
                                controller.refreshDashboard();
                              });
                            },
                          ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 12),

                  // Navigation Links
                  Expanded(
                    child: Obx(() {
                      final activeIndex = controller.selectedNavIndex.value;
                      return ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompactSidebar ? 8 : 12,
                        ),
                        children: [
                          _buildSidebarItem(
                            context: context,
                            icon: Icons.dashboard_rounded,
                            label: 'nav_home'.tr,
                            isSelected: activeIndex == 0,
                            isCompact: isCompactSidebar,
                            isDark: isDark,
                            onTap: () => controller.changeNavIndex(0),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarItem(
                            context: context,
                            icon: Icons.receipt_long_rounded,
                            label: 'nav_transactions'.tr,
                            isSelected: activeIndex == 1,
                            isCompact: isCompactSidebar,
                            isDark: isDark,
                            onTap: () => controller.changeNavIndex(1),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarItem(
                            context: context,
                            icon: Icons.bar_chart_rounded,
                            label: 'nav_analytics'.tr,
                            isSelected: activeIndex == 3,
                            isCompact: isCompactSidebar,
                            isDark: isDark,
                            onTap: () => controller.changeNavIndex(3),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarItem(
                            context: context,
                            icon: Icons.person_rounded,
                            label: 'nav_profile'.tr,
                            isSelected: activeIndex == 4,
                            isCompact: isCompactSidebar,
                            isDark: isDark,
                            onTap: () => controller.changeNavIndex(4),
                          ),
                        ],
                      );
                    }),
                  ),

                  // Sidebar Bottom: Currency Switcher & User Profile Info
                  _buildSidebarFooter(context, controller, isCompactSidebar, isDark),
                ],
              ),
            ),
          ),

          // Main Content View Area
          Expanded(
            child: Obx(() {
              final index = controller.selectedNavIndex.value;
              return IndexedStack(
                index: index == 2 ? 0 : index,
                children: pages,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isCompact,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBg = AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12);
    const activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          mainAxisAlignment:
              isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            if (!isCompact) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? activeColor
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(
    BuildContext context,
    DashboardController controller,
    bool isCompact,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Currency Switcher
          Obx(() {
            final curr = controller.selectedCurrency.value;
            if (isCompact) {
              return IconButton(
                icon: Text(
                  curr == 'USD' ? '\$' : '៛',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                tooltip: 'Switch Currency (USD / KHR)',
                onPressed: () {
                  controller.setCurrency(curr == 'USD' ? 'KHR' : 'USD');
                },
              );
            }
            return Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.setCurrency('USD'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: curr == 'USD' ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '\$ USD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: curr == 'USD' ? Colors.white : (isDark ? Colors.white60 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.setCurrency('KHR'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: curr == 'KHR' ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '៛ KHR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: curr == 'KHR' ? Colors.white : (isDark ? Colors.white60 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (!isCompact) ...[
            const SizedBox(height: 12),
            // User Profile Info
            if (Get.isRegistered<AuthController>())
              Obx(() {
                final auth = Get.find<AuthController>();
                final name = auth.userModel.value?.name ?? 'User';
                final email = auth.userModel.value?.email ?? '';
                final photo = auth.userModel.value?.photoURL;

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      backgroundImage: photo != null && photo.isNotEmpty
                          ? NetworkImage(photo)
                          : null,
                      child: photo == null || photo.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
          ],
        ],
      ),
    );
  }
}
