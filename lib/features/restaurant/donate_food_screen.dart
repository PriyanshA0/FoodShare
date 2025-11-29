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

  // New: Controller for displaying selected DateTime
  final TextEditingController _expiryTimeDisplayController =
      TextEditingController();

  final ApiService _apiService = ApiService();
  String _selectedCategory = 'veg';
  bool _isLoading = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Stores the actual DateTime object to send to API
  DateTime? _selectedExpiryDateTime;

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
        _expiryTimeDisplayController
            .text, // Use formatted string from controller
        _pickupLocationController.text,
        _image,
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response['message']!)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to the server.')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Reports'),

        // Explicitly set the background to the new primary color
        backgroundColor: AppColors.primary,

        // Ensure the title and icons are visible against the dark primary color
        foregroundColor: Colors.white,

        elevation: 0,
      ),
      body: Padding(
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
                  label: 'Food Title',
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
                  items: ['veg', 'non-veg'],
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
                  label: 'Pickup Location',
                  icon: Icons.location_on,
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
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
