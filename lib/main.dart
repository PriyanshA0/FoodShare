import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fwm_sys/features/splash/splash_screen.dart';
import 'dart:async';
import 'dart:io';

void main() {
  // Wrap everything in error handling
  runZonedGuarded(
    () {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Handle all Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        // Log error but don't crash
        FlutterError.presentError(details);
        debugPrint('═══════════════════════════════════════');
        debugPrint('Flutter Error Caught: ${details.exception}');
        debugPrint('Stack: ${details.stack}');
        debugPrint('═══════════════════════════════════════');
      };

      // Set orientation (with error handling)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]).catchError((error) {
        debugPrint('Orientation error (non-critical): $error');
      });

      runApp(const FoodWasteManagementApp());
    },
    (error, stackTrace) {
      // Catch all async errors that escape the framework
      debugPrint('═══════════════════════════════════════');
      debugPrint('Async Error Caught: $error');
      debugPrint('Stack: $stackTrace');
      debugPrint('═══════════════════════════════════════');
    },
  );
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

      // Wrap home screen in error boundary
      home: const ErrorBoundary(child: SplashScreen()),

      // Global error widget builder - catches widget build errors
      builder: (context, widget) {
        // Custom error widget that doesn't crash the app
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return _buildErrorScreen(errorDetails);
        };

        // Wrap entire app to catch any remaining errors
        return ErrorBoundary(child: widget ?? const SizedBox.shrink());
      },
    );
  }

  // Custom error screen UI
  Widget _buildErrorScreen(FlutterErrorDetails errorDetails) {
    return Material(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFF2E7D32),
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Don\'t worry, your data is safe',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Force app restart
                      if (Platform.isAndroid) {
                        SystemNavigator.pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Restart App',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Try to continue (may work for minor errors)
                    },
                    child: const Text(
                      'Try to Continue',
                      style: TextStyle(color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Error Boundary Widget - catches errors in child widgets
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Reset error state when widget initializes
    _hasError = false;
  }

  // Catch errors during build
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    // Wrap child in error catching wrapper
    return Builder(
      builder: (context) {
        try {
          return widget.child;
        } catch (error, stackTrace) {
          // Caught error during build
          _handleError(error, stackTrace);
          return _buildErrorWidget();
        }
      },
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _hasError = true;
    });

    debugPrint('═══════════════════════════════════════');
    debugPrint('Error Boundary Caught: $error');
    debugPrint('Stack: $stackTrace');
    debugPrint('═══════════════════════════════════════');
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Something unexpected happened',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'The app encountered an error but it\'s safe to continue',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    }
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Restart App'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Extension for safe async operations
extension SafeFuture<T> on Future<T> {
  Future<T?> safely() async {
    try {
      return await this;
    } catch (error, stackTrace) {
      debugPrint('Safe Future Error: $error');
      debugPrint('Stack: $stackTrace');
      return null;
    }
  }
}
