import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/features/ngo/view_food_posts_screen.dart';
import 'package:fwm_sys/features/ngo/accepted_orders_screen.dart';
import 'package:fwm_sys/features/ngo/collection_summary_screen.dart';
import 'package:fwm_sys/features/common/notifications_screen.dart';
import 'package:fwm_sys/features/common/profile_screen.dart';
import 'package:fwm_sys/features/auth/login_screen.dart';

class NGODashboard extends StatelessWidget {
  const NGODashboard({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await ApiService().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<Map<String, dynamic>> _fetchNgoCompositeData() async {
    final statsFuture = ApiService().fetchDashboardStats();
    final userFuture = ApiService().fetchUserData();

    final results = await Future.wait([statsFuture, userFuture]);

    return {'stats': results[0], 'user_data': results[1]};
  }

  @override
  Widget build(BuildContext context) {
    // The top-level FutureBuilder fetches data needed for the Scaffold and body.
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchNgoCompositeData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final bool hasError = snapshot.hasError;

        if (hasError) {
          return Center(child: Text('Failed to load data: ${snapshot.error}'));
        }

        // Show loading spinner if data isn't ready
        if (snapshot.connectionState == ConnectionState.waiting ||
            data == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Fetch necessary data parts
        final stats = data['stats'] ?? {};
        final userData = data['user_data'] ?? {};

        // --- SAFELY EXTRACT AND CAST DATA ---
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

        // FIX 1: Extract Organization Name and Contact Person reliably
        String orgName = userData['name'] ?? 'Food Aid Foundation';
        final String? contactPersonRaw = userData['contact_person'] as String?;

        // 2. Check if the retrieved value is non-null AND non-empty.
        String contactPerson =
            (contactPersonRaw != null && contactPersonRaw.isNotEmpty)
            ? contactPersonRaw
            : 'Volunteer';
        String registrationNo = userData['verification_detail'] ?? 'N/A';
        String volunteers = userData['volunteers_count']?.toString() ?? '0';
        String address = userData['address'] ?? 'N/A';
        String contactNo = userData['contact_number'] ?? 'N/A';

        // Safely format strings
        String availablePosts = availablePostsCount.toString();
        String pendingPickups = activeOrdersCount.toString();
        String foodCollected = '${foodCollectedKg.toStringAsFixed(0)} kg';
        String mealsDistributed = '$mealsDistributedEstimate+';

        // --- DYNAMICALLY RETURNED SCAFFOLD (uses orgName in title) ---
        return Scaffold(
          backgroundColor: AppColors.background,

          // --- DYNAMIC APP BAR (uses fetched orgName) ---
          appBar: AppBar(
            // Ensures no default back button is added
            automaticallyImplyLeading: false,

            // --- USES THE FETCHED NGO NAME ---
            title: Text(
              orgName, // <--- orgName is now accessible here!
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Set a solid, visible background color
            backgroundColor: Colors.white,

            // Add a slight shadow
            elevation: 2,

            actions: [
              // --- NEW: View Food Posts Icon (beside the bell) ---
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
              // --- Existing: Notifications Icon (Bell) ---
              IconButton(
                icon: const Badge(
                  label: Text('0'),
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
              // --- Existing: Profile Icon ---
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
              // --- Existing: Logout Icon ---
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
                          'Welcome, $contactPerson!',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Find and collect food donations from local restaurants',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // === STATS CARDS ===
                  _buildNgoStatCard(
                    title: 'Available Posts',
                    value: availablePosts,
                    subtitle: 'Ready to accept',
                    icon: Icons.search,
                    color: AppColors.warning,
                  ),
                  _buildNgoStatCard(
                    title: 'Pending Pickups',
                    value: pendingPickups,
                    subtitle: 'Awaiting collection',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.info,
                  ),
                  _buildNgoStatCard(
                    title: 'Food Collected',
                    value: foodCollected,
                    subtitle: 'Total confirmed collections',
                    icon: Icons.ssid_chart,
                    color: AppColors.success,
                  ),
                  _buildNgoStatCard(
                    title: 'Meals Distributed',
                    value: mealsDistributed,
                    subtitle: 'People helped',
                    icon: Icons.people_alt,
                    color: const Color(0xFF9C27B0),
                  ),

                  const SizedBox(height: 24),
                  // === QUICK ACTION CARDS ===
                  _buildNgoActionCard(
                    context,
                    title: 'View Food Posts',
                    subtitle:
                        'Browse available food donations from restaurants and hotels',
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
                  _buildNgoActionCard(
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
                  _buildNgoActionCard(
                    context,
                    title: 'Collection Summary',
                    subtitle:
                        'View your impact, analytics and collection history',
                    icon: Icons.bar_chart_outlined,
                    iconColor: const Color(0xFF9C27B0),
                    badgeText: '',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CollectionSummaryScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  // === ORGANIZATION DETAILS (Using Fetched Data) ===
                  const Text(
                    'Organization Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildNgoDetailCard(
                    orgName: orgName,
                    regNo: registrationNo,
                    volunteers: volunteers,
                    address: address,
                    contact: contactNo,
                  ),

                  // FIX: Add space to clear the Bottom Navigation Bar
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
        // --- END DYNAMICALLY RETURNED SCAFFOLD ---
      },
    );
  }

  // --- Helper methods (Omitted for brevity) ---
  Widget _buildNgoStatCard({
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

  Widget _buildNgoActionCard(
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

  Widget _buildNgoDetailCard({
    required String orgName,
    required String regNo,
    required String volunteers,
    required String address,
    required String contact,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Organization Name', orgName),
            _buildDetailRow('Registration Number', regNo),
            _buildDetailRow('Volunteers', '$volunteers active volunteers'),
            _buildDetailRow('Contact', contact),
            _buildDetailRow('Address', address),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
