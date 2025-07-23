import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminHomeScreen extends StatelessWidget {
  final String userRole;
  final String username;
  final String email;
  final dynamic id;

  const AdminHomeScreen({
    super.key,
    required this.userRole,
    required this.username,
    required this.email,
    this.id,
  });

  void _logout(BuildContext context) async {
    await ApiService().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
// Drawer menu options for admin
    final navOptions = [
      {'label': "Leads", 'icon': Icons.assignment, 'route': '/leads'},
      {'label': "Tours", 'icon': Icons.map, 'route': '/tours'},
      {'label': "Company", 'icon': Icons.business, 'route': '/company'},
      {'label': "Bookings", 'icon': Icons.book, 'route': '/bookings'},
      {'label': "Drivers", 'icon': Icons.people_outline, 'route': '/drivers'},
      {'label': "Vehicles", 'icon': Icons.directions_car, 'route': '/vehicles'},
      {'label': "Users", 'icon': Icons.people, 'route': '/users'},
    ];

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false, // Disable system back button
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.blue),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            )
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(username, style: const TextStyle(color: Colors.black)),
                  accountEmail: Text(email, style: const TextStyle(color: Colors.black54)),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  decoration: const BoxDecoration(color: Colors.white),
                ),
                ...navOptions.map((item) => ListTile(
                  leading: Icon(item['icon'] as IconData, color: Colors.blue),
                  title: Text(item['label'] as String, style: const TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, item['route'] as String);
                  },
                )),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.red)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            "Welcome, $username ($email)\n\nSelect an option from the left menu.",
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}