import 'package:flutter/material.dart';
import 'package:fwm_sys/core/constants/colors.dart';
import 'package:fwm_sys/core/constants/strings.dart';
import 'package:fwm_sys/core/services/api_service.dart';
import 'package:fwm_sys/features/auth/login_screen.dart';
import 'package:fwm_sys/widgets/custom_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared fields
  final _nameController = TextEditingController(); // Organization/College Name
  final _contactController =
      TextEditingController(); // Organization/Student Contact
  final _emailController =
      TextEditingController(); // Organization/Student Email
  final _passwordController = TextEditingController();

  // NGO/Restaurant specific fields
  final _addressController = TextEditingController();
  final _licenseController = TextEditingController();
  final _registrationNoController = TextEditingController();
  final _volunteersController = TextEditingController(); // NGO volunteers count

  // NSS specific fields
  final _nssUnitNoController = TextEditingController();
  final _nssVECController = TextEditingController();
  final _nssStudentNameController = TextEditingController();
  final _nssStudentContactController = TextEditingController();
  final _nssStudentEmailController = TextEditingController();
  final _nssCollegeNameController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _obscurePassword = true;
  String _selectedUserType = 'restaurant'; // Now handles 'nss' as well
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    _registrationNoController.dispose();
    _volunteersController.dispose();

    _nssUnitNoController.dispose();
    _nssVECController.dispose();
    _nssStudentNameController.dispose();
    _nssStudentContactController.dispose();
    _nssStudentEmailController.dispose();
    _nssCollegeNameController.dispose();

    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Collect generic data
      final String role = _selectedUserType;
      String? registrationNo;
      int? volunteersCount;
      String? license;
      String? contact;
      String? address;
      String? contactPerson;

      String? collegeName;
      String? unitNo;
      String? vecNumber;

      // Collect role-specific data
      if (role == 'restaurant') {
        license = _licenseController.text;
        contact = _contactController.text;
        address = _addressController.text;
        contactPerson = _nameController
            .text; // Assuming Organization Name is the Contact Person
      } else if (role == 'ngo') {
        registrationNo = _registrationNoController.text;
        volunteersCount = int.tryParse(_volunteersController.text);
        contact = _contactController.text;
        address = _addressController.text;
        contactPerson = _nameController
            .text; // Assuming Organization Name is the Contact Person
      } else if (role == 'nss') {
        // NSS details are different and override organization name
        collegeName = _nssCollegeNameController.text;
        unitNo = _nssUnitNoController.text;
        vecNumber = _nssVECController.text;
        contactPerson = _nssStudentNameController.text; // Student Name
        contact = _nssStudentContactController.text; // Student Contact
      }

      // Determine the non-nullable 'name' (Organization/College name)
      final String organizationName = role == 'nss'
          ? (collegeName ?? '')
          : _nameController.text;

      // Determine the primary email (shared email field)
      final String primaryEmail = _emailController.text;

      try {
        final response = await _apiService.registerUser(
          // Non-nullable required fields
          email: primaryEmail,
          password: _passwordController.text,
          role: role,
          name: organizationName,

          // Nullable optional fields
          contact: contact,
          address: address,
          license: license,
          registrationNo: registrationNo,
          volunteersCount: volunteersCount,
          contactPerson: contactPerson,

          // NSS Specific fields
          unitNo: unitNo,
          vecNumber: vecNumber,
          studentEmail: _nssStudentEmailController.text,
        );

        if (mounted) {
          if (response['message'] ==
              'Registration successful! Awaiting admin approval.') {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(response['message'])));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(response['message'])));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to connect to the server. Error: $e'),
            ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.signupTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign up to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // --- USER TYPE CARDS ---
                Row(
                  children: [
                    Expanded(
                      child: UserTypeCard(
                        type: 'restaurant',
                        label: AppStrings.restaurant,
                        icon: Icons.restaurant,
                        isSelected: _selectedUserType == 'restaurant',
                        onTap: () {
                          setState(() {
                            _selectedUserType = 'restaurant';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: UserTypeCard(
                        type: 'ngo',
                        label: AppStrings.ngo,
                        icon: Icons.volunteer_activism,
                        isSelected: _selectedUserType == 'ngo',
                        onTap: () {
                          setState(() {
                            _selectedUserType = 'ngo';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // NEW NSS Card
                    Expanded(
                      child: UserTypeCard(
                        type: 'nss',
                        label: 'NSS Unit',
                        icon: Icons.school,
                        isSelected: _selectedUserType == 'nss',
                        onTap: () {
                          setState(() {
                            _selectedUserType = 'nss';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- SHARED FIELDS ---
                if (_selectedUserType != 'nss')
                  _buildTextField(
                    controller: _nameController,
                    label: _selectedUserType == 'restaurant'
                        ? 'Hotel/Hall Name (Organization Name)'
                        : 'NGO Organization Name',
                    icon: Icons.business,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Organization name is required.'
                        : null,
                  ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Enter a valid email.'
                      : null,
                ),
                const SizedBox(height: 16),

                if (_selectedUserType !=
                    'nss') // Standard Contact Number for NGO/Restaurant
                  _buildTextField(
                    controller: _contactController,
                    label: 'Organization Contact Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value == null || value.length < 10)
                        ? 'Enter a valid phone number.'
                        : null,
                  ),

                if (_selectedUserType != 'nss') ...[
                  // Standard Address for NGO/Restaurant
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Organization Address',
                    icon: Icons.location_on,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Address is required.'
                        : null,
                  ),
                ],

                // --- RESTAURANT SPECIFIC FIELDS ---
                if (_selectedUserType == 'restaurant') ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _licenseController,
                    label: 'License/ID Proof Number',
                    icon: Icons.description,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'License number is required.'
                        : null,
                  ),
                ],

                // --- NGO SPECIFIC FIELDS (Not NSS) ---
                if (_selectedUserType == 'ngo') ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _registrationNoController,
                    label: 'Registration Certificate No.',
                    icon: Icons.receipt,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Registration number is required.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _volunteersController,
                    label: 'No. of Volunteers',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null) {
                        return 'Enter a valid number.';
                      }
                      return null;
                    },
                  ),
                ],

                // --- NSS SPECIFIC FIELDS ---
                if (_selectedUserType == 'nss') ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      'NSS Unit Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _buildTextField(
                    controller: _nssCollegeNameController,
                    label: 'College/University Name',
                    icon: Icons.account_balance,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'College name is required.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _nssUnitNoController,
                          label: 'Unit No.',
                          icon: Icons.tag,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Unit No. required.'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _nssVECController,
                          label: 'VEC Number (Student Count)',
                          icon: Icons.group_add,
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              (value == null || int.tryParse(value) == null)
                              ? 'Valid VEC (count) required.'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
                    child: Text(
                      'NSS Representative (Student) Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _buildTextField(
                    controller: _nssStudentNameController,
                    label: 'Student Representative Name',
                    icon: Icons.person,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Student name is required.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nssStudentContactController,
                    label: 'Student Contact Number',
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value == null || value.length < 10)
                        ? 'Enter a valid contact.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nssStudentEmailController,
                    label: 'Student Email (For communication)',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? 'Enter a valid email.'
                        : null,
                  ),
                ],

                // --- PASSWORD FIELD (Shared) ---
                const SizedBox(height: 16),
                _buildPasswordTextField(),
                const SizedBox(height: 32),

                // --- SUBMIT BUTTON ---
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          AppStrings.signup,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                // --- LOGIN LINK ---
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        AppStrings.login,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildPasswordTextField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: AppStrings.password,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty || value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}
