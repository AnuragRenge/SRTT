import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  final String userRole;
  final String username;
  final String email;
  final dynamic id;

  HomeScreen({
    super.key,
    required this.userRole,
    required this.username,
    required this.email,
    this.id,
  });

  final ApiService _apiService = ApiService();

  void _logout(BuildContext context) async {
    await _apiService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, $username ($email), Role: $userRole'),
      ),
    );
  }
}
