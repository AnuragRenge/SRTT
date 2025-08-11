import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'package:flutter/cupertino.dart';
import 'vehicles_create_screen.dart';
import 'vehicles_detail_screen.dart';

class VehiclesListScreen extends StatefulWidget {
  final String username;
  final String email;
  final String userRole;
  final dynamic id;

  const VehiclesListScreen({
    super.key,
    required this.username,
    required this.email,
    required this.userRole,
    this.id,
  });

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  int? _longPressedIndex;
  late Future<List<Map<String, dynamic>>> _vehiclesFuture = Future.value([]);
  List<Map<String, dynamic>> _allVehicles = [];
  List<Map<String, dynamic>> _filteredVehicles = [];
  String _searchQuery = '';
  List<String> _statusFilters = [];
  final List<String> _statusOptions = ['Available', 'Booked'];
  String? _notificationMessage;
  bool _showNotification = false;
  Color _notificationColor = Colors.red;

  Widget _buildDrawer(BuildContext context) {
    final List<Map<String, dynamic>> navOptions = [
      {'label': "Home", 'icon': Icons.home, 'route': '/home', 'needsArgs': true},
      {'label': "Leads", 'icon': Icons.assignment, 'route': '/leads', 'needsArgs': true},
      {'label': "Tours", 'icon': Icons.map, 'route': '/tours', 'needsArgs': true},
      {'label': "Bookings", 'icon': Icons.book, 'route': '/bookings', 'needsArgs': true},
      {'label': "Drivers", 'icon': Icons.people_outline, 'route': '/drivers', 'needsArgs': true},
      {'label': "Company", 'icon': Icons.business, 'route': '/company', 'needsArgs': true},
      {'label': "Users", 'icon': Icons.people, 'route': '/users', 'needsArgs': true},
    ];

    return Drawer(
      backgroundColor: Colors.white,
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
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = ApiService().getVehicle();
    _loadVehicles();
  }

  void _loadVehicles() {
    _vehiclesFuture = ApiService().getVehicle();
    _vehiclesFuture.then((vehicles) {
      if (!mounted) return;
      vehicles.sort((a, b) {
        final adate = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bdate = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bdate.compareTo(adate);
      });
      setState(() {
        _allVehicles = vehicles;
        _filteredVehicles = vehicles;
      });
    });
  }

  void _filterVehicles() {
    setState(() {
      _filteredVehicles = _allVehicles.where((v) {
        final rawCompany = (v['company'] ?? '').toString().trim();
        final rawName = (v['name'] ?? '').toString().trim();
        final rawReg  = (v['registration_number'] ?? '').toString().toLowerCase();
        final title = ('$rawCompany $rawName').toLowerCase().trim();
        final status = (v['available_status'] ?? '').toString().toLowerCase();

        final searchMatch = _searchQuery.isEmpty ||
            title.contains(_searchQuery.toLowerCase()) ||
            rawReg.contains(_searchQuery.toLowerCase());

        final statusMatch = _statusFilters.isEmpty ||
            _statusFilters.map((s) => s.toLowerCase()).contains(status);

        return searchMatch && statusMatch;
      }).toList();
    });
  }

  Future<void> _pullRefresh() async {
    _loadVehicles();
    await Future.delayed(const Duration(milliseconds: 300));
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
      _filterVehicles();
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

  Future<bool> _confirmDeleteVehicle(BuildContext context, String? reg) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Confirm Delete",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text('Are you sure you want to delete the vehicle "${reg ?? ''}"?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text("Delete", style: TextStyle(color: Colors.white)),
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

  void _onDeleteVehicle(Map<String, dynamic> vehicle) async {
    final reg = vehicle['registration_number']?.toString();
    final confirmed = await _confirmDeleteVehicle(context, reg);
    if (confirmed) {
      try {
        final success = await ApiService().deleteVehicle(vehicle['id']);
        if (success) {
          _showTopNotification("Vehicle deleted successfully!", color: Colors.green);
          _loadVehicles();
        } else {
          _showTopNotification("Failed to delete vehicle.", color: Colors.red);
        }
      } catch (e) {
        _showTopNotification("Error: ${e.toString()}", color: Colors.red);
      }
    }
    setState(() {
      _longPressedIndex = null;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'booked':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _getInitials(String? name) {
    // Use the same helper you shared earlier (company + name)
    if (name == null || name.trim().isEmpty) return "";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
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
                hintText: 'Search by vehicle/company name or registration',
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
                _filterVehicles();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Vehicles'),
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
              label: const Text('Add Vehicle'),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VehicleCreateScreen()),
                  );
                  if (result is Map && result["success"] == true) {
                    _showTopNotification("Vehicle created successfully.", color: Colors.green);
                    _loadVehicles();
                  }
                }
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _vehiclesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 20, color: Color(0xFF007AFF)),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text("Failed to load vehicles:\n${snapshot.error}"));
              }
              if (_allVehicles.isEmpty && snapshot.hasData) {
                _allVehicles = snapshot.data!;
                _filteredVehicles = _allVehicles;
              }
              return Column(
                children: [
                  _buildSearchAndFilterBar(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _pullRefresh,
                      child: _filteredVehicles.isEmpty
                          ? const Center(child: Text("No vehicles found."))
                          : ListView.builder(
                        itemCount: _filteredVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _filteredVehicles[index];
                          final regnum  = (vehicle['registration_number'] ?? '[No Reg]').toString();
                          final name    = (vehicle['name'] ?? '').toString().trim();
                          final company = (vehicle['company'] ?? '').toString().trim();
                          final title   = (company.isNotEmpty ? '$company ' : '') + name;
                          final status  = (vehicle['available_status'] ?? '').toString();
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
                                      _getInitials(title),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    title.isNotEmpty ? title : '[No Name]',
                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          regnum,
                                          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
                                        builder: (_) => VehicleDetailScreen(vehicleId: vehicle['id']),
                                      ),
                                    );
                                    if (result is Map && result['updated'] == true) {
                                      _loadVehicles();
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
                                      BoxShadow(color: Colors.grey.withOpacity(0.13), blurRadius: 2),
                                    ],
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
                                        label: const Text(
                                          "Cancel",
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                        ),
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
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.delete, color: Colors.white),
                                        label: const Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () {
                                          _onDeleteVehicle(vehicle);
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
