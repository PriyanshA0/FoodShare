import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/constants/strings.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/features/auth/login_screen.dart';
import 'package:fwm_sys/features/ngo/ngo_dashboard.dart';
import 'package:fwm_sys/features/restaurant/restaurant_dashboard.dart';
import 'package:fwm_sys/features/admin/admin_dashboard.dart'; // NEW IMPORT

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  // CRITICAL CHANGE: Check for persistent session data
  _checkSessionAndNavigate() async {
    // Show splash screen for at least 2 seconds for a smooth UX
    await Future.delayed(const Duration(seconds: 2));

    final sessionData = await _apiService.getSessionData();
    final isLoggedIn = sessionData['is_logged_in'] == 'true';
    final userRole = sessionData['user_role'];

    if (mounted) {
      Widget nextScreen;

      if (isLoggedIn) {
        // If logged in, navigate to the appropriate dashboard
        if (userRole == 'restaurant') {
          nextScreen = const RestaurantDashboard();
        } else if (userRole == 'ngo') {
          nextScreen = const NGODashboard();
        } else if (userRole == 'admin') { // ADMIN CHECK
          nextScreen = const AdminDashboard();
        } else {
          // Fallback if role is corrupted
          nextScreen = const LoginScreen();
        }
      } else {
        // If not logged in, go to the login screen
        nextScreen = const LoginScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.accent],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                AppStrings.tagline,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}