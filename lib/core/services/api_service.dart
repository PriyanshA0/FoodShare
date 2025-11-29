import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fwm_sys/models/donation_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // FINAL PHP/XAMPP LOCAL HOST URL: Use the Android Emulator alias or your direct IP.
  // We assume default port 80, so no port is needed.
  static const String _baseUrl = "http://10.241.88.71/api";

  // --- PRIVATE METHOD TO RETRIEVE AUTH HEADERS (Non-JWT Header System) ---
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userRole = prefs.getString('user_role');

    if (userId == null || userRole == null) {
      throw Exception('Authentication credentials not found. Please log in.');
    }

    return {
      'Content-Type': 'application/json',
      // CRITICAL: Send raw ID and Role for PHP $_SERVER/getallheaders() to read
      'User-ID': userId,
      'User-Role': userRole,
    };
  }

  // ----------------------------------------------------
  // AUTHENTICATION & REGISTRATION
  // ----------------------------------------------------

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String role,
    required String name,
    String? contact,
    String? address,
    String? license,
    String? registrationNo,
    int? volunteersCount,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register.php'), // PHP file extension
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'role': role,
        'name': name,
        'contact': contact,
        'address': address,
        'license': license,
        'registrationNo': registrationNo,
        'volunteersCount': volunteersCount,
      }),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login.php'), // PHP file extension
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['user_id'] != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('user_id', responseData['user_id'].toString());
        await prefs.setString('user_role', responseData['role'].toString());
        await prefs.setBool('is_logged_in', true);
      }
      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('is_logged_in');
  }

  // ----------------------------------------------------
  // DONATION POSTING & FETCHING
  // ----------------------------------------------------

  Future<Map<String, dynamic>> postDonation(
    String title,
    String category,
    String quantity,
    String expiryTime,
    String pickupLocation,
    File? image,
  ) async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/donations/post.php'); // PHP file extension

    var request = http.MultipartRequest('POST', uri)
      ..fields['title'] = title
      ..fields['category'] = category
      ..fields['quantity'] = quantity
      ..fields['expiry_time'] = expiryTime
      ..fields['pickup_location'] = pickupLocation
      // Use standard headers + the custom auth headers
      ..headers.addAll({
        'Content-Type':
            'multipart/form-data', // Must be set correctly for file upload
        'User-ID': headers['User-ID']!,
        'User-Role': headers['User-Role']!,
      });

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return json.decode(response.body);
  }

  // --- RESTORED: SIMPLE FETCH (NO LOCATION ARGS) ---
  Future<List<Donation>> getAllDonations() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      // URL no longer includes lat/lon query parameters
      Uri.parse('$_baseUrl/donations/get_all.php'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load donations: ${response.statusCode}');
    }
  }
  // ------------------------------------------

  Future<List<Donation>> getMyDonations() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/donations/get_by_restaurant.php',
      ), // PHP file extension
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load your donations: ${response.statusCode}');
    }
  }

  Future<Donation> fetchDonationDetails(String donationId) async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse(
      '$_baseUrl/donations/get_donation_details.php?donation_id=$donationId',
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Donation.fromJson(data);
    } else {
      throw Exception(
        'Failed to fetch donation details: ${response.statusCode}',
      );
    }
  }

  Future<List<Donation>> getHotelHistory() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/donations/get_history_hotel.php'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load hotel history: ${response.statusCode}');
    }
  }

  Future<List<Donation>> getNgoHistory() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/donations/get_history_ngo.php'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load NGO history: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentActivity() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$_baseUrl/donations/get_recent_activity.php'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Return raw list of maps since activity doesn't need full Donation model
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load recent activity: ${response.statusCode}');
    }
  }

  // --- COMPOSITE FETCH METHOD for Dashboard ---
  Future<Map<String, dynamic>> fetchDashboardCompositeData() async {
    final statsFuture = fetchDashboardStats();
    final userFuture = fetchUserData(); // Fetches name/contact/role
    final activityFuture = fetchRecentActivity();

    final results = await Future.wait([
      statsFuture,
      userFuture,
      activityFuture,
    ]);

    return {
      'stats': results[0],
      'user_data': results[1],
      'activity': results[2],
    };
  }

  // ----------------------------------------------------
  // NGO-SPECIFIC ACTIONS
  // ----------------------------------------------------

  Future<Map<String, dynamic>> acceptDonation(String donationId) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$_baseUrl/donations/accept.php'), // PHP file extension
      headers: headers,
      body: json.encode({'donation_id': donationId}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> markInTransit(String donationId) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$_baseUrl/donations/in_transit.php'), // PHP file extension
      headers: headers,
      body: json.encode({'donation_id': donationId}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> completePickup(String donationId) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/donations/complete_pickup.php',
      ), // PHP file extension
      headers: headers,
      body: json.encode({'donation_id': donationId}),
    );
    return json.decode(response.body);
  }

  Future<List<Donation>> getAcceptedDonations() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$_baseUrl/donations/get_accepted.php'), // PHP file extension
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load accepted orders: ${response.statusCode}');
    }
  }

  // ----------------------------------------------------
  // DASHBOARD ANALYTICS & PROFILE
  // ----------------------------------------------------

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/stats/get_dashboard_stats.php',
      ), // PHP file extension
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard stats: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String contactNumber,
    required String address,
    required String contactPerson,
  }) async {
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$_baseUrl/users/update_profile.php'),
      headers: headers,
      body: json.encode({
        'name': name,
        'contact_number': contactNumber,
        'address': address,
        'contact_person_name': contactPerson,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse('$_baseUrl/users/get_profile.php'), // PHP file extension
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user data.');
    }
  }
}
