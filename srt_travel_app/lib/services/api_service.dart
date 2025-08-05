import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  //static const String baseUrl = 'http://10.0.2.2:30306';
  static const String baseUrl = 'https://srtt.up.railway.app';

  // Login and store JWT token
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      return {
        'success': true,
        'role': data['role'],
        'username': data['username'],
        'email': data['email'],
        'id': data['id'],
      };
    } else {
      try {
        //final data = jsonDecode(response.body);
        throw Exception('Login Attempt failed:${response.statusCode}');
      } catch (_) {
        throw Exception('Login failed (${response.statusCode})');
      }
    }
  }

  // New user registrations
  Future<bool> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return true;
    } else {
      try {
        final decoded = jsonDecode(response.body);
        throw Exception(
          decoded['message'] ?? 'Registration failed (${response.statusCode})',
        );
      } catch (_) {
        throw Exception('Registration failed (${response.statusCode})');
      }
    }
  }

  // Logout by removing the token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Get token from local storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
  // Helper: build common headers
  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  // --------- LEADS API METHODS -----------
  /// Fetches list of leads from backend
  Future<List<Map<String, dynamic>>> getLeads() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/leads'); // Change path if different

    final response = await http.get(url, headers: _buildHeaders(token));
    if (response.statusCode == 200) {
      // Assume response.body is a JSON array as per your sample
      final List<dynamic> jsonList = jsonDecode(response.body);
      // Ensure safe conversion to list of Map<String, dynamic>
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to load leads (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to load leads (${response.statusCode})');
      }
    }
  }
  /// fetches lead by Id
  Future<Map<String, dynamic>?> getLeadById(dynamic id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/leads/$id');
    final response = await http.get(url, headers: _buildHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to load leads (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to load leads (${response.statusCode})');
      }
    }
  }
  /// POST: Create new Lead (no duplicate based on Phone)
  Future<int> createLead(Map<String, dynamic> leadData) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/leads'); // Update path if needed

    final response = await http.post(
      url,
      headers: _buildHeaders(token),
      body: jsonEncode(leadData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else if (response.statusCode == 409) {
      throw Exception('Duplicate lead detected.');
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to create lead (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to create lead (${response.statusCode})');
      }
    }
  }
  /// PUT:Update the existing leads
  Future<Map<String, dynamic>> updateLead(dynamic id, Map<String, dynamic> updatedFields) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/leads/$id');
    final response = await http.put(
      url,
      headers: _buildHeaders(token),
      body: jsonEncode(updatedFields),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return decoded as Map<String, dynamic>;
    } else {
      throw Exception(decoded['message'] ?? 'Failed to update lead (${response.statusCode})');
    }
  }
  /// DELETE: Delete the lead by [id].
  /// Returns true if deleted, throws Exception if not.
  Future<bool> deleteLead(dynamic id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/leads/$id');

    final response = await http.delete(url, headers: _buildHeaders(token));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Optionally check message value
      if (body is Map && body['message'] == 'Lead deleted') {
        return true;
      } else {
        throw Exception('Unexpected API response: $body');
      }
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to delete lead (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to delete lead (${response.statusCode})');
      }
    }
  }

  //------------Lead API Methods ENDs HERE-----------

  // ------------- USER API METHODS ---------
  ///GET ALL LEADS
  Future<List<Map<String, dynamic>>> getUsers() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/users'); // Change path if different

    final response = await http.get(url, headers: _buildHeaders(token));
    if (response.statusCode == 200) {
      // Assume response.body is a JSON array as per your sample
      final List<dynamic> jsonList = jsonDecode(response.body);
      // Ensure safe conversion to list of Map<String, dynamic>
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to load users (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to load users (${response.statusCode})');
      }
    }
  }
  /// fetches lead by Id
  Future<Map<String, dynamic>?> getUserById(dynamic id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/users/$id');
    final response = await http.get(url, headers: _buildHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to load users (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to load users (${response.statusCode})');
      }
    }
  }
  /// PUT:Update the existing leads
  Future<Map<String, dynamic>> updateUser(dynamic id, Map<String, dynamic> updatedFields) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/users/$id');
    final response = await http.put(
      url,
      headers: _buildHeaders(token),
      body: jsonEncode(updatedFields),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return decoded as Map<String, dynamic>;
    } else {
      throw Exception(decoded['message'] ?? 'Failed to update user record (${response.statusCode})');
    }
  }

//------------User API Methods ENDs HERE-----------
//-------------------company API Starts HERE -----------
  /// Fetches list of company from backend
  Future<List<Map<String, dynamic>>> getCompany() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/companies'); // Change path if different

    final response = await http.get(url, headers: _buildHeaders(token));
    if (response.statusCode == 200) {
      // Assume response.body is a JSON array as per your sample
      final List<dynamic> jsonList = jsonDecode(response.body);
      // Ensure safe conversion to list of Map<String, dynamic>
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to load companies (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to load companies (${response.statusCode})');
      }
    }
  }
  /// fetches company by Id
  Future<Map<String, dynamic>?> getCompanyById(dynamic id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/companies/$id');
    final response = await http.get(url, headers: _buildHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to load companies (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to load companies (${response.statusCode})');
      }
    }
  }
  /// POST: Create new company (no duplicate based on Phone)
  Future<int> createCompany(Map<String, dynamic> leadData) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/companies'); // Update path if needed

    final response = await http.post(
      url,
      headers: _buildHeaders(token),
      body: jsonEncode(leadData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else if (response.statusCode == 409) {
      throw Exception('Duplicate companies detected.');
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to create companies (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to create companies (${response.statusCode})');
      }
    }
  }
  /// PUT:Update the existing leads
  Future<Map<String, dynamic>> updateCompany(dynamic id, Map<String, dynamic> updatedFields) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/companies/$id');
    final response = await http.put(
      url,
      headers: _buildHeaders(token),
      body: jsonEncode(updatedFields),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return decoded as Map<String, dynamic>;
    } else {
      throw Exception(decoded['message'] ?? 'Failed to update company (${response.statusCode})');
    }
  }
  /// DELETE: Delete the company by [id].
  /// Returns true if deleted, throws Exception if not.
  Future<bool> deleteCompany(dynamic id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/companies/$id');

    final response = await http.delete(url, headers: _buildHeaders(token));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Optionally check message value
      if (body is Map && body['message'] == 'Company deleted') {
        return true;
      } else {
        throw Exception('Unexpected API response: $body');
      }
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to delete companies (${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to delete companies (${response.statusCode})');
      }
    }
  }
//------------company API Methods ENDs HERE-----------

}
