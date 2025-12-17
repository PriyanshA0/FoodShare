// lib/models/donation_model.dart

class Donation {
  final String id;
  final String title;
  final String category;
  final int quantity;
  final String expiryTime;
  final String status;
  final String? pickupLocation;
  final String? imageUrl;
  final String? restaurantName;
  final String? ngoName;
  final String? postedAt;

  // --- LIFECYCLE TIMESTAMPS ---
  final String? acceptedAt;
  final String? inTransitAt;
  final String? pickedUpAt;
  // --- CONTACT DETAILS ---
  final String? restaurantContact;

  // --- LOCATION FIELDS ---
  // These fields match the ones used in the OrderDetailsScreen
  final double? latitude;
  final double? longitude;

  Donation({
    required this.id,
    required this.title,
    required this.category,
    required this.quantity,
    required this.expiryTime,
    required this.status,
    this.pickupLocation,
    this.imageUrl,
    this.restaurantName,
    this.ngoName,
    this.postedAt,
    this.acceptedAt,
    this.inTransitAt,
    this.pickedUpAt,
    this.restaurantContact,
    // Using donation-specific location fields
    this.latitude,
    this.longitude,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id']?.toString() ?? '0',
      title: json['title'] ?? 'No Title',
      category: json['category'] ?? 'veg',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      expiryTime: json['expiry_time'] ?? '',
      status: json['status'] ?? 'pending',
      pickupLocation: json['pickup_location'],
      imageUrl: json['image_url'],
      restaurantName: json['restaurant_name'],
      ngoName: json['ngo_name'],
      postedAt: json['posted_at'],

      // Map lifecycle fields
      acceptedAt: json['accepted_at'],
      inTransitAt: json['in_transit_at'],
      pickedUpAt: json['picked_up_at'],
      restaurantContact: json['restaurant_contact'],

      // --- MAP LOCATION FIELDS ---
      // Mapping donation record's location fields (latitude, longitude)
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }
}
