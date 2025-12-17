import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/donation_model.dart';
import 'package:fwm_sys/features/restaurant/order_details_screen.dart'; // New Import
import 'package:fwm_sys/features/restaurant/donate_food_screen.dart'; // For Upload button

class FoodStatusScreen extends StatefulWidget {
  const FoodStatusScreen({super.key});

  @override
  State<FoodStatusScreen> createState() => _FoodStatusScreenState();
}

class _FoodStatusScreenState extends State<FoodStatusScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Donation>> _myDonations;

  // State to handle tab filtering
  String _selectedStatus = 'All';
  int _allCount = 0;
  int _pendingCount = 0;
  int _acceptedCount = 0;
  int _inTransitCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDonationsAndStats();
  }

  // Method to trigger refresh when returning from details/upload screen
  void _refreshData() {
    setState(() {
      _myDonations = _apiService.getMyDonations();
    });
  }

  // Refreshes data and updates tab counts
  void _fetchDonationsAndStats() {
    _myDonations = _apiService.getMyDonations();
  }

  // Helper to filter the list based on the selected tab
  List<Donation> _getFilteredList(List<Donation> donations) {
    if (_selectedStatus == 'All') return donations;

    final statusMap = {
      'Pending': 'pending',
      'Accepted': 'accepted',
      'In Transit': 'in_transit',
      'Completed': 'picked_up',
      'Cancelled': 'cancelled',
    };

    final filterStatus = statusMap[_selectedStatus];
    if (filterStatus == null) return donations;

    return donations.where((d) => d.status == filterStatus).toList();
  }

  // Helper to calculate status counts (required for the tabs)
  void _calculateStatusCounts(List<Donation> donations) {
    _allCount = donations.length;
    _pendingCount = donations.where((d) => d.status == 'pending').length;
    _acceptedCount = donations.where((d) => d.status == 'accepted').length;
    _inTransitCount = donations.where((d) => d.status == 'in_transit').length;
    _completedCount = donations.where((d) => d.status == 'picked_up').length;
    _cancelledCount = donations.where((d) => d.status == 'cancelled').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Donation Status'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header and Upload Button
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Food Donation Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track your donations and their progress',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DonateFoodScreen(),
                      ),
                    );
                    _refreshData(); // Refresh list after returning
                  },
                  icon: const Icon(Icons.upload, size: 20, color: Colors.white),
                  label: const Text(
                    'Upload New Donation',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Tabs
          FutureBuilder<List<Donation>>(
            future: _myDonations,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                _calculateStatusCounts(snapshot.data!);
              }

              final List<String> tabs = [
                'All ($_allCount)',
                'Pending ($_pendingCount)',
                'Accepted ($_acceptedCount)',
                'In Transit ($_inTransitCount)',
                'Completed ($_completedCount)',
                'Cancelled ($_cancelledCount)',
              ];

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    itemBuilder: (context, index) {
                      final tabText = tabs[index];
                      final statusName = tabText.split(' ').first;
                      final isSelected = statusName == _selectedStatus;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStatus = statusName;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            tabText,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Donation List
          Expanded(
            child: FutureBuilder<List<Donation>>(
              future: _myDonations,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // Show specific error for debugging
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No donations posted yet.'));
                } else {
                  final filteredList = _getFilteredList(snapshot.data!);
                  if (filteredList.isEmpty) {
                    return Center(
                      child: Text('No $_selectedStatus donations found.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final donation = filteredList[index];
                      return DonationStatusCard(donation: donation);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DonationStatusCard extends StatelessWidget {
  final Donation donation;

  const DonationStatusCard({super.key, required this.donation});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.info;
      case 'in_transit':
        return const Color(0xFF00BCD4); // Light Cyan for In Transit
      case 'picked_up':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  bool _isUrgent(String? expiryTime) {
    // Basic check: if expiry time contains 'hour' and the number is 6 or less.
    if (expiryTime == null || !expiryTime.toLowerCase().contains('hour')) {
      return false;
    }
    try {
      final parts = expiryTime.split(' ');
      if (parts.isNotEmpty) {
        final hours = int.tryParse(parts[0]);
        return hours != null && hours <= 6;
      }
    } catch (_) {}
    return false;
  }

  // Helper for displaying details in a single column
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(donation.status);
    final statusText = donation.status.toUpperCase().replaceAll('_', ' ');
    final isUrgent = _isUrgent(donation.expiryTime);

    final imageUrl = donation.imageUrl?.isNotEmpty == true
        ? donation.imageUrl!
        : 'https://placehold.co/600x400/CCCCCC/000000?text=FoodShare';

    // Status box content (message depending on status)
    String statusMessage = 'Waiting for an NGO to accept this donation';
    IconData statusIcon = Icons.watch_later;
    Color messageColor = AppColors.warning;

    if (donation.status == 'accepted' || donation.status == 'in_transit') {
      statusMessage = 'Accepted by: ${donation.ngoName ?? 'Unknown NGO'}';
      statusIcon = Icons.check_circle;
      messageColor = AppColors.info;
    } else if (donation.status == 'picked_up') {
      statusMessage =
          'Successfully collected on ${donation.pickedUpAt?.substring(0, 10) ?? 'N/A'}';
      statusIcon = Icons.task_alt;
      messageColor = AppColors.success;
    } else if (donation.status == 'cancelled') {
      statusMessage = 'Donation was cancelled.';
      statusIcon = Icons.cancel;
      messageColor = AppColors.error;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. IMAGE AREA ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: AppColors.background,
                    child: Center(
                      child: Text(
                        'Image Error: ${donation.title}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
              if (isUrgent && donation.status == 'pending')
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Urgent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // --- 2. DETAILS CONTENT ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        donation.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Status Badge (Aligned right, matching design)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Category (Small Text)
                Text(
                  donation.category,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),

                // Quantity, Expiry, Location details using single column style
                _buildDetailRow(
                  Icons.storage,
                  'Quantity',
                  '${donation.quantity} servings',
                ),
                _buildDetailRow(
                  Icons.schedule,
                  'Expiry Time',
                  donation.expiryTime,
                ),
                _buildDetailRow(
                  Icons.location_on,
                  'Pickup Location',
                  donation.pickupLocation ?? 'N/A',
                ),

                const SizedBox(height: 10),

                // Status/Accepted Info Box (Matching yellow/info box design)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: messageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 18, color: messageColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusMessage,
                          style: TextStyle(
                            color: messageColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // View Details Button
                ElevatedButton.icon(
                  onPressed: () async {
                    // Navigate to the Order Details Screen and refresh when done
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailsScreen(donationId: donation.id),
                      ),
                    );
                    // No need to manually refresh here, the status screen handles its own fetch
                  },
                  icon: const Icon(Icons.visibility, color: Colors.white),
                  label: const Text(
                    'View Details',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
