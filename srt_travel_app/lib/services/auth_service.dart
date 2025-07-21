// lib/services/auth_service.dart (optional)
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<bool> login(String email, String password) {
    return _api.login(email, password);
  }
}
