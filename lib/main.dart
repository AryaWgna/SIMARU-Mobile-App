import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'views/dashboard/dashboard.dart';
import 'controllers/dashboard/recent_activity_controller.dart';
import 'controllers/asset/total_asset_controller.dart';
import 'controllers/asset/asset_under_repair_controller.dart';
import 'controllers/asset/net_asset_value_controller.dart';
import 'controllers/asset/asset_complaint_controller.dart';
import 'controllers/complaint/complaint_controller.dart';
import 'controllers/notification/notification_controller.dart';
import 'controllers/scan/stockopname_controller.dart';
import 'controllers/asset/asset_document_controller.dart';
import 'controllers/asset/asset_history_controller.dart';
import 'controllers/asset/asset_mutation_controller.dart';
import 'controllers/asset/asset_details_controller.dart';
import 'controllers/asset/asset_checkin_controller.dart';
import 'controllers/asset/asset_checkout_controller.dart';
import 'controllers/asset/asset_lost_controller.dart';
import 'controllers/profile/profile_controller.dart';
import 'controllers/scan/qr_scanner_controller.dart';
import 'controllers/dashboard/dashboard_controller.dart';
import 'controllers/notification/notification_settings_controller.dart';
import 'controllers/notification/notification_badge_controller.dart';
import 'controllers/auth/auth_controller.dart'
    as auth; // Import untuk ApiService
import 'dart:developer' as developer;
import 'services/socket/socket_service.dart';
import 'services/firebase/firebase_messaging_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Import untuk mengatasi masalah anti-screenshot
import 'dart:io';
import 'package:no_screenshot/no_screenshot.dart';
import 'controllers/scan/scan_result_controller.dart';
import 'utils/logger_util.dart'; // Import LoggerUtil
import 'package:google_fonts/google_fonts.dart'; // Import for Google Fonts
import 'views/webview/web_view_screen.dart'; // Import WebViewScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pastikan fitur anti-screenshot dinonaktifkan saat aplikasi dimulai
  await _disableGlobalScreenshotProtection();

  // Log untuk debugging
  LoggerUtil.i('Starting app...', 'APP_LIFECYCLE');

  // Inisialisasi Firebase hanya jika bukan di web
  FirebaseMessagingService? messagingService;

  if (!kIsWeb) {
    // Inisialisasi Firebase dengan detail logging dan error handling
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      LoggerUtil.i('Firebase initialized successfully', 'FIREBASE');

      // Buat instance tapi jangan initialize dulu
      messagingService = FirebaseMessagingService();
      await messagingService.initialize();
    } catch (e) {
      LoggerUtil.e('Failed to initialize Firebase', e, StackTrace.current);
    }
  } else {
    LoggerUtil.i('Running on web platform, skipping Firebase initialization',
        'FIREBASE');
  }

  // Tambahkan error handler untuk Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    LoggerUtil.e(
      'Flutter error caught in main error handler',
      details.exception,
      details.stack,
    );

    // Lanjutkan ke handler error default
    FlutterError.dumpErrorToConsole(details);
  };

  // Set callback untuk navigasi ke login screen
  auth.ApiService.navigateToLogin = (BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  };

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
        if (messagingService != null) Provider.value(value: messagingService),
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
      LoggerUtil.i(
          "App Start: Memastikan anti-screenshot dinonaktifkan secara global");
      final noScreenshot = NoScreenshot();
      await noScreenshot.screenshotOn();
      LoggerUtil.i("App Start: Anti-screenshot berhasil dinonaktifkan");
    }
  } catch (e) {
    LoggerUtil.e("App Start: Error saat menonaktifkan anti-screenshot", e,
        StackTrace.current);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _hasValidToken = false;

  @override
  void initState() {
    super.initState();
    _checkForExistingToken();

    // Register as an observer to handle app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Log app lifecycle state changes
    LoggerUtil.i('App lifecycle state changed to: $state', 'APP_LIFECYCLE');

    if (state == AppLifecycleState.resumed) {
      // The app has become visible and interactive
      LoggerUtil.i('App resumed - checking token validity', 'APP_LIFECYCLE');
      _checkForExistingToken();
    }
  }

  Future<void> _checkForExistingToken() async {
    try {
      LoggerUtil.i(
          'Checking for existing token on app start...', 'APP_LIFECYCLE');

      // Check if user is already logged in
      final isLoggedIn = await auth.ApiService.isLoggedIn();

      if (isLoggedIn) {
        LoggerUtil.i('Token found, verifying validity...', 'APP_LIFECYCLE');

        // Try to refresh token to ensure it's still valid
        final refreshSuccess = await auth.ApiService.refreshToken();

        if (refreshSuccess) {
          LoggerUtil.i('Token is valid, will auto-login', 'APP_LIFECYCLE');
          setState(() {
            _hasValidToken = true;
            _isInitialized = true;
          });
          return;
        } else {
          LoggerUtil.i(
              'Token refresh failed, will show login screen', 'APP_LIFECYCLE');
        }
      } else {
        LoggerUtil.i('No token found, will show login screen', 'APP_LIFECYCLE');
      }
    } catch (e) {
      LoggerUtil.e('Error checking token', e, StackTrace.current);
    }

    setState(() {
      _hasValidToken = false;
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    LoggerUtil.i('Building MyApp...', 'APP_LIFECYCLE');

    final textTheme = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    ).copyWith(
      // Ensure readable text sizes for elderly users
      bodyLarge: GoogleFonts.poppins(fontSize: 16.0, height: 1.5),
      bodyMedium: GoogleFonts.poppins(fontSize: 14.0, height: 1.5),
      bodySmall: GoogleFonts.poppins(fontSize: 12.0, height: 1.3),
      // Make headings bold and clear
      headlineSmall: GoogleFonts.poppins(
          fontSize: 22.0, fontWeight: FontWeight.w700, height: 1.3),
      titleLarge: GoogleFonts.poppins(
          fontSize: 20.0, fontWeight: FontWeight.w700, height: 1.3),
      titleMedium: GoogleFonts.poppins(
          fontSize: 18.0, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: GoogleFonts.poppins(
          fontSize: 16.0, fontWeight: FontWeight.w600, height: 1.3),
      // Labels for buttons, etc.
      labelLarge: GoogleFonts.poppins(
          fontSize: 16.0, fontWeight: FontWeight.w500, height: 1.3),
      labelMedium: GoogleFonts.poppins(
          fontSize: 14.0, fontWeight: FontWeight.w500, height: 1.3),
      labelSmall: GoogleFonts.poppins(
          fontSize: 12.0, fontWeight: FontWeight.w500, height: 1.3),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIMARU',
      navigatorKey: auth.ApiService
          .navigatorKey, // Gunakan navigatorKey global untuk navigasi tanpa context
      navigatorObservers: [
        routeObserver
      ], // Add route observer for navigation tracking
      // Force proper navigation history
      onGenerateRoute: (RouteSettings settings) {
        LoggerUtil.i(
            'Generating route for: ${settings.name}', 'APP_NAVIGATION');
        // This ensures the back navigation follows the exact path the user took
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            switch (settings.name) {
              case '/login':
                return const LoginScreen();
              case '/dashboard':
                return const DashboardScreen();
              case '/web_portal':
                return const WebViewScreen(
                  initialUrl: 'https://web-magangunbin2025.rsummi.co.id/',
                  title: 'Web Portal SIMARU',
                );
              default:
                return _isInitialized
                    ? (_hasValidToken
                        ? const DashboardScreen()
                        : const LoginScreen())
                    : const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
            }
          },
        );
      },
      home: _isInitialized
          ? (_hasValidToken ? const DashboardScreen() : const LoginScreen())
          : const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
      theme: ThemeData(
        useMaterial3: true,
        textTheme: textTheme,
        primaryColor: const Color(0xFF213268),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF213268),
          secondary: Color(0xFF25B1FF),
          background: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF213268),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      // Localization support
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesian
        Locale('en', 'US'), // English
      ],
      locale: const Locale('id', 'ID'), // Default to Indonesian
    );
  }
}
// Info Pembuat Aplikasi
// Made by Ardwiyan (PakBos), Ahmad (Programmer Galak), 
// Farhan (Design Maker), and Daffa (Backend Specialist)

