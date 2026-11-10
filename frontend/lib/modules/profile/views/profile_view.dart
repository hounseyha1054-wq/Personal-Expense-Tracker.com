import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/localization/translation_service.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/card_container.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../controllers/profile_controller.dart';
import '../widgets/export_data_modal.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'profile_settings'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Profile',
            onPressed: () => controller.loadProfile(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: LoadingIndicator(message: 'Loading profile...'));
        }

        final user = controller.profile.value;
        final name =
            user?.name.isNotEmpty == true ? user!.name : 'Financial User';
        final email =
            user?.email.isNotEmpty == true ? user!.email : 'user@example.com';
        final currency = user?.preferredCurrency ?? 'USD';
        final isVerified = user?.emailVerified ?? false;

        return RefreshIndicator(
          onRefresh: () => controller.loadProfile(),
          child: ResponsiveContainer(
            maxWidth: 1100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                if (isWide) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Profile Card + Sign Out (40%)
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _buildProfileHeaderCard(
                                  context,
                                  name,
                                  email,
                                  user?.photoURL,
                                  isVerified,
                                  isDark,
                                ),
                                const SizedBox(height: 20),
                                _buildSignOutButton(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: 28),
                          // Right Column: Preferences, Security, App & Data (60%)
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPreferencesSection(context, currency, isDark),
                                const SizedBox(height: 20),
                                _buildSecuritySection(context, isVerified, isDark),
                                const SizedBox(height: 20),
                                _buildAppDataSection(context, isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Mobile 1-Column Layout
                return ListView(
                  children: [
                    _buildProfileHeaderCard(
                      context,
                      name,
                      email,
                      user?.photoURL,
                      isVerified,
                      isDark,
                    ),
                    const SizedBox(height: 24),
                    _buildPreferencesSection(context, currency, isDark),
                    const SizedBox(height: 20),
                    _buildSecuritySection(context, isVerified, isDark),
                    const SizedBox(height: 20),
                    _buildAppDataSection(context, isDark),
                    const SizedBox(height: 32),
                    _buildSignOutButton(context),
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

  // --------------------------------------------------------------------------
  // Preferences Section
  // --------------------------------------------------------------------------
  Widget _buildPreferencesSection(
      BuildContext context, String currency, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('preferences'.tr),
        const SizedBox(height: 8),
        CardContainer(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              // Currency Setting
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.monetization_on_rounded,
                      color: AppColors.primary, size: 22),
                ),
                title: Text('default_currency'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  currency == 'KHR'
                      ? 'currency_khr_label'.tr
                      : 'currency_usd_label'.tr,
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currency,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                onTap: () => _showCurrencyPicker(context, currency),
              ),
              const Divider(height: 1, indent: 56),

              // Language Setting
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded,
                      color: Colors.teal, size: 22),
                ),
                title: Text('language'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  TranslationService.getLanguageName(
                      TranslationService.currentLanguageCode),
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    TranslationService.currentLanguageCode.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
                onTap: () => _showLanguagePicker(context),
              ),
              const Divider(height: 1, indent: 56),

              // Theme Mode Setting
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.palette_rounded,
                      color: Colors.purple, size: 22),
                ),
                title: Text('appearance'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  controller.selectedTheme.value == 'dark'
                      ? 'theme_dark'.tr
                      : (controller.selectedTheme.value == 'light'
                          ? 'theme_light'.tr
                          : 'theme_system'.tr),
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showThemePicker(context),
              ),
              const Divider(height: 1, indent: 56),

              // Notification Switch
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: Colors.amber, size: 22),
                ),
                title: Text('budget_alerts'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('budget_alerts_sub'.tr,
                    style: const TextStyle(fontSize: 13)),
                value: controller.notificationsEnabled.value,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  controller.notificationsEnabled.value = val;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Security Section
  // --------------------------------------------------------------------------
  Widget _buildSecuritySection(
      BuildContext context, bool isVerified, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('security_account'.tr),
        const SizedBox(height: 8),
        CardContainer(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              // Change Password
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: Colors.blue, size: 22),
                ),
                title: Text('change_password'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('update_security_creds'.tr,
                    style: const TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showChangePasswordModal(context),
              ),
              const Divider(height: 1, indent: 56),

              // Email Verification
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? AppColors.income.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isVerified
                        ? Icons.verified_user_rounded
                        : Icons.mark_email_unread_rounded,
                    color: isVerified ? AppColors.income : Colors.orange,
                    size: 22,
                  ),
                ),
                title: Text('email_status'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isVerified
                      ? 'verified_account'.tr
                      : 'unverified_account'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: isVerified ? AppColors.income : Colors.orange,
                  ),
                ),
                trailing: isVerified
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.income)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () =>
                                controller.checkEmailVerificationStatus(),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Check',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () =>
                                controller.resendVerificationEmail(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Verify',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // App & Data Section
  // --------------------------------------------------------------------------
  Widget _buildAppDataSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('APP & DATA'),
        const SizedBox(height: 8),
        CardContainer(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: Colors.teal, size: 22),
                ),
                title: Text('export_data'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('export_subtitle'.tr,
                    style: const TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => ExportDataModal.show(context),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_stories_rounded,
                      color: AppColors.primary, size: 22),
                ),
                title: Text('view_onboarding'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('view_onboarding_sub'.tr,
                    style: const TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Get.toNamed(Routes.onboarding),
              ),
              if (Get.isRegistered<AppUpdateService>()) ...[
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: Colors.amber, size: 22),
                  ),
                  title: const Text('FCM Device Token',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Obx(() {
                    final token =
                        Get.find<AppUpdateService>().fcmToken.value;
                    return Text(
                      token.isNotEmpty
                          ? '${token.substring(0, token.length > 22 ? 22 : token.length)}...'
                          : 'Tap to fetch token',
                      style: const TextStyle(fontSize: 12),
                    );
                  }),
                  trailing: ElevatedButton.icon(
                    onPressed: () async {
                      final service = Get.find<AppUpdateService>();
                      var token = service.fcmToken.value;
                      if (token.isEmpty) {
                        token =
                            await FirebaseMessaging.instance.getToken() ??
                                '';
                        service.fcmToken.value = token;
                      }
                      if (token.isNotEmpty) {
                        await Clipboard.setData(
                            ClipboardData(text: token));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('FCM Token copied to clipboard!'),
                              backgroundColor: AppColors.income,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded, size: 22),
                ),
                title: const Text('Version',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('1.0.0 (Production Build)',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Sign Out Button
  // --------------------------------------------------------------------------
  Widget _buildSignOutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmSignOut(context),
      icon: const Icon(Icons.logout_rounded, color: AppColors.expense),
      label: Text(
        'sign_out'.tr,
        style: const TextStyle(
          color: AppColors.expense,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side:
            BorderSide(color: AppColors.expense.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&auto=format&fit=crop&q=80',
  ];

  Widget _buildProfileHeaderCard(
    BuildContext context,
    String name,
    String email,
    String? photoURL,
    bool isVerified,
    bool isDark,
  ) {
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    final resolvedPhoto = ApiConstants.resolveImageUrl(photoURL);
    final hasPhoto = resolvedPhoto.isNotEmpty;

    return CardContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar with camera badge
          GestureDetector(
            onTap: () => _showEditProfileSheet(context, name, photoURL),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? Image.network(
                            resolvedPhoto,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildInitialsWidget(initials),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildInitialsWidget(initials),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          color: AppColors.income, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showEditProfileSheet(context, name, photoURL),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'edit_profile'.tr,
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
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsWidget(String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  void _showEditProfileSheet(
    BuildContext context,
    String currentName,
    String? currentPhoto,
  ) {
    final nameController = TextEditingController(text: currentName);
    final urlController = TextEditingController(text: currentPhoto ?? '');
    String selectedPhoto = (currentPhoto ?? '').trim();
    bool isSaving = false;
    bool isUploadingPhone = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final initials = currentName.isNotEmpty
        ? currentName
            .trim()
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset =
                MediaQuery.of(bottomSheetContext).viewInsets.bottom;
            final resolvedPreview =
                ApiConstants.resolveImageUrl(selectedPhoto);

            return Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(bottomSheetContext).size.height * 0.90,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title & Close Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'edit_profile'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              splashRadius: 20,
                              onPressed: () =>
                                  Navigator.of(bottomSheetContext).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Live Avatar Preview with Uploading Overlay
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: resolvedPreview.isNotEmpty
                                      ? Image.network(
                                          resolvedPreview,
                                          width: 88,
                                          height: 88,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              _buildInitialsWidget(initials),
                                          loadingBuilder:
                                              (ctx, child, progress) {
                                            if (progress == null) return child;
                                            return const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : _buildInitialsWidget(initials),
                                ),
                              ),
                              if (isUploadingPhone)
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 1. Upload from Phone Action Buttons
                        Text(
                          'upload_photo'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Gallery button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isUploadingPhone || isSaving
                                    ? null
                                    : () async {
                                        setSheetState(() => isUploadingPhone = true);
                                        final ok = await controller
                                            .uploadAvatarFromDevice(ImageSource.gallery);
                                        if (ok) {
                                          final newUrl =
                                              controller.profile.value?.photoURL ?? '';
                                          setSheetState(() {
                                            selectedPhoto = newUrl;
                                            urlController.text = newUrl;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('photo_upload_success'.tr),
                                                backgroundColor: AppColors.income,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                        setSheetState(() => isUploadingPhone = false);
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.photo_library_rounded,
                                    size: 18, color: AppColors.primary),
                                label: Text(
                                  'choose_from_gallery'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Camera button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isUploadingPhone || isSaving
                                    ? null
                                    : () async {
                                        setSheetState(() => isUploadingPhone = true);
                                        final ok = await controller
                                            .uploadAvatarFromDevice(ImageSource.camera);
                                        if (ok) {
                                          final newUrl =
                                              controller.profile.value?.photoURL ?? '';
                                          setSheetState(() {
                                            selectedPhoto = newUrl;
                                            urlController.text = newUrl;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('photo_upload_success'.tr),
                                                backgroundColor: AppColors.income,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                        setSheetState(() => isUploadingPhone = false);
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.camera_alt_rounded,
                                    size: 18, color: AppColors.primary),
                                label: Text(
                                  'take_photo'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // 2. Choose Preset Avatar
                        Text(
                          'choose_avatar'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _presetAvatars.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final avatarUrl = _presetAvatars[index];
                              final isSelected = selectedPhoto == avatarUrl;

                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedPhoto = avatarUrl;
                                    urlController.text = avatarUrl;
                                  });
                                },
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: ClipOval(
                                      child: Image.network(
                                        avatarUrl,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            Container(
                                          color: Colors.grey.shade400,
                                          child: const Icon(
                                              Icons.person_rounded,
                                              size: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Display Name
                        CustomTextField(
                          controller: nameController,
                          label: 'edit_profile_name'.tr,
                          hint: 'name'.tr,
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),

                        // 4. Custom Image URL
                        CustomTextField(
                          controller: urlController,
                          label: 'custom_image_url'.tr,
                          hint: 'image_url_hint'.tr,
                          prefixIcon: Icons.link_rounded,
                          suffixIcon: urlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    setSheetState(() {
                                      urlController.clear();
                                      selectedPhoto = '';
                                    });
                                  },
                                )
                              : null,
                          onChanged: (val) {
                            setSheetState(() {
                              selectedPhoto = val.trim();
                            });
                          },
                        ),
                        const SizedBox(height: 8),

                        // Remove Photo Button (if photo exists)
                        if (selectedPhoto.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  selectedPhoto = '';
                                  urlController.clear();
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: AppColors.expense),
                              label: Text(
                                'remove_photo'.tr,
                                style: const TextStyle(
                                  color: AppColors.expense,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Save Button
                        CustomButton(
                          text: 'save_changes'.tr,
                          isLoading: isSaving,
                          icon: Icons.check_rounded,
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            if (newName.isEmpty) return;

                            setSheetState(() => isSaving = true);
                            final success =
                                await controller.updateProfileData(
                              name: newName,
                              photoURL: selectedPhoto,
                            );

                            if (bottomSheetContext.mounted) {
                              Navigator.of(bottomSheetContext).pop();
                            }

                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'profile_updated_successfully'.tr),
                                  backgroundColor: AppColors.income,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context, String currentCurrency) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Preferred Currency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'This affects formatting of your dashboard, reports, and charts.',
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Text('\$',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              title: const Text('US Dollar (USD)'),
              trailing: currentCurrency == 'USD'
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary)
                  : null,
              onTap: () {
                Get.back();
                controller.updatePreferredCurrency('USD');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Text('៛',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              title: const Text('Cambodian Riel (KHR)'),
              trailing: currentCurrency == 'KHR'
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary)
                  : null,
              onTap: () {
                Get.back();
                controller.updatePreferredCurrency('KHR');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.brightness_auto_rounded),
              title: const Text('System Default'),
              trailing: controller.selectedTheme.value == 'system'
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary)
                  : null,
              onTap: () {
                Get.back();
                controller.setThemeMode('system');
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_rounded),
              title: const Text('Light Mode'),
              trailing: controller.selectedTheme.value == 'light'
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary)
                  : null,
              onTap: () {
                Get.back();
                controller.setThemeMode('light');
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: const Text('Dark Mode'),
              trailing: controller.selectedTheme.value == 'dark'
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary)
                  : null,
              onTap: () {
                Get.back();
                controller.setThemeMode('dark');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final activeCode = TranslationService.currentLanguageCode;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_language'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'language'.tr,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 18),
            ...TranslationService.languages.map((lang) {
              final isSelected = activeCode == lang['code'];
              return Column(
                children: [
                  ListTile(
                    leading: Text(
                      lang['flag'] ?? '',
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(
                      lang['name'] ?? '',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      lang['englishName'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary)
                        : null,
                    onTap: () async {
                      Get.back();
                      await TranslationService.changeLocale(lang['code']!);
                      Get.snackbar(
                        'language'.tr,
                        'language_updated'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.teal.shade700,
                        colorText: Colors.white,
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your current password and a new secure password.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: currentPassController,
                label: 'Current Password',
                hint: '••••••••',
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Enter current password';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: newPassController,
                label: 'New Password',
                hint: 'At least 6 characters',
                obscureText: true,
                prefixIcon: Icons.vpn_key_rounded,
                validator: (val) {
                  if (val == null || val.length < 6)
                    return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: confirmPassController,
                label: 'Confirm New Password',
                hint: 'Re-enter new password',
                obscureText: true,
                prefixIcon: Icons.check_circle_outline_rounded,
                validator: (val) {
                  if (val != newPassController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Update Password',
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Get.back();
                    await controller.changePassword(
                      currentPassController.text,
                      newPassController.text,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You will need to sign in again to access your financial records.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
