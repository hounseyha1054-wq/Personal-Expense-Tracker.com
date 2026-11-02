import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
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
      const SizedBox.shrink(), // Placeholder for center Add button
      const AnalyticsView(),
      const ProfileView(),
    ];

    return Scaffold(
      body: Obx(() {
        final index = controller.selectedNavIndex.value;
        return IndexedStack(
          index: index == 2 ? 0 : index, // Add tab triggers action instead of staying on blank
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
              // Open add transaction
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
}
