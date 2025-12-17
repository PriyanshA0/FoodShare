import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/services/api_service.dart';

class DonateFoodScreen extends StatefulWidget {
  const DonateFoodScreen({super.key});

  @override
  State<DonateFoodScreen> createState() => _DonateFoodScreenState();
}

class _DonateFoodScreenState extends State<DonateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pickupLocationController = TextEditingController();

  final TextEditingController _expiryTimeDisplayController =
      TextEditingController();

  final ApiService _apiService = ApiService();
  String _selectedCategory = 'veg';
  bool _isLoading = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedExpiryDateTime;

  // NEW: Location fields fetched from the user profile
  double? _restaurantLat;
  double? _restaurantLon;
  String? _defaultAddress;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantLocation();
  }

  // --- LOCATION LOADING ---
  void _loadRestaurantLocation() async {
    setState(() {
      _isLocationLoading = true;
    });
    try {
      final userData = await _apiService.fetchUserData();
      if (mounted) {
        // Assuming latitude and longitude are returned as nullable doubles or strings
        _restaurantLat = double.tryParse(
          userData['latitude']?.toString() ?? '',
        );
        _restaurantLon = double.tryParse(
          userData['longitude']?.toString() ?? '',
        );
        _defaultAddress = userData['address'] as String?;

        // Use the saved address as the default pickup location
        if (_defaultAddress != null && _defaultAddress!.isNotEmpty) {
          _pickupLocationController.text = _defaultAddress!;
        }
      }
    } catch (e) {
      if (mounted) {
        // This is fine, we just won't have location pre-filled.
        print('Error loading location data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }
  // -------------------------

  @override
  void dispose() {
    _titleController.dispose();
    _quantityController.dispose();
    _expiryTimeDisplayController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedExpiryDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          // Format DateTime for SQL (YYYY-MM-DD HH:MM:SS) and display
          // We truncate to 19 chars and replace 'T' with space
          _expiryTimeDisplayController.text = _selectedExpiryDateTime!
              .toIso8601String()
              .substring(0, 19)
              .replaceFirst('T', ' ');
        });
      }
    }
  }

  void _handlePostDonation() async {
    if (!_formKey.currentState!.validate() || _selectedExpiryDateTime == null) {
      if (_selectedExpiryDateTime == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a valid expiry date and time.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.postDonation(
        _titleController.text,
        _selectedCategory,
        _quantityController.text,
        _expiryTimeDisplayController.text,
        _pickupLocationController.text,
        _image,
        // NEW: Pass coordinates to API
        latitude: _restaurantLat,
        longitude: _restaurantLon,
        // END NEW
      );

      if (response['message'] == 'Donation posted successfully.') {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response['message']!)));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          // If the API returns a message but not success, show that message
          final message = response['message'] ?? 'Unknown API error occurred.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          print(
            'API Post Failure (Non-Success Message): $response',
          ); // DEBUG LOG
        }
      }
    } catch (e) {
      if (mounted) {
        // Show the specific exception message
        String errorMessage = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post donation: $errorMessage')),
        );
        print('Post Donation Exception: $e'); // DEBUG LOG
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post New Donation'), // Changed title
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLocationLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Food Title (e.g., Leftover bread, buffet)',
                        icon: Icons.title,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'Food Category',
                        icon: Icons.category,
                        items: const ['veg', 'non-veg'],
                        value: _selectedCategory,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _quantityController,
                        label: 'Approx. Quantity (servings)',
                        icon: Icons.format_list_numbered,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              int.tryParse(value) == null) {
                            return 'Enter valid quantity';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- DATE/TIME PICKER FIELD ---
                      TextFormField(
                        controller: _expiryTimeDisplayController,
                        readOnly: true,
                        onTap: () => _selectDateTime(context),
                        decoration: InputDecoration(
                          labelText: 'Expiry Time (Tap to Select)',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select date and time';
                          }
                          return null;
                        },
                      ),

                      // --- END DATE/TIME PICKER FIELD ---
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _pickupLocationController,
                        label: 'Pickup Location (Default: Your Address)',
                        icon: Icons.location_on,
                        // NOTE: No validator added here, assuming the address can be edited
                      ),
                      // Show coordinates if available
                      if (_restaurantLat != null && _restaurantLon != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 10),
                          child: Text(
                            'Saved Coordinates: Lat ${_restaurantLat!.toStringAsFixed(4)}, Lon ${_restaurantLon!.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, color: AppColors.primary),
                        label: const Text('Upload Image of Food'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      if (_image != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Image.file(_image!, height: 150),
                        ),
                      const SizedBox(height: 32),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _handlePostDonation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                'Post Donation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ],
                  ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required List<String> items,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
