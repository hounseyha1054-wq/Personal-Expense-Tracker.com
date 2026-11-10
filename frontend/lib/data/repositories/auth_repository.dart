import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/api_service.dart';

class AuthRepository {
  final FirebaseAuthService _firebaseAuthService;
  final ApiService _apiService;

  AuthRepository(this._firebaseAuthService, this._apiService);

  User? get currentFirebaseUser => _firebaseAuthService.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuthService.authStateChanges;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Synchronize with Express.js MongoDB
    try {
      return await _apiService.syncUser(
        name: cred.user?.displayName,
        photoURL: cred.user?.photoURL,
      );
    } catch (e) {
      debugPrint('[AuthRepository] Backend sync failed, using Firebase profile: $e');
      final u = cred.user;
      return UserModel(
        id: u?.uid,
        firebaseUid: u?.uid ?? '',
        name: u?.displayName ?? '',
        email: u?.email ?? email,
        photoURL: u?.photoURL ?? '',
        emailVerified: u?.emailVerified ?? false,
      );
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _firebaseAuthService.registerWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
    );
    // Synchronize with Express.js MongoDB
    try {
      return await _apiService.syncUser(
        name: name,
        photoURL: cred.user?.photoURL,
      );
    } catch (e) {
      debugPrint('[AuthRepository] Backend sync failed, using Firebase profile: $e');
      final u = cred.user;
      return UserModel(
        id: u?.uid,
        firebaseUid: u?.uid ?? '',
        name: name,
        email: u?.email ?? email,
        photoURL: u?.photoURL ?? '',
        emailVerified: u?.emailVerified ?? false,
      );
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    final cred = await _firebaseAuthService.signInWithGoogle();
    if (cred == null || cred.user == null) {
      return null;
    }
    // Synchronize with Express.js MongoDB
    try {
      return await _apiService.syncUser(
        name: cred.user?.displayName,
        photoURL: cred.user?.photoURL,
      );
    } catch (e) {
      debugPrint('[AuthRepository] Backend sync failed, using Firebase profile: $e');
      final u = cred.user!;
      return UserModel(
        id: u.uid,
        firebaseUid: u.uid,
        name: u.displayName ?? '',
        email: u.email ?? '',
        photoURL: u.photoURL ?? '',
        emailVerified: u.emailVerified,
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuthService.sendPasswordResetEmail(email);
  }

  Future<void> sendEmailVerification() async {
    await _firebaseAuthService.sendEmailVerification();
  }

  Future<User?> reloadUser() async {
    return await _firebaseAuthService.reloadUser();
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _firebaseAuthService.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuthService.signOut();
  }

  Future<UserModel> getMe() async {
    return await _apiService.getMe();
  }

  Future<UserModel> updateProfile({String? name, String? photoURL}) async {
    final updated = await _apiService.updateProfile(name: name, photoURL: photoURL);
    try {
      await _firebaseAuthService.updateProfile(displayName: name, photoURL: photoURL);
    } catch (_) {}
    return updated;
  }

  Future<UserModel> uploadAvatar(File file) async {
    final updated = await _apiService.uploadAvatar(file);
    try {
      await _firebaseAuthService.updateProfile(photoURL: updated.photoURL);
    } catch (_) {}
    return updated;
  }

  Future<UserModel> updatePreferences({required String preferredCurrency}) async {
    return await _apiService.updatePreferences(preferredCurrency: preferredCurrency);
  }
}
