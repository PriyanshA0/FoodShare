// lib/models/user_model.dart

class User {
  final String id;
  final String email;
  final String role;
  final String status;

  final String? name; // Organization Name (Restaurant/NGO Name)
  final String? contactNumber;
  final String? address;
  final String? verificationDetail; // License/Registration No
  final int? volunteersCount;
  final String? contactPerson; // Owner Name / Contact Person

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.name,
    this.contactNumber,
    this.address,
    this.verificationDetail,
    this.volunteersCount,
    this.contactPerson,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // PHP returns a flattened structure, so keys are looked up directly:

    // Logic to handle different verification keys
    final verificationDetail =
        json['license_proof'] ?? json['registration_certificate'];

    // Safely retrieve contact person/owner name
    final contactPerson = json['owner_name'] ?? json['contact_person'];

    // Safely retrieve organization name (just 'name' in PHP)
    final name =
        json['name'] ?? 'N/A'; // Assuming 'name' is always the org/hotel name

    return User(
      id: json['id']?.toString() ?? '0',
      email: json['email'] ?? 'N/A',
      role: json['role'] ?? 'N/A',
      status: json['status'] ?? 'N/A',
      name: name,
      contactNumber: json['contact_number'],
      address: json['address'],
      verificationDetail: verificationDetail,
      // Safely parse int, returning null if the field is missing/invalid
      volunteersCount: int.tryParse(json['volunteers_count']?.toString() ?? ''),
      contactPerson: contactPerson,
    );
  }
}
