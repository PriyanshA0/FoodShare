import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/features/auth/login_screen.dart';
import 'dart:async'; // Required for Timer

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _pendingUsersFuture;
  late Future<List<Map<String, dynamic>>> _allUsersFuture;
  late Future<List<Map<String, dynamic>>>
  _allDonationsFuture; // NEW: For All Orders Tab
  late Timer _timer;

  // State to track if data has loaded at least once
  bool _isInitialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // FIX: 5-second refresh interval to prevent blinking.
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        // We only call setState inside _fetchData to update the futures.
        _fetchData();
      }
    });
  }

  void _fetchData() {
    // We only set _isInitialDataLoaded once, when the first data fetch completes successfully.

    // Set state once to update all Futures
    setState(() {
      _pendingUsersFuture = _apiService.fetchPendingUsers();

      // Fetch All Users
      _allUsersFuture = _apiService
          .fetchAllUsersAdmin()
          .then((data) {
            if (!_isInitialDataLoaded) {
              // Mark initial load complete only upon success
              _isInitialDataLoaded = true;
            }
            return data;
          })
          .catchError((e) {
            print("Admin Users Fetch Error: $e");
            // The Dart Type Error is fixed by ensuring the underlying ApiService throws an Exception
            // which is caught here and properly returned as a Future.error.
            // ignore: invalid_return_type_for_catch_error
            return Future.error(e);
          });

      // NEW: Fetch All Donations
      _allDonationsFuture = _apiService.fetchAllDonationsAdmin().catchError((
        e,
      ) {
        print("Admin Donations Fetch Error: $e");
        // ignore: invalid_return_type_for_catch_error
        return Future.error(e);
      });
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    _timer.cancel();
    await _apiService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      final response = await _apiService.updateUserStatus(userId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Status updated successfully!',
            ),
          ),
        );
        _fetchData(); // Refresh the lists
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  // NOTE: Order status updates are not typically done on the Admin Dashboard,
  // but they view the status, which is updated by NGO/Restaurant actions.

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Changed from 2 to 3
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Admin Console'),
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _handleLogout(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Users', icon: Icon(Icons.person_add_alt_1)),
              Tab(text: 'All Users', icon: Icon(Icons.group)),
              Tab(
                text: 'All Orders',
                icon: Icon(Icons.track_changes),
              ), // NEW TAB
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.accent,
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingUsersTab(),
            _buildAllUsersTab(),
            _buildAllOrdersTab(), // NEW TAB VIEW
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pendingUsersFuture,
      builder: (context, snapshot) {
        // FIX: Only show spinner on the *very first* load.
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialDataLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          );
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No new users pending approval.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return UserManagementCard(
              user: user,
              isPending: true, // Show Approval buttons
              onApprove: () =>
                  _updateUserStatus(user['user_id'].toString(), 'approved'),
              onSuspend: () =>
                  _updateUserStatus(user['user_id'].toString(), 'suspended'),
            );
          },
        );
      },
    );
  }

  Widget _buildAllUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _allUsersFuture,
      builder: (context, snapshot) {
        // FIX: Only show spinner on the *very first* load.
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialDataLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error loading all users: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          );
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No users found in the system.'));
        }

        // Sort users so pending users appear first
        users.sort((a, b) {
          if (a['status'] == 'pending' && b['status'] != 'pending') return -1;
          if (a['status'] != 'pending' && b['status'] == 'pending') return 1;
          return a['created_at'].compareTo(b['created_at']);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final bool isPending = user['status'] == 'pending';

            return UserManagementCard(
              user: user,
              isPending: isPending,
              onApprove: () =>
                  _updateUserStatus(user['user_id'].toString(), 'approved'),
              onSuspend: () =>
                  _updateUserStatus(user['user_id'].toString(), 'suspended'),
            );
          },
        );
      },
    );
  }

  // NEW: All Orders Tab View
  Widget _buildAllOrdersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _allDonationsFuture,
      builder: (context, snapshot) {
        // FIX: Only show spinner on the *very first* load.
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialDataLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error loading orders: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          );
        }
        final donations = snapshot.data ?? [];
        if (donations.isEmpty) {
          return const Center(child: Text('No donation records found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index];
            return OrderManagementCard(donation: donation);
          },
        );
      },
    );
  }
}

// Reusable card component for user approval/management
class UserManagementCard extends StatelessWidget {
  // ... (UserManagementCard code omitted for brevity but is unchanged)
  // ...

  final Map<String, dynamic> user;
  final VoidCallback onApprove;
  final VoidCallback onSuspend;
  final bool isPending;

  const UserManagementCard({
    super.key,
    required this.user,
    required this.onApprove,
    required this.onSuspend,
    required this.isPending,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    // CRITICAL FIX: Ensure value is explicitly checked for null before being passed to toString()
    final String text = (value == null || value.toString().isEmpty)
        ? 'N/A'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: $text',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safely retrieve status, defaulting to 'unknown' if the key itself is missing
    final String status = user['status']?.toString() ?? 'unknown';
    final statusColor = _getStatusColor(status);

    // Safely extract data, providing default strings for null values for better display
    // Using ?? 'N/A' after the optional chaining operator (?.) is the safest way.
    final String organizationName =
        user['organization_name']?.toString() ?? 'General User';
    final String contactPerson =
        user['contact_person']?.toString() ??
        (user['role']?.toString().toUpperCase() ?? 'N/A');
    final String verificationDetail =
        user['verification_detail']?.toString() ?? 'N/A';
    final String email = user['email']?.toString() ?? 'N/A';
    final String contact = user['contact']?.toString() ?? 'N/A';
    final String address = user['address']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isPending ? AppColors.warning.withOpacity(0.05) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Role and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    user['role']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(color: AppColors.info),
                  ),
                  backgroundColor: AppColors.info.withOpacity(0.1),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Organization Info
            Text(
              organizationName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Contact: $contactPerson',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // Details
            _buildDetailRow(Icons.email, 'Email', email),
            _buildDetailRow(Icons.phone, 'Contact', contact),
            _buildDetailRow(Icons.location_on, 'Address', address),
            _buildDetailRow(
              Icons.verified_user,
              'Verification ID',
              verificationDetail,
            ),
            const SizedBox(height: 16),

            // Action Buttons (Conditional on status)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Suspend/Reactivate Button Group
                if (status == 'approved' || status == 'pending')
                  // Suspend Button (Visible for Approved and Pending)
                  TextButton.icon(
                    onPressed: onSuspend,
                    icon: const Icon(
                      Icons.block,
                      size: 18,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Suspend',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),

                if (status == 'suspended')
                  // Reactivate Button (Visible for Suspended)
                  ElevatedButton.icon(
                    onPressed: onApprove, // Reuse approve logic to reactivate
                    icon: const Icon(Icons.undo, size: 18, color: Colors.white),
                    label: const Text(
                      'Reactivate',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                    ),
                  ),

                const SizedBox(width: 8),

                // Approve Button (Only for Pending)
                if (isPending)
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Approve',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// NEW WIDGET: Card to display a single donation lifecycle
class OrderManagementCard extends StatelessWidget {
  final Map<String, dynamic> donation;

  const OrderManagementCard({super.key, required this.donation});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'picked_up':
      case 'completed':
        return AppColors.success;
      case 'in_transit':
        return AppColors.accent;
      case 'accepted':
        return AppColors.info;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    // Assuming dateTime comes as a string timestamp
    String dt = dateTime.toString();
    try {
      return '${dt.substring(0, 10)} ${dt.substring(11, 16)}';
    } catch (_) {
      return dt;
    }
  }

  Widget _buildLifecycleRow(String label, dynamic value) {
    final String text = (value == null || value.toString().isEmpty)
        ? 'N/A'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String status = donation['status']?.toString() ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final String title = donation['title']?.toString() ?? 'Unknown Donation';
    final String restaurantName =
        donation['restaurant_name']?.toString() ?? 'N/A';
    final String ngoName =
        donation['ngo_name']?.toString() ?? 'Awaiting Acceptance';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),

            // Key Details
            _buildLifecycleRow('ID', donation['id']),
            _buildLifecycleRow('Source', restaurantName),
            _buildLifecycleRow('Recipient', ngoName),
            _buildLifecycleRow(
              'Quantity',
              '${donation['quantity'] ?? 'N/A'} servings',
            ),
            _buildLifecycleRow('Category', donation['category']),
            _buildLifecycleRow(
              'Posted At',
              _formatDateTime(donation['posted_at']),
            ),

            const Divider(height: 20, thickness: 1),

            // Order Lifecycle Timestamps
            const Text(
              'Lifecycle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildLifecycleRow(
              'Accepted At',
              _formatDateTime(donation['accepted_at']),
            ),
            _buildLifecycleRow(
              'In Transit At',
              _formatDateTime(donation['in_transit_at']),
            ),
            _buildLifecycleRow(
              'Picked Up At',
              _formatDateTime(donation['picked_up_at']),
            ),
          ],
        ),
      ),
    );
  }
}
