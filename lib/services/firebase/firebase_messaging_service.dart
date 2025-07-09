import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../utils/logger_util.dart';

// Conditional import
import 'firebase_messaging_stub.dart'
    if (dart.library.io) 'firebase_messaging_impl.dart';

class FirebaseMessagingService {
  String? _token;
  String? get token => _token;

  // Initialize Firebase messaging
  Future<void> initialize() async {
    if (kIsWeb) {
      LoggerUtil.i(
          'FirebaseMessagingService: Web platform detected, skipping initialization');
      return;
    }

    LoggerUtil.i(
        'FirebaseMessagingService: Starting initialization for mobile');
    await initializeMessaging();
  }

  // Send FCM token to server
  Future<void> sendFcmTokenToServer(String authToken) async {
    if (kIsWeb) {
      LoggerUtil.i(
          'FirebaseMessagingService: Web platform detected, skipping sendFcmTokenToServer');
      return;
    }

    await sendTokenToServer(authToken);
  }
}
