import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  final String username;
  final String email;
  final String userRole;
  final dynamic id;

  const UserListScreen({
    super.key,
    required this.username,
    required this.email,
    required this.userRole,
    this.id,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchQuery = '';
  final List<String> _roleOptions = [];
  List<String> _selectedRoles = [];
  String? _notificationMessage;
  bool _showNotification = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _usersFuture = ApiService().getUsers();
    _usersFuture.then((users) {
      if (mounted) {
        users.sort((a, b) {
          final adate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bdate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bdate.compareTo(adate);
        });
        final roles = users
            .map((u) => u['role']?.toString() ?? '')
            .where((r) => r.isNotEmpty)
            .toSet()
            .toList();
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _roleOptions
            ..clear()
            ..addAll(roles);
        });
      }
    });
  }

  Future<void> _pullRefresh() async {
    _loadUsers();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _logout() async {
    await ApiService().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['username'] ?? '').toLowerCase();
        final mobile = (user['mobile'] ?? '').toLowerCase();
        final role = (user['role'] ?? '').toLowerCase();

        final searchMatches = _searchQuery.isEmpty ||
            name.contains(_searchQuery.toLowerCase()) ||
            mobile.contains(_searchQuery.toLowerCase());
        final roleMatches = _selectedRoles.isEmpty ||
            _selectedRoles.map((s) => s.toLowerCase()).contains(role);

        return searchMatches && roleMatches;
      }).toList();
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.blueAccent;
      case 'agent':
        return Colors.green;
      default:
        return Colors.amber[800] ?? Colors.grey;
    }
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

  void _showRolePicklist() async {
    List<String> tempSelected = List.from(_selectedRoles);
    final result = await showDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter by Role'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _roleOptions
                      .map((role) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(role[0].toUpperCase() + role.substring(1)),
                    value: tempSelected.contains(role),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          tempSelected.add(role);
                        } else {
                          tempSelected.remove(role);
                        }
                      });
                    },
                  ))
                      .toList(),
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.black, size: 18),
                  label: const Text("Reset", style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.pop(ctx, <String>[]);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text("Apply", style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(ctx, tempSelected),
                ),
              ],
            );
          },
        );
      },
    ) ?? _selectedRoles;

    setState(() {
      _selectedRoles = result;
      _filterUsers();
    });
  }

  Widget _buildSearchAndFilterBar() {
    final bool filterActive = _selectedRoles.isNotEmpty;
    final Color iconColor = filterActive ? _getRoleColor(_selectedRoles.first) : Colors.blue;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, size: 24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterUsers();
              },
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: Text(
                  String.fromCharCode(Icons.filter_list.codePoint),
                  style: TextStyle(
                    fontFamily: Icons.filter_list.fontFamily,
                    package: Icons.filter_list.fontPackage,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: iconColor,
                  ),
                ),
                tooltip: "Filter by role",
                onPressed: _roleOptions.isEmpty ? null : _showRolePicklist,
              ),
              if (filterActive)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
        'icon': Icons.people,
        'route': '/leads',
        'needsArgs': true,
      },
      {
        'label': "Tours",
        'icon': Icons.map,
        'route': '/tours',
        'needsArgs': false,
      },
      {
        'label': "Company",
        'icon': Icons.business,
        'route': '/company',
        'needsArgs': false,
      },
      {
        'label': "Bookings",
        'icon': Icons.book,
        'route': '/bookings',
        'needsArgs': false,
      },
      {
        'label': "Drivers",
        'icon': Icons.people_outline,
        'route': '/drivers',
        'needsArgs': false,
      },
      {
        'label': "Vehicles",
        'icon': Icons.directions_car,
        'route': '/vehicles',
        'needsArgs': false,
      },
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.username.isEmpty ? "No name" : widget.username,
                  style: const TextStyle(color: Colors.black)),
              accountEmail: Text(widget.email.isEmpty ? "No email" : widget.email,
                  style: const TextStyle(color: Colors.black54)),
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
                if (item['route'] == '/home' && item['needsArgs'] == true) {
                  Navigator.pushNamed(
                    context,
                    '/home',
                    arguments: {
                      'role': widget.userRole,
                      'username': widget.username,
                      'email': widget.email,
                      'id': widget.id,
                    },
                  );
                }else if (item['route'] == '/leads' && item['needsArgs'] == true) {
                  Navigator.pushNamed(
                    context,
                    '/leads',
                    arguments: {
                      'role': widget.userRole,
                      'username': widget.username,
                      'email': widget.email,
                      'id': widget.id,
                    },
                  );
                }else {
                  Navigator.pushNamed(context, item['route'] as String);
                }
              },
            )),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // didPop: bool, result: dynamic
        // You can handle the pop event here, but with canPop: false, back navigation is blocked.
        // Usually, leave this empty if you are just blocking back nav.
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("All Users"),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.blue),
        ),
        drawer: _buildDrawer(context),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (_allUsers.isEmpty && snapshot.hasData) {
                  _allUsers = snapshot.data!;
                  _filteredUsers = _allUsers;
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Failed to load users:\n${snapshot.error}", textAlign: TextAlign.center)
                  );
                }

                return Column(
                  children: [
                    _buildSearchAndFilterBar(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _pullRefresh,
                        child: _filteredUsers.isEmpty
                            ? const Center(child: Text("No users found."))
                            : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final username = user['username'] ?? '[No Name]';
                            final mobile = user['mobile']?.toString() ?? '';
                            final role = user['role'] ?? '';
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    _getInitials(username),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  username,
                                  style: const TextStyle(
                                    //fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mobile.isNotEmpty ? mobile : 'No Mobile',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(role).withOpacity(0.17),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    role.isNotEmpty
                                        ? role[0].toUpperCase() + role.substring(1)
                                        : "NA",
                                    style: TextStyle(
                                      color: _getRoleColor(role),
                                      //fontWeight: FontWeight.w600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => UserDetailScreen(id: user['id'])),
                                  );
                                  if (result is Map && result['updated'] == true) {
                                    _loadUsers();  // << Reloads the users after return from details if an update occurred
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_showNotification && _notificationMessage != null)
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.up,
                  onDismissed: (_) => setState(() => _showNotification = false),
                  child: InAppNotification(
                    message: _notificationMessage!,
                    color: Colors.green,
                    onClose: () => setState(() => _showNotification = false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
