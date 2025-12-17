import 'package:flutter/material.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/donation_model.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/features/ngo/ngo_order_details_screen.dart';

class ViewFoodPostsScreen extends StatefulWidget {
  const ViewFoodPostsScreen({super.key});

  @override
  State<ViewFoodPostsScreen> createState() => _ViewFoodPostsScreenState();
}

class _ViewFoodPostsScreenState extends State<ViewFoodPostsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Donation>> _donations;

  // Filtering state (retained for search functionality)
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedUrgency = 'All';

  @override
  void initState() {
    super.initState();
    _fetchDonations(); // Fetch posts immediately, no location needed
  }

  void _fetchDonations() {
    setState(() {
      // API call reverted to simple getAllDonations() without location args
      _donations = _apiService.getAllDonations();
    });
  }

  // Helper to filter the list based on search/category/urgency (retains the logic)
  List<Donation> _getFilteredList(List<Donation> allDonations) {
    return allDonations.where((d) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.restaurantName?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ==
              true;

      final matchesCategory =
          _selectedCategory == 'All' ||
          d.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesUrgency =
          _selectedUrgency == 'All' ||
          (_selectedUrgency == 'Urgent' && _isUrgent(d.expiryTime)) ||
          (_selectedUrgency == 'Standard' && !_isUrgent(d.expiryTime));

      return matchesSearch && matchesCategory && matchesUrgency;
    }).toList();
  }

  bool _isUrgent(String expiryTime) {
    if (!expiryTime.toLowerCase().contains('hour')) return false;
    try {
      final hours = int.tryParse(expiryTime.split(' ')[0]);
      return hours != null && hours <= 6;
    } catch (_) {
      return false;
    }
  }

  void _acceptOrder(String donationId) async {
    try {
      final response = await _apiService.acceptDonation(donationId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message']!)));
        _fetchDonations(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept order: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Reverted title
        title: const Text('Available Food Donations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Food Donations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Simple status message
                Text(
                  'Browse posts from all registered restaurants.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Search and Filter Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search by title, hotel, or location...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        label: 'Categories',
                        options: const ['All', 'veg', 'non-veg', 'mixed'],
                        currentValue: _selectedCategory,
                        onChanged: (newValue) =>
                            setState(() => _selectedCategory = newValue!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        label: 'Urgency',
                        options: const ['All', 'Urgent', 'Standard'],
                        currentValue: _selectedUrgency,
                        onChanged: (newValue) =>
                            setState(() => _selectedUrgency = newValue!),
                      ),
                    ),
                  ],
                ),

                // Map button is removed completely
                const SizedBox(height: 10),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Donation>>(
              future: _donations,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('API Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No food posts currently available.'),
                  );
                } else {
                  final filteredList = _getFilteredList(snapshot.data!);

                  if (filteredList.isEmpty) {
                    return const Center(
                      child: Text('No donations matching your filters.'),
                    );
                  }

                  // --- CHANGE: Use ListView.builder for single column rich cards ---
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final donation = filteredList[index];
                      return FoodPostRichCard(
                        // Renamed card for clarity
                        donation: donation,
                        isUrgent: _isUrgent(donation.expiryTime),
                        onAccept: () => _acceptOrder(donation.id),
                        onViewDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NGOOrderDetailsScreen(
                                donationId: donation.id,
                              ),
                            ),
                          );
                        },
                      );
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

  Widget _buildFilterDropdown({
    required String label,
    required List<String> options,
    required String currentValue,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: currentValue,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// --- NEW WIDGET: FoodPostRichCard (Matches Single Column Design) ---
class FoodPostRichCard extends StatelessWidget {
  final Donation donation;
  final bool isUrgent;
  final VoidCallback onAccept;
  final VoidCallback onViewDetails;

  const FoodPostRichCard({
    super.key,
    required this.donation,
    required this.isUrgent,
    required this.onAccept,
    required this.onViewDetails,
  });

  Widget _buildDetailRow(IconData icon, String text, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isStatus ? AppColors.error : AppColors.textPrimary,
                fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
              ),
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
    final imageUrl = donation.imageUrl?.isNotEmpty == true
        ? donation.imageUrl!
        : 'https://placehold.co/600x200/D3F4D3/000000?text=FoodShare';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Image Area with Urgency Tag ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: AppColors.background,
                    child: Center(
                      child: Text(
                        'Image Unavailable: ${donation.title}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
              if (isUrgent)
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Urgent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // --- Details Content ---
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
                        ),
                      ),
                    ),
                    // Category Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        donation.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  donation.restaurantName ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 15),

                // Info Rows
                _buildDetailRow(Icons.storage, '${donation.quantity} servings'),
                _buildDetailRow(
                  Icons.schedule,
                  donation.expiryTime,
                  isStatus: isUrgent,
                ),
                _buildDetailRow(
                  Icons.location_on,
                  donation.pickupLocation ?? 'N/A',
                ),
                _buildDetailRow(
                  Icons.contact_phone,
                  donation.restaurantContact ?? 'N/A',
                ),

                const SizedBox(height: 20),

                // Action Button (Accept Order)
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.accent, // Use accent color for accept button
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Accept Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Secondary action: View Details (tappable text)
                Center(
                  child: TextButton(
                    onPressed: onViewDetails,
                    child: Text(
                      'View Details',
                      style: TextStyle(color: AppColors.textSecondary),
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
