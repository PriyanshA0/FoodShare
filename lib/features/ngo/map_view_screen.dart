// import 'package:flutter/material.dart';
// import 'package:fwm_sys/core/constants/colors.dart';
// import 'package:fwm_sys/models/donation_model.dart';

// class MapViewScreen extends StatelessWidget {
//   final double currentLat;
//   final double currentLon;
//   final List<Donation> nearbyDonations;

//   const MapViewScreen({
//     super.key,
//     required this.currentLat,
//     required this.currentLon,
//     required this.nearbyDonations,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Donations Map View (10 km)'),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Stack(
//         children: [
//           // --- Map Placeholder ---
//           Container(
//             color: Colors.grey[300],
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.map,
//                     size: 80,
//                     color: AppColors.textSecondary,
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     'Map Integration Placeholder',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: AppColors.textSecondary,
//                     ),
//                   ),
//                   Text(
//                     'Showing ${nearbyDonations.length} orders within 10 km.',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: AppColors.textSecondary,
//                     ),
//                   ),
//                   Text(
//                     'Your Location: (${currentLat.toStringAsFixed(4)}, ${currentLon.toStringAsFixed(4)})',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: AppColors.textSecondary,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // --- End Map Placeholder ---

//           // Floating List of Donations (for UX)
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               height: 200,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                 boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Text(
//                       'Nearby Posts (${nearbyDonations.length})',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: nearbyDonations.length,
//                       itemBuilder: (context, index) {
//                         final donation = nearbyDonations[index];
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                           child: _buildMapCard(donation),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMapCard(Donation donation) {
//     final distance = donation.distanceKm != null
//         ? '${donation.distanceKm!.toStringAsFixed(1)} km away'
//         : 'N/A';

//     return Container(
//       width: 150,
//       margin: const EdgeInsets.only(bottom: 10),
//       decoration: BoxDecoration(
//         color: AppColors.cardBgNgo,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: AppColors.info.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ClipRRect(
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//             child: Image.network(
//               donation.imageUrl ?? 'https://placehold.co/150',
//               height: 60,
//               width: 150,
//               fit: BoxFit.cover,
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   donation.title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 13,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 Text(
//                   donation.restaurantName ?? 'Hotel',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     Icon(Icons.near_me, size: 14, color: AppColors.info),
//                     const SizedBox(width: 4),
//                     Text(
//                       distance,
//                       style: TextStyle(fontSize: 12, color: AppColors.info),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
