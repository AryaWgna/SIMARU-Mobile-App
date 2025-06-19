import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

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
  print('Background message: ${message.notification?.title}');
}

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _token;

  String? get token => _token;

  // Initialize Firebase messaging
  Future<void> initialize() async {
    print('FirebaseMessagingService: Starting initialization');

    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print(
            'FirebaseMessagingService: Firebase not initialized, initializing now');
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      } else {
        print('FirebaseMessagingService: Firebase already initialized');
      }

      // Request permission
      await _requestPermission();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

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
      await _getToken();

      print('FirebaseMessagingService: Initialization complete');
    } catch (e) {
      print('FirebaseMessagingService: Error during initialization: $e');
    }
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    print('FirebaseMessagingService: Requesting permissions');
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // Setup local notifications
  Future<void> _setupLocalNotifications() async {
    print('FirebaseMessagingService: Setting up local notifications');
    // Create Android notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
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
      print('Notification payload: ${response.payload}');

      // You can add navigation logic here based on the payload
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message in foreground!');
    print('Message data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Show notification
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon ?? '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.notification?.title}');

    // You can add navigation logic here based on the message
  }

  // Get FCM token
  Future<void> _getToken() async {
    print('FirebaseMessagingService: Getting FCM token');
    try {
      // Pastikan Firebase sudah diinisialisasi
      if (Firebase.apps.isEmpty) {
        print('Firebase not initialized in _getToken, initializing now');
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }

      _token = await _messaging.getToken();
      print('FCM Token obtained: ${_token != null ? 'yes' : 'no'}');
      if (_token != null) {
        print('FCM Token length: ${_token!.length}');
      }

      // Save token to shared preferences
      if (_token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _token!);
        print('Token saved to SharedPreferences');
      }

      // Setup token refresh listener
      _messaging.onTokenRefresh.listen((newToken) {
        _token = newToken;
        print('FCM Token refreshed');
        _saveTokenToSharedPreferences(newToken);
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Save token to shared preferences
  Future<void> _saveTokenToSharedPreferences(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('Token saved to shared preferences');
    } catch (e) {
      print('Error saving token to shared preferences: $e');
    }
  }

  // Send FCM token to server
  Future<void> sendFcmTokenToServer(String authToken) async {
    print('FirebaseMessagingService: Starting sendFcmTokenToServer');
    try {
      // Pastikan Firebase sudah diinisialisasi
      if (Firebase.apps.isEmpty) {
        print(
            'Firebase not initialized in sendFcmTokenToServer, initializing now');
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }

      if (_token == null) {
        print('FCM Token not found, attempting to get token');
        await _getToken();
      }

      if (_token != null) {
        print('Sending FCM token to server, token exists');

        final Map<String, dynamic> requestData = {
          'fcm_token': _token,
        };
        print('Request data prepared: $requestData');

        try {
          print(
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

          print('FCM Token send response status: ${response.statusCode}');
          if (response.statusCode == 200) {
            print('FCM Token updated successfully');
            print('Response body: ${response.body}');
          } else {
            print('Failed to update FCM Token: ${response.statusCode}');
            print('Response body: ${response.body}');
          }
        } catch (e) {
          print('Error sending FCM token to server: $e');
        }
      } else {
        print('FCM Token is still null after attempting to get it');
      }
    } catch (e) {
      print('Error in sendFcmTokenToServer: $e');
    }
  }
}
