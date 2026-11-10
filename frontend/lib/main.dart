import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/localization/translation_service.dart';
import 'core/network/api_client.dart';
import 'core/services/app_update_service.dart';
import 'data/repositories/analytics_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/firebase_auth_service.dart';
import 'firebase_options.dart';
import 'modules/analytics/controllers/analytics_controller.dart';
import 'modules/analytics/views/analytics_view.dart';
import 'modules/auth/bindings/auth_binding.dart';
import 'modules/auth/views/email_verification_view.dart';
import 'modules/auth/views/forgot_password_view.dart';
import 'modules/auth/views/login_view.dart';
import 'modules/auth/views/register_view.dart';
import 'modules/auth/views/splash_view.dart';
import 'modules/onboarding/views/onboarding_view.dart';
import 'modules/dashboard/bindings/dashboard_binding.dart';
import 'modules/dashboard/views/dashboard_view.dart';
import 'modules/dashboard/views/main_nav_view.dart';
import 'modules/profile/views/profile_view.dart';
import 'modules/transactions/bindings/transaction_binding.dart';
import 'modules/transactions/views/add_edit_transaction_view.dart';
import 'modules/transactions/views/transaction_detail_view.dart';
import 'modules/transactions/views/transactions_view.dart';

/// Mandatory top-level background message handler for Firebase Messaging.
/// Annotated with @pragma('vm:entry-point') so it is not stripped away by the Dart compiler.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[FCM Background] Message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background message handler on native platforms (handled by Service Worker on Web)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Inject the AppUpdateService for Play Store in-app updates and FCM notifications
  await Get.putAsync<AppUpdateService>(() => AppUpdateService().init());

  final apiClient = ApiClient();
  final apiService = ApiService(apiClient);
  final firebaseAuthService = FirebaseAuthService();

  Get.put<ApiClient>(apiClient, permanent: true);
  Get.put<ApiService>(apiService, permanent: true);
  Get.put<FirebaseAuthService>(firebaseAuthService, permanent: true);
  Get.put<AuthRepository>(
    AuthRepository(firebaseAuthService, apiService),
    permanent: true,
  );
  Get.put<AnalyticsRepository>(AnalyticsRepository(apiService),
      permanent: true);
  Get.put<BudgetRepository>(BudgetRepository(apiService), permanent: true);
  Get.put<CategoryRepository>(CategoryRepository(apiService), permanent: true);
  Get.put<TransactionRepository>(TransactionRepository(apiService),
      permanent: true);

  runApp(const MyApp());
}

class WebAppScrollBehavior extends MaterialScrollBehavior {
  const WebAppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ExpenseTracker',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const WebAppScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      translations: AppTranslations(),
      locale: TranslationService.currentLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: Routes.splash,
      getPages: [
        GetPage(
          name: Routes.splash,
          page: () => const SplashView(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: Routes.onboarding,
          page: () => const OnboardingView(),
        ),
        GetPage(
          name: Routes.login,
          page: () => const LoginView(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: Routes.register,
          page: () => const RegisterView(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: Routes.forgotPassword,
          page: () => const ForgotPasswordView(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: Routes.emailVerification,
          page: () => const EmailVerificationView(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: Routes.mainNav,
          page: () => const MainNavView(),
          binding: DashboardBinding(),
        ),
        GetPage(
          name: Routes.dashboard,
          page: () => const DashboardView(),
          binding: DashboardBinding(),
        ),
        GetPage(
          name: Routes.transactions,
          page: () => const TransactionsView(),
          binding: DashboardBinding(),
        ),
        GetPage(
          name: Routes.analytics,
          page: () => const AnalyticsView(),
          binding: BindingsBuilder(() {
            Get.put(AnalyticsController());
          }),
        ),
        GetPage(
          name: Routes.profile,
          page: () => const ProfileView(),
          binding: DashboardBinding(),
        ),
        GetPage(
          name: Routes.addEditTransaction,
          page: () => const AddEditTransactionView(),
          binding: TransactionBinding(),
        ),
        GetPage(
          name: Routes.transactionDetail,
          page: () => const TransactionDetailView(),
          binding: TransactionBinding(),
        ),
      ],
    );
  }
}
