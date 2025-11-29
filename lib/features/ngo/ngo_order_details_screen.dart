import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/donation_model.dart';
import 'package:intl/intl.dart';

class NGOOrderDetailsScreen extends StatefulWidget {
  final String donationId;
  const NGOOrderDetailsScreen({super.key, required this.donationId});

  @override
  State<NGOOrderDetailsScreen> createState() => _NGOOrderDetailsScreenState();
}

class _NGOOrderDetailsScreenState extends State<NGOOrderDetailsScreen> {
  late Future<Donation> _donationDetails;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  void _fetchDetails() {
    setState(() {
      _donationDetails = _apiService.fetchDonationDetails(widget.donationId);
    });
  }

  // --- NGO ACTIONS ---
  void _markInTransit() async {
    try {
      final response = await _apiService.markInTransit(widget.donationId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message']!)));
        _fetchDetails(); // Refresh view
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  void _markAsPickedUp() async {
    try {
      final response = await _apiService.completePickup(widget.donationId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message']!)));
        _fetchDetails(); // Refresh view
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as picked up: $e')),
        );
      }
    }
  }
  // --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Donation>(
        future: _donationDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Error loading details: ${snapshot.error}.'),
            );
          }

          final donation = snapshot.data!;
          final statusColor = _getStatusColor(donation.status);
          final statusText = donation.status.toUpperCase().replaceAll('_', ' ');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP STATUS AND ID ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order ID: ${donation.id}',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- NEW: SINGLE COLUMN FLOW ---

                // 1. MAIN DETAILS CARD
                _buildDonationDetailsCard(donation),
                const SizedBox(height: 20),

                // 2. QUICK ACTIONS (Stacked)
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildNGOQuickActions(context, donation.status),
                const SizedBox(height: 20),

                // 3. ORDER SUMMARY CARD
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(donation, statusColor),
                const SizedBox(height: 20),

                // 4. CONTACT INFORMATION CARD
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildContactCard(donation),
                const SizedBox(height: 20),

                // 5. ORDER TIMELINE
                const Text(
                  'Order Timeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildTimeline(donation),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
      case 'in_transit':
        return AppColors.info;
      case 'picked_up':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildDonationDetailsCard(Donation donation) {
    final imageUrl = donation.imageUrl?.isNotEmpty == true
        ? donation.imageUrl!
        : 'https://placehold.co/600x200/CCCCCC/000000?text=Food';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        // Changed from Row to Column for full width image
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full width Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 150, // Slightly reduced height
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    donation.category,
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ),
                const SizedBox(height: 15),

                // Details stacked below
                _buildDetailRow(
                  Icons.storage,
                  'Quantity: ${donation.quantity} servings',
                ),
                _buildDetailRow(
                  Icons.schedule,
                  'Expires: ${donation.expiryTime}',
                ),
                _buildDetailRow(
                  Icons.location_on,
                  'Pickup: ${donation.pickupLocation ?? 'N/A'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Donation donation) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoTile(
              Icons.store,
              'Donor',
              donation.restaurantName ?? 'N/A',
            ),
            const Divider(height: 15),
            _buildInfoTile(
              Icons.phone,
              'Contact Number',
              donation.restaurantContact ?? 'N/A',
            ),
            if (donation.ngoName != null) ...[
              const Divider(height: 15),
              _buildInfoTile(Icons.handshake, 'Accepted By', donation.ngoName!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Donation donation, Color statusColor) {
    final postedDate = DateFormat(
      'MM/dd/yyyy',
    ).format(DateTime.parse(donation.postedAt ?? '2000-01-01'));
    final pickedUpDate = donation.pickedUpAt != null
        ? DateFormat('MM/dd/yyyy').format(DateTime.parse(donation.pickedUpAt!))
        : 'N/A';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow('Posted Date', postedDate),
            _buildSummaryRow('Collected Date', pickedUpDate),
            _buildSummaryRow(
              'Current Status',
              donation.status.toUpperCase().replaceAll('_', ' '),
              statusColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // NGO Specific Quick Actions
  Widget _buildNGOQuickActions(BuildContext context, String status) {
    final isAccepted = status == 'accepted';
    final isInTransit = status == 'in_transit';
    final isCompleted = status == 'picked_up';

    if (isCompleted) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Order completed successfully.',
          style: TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mark In Transit Button (Purple)
            ElevatedButton.icon(
              onPressed: isAccepted ? _markInTransit : null,
              icon: const Icon(Icons.delivery_dining, color: Colors.white),
              label: const Text(
                'Mark In Transit',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, // Purple/Indigo
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Mark as Picked Up Button (Green)
            ElevatedButton.icon(
              onPressed: isInTransit ? _markAsPickedUp : null,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Mark as Picked Up',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, // Green
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Other buttons
            _buildActionButton(
              'Add Note',
              Icons.note_add,
              AppColors.info, // Use Info color for secondary actions
            ),
            const SizedBox(height: 10),
            _buildActionButton('Cancel Order', Icons.cancel, AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () {
        // Implement note/cancellation logic here
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label action triggered!')));
      },
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 40),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTimeline(Donation donation) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTimelineItem(
              'Donation Created',
              'Posted by ${donation.restaurantName}',
              donation.postedAt,
              Icons.access_time,
              AppColors.warning,
            ),
            if (donation.acceptedAt != null)
              _buildTimelineItem(
                'Order Accepted',
                'Accepted by ${donation.ngoName}',
                donation.acceptedAt,
                Icons.handshake,
                AppColors.info,
              ),
            if (donation.inTransitAt != null)
              _buildTimelineItem(
                'In Transit',
                'NGO is picking up the food',
                donation.inTransitAt,
                Icons.local_shipping,
                const Color(0xFF00BCD4),
              ),
            if (donation.pickedUpAt != null)
              _buildTimelineItem(
                'Picked Up',
                'Food collected successfully',
                donation.pickedUpAt,
                Icons.check_circle,
                AppColors.success,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    String? dateTimeStr,
    IconData icon,
    Color color,
  ) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return const SizedBox.shrink();
    }

    DateTime? dateTime;
    try {
      dateTime = DateTime.parse(dateTimeStr);
    } catch (e) {
      return SizedBox(
        height: 10,
        child: Text(
          'Invalid date format for $title',
          style: TextStyle(color: AppColors.error),
        ),
      );
    }

    final date = DateFormat('MM/dd/yyyy').format(dateTime);
    final time = DateFormat('h:mm a').format(dateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
