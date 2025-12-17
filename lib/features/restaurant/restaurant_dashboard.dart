import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/features/restaurant/donate_food_screen.dart';
import 'package:fwm_sys/features/restaurant/food_status_screen.dart';
import 'package:fwm_sys/features/restaurant/history_analytics_screen.dart';
import 'package:fwm_sys/features/common/profile_screen.dart';
import 'package:fwm_sys/features/auth/login_screen.dart';
import 'package:fwm_sys/features/common/notifications_screen.dart';
import 'dart:async'; // Required for Timer

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  // CRITICAL: Future to hold the combined data fetch result
  late Future<Map<String, dynamic>> _compositeDataFuture;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // 1. Initial Data Fetch
    _fetchRestaurantCompositeData();
    // 2. Setup Auto-Refresh Timer
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // CRITICAL: Stop the timer when the widget is removed
    _timer.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // FIX: Changed refresh interval from 1 second to 5 seconds to prevent blinking.
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchRestaurantCompositeData();
      }
    });
  }

  void _fetchRestaurantCompositeData() {
    final statsFuture = ApiService().fetchDashboardStats();
    final userFuture = ApiService().fetchUserData();
    final activityFuture = ApiService().fetchRecentActivity();

    // The setState wrapper around the Future assignment triggers the FutureBuilder rebuild.
    setState(() {
      // Use .catchError() on the combined future to handle errors gracefully
      _compositeDataFuture = Future.wait([statsFuture, userFuture, activityFuture])
          .then((results) {
            return {
              'stats': results[0],
              'user_data': results[1],
              'activity': results[2],
            };
          })
          .catchError((e) {
            // CRITICAL: Throw the error so the FutureBuilder captures the detailed message.
            throw Exception(e.toString());
          });
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Stop refresh before logging out
    _timer.cancel();
    await ApiService().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _compositeDataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting;
        final bool hasError = snapshot.hasError;

        // This conditional logic allows the screen to stay visible and only shows
        // the loading indicator on the FIRST load, or error state.
        if (hasError) {
          // Display the full, detailed error message from the exception
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Dashboard Load Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Data is ready, build the Scaffold
        final stats = data['stats'] ?? {};
        final userData = data['user_data'] ?? {};
        final activityList = data['activity'] ?? [];

        // --- SAFELY EXTRACT DATA ---
        final double totalQuantityKg =
            double.tryParse(stats['total_quantity_kg']?.toString() ?? '0') ??
            0.0;
        final int completedCount =
            int.tryParse(stats['completed_orders']?.toString() ?? '0') ?? 0;
        final int totalPostCount =
            int.tryParse(
              stats['total_posts_or_collections']?.toString() ?? '0',
            ) ??
            0;
        final int mealsServedEstimate =
            int.tryParse(stats['meals_served_estimate']?.toString() ?? '0') ??
            0;

        String hotelName = userData['name'] ?? 'Hotel Name';
        String contactPerson = userData['contact_person'] ?? 'Manager';
        String foodDonated = '${totalQuantityKg.toStringAsFixed(0)} kg';
        String completedOrders = completedCount.toString();
        String totalPostsStr = totalPostCount.toString();
        String mealsServed = '$mealsServedEstimate+';

        double acceptanceRate = 0.0;
        if (totalPostCount > 0) {
          acceptanceRate =
              (completedCount.toDouble() / totalPostCount.toDouble()) * 100;
        }
        String acceptanceRateText =
            '${acceptanceRate.toStringAsFixed(0)}% acceptance rate';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              // <-- Dynamic title is now built here
              children: [
                const Icon(
                  Icons.cloud_upload,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotelName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Hotel Dashboard',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Badge(
                  //label: Text('2'),
                  child: Icon(
                    Icons.notifications_none,
                    color: AppColors.textPrimary,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
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
                  // --- HEADER: DYNAMICALLY SHOWING USER NAME ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $contactPerson!',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Ready to make a difference today?',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- END HEADER ---

                  // === STATS CARDS (Dynamic Data) ===
                  _buildStatCard(
                    title: 'Food Donated',
                    value: foodDonated,
                    subtitle: '$totalPostsStr total posts',
                    icon: Icons.ssid_chart,
                    color: AppColors.success,
                  ),
                  _buildStatCard(
                    title: 'Orders Accepted',
                    value: completedOrders,
                    subtitle: acceptanceRateText,
                    icon: Icons.list_alt,
                    color: AppColors.info,
                  ),
                  _buildStatCard(
                    title: 'Meals Served',
                    value: mealsServed,
                    subtitle: 'Estimated people helped',
                    icon: Icons.people_alt,
                    color: const Color(0xFF9C27B0),
                  ),

                  const SizedBox(height: 24),
                  // === QUICK ACTION CARDS (Unchanged) ===
                  _buildActionCard(
                    context,
                    title: 'Upload Food',
                    subtitle:
                        'Post available food for donation to NGOs in your area',
                    icon: Icons.cloud_upload_outlined,
                    iconColor: AppColors.success,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DonateFoodScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'View Status',
                    subtitle:
                        'Track the status of your donations and pickup requests',
                    icon: Icons.list_alt_outlined,
                    iconColor: AppColors.info,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FoodStatusScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'History & Reports',
                    subtitle:
                        'View analytics and donation history with insights',
                    icon: Icons.bar_chart_outlined,
                    iconColor: const Color(0xFF9C27B0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryAnalyticsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  // === RECENT ACTIVITY (Dynamic Data) ===
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...activityList
                      .map<Widget>(
                        (activity) => _buildRecentActivityItem(
                          activity['title'],
                          '${activity['quantity']} servings',
                          activity['status'],
                        ),
                      )
                      .toList(),

                  if (activityList.isEmpty && !isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No recent activity found."),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Helper methods (Copied from original snippet for completeness) ---
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(
    String title,
    String servings,
    String status,
  ) {
    Color statusColor;
    String statusText = status.toUpperCase();

    switch (status) {
      case 'accepted':
      case 'in_transit':
        statusColor = AppColors.info;
        break;
      case 'picked_up':
        statusColor = AppColors.success;
        break;
      default:
        statusColor = AppColors.warning;
        statusText = 'PENDING';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.background,
            ),
            child: const Icon(Icons.fastfood, color: AppColors.textSecondary),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            servings,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
