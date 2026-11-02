import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/auth_controller.dart';

class EmailVerificationView extends StatelessWidget {
  const EmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: controller.logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email Address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => Text(
                  'We sent a verification email to:\n${controller.firebaseUser.value?.email ?? 'your email'}.\n\nPlease click the link in your email inbox to verify.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Refresh Status
              Obx(
                () => CustomButton(
                  text: 'I have verified my email',
                  onPressed: controller.refreshVerificationStatus,
                  isLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 14),

              // Resend Email
              Obx(
                () => CustomButton(
                  text: 'Resend Verification Email',
                  isOutlined: true,
                  onPressed: controller.resendVerificationEmail,
                  isLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 20),

              // Skip / Go to Dashboard
              TextButton(
                onPressed: () => Get.offAllNamed(Routes.mainNav),
                child: const Text('Continue to Dashboard anyway'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
