import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fwm_sys/models/donation_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // *** FIXED HOSTINGER URL ***
  // IMPORTANT: Must end with trailing slash
  static const String _baseUrl = "https://foodshareapp.me/api/";

  // Storage for cached session data
  String? _cachedUserId;
  String? _cachedUserRole;

  // -------------------------------
  // GET AUTH DATA (REPLACES _getAuthHeaders())
  // -------------------------------
  Future<Map<String, String>> _getAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    // Re-read from prefs if cache is empty (to ensure we capture late writes from login)
    if (_cachedUserId == null || _cachedUserRole == null) {
      _cachedUserId = prefs.getString('user_id');
      _cachedUserRole = prefs.getString('user_role');
    }

    // CRITICAL FIX: Check if the role is null OR an empty/whitespace string
    if (_cachedUserId == null ||
        _cachedUserRole == null ||
        _cachedUserRole!.trim().isEmpty) {
      // Clear cache if role is invalid/empty, forcing re-login
      _cachedUserId = null;
      _cachedUserRole = null;

      print(
        "DEBUG AUTH: Credentials NOT found or Role is EMPTY in SharedPreferences.",
      );
      throw Exception('Authentication credentials not found or invalid role.');
    }

    // DEBUG: Log retrieved credentials
    print("DEBUG AUTH: Retrieved ID: $_cachedUserId, Role: $_cachedUserRole");

    // Returns the data required for URL or Body, NOT HTTP HEADERS
    return {'user_id': _cachedUserId!, 'user_role': _cachedUserRole!};
  }

  // Helper to create URL with auth query parameters for GET requests
  Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    final userIdToSend = _cachedUserId ?? '';
    final userRoleToSend = _cachedUserRole ?? '';

    final authData = {'user_id': userIdToSend, 'user_role': userRoleToSend};

    final uri = Uri.parse(_baseUrl + path);
    // Merge provided query parameters with auth parameters
    final finalQueryParams = {
      ...uri.queryParameters,
      ...queryParams ?? {},
      ...authData,
    };

    // CRITICAL DEBUG: Log the full URI being constructed
    final debugUri = uri.replace(queryParameters: finalQueryParams);
    print("DEBUG URI: Path: $path");
    print("DEBUG URI: Sent Auth Data: ID=$userIdToSend, Role=$userRoleToSend");
    print("DEBUG URI: Full Request URL: $debugUri");

    return debugUri;
  }

  // Helper to inject auth data into the body for POST requests
  Map<String, dynamic> _injectAuth(Map<String, dynamic> body) {
    return {
      ...body,
      'auth_user_id': _cachedUserId,
      'auth_user_role': _cachedUserRole,
    };
  }

  // ----------------------------------------------------
  // 1. AUTH - Register User (Includes NSS fields)
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
    String? contactPerson,

    // NSS Specific Fields
    String? unitNo,
    String? vecNumber,
    String? studentEmail,
  }) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}auth/register.php'),
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
        'contactPerson': contactPerson,

        // NSS Fields
        'unitNo': unitNo,
        'vecNumber': vecNumber,
        'studentEmail': studentEmail,
      }),
    );
    final responseData = json.decode(response.body);

    // Save session on successful registration as well
    if (response.statusCode == 200 && responseData['user_id'] != null) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('user_id', responseData['user_id'].toString());
      await prefs.setString('user_role', responseData['role'].toString());
      await prefs.setBool('is_logged_in', true);
    }

    return responseData;
  }

  // ----------------------------------------------------
  // 2. AUTH - Login User (General)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}auth/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['user_id'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = responseData['user_id'].toString();
        // Ensure role is a valid string, defaulting to 'unknown' if missing from response
        final userRole = responseData['role']?.toString() ?? 'unknown';

        await prefs.setString('user_id', userId);
        await prefs.setString('user_role', userRole);
        await prefs.setBool('is_logged_in', true);

        // Ensure the cache is immediately updated upon successful login
        _cachedUserId = userId;
        _cachedUserRole = userRole;
      }
      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  // NEW DEDICATED LOGIN FOR NSS (Uses isolated PHP endpoint)
  Future<Map<String, dynamic>> loginNssUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}auth/login_nss.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['user_id'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = responseData['user_id'].toString();
        final userRole =
            responseData['role']?.toString() ??
            'nss'; // Force to 'nss' if missing

        await prefs.setString('user_id', userId);
        await prefs.setString('user_role', userRole);
        await prefs.setBool('is_logged_in', true);

        _cachedUserId = userId;
        _cachedUserRole = userRole;
      }
      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('is_logged_in');

    // Clear cache immediately
    _cachedUserId = null;
    _cachedUserRole = null;
  }

  // New helper method for session check on startup
  Future<Map<String, String?>> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final userId = prefs.getString('user_id');
    final userRole = prefs.getString('user_role');

    return {
      'is_logged_in': isLoggedIn.toString(),
      'user_id': userId,
      'user_role': userRole,
    };
  }

  // ----------------------------------------------------
  // 3. FETCH USER PROFILE (General implementation)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> fetchUserData() async {
    // CRITICAL: Ensure credentials are loaded before fetching data
    await _getAuthData();

    // CRITICAL FIX: Determine endpoint based on role
    String path;
    if (_cachedUserRole == 'nss') {
      path = 'users/get_nss_profile.php';
    } else {
      path = 'users/get_profile.php';
    }

    // DEBUG: Path being used for fetchUserData
    print("DEBUG FETCH USER: Using path $path for role $_cachedUserRole");

    final uri = _buildUri(path);

    final response = await http.get(uri);

    // START DEBUG LOGGING: Log response details
    print("DEBUG RESPONSE: URL: $uri");
    print("DEBUG RESPONSE: Status Code: ${response.statusCode}");
    print("DEBUG RESPONSE: Body: ${response.body}");
    // END DEBUG LOGGING

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Throw exception with the body content for detailed error message in Flutter
      throw Exception('Failed to fetch user data: ${response.body}');
    }
  }

  // RETAINED: Dedicated NSS Profile Fetch (Now relies on fetchUserData)
  Future<Map<String, dynamic>> fetchNSSUserData() async {
    // Use fetchUserData which now handles the routing based on the cached role
    return fetchUserData();
  }

  // ----------------------------------------------------
  // 4. FETCH DASHBOARD STATS (CRITICAL FIX: Changed to URL-ENCODED POST)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final authData = await _getAuthData();

    // --- CHANGE TO URL-ENCODED POST ---
    final uri = Uri.parse('${_baseUrl}stats/get_dashboard_stats.php');
    final response = await http.post(
      uri,
      headers: {
        // Use standard URL encoding instead of JSON
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      // Send data as URL-encoded string
      body: 'user_id=${authData['user_id']}&user_role=${authData['user_role']}',
    );
    // --- END CHANGE ---

    // START DEBUG LOGGING: Log response details
    print("DEBUG STATS RESPONSE: URL: $uri");
    print("DEBUG STATS RESPONSE: Status Code: ${response.statusCode}");
    print("DEBUG STATS RESPONSE: Body: ${response.body}");
    // END DEBUG LOGGING

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard stats: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 5. UPDATE PROFILE (FIXED TO INJECT AUTH DATA IN BODY)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String contactNumber,
    required String address,
    required String contactPerson,
    double? latitude,
    double? longitude,
  }) async {
    await _getAuthData();

    final bodyData = {
      'name': name,
      'contact_number': contactNumber,
      'address': address,
      'contactPerson': contactPerson,
      'latitude': latitude,
      'longitude': longitude,
    };

    final finalBody = _injectAuth(bodyData);

    final response = await http.post(
      Uri.parse('${_baseUrl}users/update_profile.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(finalBody),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 6. POST DONATION (PHOTO UPLOAD) (FIXED TO INJECT AUTH DATA IN FIELDS)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> postDonation(
    String title,
    String category,
    String quantity,
    String expiryTime,
    String pickupLocation,
    File? image, {
    // NEW: Accept latitude and longitude
    double? latitude,
    double? longitude,
  }) async {
    await _getAuthData();
    final authData = {
      'user_id': _cachedUserId!,
      'user_role': _cachedUserRole!,
    }; // Use fresh cache data
    final uri = Uri.parse('${_baseUrl}donations/post.php');

    var request = http.MultipartRequest('POST', uri)
      ..fields['title'] = title
      ..fields['category'] = category
      ..fields['quantity'] = quantity
      ..fields['expiry_time'] = expiryTime
      ..fields['pickup_location'] = pickupLocation
      // CRITICAL FIX: Inject auth data into fields for Multipart request
      ..fields['auth_user_id'] = authData['user_id']!
      ..fields['auth_user_role'] = authData['user_role']!;

    // NEW: Add coordinates to fields if available
    if (latitude != null) {
      request.fields['latitude'] = latitude.toString();
    }
    if (longitude != null) {
      request.fields['longitude'] = longitude.toString();
    }
    // END NEW

    // Custom headers removed for reliability

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return json.decode(response.body);
  }

  // ----------------------------------------------------
  // 7. GET ALL DONATIONS (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<List<Donation>> getAllDonations() async {
    await _getAuthData();
    final uri = _buildUri('donations/get_all.php');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load donations: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 8. GET MY DONATIONS (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<List<Donation>> getMyDonations() async {
    await _getAuthData();
    final uri = _buildUri('donations/get_by_restaurant.php');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load your donations: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 9. DONATION DETAILS (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<Donation> fetchDonationDetails(String donationId) async {
    await _getAuthData();
    final uri = _buildUri(
      'donations/get_donation_details.php',
      queryParams: {'donation_id': donationId},
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Donation.fromJson(data);
    } else {
      throw Exception('Failed to fetch donation details: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 10. ACCEPTED DONATIONS (NGO) (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<List<Donation>> getAcceptedDonations() async {
    await _getAuthData();
    final uri = _buildUri('donations/get_accepted.php');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load accepted orders: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 11. ACCEPT DONATION (NGO) (FIXED TO INJECT AUTH DATA IN BODY)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> acceptDonation(String donationId) async {
    await _getAuthData();
    final bodyData = {'donation_id': donationId};
    final finalBody = _injectAuth(bodyData);

    final response = await http.post(
      Uri.parse('${_baseUrl}donations/accept.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(finalBody),
    );
    return json.decode(response.body);
  }

  // ----------------------------------------------------
  // 12. MARK IN TRANSIT (FIXED TO INJECT AUTH DATA IN BODY)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> markInTransit(String donationId) async {
    await _getAuthData();
    final bodyData = {'donation_id': donationId};
    final finalBody = _injectAuth(bodyData);

    final response = await http.post(
      Uri.parse('${_baseUrl}donations/in_transit.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(finalBody),
    );
    return json.decode(response.body);
  }

  // ----------------------------------------------------
  // 13. COMPLETE PICKUP (FIXED TO INJECT AUTH DATA IN BODY)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> completePickup(String donationId) async {
    await _getAuthData();
    final bodyData = {'donation_id': donationId};
    final finalBody = _injectAuth(bodyData);

    final response = await http.post(
      Uri.parse('${_baseUrl}donations/complete_pickup.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(finalBody),
    );
    return json.decode(response.body);
  }

  // ----------------------------------------------------
  // 14. GET HOTEL HISTORY (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<List<Donation>> getHotelHistory() async {
    await _getAuthData();
    final uri = _buildUri('donations/get_history_hotel.php');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load hotel history: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 15. GET NGO HISTORY (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<List<Donation>> getNgoHistory() async {
    await _getAuthData();
    final uri = _buildUri('donations/get_history_ngo.php');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Donation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load NGO history: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 16. RECENT ACTIVITY FEED (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchRecentActivity() async {
    await _getAuthData();
    final uri = _buildUri('donations/get_recent_activity.php');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load recent activity: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 17. ADMIN - Fetch Pending Users (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchPendingUsers() async {
    await _getAuthData();
    final uri = _buildUri('admin/get_pending_users.php');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to load pending users: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 19. ADMIN - Fetch ALL Users (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAllUsersAdmin() async {
    await _getAuthData();
    final uri = _buildUri('admin/get_all_users.php');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // CRITICAL FIX: Cast the list explicitly
      return data.cast<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to load all users: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 20. ADMIN - Fetch ALL Donations (FIXED TO USE URL PARAMETERS)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAllDonationsAdmin() async {
    await _getAuthData();
    final uri = _buildUri('admin/get_all_donations_admin.php');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // CRITICAL FIX: Cast the list explicitly
      return data.cast<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to load all donations: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // 18. ADMIN - Update User Status (FIXED TO INJECT AUTH DATA IN BODY)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> updateUserStatus(
    String userId,
    String status,
  ) async {
    await _getAuthData();
    final bodyData = {'user_id': userId, 'status': status};
    final finalBody = _injectAuth(bodyData);

    final response = await http.post(
      Uri.parse('${_baseUrl}admin/update_user_status.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(finalBody),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update status: ${response.body}');
    }
  }
}
