import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'views/dashboard/dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const DashboardScreen(),
      },
      theme: ThemeData(
        fontFamily: 'Inter',
      ),
    );
  }
}
