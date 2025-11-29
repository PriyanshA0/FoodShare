import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/donation_model.dart';
import 'package:fwm_sys/features/ngo/ngo_order_details_screen.dart';

class AcceptedOrdersScreen extends StatefulWidget {
  const AcceptedOrdersScreen({super.key});

  @override
  State<AcceptedOrdersScreen> createState() => _AcceptedOrdersScreenState();
}

class _AcceptedOrdersScreenState extends State<AcceptedOrdersScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Donation>> _acceptedDonations;

  // State to handle tab filtering
  String _selectedStatus =
      'Active'; // Initial status set to the merged 'Active'
  int _activeCount = 0; // Combined count for Accepted and In Transit
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAcceptedDonations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures data is fetched when navigating back to this screen
    _fetchAcceptedDonations();
  }

  void _fetchAcceptedDonations() {
    final newFuture = _apiService.getAcceptedDonations();

    if (!mounted) return;
    setState(() {
      // Reassigning the future object triggers a fresh fetch
      _acceptedDonations = newFuture;
    });
  }

  void _markInTransit(String donationId) async {
    try {
      final response = await _apiService.markInTransit(donationId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message']!)));

        // FIX: No need to switch tabs, just refresh the data on the current 'Active' tab.
        setState(() {
          _acceptedDonations = Future.value(
            [],
          ); // CRITICAL: Clear old data immediately to show loading spinner
          _acceptedDonations = _apiService
              .getAcceptedDonations(); // 2. Trigger new data fetch
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  void _markAsPickedUp(String donationId) async {
    try {
      final response = await _apiService.completePickup(donationId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message']!)));

        // FIX: Switch to 'Completed' tab after successful pickup
        setState(() {
          _acceptedDonations = Future.value(
            [],
          ); // CRITICAL: Clear old data immediately to show loading spinner
          _selectedStatus = 'Completed'; // 1. Update the selected tab state
          _acceptedDonations = _apiService
              .getAcceptedDonations(); // 2. Trigger new data fetch
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as picked up: $e')),
        );
      }
    }
  }

  // Helper to filter the list based on the selected tab
  List<Donation> _getFilteredList(List<Donation> donations) {
    if (_selectedStatus == 'Active') {
      // MERGED LOGIC: Show both 'accepted' AND 'in_transit' orders
      return donations
          .where((d) => d.status == 'accepted' || d.status == 'in_transit')
          .toList();
    } else if (_selectedStatus == 'Completed') {
      return donations.where((d) => d.status == 'picked_up').toList();
    }
    return [];
  }

  // Helper to calculate status counts (required for the tabs)
  void _calculateStatusCounts(List<Donation> donations) {
    int accepted = donations.where((d) => d.status == 'accepted').length;
    int inTransit = donations.where((d) => d.status == 'in_transit').length;

    _activeCount = accepted + inTransit; // Combined count
    _completedCount = donations.where((d) => d.status == 'picked_up').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Accepted Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Fixed height)
          const Padding(
            padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Accepted Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Manage your active and completed pickups',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),

          // Tabs and List Count Logic (Fixed height)
          FutureBuilder<List<Donation>>(
            future: _acceptedDonations,
            builder: (context, snapshot) {
              // Recalculate counts when data is available
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                _calculateStatusCounts(snapshot.data!);
              }

              // Updated Tab Titles (Only Active and Completed)
              final List<String> tabTitles = [
                'Active ($_activeCount)', // Merged tab
                'Completed ($_completedCount)',
              ];

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: tabTitles.map((tabText) {
                    final statusName = tabText.split(' ').first;
                    final isSelected = statusName == _selectedStatus;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(tabText),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedStatus = statusName;
                            });
                          }
                        },
                        selectedColor: AppColors.primary.withOpacity(0.9),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // Donation List
          Expanded(
            child: FutureBuilder<List<Donation>>(
              future: _acceptedDonations,
              builder: (context, snapshot) {
                // Check ConnectionState first to prevent faulty filtering
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
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
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No accepted orders fetched from API.'),
                  );
                }

                // Data is available, now filter it
                final filteredList = _getFilteredList(snapshot.data!);

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text('No $_selectedStatus orders found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final donation = filteredList[index];

                    return AcceptedDonationCard(
                      donation: donation,
                      onPickedUp: () => _markAsPickedUp(donation.id),
                      onInTransit: () => _markInTransit(donation.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW WIDGET: AcceptedDonationCard (Rich UI - Single Column) ---
class AcceptedDonationCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback onPickedUp;
  final VoidCallback onInTransit;

  const AcceptedDonationCard({
    super.key,
    required this.donation,
    required this.onPickedUp,
    required this.onInTransit,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_transit':
        return AppColors.accent; // Using accent/purple for in transit
      case 'picked_up':
        return AppColors.success;
      default:
        return AppColors.info; // Accepted
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(donation.status);
    final isAccepted = donation.status == 'accepted';
    final isInTransit = donation.status == 'in_transit';
    final isCompleted = donation.status == 'picked_up';

    final imageUrl = donation.imageUrl?.isNotEmpty == true
        ? donation.imageUrl!
        : 'https://placehold.co/600x200/CCCCCC/000000?text=Food';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // 1. Image Area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // 2. Details Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        donation.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        donation.status.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'From ${donation.restaurantName ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 15),

                // Info Rows
                _buildInfoRow(
                  Icons.storage,
                  'Quantity: ${donation.quantity} servings',
                ),
                _buildInfoRow(
                  Icons.schedule,
                  'Expires in: ${donation.expiryTime}',
                ),
                _buildInfoRow(
                  Icons.location_on,
                  'Pickup Location: ${donation.pickupLocation ?? 'N/A'}',
                ),
                _buildInfoRow(
                  Icons.contact_phone,
                  'Contact: ${donation.restaurantContact ?? 'N/A'}',
                ),

                const SizedBox(height: 15),

                // Action Buttons Row (Only if not completed)
                if (!isCompleted)
                  Column(
                    children: [
                      // Mark In Transit Button
                      ElevatedButton.icon(
                        onPressed: isAccepted ? onInTransit : null,
                        icon: const Icon(
                          Icons.delivery_dining,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Mark In Transit',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Mark as Picked Up Button
                      ElevatedButton.icon(
                        onPressed: isInTransit ? onPickedUp : null,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Mark as Picked Up',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // View Details Button
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NGOOrderDetailsScreen(
                                  donationId: donation.id,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'View Full Details',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),

                // Completed status message
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Collection Completed on ${donation.pickedUpAt?.substring(0, 10) ?? 'N/A'}',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
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
