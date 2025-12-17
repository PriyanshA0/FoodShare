import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/donation_model.dart';
import 'package:intl/intl.dart';

// You need to install the intl package: flutter pub add intl

class OrderDetailsScreen extends StatelessWidget {
  final String donationId;
  const OrderDetailsScreen({super.key, required this.donationId});

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
        future: ApiService().fetchDonationDetails(donationId),
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

                // --- STACKED DETAILS (Single Column) ---
                // Replaced the Row layout with a single Column for mobile-friendly stacking
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Donation Card
                    _buildDonationDetailsCard(donation),
                    const SizedBox(height: 20),

                    // 2. Contact Information
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildContactCard(donation),
                    const SizedBox(height: 20),

                    // 3. Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildQuickActions(context, donation.status),
                    const SizedBox(height: 20),

                    // 4. Order Summary
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryCard(donation, statusColor),
                    const SizedBox(height: 20),

                    // 5. Order Timeline
                    const Text(
                      'Order Timeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTimeline(donation),
                    const SizedBox(height: 40),
                  ],
                ),
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
    // Improved placeholder for better visual fallback
    final imageUrl = donation.imageUrl?.isNotEmpty == true
        ? donation.imageUrl!
        : 'https://placehold.co/100x100/A3E4D7/000000?text=Food+Image';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                // Handle image load error to display the placeholder gracefully
                errorBuilder: (context, error, stackTrace) => Image.network(
                  'https://placehold.co/100x100/A3E4D7/000000?text=Load+Error',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.title,
                    style: const TextStyle(
                      fontSize: 18,
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
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.storage,
                    '${donation.quantity} servings',
                  ),
                  _buildDetailRow(Icons.schedule, donation.expiryTime),
                  _buildDetailRow(
                    Icons.location_on,
                    donation.pickupLocation ?? 'N/A',
                  ),
                  // Display Coordinates if available
                  if (donation.latitude != null && donation.longitude != null)
                    _buildDetailRow(
                      Icons.gps_fixed,
                      'Lat: ${donation.latitude!.toStringAsFixed(4)}, Lon: ${donation.longitude!.toStringAsFixed(4)}',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoTile(
              Icons.store,
              'Hotel Name',
              donation.restaurantName ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.phone,
              'Contact Number',
              donation.restaurantContact ?? 'N/A',
            ),
            if (donation.ngoName != null)
              _buildInfoTile(Icons.handshake, 'Accepted By', donation.ngoName!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildSummaryRow('Posted', postedDate),
            _buildSummaryRow('Picked Up', pickedUpDate),
            _buildSummaryRow(
              'Status',
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String status) {
    if (status == 'pending') {
      return Column(
        children: [
          _buildActionButton(
            context,
            'Add Note',
            Icons.note_add,
            AppColors.info,
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            context,
            'Cancel Order',
            Icons.cancel,
            AppColors.error,
          ),
        ],
      );
    }
    // Only pending orders can be cancelled or modified from the hotel side
    return const SizedBox.shrink();
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return OutlinedButton.icon(
      onPressed: () {
        // Implement cancellation/note logic here (e.g., calling API)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label action triggered!')));
      },
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 40),
        side: BorderSide(color: color),
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
              'Posted by Grand Hotel',
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

    // Attempt to parse DateTime, handle potential format issues gracefully
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.w600)),
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
