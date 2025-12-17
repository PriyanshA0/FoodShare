import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/user_model.dart'; // Ensure UserModel.dart is available
import 'package:fwm_sys/features/common/edit_profile_screen.dart';
import 'package:fwm_sys/features/auth/login_screen.dart';
import 'dart:async';

// Helper model to hold combined data
class ProfileData {
  final User user;
  final Map<String, dynamic> stats;

  ProfileData({required this.user, required this.stats});
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<ProfileData>? _profileDataFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching combined user data and stats immediately
    _profileDataFuture = _fetchCombinedData();
  }

  // --- Fetches unified user data and dashboard stats ---
  Future<ProfileData> _fetchCombinedData() async {
    try {
      final userFuture = ApiService().fetchUserData();
      final statsFuture = ApiService().fetchDashboardStats();

      final results = await Future.wait([userFuture, statsFuture]);

      final Map<String, dynamic> userData = results[0];
      final Map<String, dynamic> statsData = results[1];

      final user = User.fromJson(userData);

      return ProfileData(user: user, stats: statsData);
    } catch (e) {
      throw Exception('Failed to fetch user profile or stats: $e');
    }
  }

  void _navigateToEditScreen(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
    );

    if (result == true && mounted) {
      setState(() {
        // Refresh data after successful edit
        _profileDataFuture = _fetchCombinedData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  // CRITICAL: Professional Logout Handler
  Future<void> _handleLogout(BuildContext context) async {
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
    return FutureBuilder<ProfileData>(
      future: _profileDataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final profileData = snapshot.data!;
          final user = profileData.user;
          final stats = profileData.stats;

          return Scaffold(
            key: ValueKey(user.id),
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Back to Dashboard'),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => _navigateToEditScreen(user),
                ),
              ],
            ),
            body: _buildProfileBody(context, user, stats), // PASS STATS
          );
        } else {
          // Handle Loading and Errors
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Profile'),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(child: _handleLoadingAndErrorStates(snapshot)),
          );
        }
      },
    );
  }

  Widget _handleLoadingAndErrorStates(AsyncSnapshot<ProfileData> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading profile...'),
        ],
      );
    } else if (snapshot.hasError) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              // Show the specific error if possible
              'Error Loading Profile: ${snapshot.error.toString().split(':')[1].trim()}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _profileDataFuture = _fetchCombinedData();
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }
    return const Text('No profile data available.');
  }

  // Helper for the custom logout button tile
  Widget _buildLogoutTile(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.exit_to_app, color: AppColors.error),
        title: const Text(
          'Log Out',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.error),
        onTap: () => _handleLogout(context),
      ),
    );
  }

  Widget _buildProfileBody(
    BuildContext context,
    User user,
    Map<String, dynamic> stats,
  ) {
    bool isRestaurant = user.role == 'restaurant';
    Color roleColor = isRestaurant ? AppColors.success : AppColors.info;

    // --- Dynamic Labels based on Role ---
    String verificationLabel = isRestaurant
        ? 'License/ID Proof Number'
        : 'Registration Certificate No.';
    String businessDetailLabel = isRestaurant
        ? 'Business Name'
        : 'Organization Name';

    // --- REAL STATS EXTRACTION ---
    // Safely extract and parse completed orders count
    final int completedCount =
        int.tryParse(stats['completed_orders']?.toString() ?? '0') ?? 0;

    // Safely extract and parse active orders count (for NGO)
    final int activeOrdersStats =
        int.tryParse(stats['active_orders']?.toString() ?? '0') ?? 0;

    // Total posts/collections count
    final int totalPostsStats =
        int.tryParse(stats['total_posts_or_collections']?.toString() ?? '0') ??
        0;

    // Total count logic: Total posts for Restaurant, or (Completed + Active) for NGO
    final int totalCount = isRestaurant
        ? totalPostsStats
        : completedCount + activeOrdersStats;

    // Active orders are pending/in_transit
    final int activeCount = isRestaurant
        ? totalPostsStats -
              completedCount // Posts that aren't completed yet (Resto)
        : activeOrdersStats; // Active orders (NGO)
    // ------------------------------------

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER AND ROLE INFO
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: roleColor.withOpacity(0.2),
                  child: Icon(
                    isRestaurant ? Icons.store : Icons.groups,
                    size: 40,
                    color: roleColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.name ?? 'Organization Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  // Display Owner Name for Restaurant, Contact Person for NGO
                  user.contactPerson ??
                      (isRestaurant ? 'Owner/Manager' : 'Contact Person'),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRestaurant
                        ? 'Hotel / Restaurant'
                        : 'NGO / Social Organization',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // 2. STATS CARDS (NOW REAL DATA)
          _buildStatsCard(
            isRestaurant ? 'Total Donations' : 'Total Collections',
            totalCount.toString(), // <--- USING REAL DATA
          ),
          _buildStatsCard(
            'Completed',
            completedCount.toString(),
          ), // <--- USING REAL DATA
          _buildStatsCard(
            'Active',
            activeCount.toString(),
          ), // <--- USING REAL DATA

          const SizedBox(height: 20),

          // 3. CONTACT INFORMATION
          _buildInfoCard(
            title: 'Contact Information',
            children: [
              _buildDetailRow(Icons.email, 'Email Address', user.email),
              _buildDetailRow(
                Icons.phone,
                'Phone Number',
                user.contactNumber ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.location_on,
                'Address',
                user.address ?? 'N/A',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4. BUSINESS/ORGANIZATION DETAILS
          _buildInfoCard(
            title: isRestaurant ? 'Business Details' : 'Organization Details',
            children: [
              _buildDetailRow(
                Icons.receipt,
                verificationLabel,
                user.verificationDetail ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.business_center,
                businessDetailLabel,
                user.name ?? 'N/A',
              ),
              // Only show volunteer count for NGO
              if (user.volunteersCount != null && !isRestaurant)
                _buildDetailRow(
                  Icons.people,
                  'Number of Volunteers',
                  '${user.volunteersCount} active volunteers',
                ),
            ],
          ),

          const SizedBox(height: 20),

          // 5. ACHIEVEMENT BADGE (MOCKED)
          _buildAchievementBadge(isRestaurant, completedCount),

          // 6. PROFESSIONAL LOGOUT BUTTON
          _buildLogoutTile(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- Helper Methods (Stats, InfoCard, DetailRow, AchievementBadge) ---

  Widget _buildStatsCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(bool isRestaurant, int completedCount) {
    if (completedCount < 1) return const SizedBox.shrink();

    String action = isRestaurant ? 'donation' : 'collection';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: AppColors.warning, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Impact Champion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'You\'ve successfully completed $completedCount $action!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
