import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'create_lead_screen.dart';
import '../widgets/in_app_notification.dart';
import 'lead_detail_screen.dart';

class LeadsListScreen extends StatefulWidget {
  final String username;
  final String email;
  final String userRole;
  final dynamic id;

  const LeadsListScreen({
    super.key,
    required this.username,
    required this.email,
    required this.userRole,
    this.id,
  });

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  late Future<List<Map<String, dynamic>>> _leadsFuture;
  List<Map<String, dynamic>> _allLeads = [];
  List<Map<String, dynamic>> _filteredLeads = [];
  String _searchQuery = '';
  final List<String> _statusOptions = [
    'New', 'Lost', 'Booked', 'Under Follow-up', 'Not Answered'
  ];
  List<String> _selectedStatuses = [];

  // Notification state
  String? _notificationMessage;
  bool _showNotification = false;

  // Track which lead (index) is in long pressed/delete mode
  int? _longPressedIndex;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  void _loadLeads() {
    _leadsFuture = ApiService().getLeads();
    _leadsFuture.then((leads) {
      if (mounted) {
        leads.sort((a, b) {
          final adate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bdate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bdate.compareTo(adate);
        });
        setState(() {
          _allLeads = leads;
          _filteredLeads = leads;
        });
      }
    });
  }

  Future<void> _pullRefresh() async {
    _loadLeads();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _logout() async {
    await ApiService().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _filterLeads() {
    setState(() {
      _filteredLeads = _allLeads.where((lead) {
        final name = (lead['name'] ?? '').toLowerCase();
        final phone = (lead['phone'] ?? '').toLowerCase();
        final status = (lead['status'] ?? '').toLowerCase();

        final searchMatches = _searchQuery.isEmpty ||
            name.contains(_searchQuery.toLowerCase()) ||
            phone.contains(_searchQuery.toLowerCase());
        final statusMatches = _selectedStatuses.isEmpty ||
            _selectedStatuses.map((s) => s.toLowerCase()).contains(status);

        return searchMatches && statusMatches;
      }).toList();
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new': return Colors.blueAccent;
      case 'not answered': return Colors.red;
      case 'under follow-up': return Colors.green;
      case 'lost': return Colors.redAccent;
      case 'booked': return Colors.grey;
      default: return Colors.black54;
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

  void _showCreateLeadScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateLeadScreen()),
    );
    if (result is Map && result["success"] == true) {
      _showTopNotification("Lead created successfully!", color: Colors.green);
      _loadLeads();
    }
  }

  void _showStatusPicklist() async {
    List<String> tempSelected = List.from(_selectedStatuses);
    final result = await showDialog<List<String>>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
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
        }
    ) ?? _selectedStatuses;

    setState(() {
      _selectedStatuses = result;
      _filterLeads();
    });
  }

  void _onDeleteLead(Map<String, dynamic> lead) async {
    final confirmed = await _confirmDeleteLead(context, lead['name']);
    if (confirmed) {
      try {
        final success = await ApiService().deleteLead(lead['id']);
        if (success) {
          _showTopNotification("Lead deleted successfully!", color: Colors.green);
          _loadLeads();
        } else {
          _showTopNotification("Failed to delete lead.", color: Colors.red);
        }
      } catch (e) {
        _showTopNotification("Error: ${e.toString()}", color: Colors.red);
      }
    }
    setState(() {
      _longPressedIndex = null;
    });
  }

  Future<bool> _confirmDeleteLead(BuildContext context, String? leadName) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Delete",
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete the lead \"${leadName ?? ''}\"?"),
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

  Widget _buildSearchAndFilterBar() {
    final bool filterActive = _selectedStatuses.isNotEmpty;
    final Color iconColor = filterActive ? _getStatusColor(_selectedStatuses.first) : Colors.blue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterLeads();
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
                tooltip: "Filter by status",
                onPressed: _showStatusPicklist,
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
    final List<Map<String, dynamic>> _navOptions = [
      {
        'label': "Home",
        'icon': Icons.home,
        'route': '/home',
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
      {
        'label': "Users",
        'icon': Icons.people,
        'route': '/users',
        'needsArgs': true,
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
            ..._navOptions.map((item) => ListTile(
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
                }else if (item['route'] == '/users' && item['needsArgs'] == true) {
                  Navigator.pushNamed(
                    context,
                    '/users',
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("All Leads"),
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
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  elevation: 0,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.add, size: 26, color: Colors.white),
                label: const Text('Create Lead'),
                onPressed: _showCreateLeadScreen,
              ),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _leadsFuture,
              builder: (context, snapshot) {
                if (_allLeads.isEmpty && snapshot.hasData) {
                  _allLeads = snapshot.data!;
                  _filteredLeads = _allLeads;
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Failed to load leads:\n${snapshot.error}", textAlign: TextAlign.center)
                  );
                }

                return Column(
                  children: [
                    _buildSearchAndFilterBar(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _pullRefresh,
                        child: _filteredLeads.isEmpty
                            ? const Center(child: Text("No leads found."))
                            : ListView.builder(
                          itemCount: _filteredLeads.length,
                          itemBuilder: (context, index) {
                            final lead = _filteredLeads[index];
                            final name = lead['name'] ?? '[No Name]';
                            final status = lead['status'] ?? '';

                            final bool isLongPressed = _longPressedIndex == index;
                            return Column(
                              children: [
                                Card(
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
                                        Text(
                                          lead['phone'] ?? 'NA',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(
                                            status.isNotEmpty
                                                ? status[0].toUpperCase() + status.substring(1)
                                                : "NA",
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      setState(() {_longPressedIndex = null;});
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LeadDetailScreen(leadId: lead['id']),
                                        ),
                                      );
                                      if (result is Map && result['updated'] == true) {
                                        _loadLeads();
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
                                            _onDeleteLead(lead);
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
                    color: (_notificationMessage == "Lead created successfully!" ||
                        _notificationMessage == "Lead deleted successfully!"
                        ? Colors.green
                        : Colors.red),
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
