import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/donation_model.dart';
import 'package:fwm_sys/features/ngo/ngo_order_details_screen.dart';
import 'package:intl/intl.dart';

class CollectionSummaryScreen extends StatefulWidget {
  const CollectionSummaryScreen({super.key});

  @override
  State<CollectionSummaryScreen> createState() =>
      _CollectionSummaryScreenState();
}

class _CollectionSummaryScreenState extends State<CollectionSummaryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Donation>> _collectionHistory;

  @override
  void initState() {
    super.initState();
    _collectionHistory = _apiService.getNgoHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Collection Summary'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collection History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<Donation>>(
              future: _collectionHistory,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading history: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No completed collections history found.'),
                    ),
                  );
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final donation = snapshot.data![index];
                      // Use the new detailed card
                      return CompletedCollectionCard(donation: donation);
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- NEW WIDGET: CompletedCollectionCard (Detailed History Card) ---
class CompletedCollectionCard extends StatelessWidget {
  final Donation donation;

  const CompletedCollectionCard({super.key, required this.donation});

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 8),
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
    final collectedDate = donation.pickedUpAt != null
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(donation.pickedUpAt!))
        : 'N/A';
    final imageUrl = donation.imageUrl?.isNotEmpty == true
        ? donation.imageUrl!
        : 'https://placehold.co/600x100/D3F4D3/000000?text=Completed';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to details on tap
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NGOOrderDetailsScreen(donationId: donation.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image and Title Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Collected from ${donation.restaurantName ?? 'N/A'}',
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
              const SizedBox(height: 15),

              // Details Grid
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            Icons.calendar_month,
                            collectedDate,
                            color: AppColors.success,
                          ),
                          _buildDetailRow(
                            Icons.storage,
                            '${donation.quantity} servings',
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(
                      width: 20,
                      thickness: 1,
                      color: Color(0xFFE0E0E0),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            Icons.location_on,
                            donation.pickupLocation ?? 'N/A',
                          ),
                          _buildDetailRow(
                            Icons.assignment,
                            'Order ID: ${donation.id}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              // View Details Footer
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NGOOrderDetailsScreen(donationId: donation.id),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: AppColors.info,
                  ),
                  label: Text(
                    'View Full Timeline',
                    style: TextStyle(color: AppColors.info),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
