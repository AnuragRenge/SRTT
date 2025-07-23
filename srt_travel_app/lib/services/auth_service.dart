// lib/services/auth_service.dart (optional)
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) {
    return _api.login(email, password);
  }
}
