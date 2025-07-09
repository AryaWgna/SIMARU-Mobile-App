import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../../utils/logger_util.dart';

// Define your notification channel
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

// Initialize FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// This is needed to receive notifications when app is in background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  LoggerUtil.d('Background message: ${message.notification?.title}');
}

// Mobile implementation
Future<void> initializeMessaging() async {
  String? _token;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  try {
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      LoggerUtil.i('Firebase not initialized, initializing now');
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } else {
      LoggerUtil.d('Firebase already initialized');
    }

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      LoggerUtil.i('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      LoggerUtil.i('User granted provisional permission');
    } else {
      LoggerUtil.w('User declined or has not accepted permission');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Set up foreground notification presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notification channel
    await _setupLocalNotifications();

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification click when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Get the token
    _token = await _messaging.getToken();
    LoggerUtil.d('FCM Token obtained: ${_token != null ? 'yes' : 'no'}');
    if (_token != null) {
      LoggerUtil.d('FCM Token length: ${_token.length}');
    }

    // Save token to shared preferences
    if (_token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _token);
      LoggerUtil.i('Token saved to SharedPreferences');
    }

    // Setup token refresh listener
    _messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      LoggerUtil.i('FCM Token refreshed');
      _saveTokenToSharedPreferences(newToken);
    });

    LoggerUtil.i('Firebase Messaging initialization complete');
  } catch (e) {
    LoggerUtil.e('Error during Firebase Messaging initialization', e,
        StackTrace.current);
  }
}

// Setup local notifications
Future<void> _setupLocalNotifications() async {
  LoggerUtil.d('Setting up local notifications');
  // Create Android notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/icon_notification');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
  );
}

// Handle notification response when app is opened from notification
void _onDidReceiveNotificationResponse(NotificationResponse response) {
  // Handle notification click
  if (response.payload != null) {
    // Parse the payload and navigate to appropriate screen
    LoggerUtil.d('Notification payload: ${response.payload}');
  }
}

// Handle foreground messages
void _handleForegroundMessage(RemoteMessage message) {
  LoggerUtil.i('Got a message in foreground!');
  LoggerUtil.d('Message data: ${message.data}');

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  // Show notification
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'icon_notification',
          largeIcon: const DrawableResourceAndroidBitmap('icon_notification'),
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}

// Handle message opened app
void _handleMessageOpenedApp(RemoteMessage message) {
  LoggerUtil.i('Message opened app: ${message.notification?.title}');
}

// Save token to shared preferences
Future<void> _saveTokenToSharedPreferences(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    LoggerUtil.i('Token saved to shared preferences');
  } catch (e) {
    LoggerUtil.e(
        'Error saving token to shared preferences', e, StackTrace.current);
  }
}

// Send FCM token to server
Future<void> sendTokenToServer(String authToken) async {
  LoggerUtil.i('Starting sendTokenToServer');
  String? _token;

  try {
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      LoggerUtil.i(
          'Firebase not initialized in sendTokenToServer, initializing now');
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }

    // Get token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('fcm_token');

    if (_token == null) {
      LoggerUtil.w(
          'FCM Token not found in SharedPreferences, attempting to get from Firebase');
      _token = await FirebaseMessaging.instance.getToken();
    }

    if (_token != null) {
      LoggerUtil.i('Sending FCM token to server, token exists');

      final Map<String, dynamic> requestData = {
        'fcm_token': _token,
      };
      LoggerUtil.d('Request data prepared: $requestData');

      try {
        LoggerUtil.d(
            'Sending HTTP request to: https://web-magangunbin2025.rsummi.co.id/api/notifications/fcm-token');
        final response = await http.post(
          Uri.parse(
              'https://web-magangunbin2025.rsummi.co.id/api/notifications/fcm-token'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestData),
        );

        LoggerUtil.d('FCM Token send response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          LoggerUtil.i('FCM Token updated successfully');
          LoggerUtil.d('Response body: ${response.body}');
        } else {
          LoggerUtil.w('Failed to update FCM Token: ${response.statusCode}');
          LoggerUtil.w('Response body: ${response.body}');
        }
      } catch (e) {
        LoggerUtil.e(
            'Error sending FCM token to server', e, StackTrace.current);
      }
    } else {
      LoggerUtil.w('FCM Token is still null after attempting to get it');
    }
  } catch (e) {
    LoggerUtil.e('Error in sendTokenToServer', e, StackTrace.current);
  }
}
