import 'package:flutter/material.dart';
import 'package:fwm_sys/features/splash/splash_screen.dart';

void main() {
  runApp(const FoodWasteManagementApp());
}

class FoodWasteManagementApp extends StatelessWidget {
  const FoodWasteManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Waste Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          color: Color(0xFF2E7D32),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}