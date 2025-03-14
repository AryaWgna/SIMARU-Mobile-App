import 'package:flutter/material.dart';
import 'package:flutter_assets_monitoring/auth/login.dart';
import 'package:provider/provider.dart';
import 'views/dashboard/dashboard.dart';
import 'controllers/recent_activity_controller.dart';
import 'controllers/total_asset_controller.dart';
import 'controllers/asset_under_repair_controller.dart';
import 'controllers/net_asset_value_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          '/': (context) => const LoginScreen(),
          '/home': (context) => const DashboardScreen(),
        },
        theme: ThemeData(
          fontFamily: 'Inter',
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
    );
  }
}
