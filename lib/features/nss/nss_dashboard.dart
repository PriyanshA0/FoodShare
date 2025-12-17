import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/features/ngo/view_food_posts_screen.dart';
import 'package:fwm_sys/features/ngo/accepted_orders_screen.dart';
import 'package:fwm_sys/features/common/profile_screen.dart';
import 'package:fwm_sys/features/auth/login_screen.dart';
import 'dart:async';
import 'dart:io';

class NSSDashboard extends StatefulWidget {
  const NSSDashboard({super.key});

  @override
  State<NSSDashboard> createState() => _NSSDashboardState();
}

class _NSSDashboardState extends State<NSSDashboard> {
  late Future<Map<String, dynamic>> _compositeDataFuture;
  // FIX: Changed to nullable Timer to prevent LateInitializationError
  Timer? _timer;
  String? _errorMessage;
  bool _isAuthError = false;

  // New state variables to hold data outside the Future, preventing data loss on error
  Map<String, dynamic> _currentStats = {};
  Map<String, dynamic> _currentUserData = {};

  @override
  void initState() {
    super.initState();
    // Initialize _compositeDataFuture immediately
    _compositeDataFuture = _fetchNSSCompositeData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // FIX: Safely cancel the timer using the null-conditional operator
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Ensure only one timer is active
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isAuthError) {
        _fetchNSSCompositeData(silent: true); // Run silently on refresh
      } else if (mounted && _isAuthError) {
        _timer?.cancel();
      }
    });
  }

  // Refactored to handle individual API call failures and update state
  Future<Map<String, dynamic>> _fetchNSSCompositeData({
    bool silent = false,
  }) async {
    final statsFuture = ApiService().fetchDashboardStats();
    final userFuture = ApiService().fetchNSSUserData();

    // --- 1. Fetch User Data (CRITICAL) ---
    // This call is known to succeed (Status 200)
    Map<String, dynamic> userData;
    try {
      userData = await userFuture;
      _currentUserData = userData;
      if (mounted && !silent) {
        setState(() {}); // Redraw immediately with critical profile data
      }
    } catch (e) {
      // If user data fails, this is a CRITICAL AUTH failure. Stop and notify.
      if (mounted) {
        _handleApiError(e, isCritical: true);
      }
      return {'stats': _currentStats, 'user_data': _currentUserData};
    }

    // --- 2. Fetch Stats (Can fail without stopping the page) ---
    Map<String, dynamic> stats;
    try {
      stats = await statsFuture;
      _currentStats = stats;
      if (mounted) {
        setState(() {
          _errorMessage = null; // Clear error on successful stats fetch
        });
      }
    } catch (e) {
      // If stats fail (which it currently does with 401), show an error but keep the profile data.
      if (mounted) {
        _handleApiError(e, isCritical: false);
      }
      _currentStats = {}; // Reset stats if fetch fails
      // We still return the full data structure, including the good profile data
    }

    return {'stats': _currentStats, 'user_data': _currentUserData};
  }

  void _handleApiError(Object e, {required bool isCritical}) {
    if (!mounted) return;

    String errorDetail = e.toString();

    // Check for 401/403/Credentials not found (The primary issue)
    if (errorDetail.contains('Unauthorized') ||
        errorDetail.contains('401') ||
        errorDetail.contains('403') ||
        errorDetail.contains('credentials not found')) {
      _errorMessage = isCritical
          ? 'CRITICAL: Authentication failed for profile. Please LOGOUT.'
          : 'WARNING: Dashboard stats failed (Auth/Role error). Check server logs.';
      _isAuthError = isCritical;
      if (isCritical) {
        _timer?.cancel();
      }
    }
    // Check for 404 (Missing profile data, e.g., missing nss_details entry)
    else if (errorDetail.contains('404') ||
        errorDetail.contains('Profile Details Missing')) {
      _errorMessage = 'Profile setup incomplete. Please contact admin.';
      _isAuthError = false;
    }
    // Check for connection/generic error
    else if (errorDetail.contains('SocketException') || e is SocketException) {
      _errorMessage = 'Connection Error: Please check your network.';
      _isAuthError = false;
    } else {
      _errorMessage = isCritical
          ? 'Critical Data failed to load. Error: $e'
          : 'Stats failed to load. Try refresh.';
      _isAuthError = false;
      print('NSS Dashboard Fetch Detailed Error: $e');
    }

    setState(() {});
  }

  Future<void> _handleLogout(BuildContext context) async {
    _timer?.cancel();
    await ApiService().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Show Logout button for critical errors
          TextButton(
            onPressed: () => _handleLogout(context),
            child: const Text(
              'LOGOUT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _compositeDataFuture,
      builder: (context, snapshot) {
        // Use current state variables for data presentation, not snapshot.data
        // This preserves the profile data even if the future throws an error.
        final stats = _currentStats;
        final userData = _currentUserData;

        // Use snapshot to only show CircularProgressIndicator on first load
        final bool isWaitingForInitialData =
            snapshot.connectionState == ConnectionState.waiting &&
            userData.isEmpty;

        if (isWaitingForInitialData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- SAFELY EXTRACT NSS DATA ---
        final int availablePostsCount =
            int.tryParse(stats['available_posts']?.toString() ?? '0') ?? 0;
        final int activeOrdersCount =
            int.tryParse(stats['active_orders']?.toString() ?? '0') ?? 0;
        final double foodCollectedKg =
            double.tryParse(stats['total_quantity_kg']?.toString() ?? '0') ??
            0.0;
        final int mealsDistributedEstimate =
            int.tryParse(stats['meals_served_estimate']?.toString() ?? '0') ??
            0;

        // Use null checks (??) to display placeholders if data is missing,
        // relying on the data cached in _currentUserData
        String collegeName = userData['college_name'] ?? 'NSS College Unit';
        String studentName = userData['student_name'] ?? 'Representative';
        String unitNo = userData['unit_no'] ?? 'N/A';
        String vecNumber = userData['vec_number']?.toString() ?? 'N/A';

        String availablePosts = availablePostsCount.toString();
        String pendingPickups = activeOrdersCount.toString();
        String foodCollected = '${foodCollectedKg.toStringAsFixed(0)} kg';
        String mealsDistributed = '$mealsDistributedEstimate+';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'NSS - $collegeName',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ViewFoodPostsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Uses the generic profile screen, which must fetch NSS data
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.textPrimary),
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),

          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error banner is shown here if _errorMessage is not null
                  if (_errorMessage != null) _buildErrorBanner(_errorMessage!),

                  // --- HEADER ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $studentName (Unit $unitNo)!',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'VEC Count: $vecNumber Students',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // === STATS CARDS ===
                  _buildStatCard(
                    title: 'Available Posts',
                    value: availablePosts,
                    subtitle: 'Ready to accept',
                    icon: Icons.search,
                    color: AppColors.warning,
                  ),
                  _buildStatCard(
                    title: 'Pending Pickups',
                    value: pendingPickups,
                    subtitle: 'Awaiting collection',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.info,
                  ),
                  _buildStatCard(
                    title: 'Food Collected',
                    value: foodCollected,
                    subtitle: 'Total confirmed collections',
                    icon: Icons.ssid_chart,
                    color: AppColors.success,
                  ),
                  _buildStatCard(
                    title: 'Meals Distributed',
                    value: mealsDistributed,
                    subtitle: 'People helped',
                    icon: Icons.people_alt,
                    color: const Color(0xFF9C27B0),
                  ),

                  const SizedBox(height: 24),
                  // === QUICK ACTION CARDS (Similar to NGO) ===
                  _buildActionCard(
                    context,
                    title: 'View Food Posts',
                    subtitle:
                        'Browse available food donations from local sources',
                    icon: Icons.search_outlined,
                    iconColor: AppColors.warning,
                    badgeText: '$availablePosts new donations available',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ViewFoodPostsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'My Accepted Orders',
                    subtitle:
                        'View and manage your accepted food donations for pickup',
                    icon: Icons.inventory_2,
                    iconColor: AppColors.info,
                    badgeText: '$pendingPickups pending pickup',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AcceptedOrdersScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Helper methods (reused from NGO Dashboard) ---
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 30),
                    ),
                    if (badgeText.isNotEmpty)
                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
