import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/user_model.dart';
import 'package:fwm_sys/features/common/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<User>? _userData;

  @override
  void initState() {
    super.initState();
    _userData = _fetchUserData();
  }

  Future<User> _fetchUserData() async {
    try {
      final response = await ApiService().fetchUserData();
      // Use the corrected User.fromJson factory
      return User.fromJson(response);
    } catch (e) {
      throw Exception(e);
    }
  }

  void _navigateToEditScreen(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
    );

    if (result == true && mounted) {
      setState(() {
        _userData = _fetchUserData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return Scaffold(
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
            body: _buildProfileBody(context, user),
          );
        } else {
          // Handle Loading and Errors (Omitting for brevity, assume correct)
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

  Widget _handleLoadingAndErrorStates(AsyncSnapshot<User> snapshot) {
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
              'Error Loading Profile: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _userData = _fetchUserData();
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

  Widget _buildProfileBody(BuildContext context, User user) {
    bool isRestaurant = user.role == 'restaurant';
    Color roleColor = isRestaurant ? AppColors.success : AppColors.info;

    // Use actual data for display
    String verificationLabel = isRestaurant
        ? 'License/ID Proof Number'
        : 'Registration Certificate No.';
    String businessDetailLabel = isRestaurant
        ? 'Business Name'
        : 'Organization Name';

    // Mock Stats (to be replaced by dedicated API calls later)
    int totalCount = isRestaurant ? 4 : 2;
    int completedCount = 1;
    int activeCount = isRestaurant ? 3 : 1;

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
                  user.contactPerson ??
                      (isRestaurant ? 'Owner Name' : 'Contact Person'),
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

          // 2. STATS CARDS
          _buildStatsCard(
            isRestaurant ? 'Total Donations' : 'Total Collections',
            totalCount.toString(),
          ),
          _buildStatsCard('Completed', completedCount.toString()),
          _buildStatsCard('Active', activeCount.toString()),

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
              if (user.volunteersCount != null && user.volunteersCount! > 0)
                _buildDetailRow(
                  Icons.people,
                  'Number of Volunteers',
                  '${user.volunteersCount} active volunteers',
                ),
            ],
          ),

          const SizedBox(height: 20),

          // 5. ACHIEVEMENT BADGE
          _buildAchievementBadge(isRestaurant, completedCount),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- Helper Methods (_buildStatsCard, _buildInfoCard, etc.) must be defined below ---

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
