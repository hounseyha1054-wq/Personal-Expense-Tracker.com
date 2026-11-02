import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class ProfileController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  final Rx<UserModel?> profile = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;

  // Settings & Toggles
  final RxString selectedTheme = 'system'.obs; // 'light', 'dark', 'system'
  final RxBool notificationsEnabled = true.obs;
  final RxBool biometricsEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final user = await _authRepository.getMe();
      profile.value = user;
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().userModel.value = user;
      }
    } catch (_) {
      // Fallback to AuthController user if available
      if (Get.isRegistered<AuthController>()) {
        profile.value = Get.find<AuthController>().userModel.value;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfileData({String? name, String? photoURL}) async {
    try {
      isUpdating.value = true;
      final updated = await _authRepository.updateProfile(
        name: name?.trim(),
        photoURL: photoURL,
      );
      profile.value = updated;
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().userModel.value = updated;
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updateName(String newName) async {
    if (newName.trim().isEmpty) return false;
    return await updateProfileData(name: newName);
  }

  Future<bool> updatePhoto(String? newPhotoUrl) async {
    return await updateProfileData(photoURL: newPhotoUrl ?? '');
  }

  Future<bool> uploadAvatarFromDevice(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return false;

      isUpdating.value = true;
      final file = File(picked.path);
      final updated = await _authRepository.uploadAvatar(file);
      profile.value = updated;
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().userModel.value = updated;
      }
      return true;
    } catch (e) {
      debugPrint('[ProfileController] uploadAvatar error: $e');
      String msg = 'photo_upload_failed'.tr;
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('connection') ||
          errStr.contains('refused') ||
          errStr.contains('failed host lookup') ||
          errStr.contains('network is unreachable')) {
        msg = 'Cannot reach backend server. Please verify backend is running.';
      } else if (errStr.contains('permission') || errStr.contains('denied')) {
        msg = 'Camera or storage permission was denied.';
      }

      Get.snackbar(
        'upload_photo'.tr,
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> updatePreferredCurrency(String currency) async {
    try {
      isUpdating.value = true;
      final updated = await _authRepository.updatePreferences(preferredCurrency: currency);
      profile.value = updated;
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().userModel.value = updated;
      }
      if (Get.isRegistered<AnalyticsController>()) {
        Get.find<AnalyticsController>().setCurrency(currency);
      }
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      if (Get.isRegistered<TransactionController>()) {
        Get.find<TransactionController>().setCurrency(currency);
      }
      Get.snackbar(
        'Currency Updated',
        'Default currency set to $currency',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update currency: $e');
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      isUpdating.value = true;
      await _authRepository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      Get.snackbar(
        'Password Changed',
        'Your password has been changed successfully.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Password Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Notice',
          'Please re-login to verify your email address.',
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
        return;
      }

      await user.reload();
      if (user.emailVerified) {
        profile.value = profile.value?.copyWith(emailVerified: true);
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().userModel.value =
              Get.find<AuthController>().userModel.value?.copyWith(emailVerified: true);
        }
        Get.snackbar(
          'Email Verified',
          'Your email is already verified!',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
        return;
      }

      await user.sendEmailVerification();
      Get.snackbar(
        'Verification Sent',
        'Link sent to ${user.email}. Check your Inbox and Spam/Junk folder!',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[ProfileController] sendEmailVerification error: ${e.code} - ${e.message}');
      if (e.code == 'too-many-requests') {
        Get.snackbar(
          'Email Already Sent',
          'A link was sent recently. Please check your Spam/Junk folder or wait a moment.',
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Notice',
          e.message ?? 'Failed to send verification link.',
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('Notice', 'Please check your Spam/Junk folder.');
    }
  }

  Future<void> checkEmailVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          profile.value = profile.value?.copyWith(emailVerified: true);
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().userModel.value =
                Get.find<AuthController>().userModel.value?.copyWith(emailVerified: true);
          }
          Get.snackbar(
            'Verified!',
            'Your email is verified successfully.',
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white,
          );
          return;
        }
      }
      Get.snackbar(
        'Not Yet Verified',
        'Please click the link in your email (check Spam folder), then try again.',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
    } catch (_) {}
  }

  void setThemeMode(String mode) {
    selectedTheme.value = mode;
    switch (mode) {
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      default:
        Get.changeThemeMode(ThemeMode.system);
    }
  }

  Future<void> logout() async {
    await Get.find<AuthController>().logout();
  }
}
