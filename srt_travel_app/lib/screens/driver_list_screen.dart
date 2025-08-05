import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'package:flutter/cupertino.dart';

class DriverListScreen extends StatefulWidget {
  final String username;
  final String email;
  final String userRole;
  final dynamic id;

  const DriverListScreen({
    super.key,
    required this.username,
    required this.email,
    required this.userRole,
    this.id,
  });

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  String? _notificationMessage;
  bool _showNotification = false;

  void _logout() async {
    await ApiService().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _showTopNotification(String message, {Color color = Colors.red}) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showNotification) {
        setState(() {
          _showNotification = false;
          _notificationMessage = null;
        });
      }
    });
  }

  Widget _buildDrawer(BuildContext context) {
    final List<Map<String, dynamic>> navOptions = [
      {
        'label': "Home",
        'icon': Icons.home,
        'route': '/home',
        'needsArgs': true,
      },
      {
        'label': "Leads",
        'icon': Icons.assignment,
        'route': '/leads',
        'needsArgs': true,
      },
      {
        'label': "Tours",
        'icon': Icons.map,
        'route': '/tours',
        'needsArgs': true,
      },
      {
        'label': "Bookings",
        'icon': Icons.book,
        'route': '/bookings',
        'needsArgs': true,
      },
      {
        'label': "Company",
        'icon': Icons.business,
        'route': '/company',
        'needsArgs': true,
      },
      {
        'label': "Vehicles",
        'icon': Icons.directions_car,
        'route': '/vehicles',
        'needsArgs': true,
      },
      {
        'label': "Users",
        'icon': Icons.people,
        'route': '/users',
        'needsArgs': true,
      },
    ];

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                widget.username.isEmpty ? "No name" : widget.username,
                style: const TextStyle(color: Colors.black),
              ),
              accountEmail: Text(
                widget.email.isEmpty ? "No email" : widget.email,
                style: const TextStyle(color: Colors.black54),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              decoration: const BoxDecoration(color: Colors.white),
            ),
            ...navOptions.map(
                  (item) => ListTile(
                leading: Icon(item['icon'] as IconData, color: Colors.blue),
                title: Text(item['label'] as String, style: const TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  if (item['needsArgs'] == true) {
                    Navigator.pushNamed(
                      context,
                      item['route'] as String,
                      arguments: {
                        'role': widget.userRole,
                        'username': widget.username,
                        'email': widget.email,
                        'id': widget.id,
                      },
                    );
                  } else {
                    Navigator.pushNamed(context, item['route'] as String);
                  }
                },
              ),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drivers'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      drawer: _buildDrawer(context),
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Welcome ${widget.username}!\nEmail: ${widget.email}\nRole: ${widget.userRole}',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
