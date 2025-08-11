import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'package:flutter/cupertino.dart';
import 'driver_create_screen.dart';
import 'driver_detail_screen.dart';

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
  int? _longPressedIndex;
  late Future<List<Map<String, dynamic>>> _driversFuture = Future.value([]);
  List<Map<String, dynamic>> _allDrivers = [];
  List<Map<String, dynamic>> _filteredDrivers = [];
  String _searchQuery = '';
  List<String> _statusFilters = [];
  final List<String> _statusOptions = ['Available', 'On Duty'];
  String? _notificationMessage;
  bool _showNotification = false;
  Color _notificationColor = Colors.red;

  void _showCreateDriverScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DriverCreateScreen()),
    );
    if (result is Map && result["success"] == true) {
      _showTopNotification("Driver created successfully in system.", color: Colors.green);
      _loadDrivers();
    }
  }

  @override
  void initState() {
    super.initState();
    _driversFuture = ApiService().getDriver();
    _loadDrivers();
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

  void _logout() async {
    await ApiService().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _loadDrivers() {
    _driversFuture = ApiService().getDriver();
    _driversFuture.then((drivers) {
      if (mounted) {
        drivers.sort((a, b) {
          final adate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bdate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bdate.compareTo(adate);
        });
        setState(() {
          _allDrivers = drivers;
          _filteredDrivers = drivers;
        });
      }
    });
  }

  void _filterDrivers() {
    setState(() {
      _filteredDrivers = _allDrivers.where((driver) {
        final name = (driver['name'] ?? '').toLowerCase();
        final phone = (driver['phone'] ?? '').toLowerCase();
        final status = (driver['status'] ?? '').toLowerCase();

        final searchMatch = _searchQuery.isEmpty ||
            name.contains(_searchQuery.toLowerCase()) ||
            phone.contains(_searchQuery.toLowerCase());

        final statusMatch = _statusFilters.isEmpty ||
            _statusFilters.map((s) => s.toLowerCase()).contains(status);

        return searchMatch && statusMatch;
      }).toList();
    });
  }

  Future<void> _pullRefresh() async {
    _loadDrivers();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _showStatusFilterDialog() async {
    List<String> tempSelected = List.from(_statusFilters);

    final result = await showDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Filter Status'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _statusOptions.map((status) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(status),
                    value: tempSelected.contains(status),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          tempSelected.add(status);
                        } else {
                          tempSelected.remove(status);
                        }
                      });
                    },
                  )).toList(),
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
    ) ?? _statusFilters;

    setState(() {
      _statusFilters = result;
      _filterDrivers();
    });
  }

  void _showTopNotification(String message, {Color color = Colors.red}) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
      _notificationColor = color;
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

  Future<bool> _confirmDeleteDriver(BuildContext context, String? driverName) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Delete",
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete the driver \"${driverName ?? ''}\"?"),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text("Delete",style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    ) ?? false;
  }

  void _onDeleteDriver(Map<String, dynamic> driver) async {
    final confirmed = await _confirmDeleteDriver(context, driver['name']);
    if (confirmed) {
      try {
        final success = await ApiService().deleteDriver(driver['id']);
        if (success) {
          _showTopNotification("Driver deleted successfully!", color: Colors.green);
          _loadDrivers();
        } else {
          _showTopNotification("Failed to delete driver.", color: Colors.red);
        }
      } catch (e) {
        _showTopNotification("Error: ${e.toString()}", color: Colors.red);
      }
    }
    setState(() {
      _longPressedIndex = null;
    });
  }

  Widget _buildSearchAndFilterBar() {
    final bool filterActive = _statusFilters.isNotEmpty;
    final Color iconColor = filterActive ? _getStatusColor(_statusFilters.first) : Colors.blue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search by name or mobile',
                prefixIcon: const Icon(Icons.search, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.all(8),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterDrivers();
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
                tooltip: "Filter by Status",
                onPressed: _showStatusFilterDialog,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available': return Colors.green;
      case 'on duty': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drivers'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                elevation: 0,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.add, size: 22, color: Colors.white),
              label: const Text('Create Driver'),
              onPressed: _showCreateDriverScreen,
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _driversFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator(radius: 20, color: Color(0xFF007AFF)));
              }
              if (snapshot.hasError) {
                return Center(child: Text("Failed to load drivers:\n${snapshot.error}"));
              }
              if (_allDrivers.isEmpty && snapshot.hasData) {
                _allDrivers = snapshot.data!;
                _filteredDrivers = _allDrivers;
              }
              return Column(
                children: [
                  _buildSearchAndFilterBar(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _pullRefresh,
                      child: _filteredDrivers.isEmpty
                          ? const Center(child: Text("No drivers found."))
                          : ListView.builder(
                        itemCount: _filteredDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = _filteredDrivers[index];
                          final name = driver['name'] ?? '[No Name]';
                          final status = driver['status'] ?? '';
                          final bool isLongPressed = _longPressedIndex == index;

                          return Column(
                            children: [
                              Card(
                                color: Colors.white,
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[100],
                                    child: Text(
                                      _getInitials(name),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  title: Text(name),
                                  subtitle: Row(
                                    children: [
                                      Text(driver['phone'] ?? 'NA',
                                          style: const TextStyle(fontWeight: FontWeight.w500)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          status.isEmpty ? "NA" : status,
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    setState(() { _longPressedIndex = null; });
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DriverDetailScreen(driverId: driver['id']),
                                      ),
                                    );
                                    if (result is Map && result['updated'] == true) {
                                      _loadDrivers();
                                    }
                                  },
                                  onLongPress: () {
                                    setState(() {
                                      if (_longPressedIndex == index) {
                                        _longPressedIndex = null;
                                      } else {
                                        _longPressedIndex = index;
                                      }
                                    });
                                  },
                                ),
                              ),
                              if (isLongPressed)
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(color: Colors.grey.withOpacity(0.13), blurRadius: 2)
                                      ]
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.cancel, color: Colors.black45),
                                        label: const Text("Cancel", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          setState(() {
                                            _longPressedIndex = null;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 14),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.delete, color: Colors.white),
                                        label: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          _onDeleteDriver(driver);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                  color: _notificationColor,
                  onClose: () => setState(() => _showNotification = false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
