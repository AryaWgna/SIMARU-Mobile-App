import 'package:flutter/material.dart';
import 'package:flutter_assets_monitoring/auth/login.dart';
import 'package:provider/provider.dart';
import 'views/dashboard/dashboard.dart';
import 'controllers/recent_activity_controller.dart';
import 'controllers/total_asset_controller.dart';
import 'controllers/asset_under_repair_controller.dart';
import 'controllers/net_asset_value_controller.dart';
import 'controllers/auth_controller.dart';
import 'dart:developer' as developer;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Log untuk debugging
  developer.log('Starting app...', name: 'APP_LIFECYCLE');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecentActivityController()),
        ChangeNotifierProvider(create: (_) => TotalAssetController()),
        ChangeNotifierProvider(create: (_) => AssetUnderRepairController()),
        ChangeNotifierProvider(create: (_) => NetAssetValueController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('Building MyApp...', name: 'APP_LIFECYCLE');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecentActivityController()),
        ChangeNotifierProvider(create: (_) => TotalAssetController()),
        ChangeNotifierProvider(create: (_) => AssetUnderRepairController()),
        ChangeNotifierProvider(create: (_) => NetAssetValueController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) {
            developer.log('Navigating to LoginScreen', name: 'APP_NAVIGATION');
            return const LoginScreen();
          },
          '/home': (context) {
            developer.log('Navigating to DashboardScreen',
                name: 'APP_NAVIGATION');
            return const DashboardScreen();
          },
        },
        theme: ThemeData(
          fontFamily: 'Inter',
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Handle route errors
        onGenerateRoute: (settings) {
          developer.log('Generating route for: ${settings.name}',
              name: 'APP_NAVIGATION');
          return null; // Let the normal routes handle it
        },
        // Handle page not found
        onUnknownRoute: (settings) {
          developer.log('Unknown route: ${settings.name}',
              name: 'APP_NAVIGATION');
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        },
      ),
    );
  }
}
