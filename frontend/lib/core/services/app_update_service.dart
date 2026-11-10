import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service responsible for managing Google Play Store in-app updates
/// and Firebase Cloud Messaging (FCM) push notifications for the app.
class AppUpdateService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Holds the current device FCM token for developer testing
  final RxString fcmToken = ''.obs;

  /// Initializes update checks and push notifications.
  Future<AppUpdateService> init() async {
    // 1. Initialize Firebase Push Notifications and listener bindings
    await _initPushNotifications();

    // 2. Check for in-app updates from Google Play Store (non-blocking)
    _checkForPlayStoreUpdate();

    return this;
  }

  /// ---------------------------------------------------------------------------
  /// Play Store In-App Update
  /// ---------------------------------------------------------------------------
  Future<void> _checkForPlayStoreUpdate() async {
    // In-app updates are exclusive to Android devices and are not available on web or iOS
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      debugPrint('[AppUpdateService] Checking for Play Store updates...');
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('[AppUpdateService] Play Store update available. Triggering immediate update...');
        // Perform mandatory immediate full-screen update dialog
        await InAppUpdate.performImmediateUpdate();
      } else {
        debugPrint('[AppUpdateService] App is up to date.');
      }
    } catch (e) {
      // In local development / debug APKs (not downloaded directly from Google Play),
      // the Play Core API returns an error or PlatformException.
      // We gracefully catch and log it so it does not interfere with development.
      debugPrint('[AppUpdateService] In-App Update check skipped or failed: $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// Firebase Push Notifications (FCM)
  /// ---------------------------------------------------------------------------
  Future<void> _initPushNotifications() async {
    try {
      // 1. Request notification permissions (Required for Android 13+ and iOS)
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '[AppUpdateService] Notification permission authorization: ${settings.authorizationStatus}',
      );

      // Enable foreground notification display (shows banner even while inside the app)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Store and print FCM Registration Token for instant testing from Firebase Console
      final String? token = await _messaging.getToken();
      if (token != null) {
        fcmToken.value = token;
      }
      debugPrint('==================== FCM REGISTRATION TOKEN ====================');
      debugPrint('$token');
      debugPrint('================================================================');

      // 2. Subscribe to the 'app_updates' topic for broadcast notifications (Mobile only)
      if (!kIsWeb) {
        await _messaging.subscribeToTopic('app_updates');
        debugPrint('[AppUpdateService] Successfully subscribed to topic "app_updates"');
      }

      // 3. Handle Terminated notification tap (app was completely closed)
      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[AppUpdateService] App launched from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }

      // 4. Handle Background notification tap (app was minimized in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[AppUpdateService] Notification clicked from background state');
        _handleNotificationTap(message);
      });

      // 5. Handle Foreground notifications (app is actively open on screen)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[AppUpdateService] Foreground message received: ${message.notification?.title}',
        );
        if (message.notification != null) {
          Get.snackbar(
            message.notification!.title ?? 'Update Notice',
            message.notification!.body ?? '',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFF1E293B),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 12,
            duration: const Duration(seconds: 5),
            onTap: (_) => _handleNotificationTap(message),
          );
        }
      });
    } catch (e) {
      debugPrint('[AppUpdateService] Error initializing Firebase Messaging: $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// Notification Payload & URL Launcher Handling
  /// ---------------------------------------------------------------------------
  void _handleNotificationTap(RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    debugPrint('[AppUpdateService] Processing notification payload data: $data');

    // Cross-platform store URL support (Google Play Store & Apple App Store)
    String? targetUrl;
    if (defaultTargetPlatform == TargetPlatform.iOS && data.containsKey('appstore_url')) {
      targetUrl = data['appstore_url']?.toString().trim();
    } else if (data.containsKey('playstore_url')) {
      targetUrl = data['playstore_url']?.toString().trim();
    } else if (data.containsKey('store_url')) {
      targetUrl = data['store_url']?.toString().trim();
    } else if (data.containsKey('url')) {
      targetUrl = data['url']?.toString().trim();
    }

    if (targetUrl != null && targetUrl.isNotEmpty) {
      _openExternalUrl(targetUrl);
    }
  }

  /// Opens the external Play Store or website link in an external application
  Future<void> _openExternalUrl(String urlString) async {
    try {
      final Uri? uri = Uri.tryParse(urlString);
      if (uri == null) {
        debugPrint('[AppUpdateService] Invalid URL: $urlString');
        return;
      }

      debugPrint('[AppUpdateService] Launching external URL: $urlString');
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('[AppUpdateService] Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Error launching URL: $e');
    }
  }
}

