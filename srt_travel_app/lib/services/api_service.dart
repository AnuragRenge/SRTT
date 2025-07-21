import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:30306';

  // Login and store JWT token
  Future<bool> login(String email, String password) async {
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
      return true;
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Login failed (${response.statusCode})');
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

  // Generic GET
  Future<http.Response> get(String path) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl$path');
    return await http.get(url, headers: _buildHeaders(token));
  }

  // Generic POST
  Future<http.Response> post(String path, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl$path');
    return await http.post(
      url,
      headers: _buildHeaders(token),
      body: jsonEncode(data),
    );
  }

  // Generic PUT
  Future<http.Response> put(String path, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl$path');
    return await http.put(
      url,
      headers: _buildHeaders(token),
      body: jsonEncode(data),
    );
  }

  // Generic DELETE
  Future<http.Response> delete(String path) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl$path');
    return await http.delete(url, headers: _buildHeaders(token));
  }

  // Helper: build common headers
  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
