import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/donation_model.dart';

class HistoryAnalyticsScreen extends StatefulWidget {
  const HistoryAnalyticsScreen({super.key});

  @override
  State<HistoryAnalyticsScreen> createState() => _HistoryAnalyticsScreenState();
}

class _HistoryAnalyticsScreenState extends State<HistoryAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Donation>> _donationHistory;

  @override
  void initState() {
    super.initState();
    _donationHistory = _apiService.getHotelHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Reports'),

        // Explicitly set the background to the new primary color
        backgroundColor: AppColors.primary,

        // Ensure the title and icons are visible against the dark primary color
        foregroundColor: Colors.white,

        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completed Donations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<Donation>>(
              future: _donationHistory,
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
                      child: Text('No completed donation history found.'),
                    ),
                  );
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final donation = snapshot.data![index];
                      return _buildHistoryItem(
                        title: donation.title,
                        ngoName: donation.ngoName ?? 'N/A',
                        date: donation.pickedUpAt ?? donation.postedAt ?? 'N/A',
                      );
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

  Widget _buildHistoryItem({
    required String title,
    required String ngoName,
    required String date,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.check_circle, color: AppColors.success),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Collected by $ngoName'),
        trailing: Text(date.substring(0, 10)),
      ),
    );
  }
}
