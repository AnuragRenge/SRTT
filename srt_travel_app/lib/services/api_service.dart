import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:30306';
  //static const String baseUrl = 'https://srtt.up.railway.app';

  // --------------------- Auth ---------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
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
      throw Exception('Login failed (${response.statusCode})');
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) return true;
    final err = _maybeDecodeJson(response.body);
    final message = (err is Map && err['message'] is String)
        ? err['message']
        : 'Registration failed (${response.statusCode})';
    throw Exception(message);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // --------------------- Token & Headers ---------------------
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --------------------- JSON helpers ---------------------
  dynamic _maybeDecodeJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic decoded) {
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    throw Exception('Expected JSON array');
  }

  Map<String, dynamic> _parseMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Expected JSON object');
  }

  // --------------------- Core request helper ---------------------
  Future<http.Response> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final token = await _getToken();
    final headers = _buildHeaders(token);
    final url = Uri.parse('$baseUrl$path');
    switch (method) {
      case 'GET':
        return await http.get(url, headers: headers);
      case 'POST':
        return await http.post(
          url,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      case 'PUT':
        return await http.put(
          url,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  String _extractErrorMessage({
    required http.Response response,
    required String fallback,
  }) {
    final decoded = _maybeDecodeJson(response.body);
    if (decoded is Map && decoded['message'] is String) {
      return decoded['message'];
    }
    return fallback;
  }

  // --------------------- Generic CRUD helpers ---------------------
  Future<List<Map<String, dynamic>>> fetchList(
    String path, {
    required String entityLabel,
  }) async {
    final response = await _request(method: 'GET', path: path);
    if (response.statusCode == 200) {
      return _parseList(jsonDecode(response.body));
    }
    final msg = _extractErrorMessage(
      response: response,
      fallback: 'Failed to load $entityLabel (${response.statusCode})',
    );
    throw Exception(msg);
  }

  Future<Map<String, dynamic>> fetchById(
    String path,
    dynamic id, {
    required String entityLabel,
  }) async {
    final response = await _request(method: 'GET', path: '$path/$id');
    if (response.statusCode == 200) {
      return _parseMap(jsonDecode(response.body));
    }
    final msg = _extractErrorMessage(
      response: response,
      fallback: 'Failed to load $entityLabel (${response.statusCode})',
    );
    throw Exception(msg);
  }

  Future<int> createEntity(
    String path,
    Map<String, dynamic> data, {
    required String entityLabel,
  }) async {
    final response = await _request(method: 'POST', path: path, body: data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final map = _parseMap(jsonDecode(response.body));
      final id = map['id'];
      if (id is int) return id;
      throw Exception('Created $entityLabel but no id returned');
    } else if (response.statusCode == 409) {
      throw Exception('Duplicate $entityLabel detected.');
    } else {
      final msg = _extractErrorMessage(
        response: response,
        fallback: 'Failed to create $entityLabel (${response.statusCode})',
      );
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> updateEntity(
    String path,
    dynamic id,
    Map<String, dynamic> data, {
    required String entityLabel,
  }) async {
    final response = await _request(
      method: 'PUT',
      path: '$path/$id',
      body: data,
    );
    if (response.statusCode == 200) {
      return _parseMap(jsonDecode(response.body));
    }
    final msg = _extractErrorMessage(
      response: response,
      fallback: 'Failed to update $entityLabel (${response.statusCode})',
    );
    throw Exception(msg);
  }

  Future<bool> deleteEntity(
    String path,
    dynamic id, {
    required String entityLabel,
    String? expectedDeleteMessage,
  }) async {
    final response = await _request(method: 'DELETE', path: '$path/$id');
    if (response.statusCode == 200) {
      final decoded = _maybeDecodeJson(response.body);
      if (decoded is Map) {
        if (expectedDeleteMessage == null) return true;
        if (decoded['message'] == expectedDeleteMessage) return true;
        throw Exception('Unexpected API response: $decoded');
      }
      return true;
    }
    final msg = _extractErrorMessage(
      response: response,
      fallback: 'Failed to delete $entityLabel (${response.statusCode})',
    );
    throw Exception(msg);
  }

  // --------------------- Entity wrappers below ---------------------

  // Leads
  Future<List<Map<String, dynamic>>> getLeads() =>
      fetchList('/leads', entityLabel: 'leads');
  Future<List<Map<String, dynamic>>> getLeadpicklist() =>
      fetchList('/leads/leadpicklist/', entityLabel: 'Lead');
  Future<Map<String, dynamic>> getLeadById(dynamic id) =>
      fetchById('/leads', id, entityLabel: 'lead');
  Future<int> createLead(Map<String, dynamic> leadData) =>
      createEntity('/leads', leadData, entityLabel: 'lead');
  Future<Map<String, dynamic>> updateLead(
    dynamic id,
    Map<String, dynamic> updatedFields,
  ) => updateEntity('/leads', id, updatedFields, entityLabel: 'lead');
  Future<bool> deleteLead(dynamic id) => deleteEntity(
    '/leads',
    id,
    entityLabel: 'lead',
    expectedDeleteMessage: 'Lead deleted',
  );

  // Users
  Future<List<Map<String, dynamic>>> getUsers() =>
      fetchList('/users', entityLabel: 'users');
  Future<Map<String, dynamic>> getUserById(dynamic id) =>
      fetchById('/users', id, entityLabel: 'user');
  Future<Map<String, dynamic>> updateUser(
    dynamic id,
    Map<String, dynamic> updatedFields,
  ) => updateEntity('/users', id, updatedFields, entityLabel: 'user record');

  // Companies
  Future<List<Map<String, dynamic>>> getCompany() =>
      fetchList('/companies', entityLabel: 'companies');
  Future<List<Map<String, dynamic>>> getCompanypicklist() =>
      fetchList('/companies/companypicklist/', entityLabel: 'companies');
  Future<Map<String, dynamic>> getCompanyById(dynamic id) =>
      fetchById('/companies', id, entityLabel: 'company');
  Future<int> createCompany(Map<String, dynamic> data) =>
      createEntity('/companies', data, entityLabel: 'company');
  Future<Map<String, dynamic>> updateCompany(
    dynamic id,
    Map<String, dynamic> updatedFields,
  ) => updateEntity('/companies', id, updatedFields, entityLabel: 'company');
  Future<bool> deleteCompany(dynamic id) => deleteEntity(
    '/companies',
    id,
    entityLabel: 'company',
    expectedDeleteMessage: 'Company deleted',
  );

  // Drivers
  Future<List<Map<String, dynamic>>> getDriver() =>
      fetchList('/drivers', entityLabel: 'drivers');
  Future<Map<String, dynamic>> getDriverById(dynamic id) =>
      fetchById('/drivers', id, entityLabel: 'driver');
  Future<List<Map<String, dynamic>>> getDriverpicklist() =>
      fetchList('/drivers/driverpicklist/', entityLabel: 'drivers');
  Future<int> createDriver(Map<String, dynamic> data) =>
      createEntity('/drivers', data, entityLabel: 'driver');
  Future<Map<String, dynamic>> updateDriver(
    dynamic id,
    Map<String, dynamic> updatedFields,
  ) => updateEntity('/drivers', id, updatedFields, entityLabel: 'driver');
  Future<bool> deleteDriver(dynamic id) => deleteEntity(
    '/drivers',
    id,
    entityLabel: 'driver record',
    expectedDeleteMessage: 'Driver deleted',
  );

  // Vehicles
  Future<List<Map<String, dynamic>>> getVehicle() =>
      fetchList('/vehicles', entityLabel: 'vehicles');
  Future<List<Map<String, dynamic>>> getVehiclepicklist() =>
      fetchList('/vehicles/vehiclepicklist/', entityLabel: 'vehicles');
  Future<Map<String, dynamic>> getVehicleById(dynamic id) =>
      fetchById('/vehicles', id, entityLabel: 'vehicle');
  Future<int> createVehicle(Map<String, dynamic> data) =>
      createEntity('/vehicles', data, entityLabel: 'vehicle');
  Future<Map<String, dynamic>> updateVehicle(
    dynamic id,
    Map<String, dynamic> updatedFields,
  ) => updateEntity('/vehicles', id, updatedFields, entityLabel: 'vehicle');
  Future<bool> deleteVehicle(dynamic id) => deleteEntity(
    '/vehicles',
    id,
    entityLabel: 'vehicle',
    expectedDeleteMessage: 'Vehicle deleted',
  );

  // Tours
  Future<List<Map<String, dynamic>>> getTour() =>
      fetchList('/tours', entityLabel: 'Tours');
  Future<List<Map<String, dynamic>>> getTourpicklist() =>
      fetchList('/tours/Tourpicklist/', entityLabel: 'tours');
  Future<Map<String, dynamic>> getTourById(dynamic id) =>
      fetchById('/tours', id, entityLabel: 'tours');
  Future<int> createTour(Map<String, dynamic> data) =>
      createEntity('/tours', data, entityLabel: 'tours');
  Future<Map<String, dynamic>> updateTour(
      dynamic id,
      Map<String, dynamic> updatedFields,
      ) => updateEntity('/tours', id, updatedFields, entityLabel: 'tours');
  Future<bool> deleteTour(dynamic id) => deleteEntity(
    '/tours',
    id,
    entityLabel: 'tours',
    expectedDeleteMessage: 'Tour deleted',
  );
}
