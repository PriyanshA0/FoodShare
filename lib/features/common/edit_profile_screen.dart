import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/models/user_model.dart';
import 'package:geocoding/geocoding.dart'; // REQUIRED

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _contactPersonController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _contactController = TextEditingController(text: widget.user.contactNumber);
    _addressController = TextEditingController(text: widget.user.address);
    _contactPersonController = TextEditingController(
      text: widget.user.contactPerson,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    super.dispose();
  }

  // --- ROBUST GEOLOCATION LOGIC: Address to Coordinates ---
  Future<Map<String, double?>?> _geocodeAddress(String address) async {
    try {
      if (address.isEmpty) return null;

      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        // Log coordinates for debugging
        print(
          'Geocoding Success: Lat=${locations.first.latitude}, Lon=${locations.first.longitude}',
        );
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }

      // If locations is empty, address was not found/invalid
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address not recognized. Please check the spelling.'),
          ),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        // Log and report the specific geocoding error
        print('Geocoding Failed with Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Geocoding Error: Check your internet or address format. ($e)',
            ),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // 1. Geocode the address
    final location = await _geocodeAddress(_addressController.text);

    final double? lat = location?['latitude'];
    final double? lon = location?['longitude'];

    try {
      final response = await _apiService.updateProfile(
        name: _nameController.text,
        contactNumber: _contactController.text,
        address: _addressController.text,
        contactPerson: _contactPersonController.text,
        latitude: lat,
        longitude: lon,
      );

      if (mounted) {
        // Log response for debugging server failure
        print('API Response: ${response['message']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Profile updated successfully!',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Logging the full error object for diagnosing connection vs. API issues
        print('--- CRITICAL API ERROR ---');
        print('Exception Type: ${e.runtimeType}');
        print('Full Error: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect or API error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRestaurant = widget.user.role == 'restaurant';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        actions: [
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveProfile,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _contactPersonController,
                label: isRestaurant ? 'Owner Name' : 'Contact Person Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: isRestaurant ? 'Business Name' : 'Organization Name',
                icon: Icons.business,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _contactController,
                label: 'Contact Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Address (Required for Map)',
                icon: Icons.location_on,
                maxLines: 3,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field cannot be empty.';
        }
        return null;
      },
    );
  }
}
