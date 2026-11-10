import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> userModel = Rx<UserModel?>(null);

  final RxBool isLoading = false.obs;
  final RxBool isPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<User?>? _authStateSub;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase authentication state changes
    _authStateSub = _authRepo.authStateChanges.listen(_handleAuthStateChange);
  }

  @override
  void onClose() {
    _authStateSub?.cancel();
    super.onClose();
  }

  void _handleAuthStateChange(User? user) {
    firebaseUser.value = user;
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  Future<void> checkInitialAuth() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final currentUser = _authRepo.currentFirebaseUser;
    if (currentUser != null) {
      try {
        // Fetch/sync user profile
        final profile = await _authRepo.getMe();
        userModel.value = profile;
        Get.offAllNamed(Routes.mainNav);
      } catch (e) {
        // If profile fetch fails but user exists, still allow into dashboard or login
        Get.offAllNamed(Routes.mainNav);
      }
    } else {
      final box = GetStorage();
      final hasSeen = box.read<bool>('hasCompletedOnboarding') ??
          box.read<bool>('has_seen_onboarding') ??
          false;
      if (!hasSeen) {
        Get.offAllNamed(Routes.onboarding);
      } else {
        Get.offAllNamed(Routes.login);
      }
    }
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _authRepo.signIn(email: email, password: password);
      userModel.value = user;

      Get.snackbar(
        'Welcome Back',
        'Signed in successfully as ${user.name.isNotEmpty ? user.name : user.email}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );

      Get.offAllNamed(Routes.mainNav);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseAuthError(e);
      Get.snackbar(
        'Login Failed',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = 'Failed to connect to backend server: $e';
      Get.snackbar(
        'Login Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _authRepo.register(
        name: name,
        email: email,
        password: password,
      );
      userModel.value = user;

      Get.snackbar(
        'Registration Successful',
        'Verification email sent. Please check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );

      Get.offAllNamed(Routes.emailVerification);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseAuthError(e);
      Get.snackbar(
        'Registration Failed',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _authRepo.signInWithGoogle();
      if (user != null) {
        userModel.value = user;
        Get.snackbar(
          'Signed In',
          'Successfully connected with Google',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
        Get.offAllNamed(Routes.mainNav);
      }
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseAuthError(e);
      Get.snackbar(
        'Google Sign-In Failed',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      isLoading.value = true;
      await _authRepo.sendPasswordReset(email);
      Get.snackbar(
        'Check Your Email',
        'If an account exists with this email, password reset instructions were sent.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Notice',
        'If an account exists with this email, password reset instructions were sent.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      isLoading.value = true;
      await _authRepo.sendEmailVerification();
      Get.snackbar(
        'Email Sent',
        'Verification link has been resent to your email address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Notice', 'Please wait before requesting another email.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshVerificationStatus() async {
    try {
      isLoading.value = true;
      final reloaded = await _authRepo.reloadUser();
      if (reloaded != null && reloaded.emailVerified) {
        Get.snackbar(
          'Verified',
          'Your email is verified! Welcome.',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
        Get.offAllNamed(Routes.mainNav);
      } else {
        Get.snackbar(
          'Not Verified Yet',
          'Please click the link in your email to verify your account.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;
      await _authRepo.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      Get.snackbar(
        'Password Updated',
        'Your password has been changed successfully.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
      Get.back();
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Update Failed',
        _mapFirebaseAuthError(e),
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepo.signOut();
      userModel.value = null;
      firebaseUser.value = null;
      Get.offAllNamed(Routes.login);
    } catch (e) {
      Get.snackbar(
        'Sign Out Failed',
        'Could not sign out. Please try again. $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'popup-closed-by-user':
        return 'Sign-in window was closed before completing.';
      case 'popup-blocked':
        return 'The Google sign-in popup was blocked by your browser. Please allow popups for this site.';
      case 'unauthorized-domain':
        return 'This domain is not authorized in Firebase Console > Authentication > Settings > Authorized Domains.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password entered.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again before changing password.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
