import 'package:flutter/material.dart';
import 'package:flutter_assets_monitoring/auth/login.dart';
import 'package:provider/provider.dart';
import 'views/dashboard/dashboard.dart';
import 'controllers/recent_activity_controller.dart';
import 'controllers/total_asset_controller.dart';
import 'controllers/asset_under_repair_controller.dart';
import 'controllers/net_asset_value_controller.dart';
import 'controllers/asset_complaint_controller.dart';
import 'controllers/complaint_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/stockopname_controller.dart';
import 'controllers/asset_document_controller.dart';
import 'controllers/asset_history_controller.dart';
import 'controllers/asset_mutation_controller.dart';
import 'controllers/asset_details_controller.dart';
import 'controllers/asset_checkin_controller.dart';
import 'controllers/asset_checkout_controller.dart';
import 'controllers/asset_lost_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/qr_scanner_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/notification_settings_controller.dart';
import 'controllers/notification_badge_controller.dart';
import 'dart:developer' as developer;
import 'services/socket_service.dart';
import 'services/firebase_messaging_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Import untuk mengatasi masalah anti-screenshot
import 'dart:io';
import 'package:no_screenshot/no_screenshot.dart';
import 'controllers/scan_result_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pastikan fitur anti-screenshot dinonaktifkan saat aplikasi dimulai
  await _disableGlobalScreenshotProtection();

  // Log untuk debugging
  developer.log('Starting app...', name: 'APP_LIFECYCLE');

  // Inisialisasi Firebase dengan detail logging dan error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('Firebase initialized successfully', name: 'FIREBASE');
  } catch (e) {
    developer.log('Failed to initialize Firebase: $e', name: 'FIREBASE');
  }

  // Buat instance tapi jangan initialize dulu
  FirebaseMessagingService messagingService = FirebaseMessagingService();

  // Tambahkan error handler untuk Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log(
      'Flutter error caught in main error handler:',
      name: 'APP_ERROR',
      error: details.exception,
      stackTrace: details.stack,
    );

    // Lanjutkan ke handler error default
    FlutterError.dumpErrorToConsole(details);
  };

  // Set callback untuk navigasi ke login screen
  ApiService.navigateToLogin = (BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  };

  await messagingService.initialize();

  runApp(
    MultiProvider(
      providers: [
        // Controllers lama
        ChangeNotifierProvider(create: (_) => TotalAssetController()),
        ChangeNotifierProvider(create: (_) => NetAssetValueController()),
        ChangeNotifierProvider(create: (_) => RecentActivityController()),
        ChangeNotifierProvider(create: (_) => AssetUnderRepairController()),
        // Controllers baru
        ChangeNotifierProvider(create: (_) => AssetHistoryController()),
        ChangeNotifierProvider(create: (_) => AssetDocumentController()),
        ChangeNotifierProvider(create: (_) => AssetComplaintController()),
        ChangeNotifierProvider(create: (_) => ComplaintController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => StockOpnameController()),
        ChangeNotifierProvider(create: (_) => AssetMutationController()),
        ChangeNotifierProvider(create: (_) => SocketService()),
        Provider.value(value: messagingService),
        ChangeNotifierProvider(create: (_) => AssetDetailsController()),
        // Controllers untuk checkin dan checkout
        ChangeNotifierProvider(create: (_) => AssetCheckinController()),
        ChangeNotifierProvider(create: (_) => AssetCheckoutController()),
        ChangeNotifierProvider(create: (_) => AssetLostController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => QRScannerController()),
        // Controller untuk scan result
        ChangeNotifierProvider(create: (_) => ScanResultController()),
        // Tambahkan provider untuk DashboardController
        ChangeNotifierProvider(create: (_) => DashboardController()),
        // Controller untuk notification settings
        ChangeNotifierProvider(create: (_) => NotificationSettingsController()),
        // Controller untuk badge notifikasi
        ChangeNotifierProvider(create: (_) => NotificationBadgeController()),
      ],
      child: const MyApp(),
    ),
  );
}

// Fungsi untuk menonaktifkan anti-screenshot secara global
Future<void> _disableGlobalScreenshotProtection() async {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      print(
          "App Start: Memastikan anti-screenshot dinonaktifkan secara global");
      final noScreenshot = NoScreenshot();
      await noScreenshot.screenshotOn();
      print("App Start: Anti-screenshot berhasil dinonaktifkan");
    }
  } catch (e) {
    print("App Start: Error saat menonaktifkan anti-screenshot: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('Building MyApp...', name: 'APP_LIFECYCLE');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) {
          developer.log('Navigating to LoginScreen', name: 'APP_NAVIGATION');
          // Pastikan anti-screenshot dinonaktifkan saat navigasi ke login screen
          _disableGlobalScreenshotProtection();
          return const LoginScreen();
        },
        '/home': (context) {
          developer.log('Navigating to DashboardScreen',
              name: 'APP_NAVIGATION');
          // Pastikan anti-screenshot dinonaktifkan saat navigasi ke dashboard
          _disableGlobalScreenshotProtection();
          return const DashboardScreen();
        },
      },
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF213268),
            primary: const Color(0xFF213268)),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF213268),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF213268),
            foregroundColor: Colors.white,
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Tambahkan dukungan lokalisasi untuk Indonesia
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesia
        Locale('en', 'US'), // English
      ],
      locale: const Locale('id', 'ID'), // Set bahasa default ke Indonesia
    );
  }
}

// Info Pembuat Aplikasi
// Made by Ardwiyan (PakBos), Ahmad (Programmer Galak), 
// Farhan (Design Maker), and Daffa (Backend Specialist)
