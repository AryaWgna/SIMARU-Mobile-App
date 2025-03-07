import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'views/dashboard/home_screen.dart';

void main() {
  runApp(MyApp());
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
        '/home': (context) => const HomeScreen(),
      },
      theme: ThemeData(
        fontFamily: 'Inter',
      ),
    );
  }
}
