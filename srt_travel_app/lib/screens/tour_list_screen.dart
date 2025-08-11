import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'tour_create_screen.dart';
import 'tour_detail_screen.dart';

class TourListScreen extends StatefulWidget {
  final String username;
  final String email;
  final String userRole;
  final dynamic id;

  const TourListScreen({
    super.key,
    required this.username,
    required this.email,
    required this.userRole,
    this.id,
  });

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> {
  int? _longPressedIndex;
  late Future<List<Map<String, dynamic>>> _toursFuture;
  List<Map<String, dynamic>> _allTours = [];
  List<Map<String, dynamic>> _filteredTours = [];

  String _searchQuery = '';
  List<String> _typeFilters = [];
  final List<String> _typeOptions = ['Lumpsum', 'Local', 'Outstation'];

  String? _notificationMessage;
  bool _showNotification = false;
  Color _notificationColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  void _loadTours() {
    _toursFuture = ApiService().getTour();
    _toursFuture.then((tours) {
      if (!mounted) return;
      _sortToursByCreatedDateDesc(tours);
      setState(() {
        _allTours = tours;
        _filteredTours = tours;
      });
    });
  }
  void _sortToursByCreatedDateDesc(List<Map<String, dynamic>> tours) {
    tours.sort((a, b) {
      final adate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bdate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bdate.compareTo(adate); // newest first
    });
  }

  void _filterTours() {
    setState(() {
      _filteredTours = _allTours.where((tour) {
        final tourName = (tour['tour_name'] ?? '').toString().toLowerCase();
        final leadName = (tour['lead_name'] ?? '').toString().toLowerCase();
        final type = (tour['tour_type'] ?? '').toString().toLowerCase();

        final searchMatch = _searchQuery.isEmpty ||
            tourName.contains(_searchQuery.toLowerCase()) ||
            leadName.contains(_searchQuery.toLowerCase());

        final typeMatch = _typeFilters.isEmpty ||
            _typeFilters.map((t) => t.toLowerCase()).contains(type);

        return searchMatch && typeMatch;
      }).toList();
    });
  }

  Future<void> _pullRefresh() async {
    _loadTours();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _showTypeFilterDialog() async {
    List<String> tempSelected = List.from(_typeFilters);

    final result = await showDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Filter by Tour Type'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _typeOptions
                      .map((type) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(type),
                    value: tempSelected.contains(type),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          tempSelected.add(type);
                        } else {
                          tempSelected.remove(type);
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
    ) ??
        _typeFilters;

    setState(() {
      _typeFilters = result;
      _filterTours();
    });
  }

  void _showTopNotification(String message, {Color color = Colors.red}) {
    setState(() {
      _notificationMessage = message;
      _notificationColor = color;
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'local':
        return Colors.blue;
      case 'lumpsum':
        return Colors.green;
      case 'outstation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSearchAndFilterBar() {
    final bool filterActive = _typeFilters.isNotEmpty;
    final Color iconColor = filterActive ? _getTypeColor(_typeFilters.first) : Colors.blue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search by tour or lead name',
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
                _filterTours();
              },
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: Icon(Icons.filter_list, size: 26, color: iconColor),
                tooltip: "Filter by Tour Type",
                onPressed: _showTypeFilterDialog,
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
    // Drawer copied exactly from your provided code
    final List<Map<String, dynamic>> navOptions = [
      {'label': "Home",'icon': Icons.home,'route': '/home','needsArgs': true},
      {'label': "Leads", 'icon': Icons.assignment, 'route': '/leads', 'needsArgs': true},
      {'label': "Company", 'icon': Icons.business, 'route': '/company', 'needsArgs': true },
      {'label': "Bookings",'icon': Icons.book,'route': '/bookings','needsArgs': true},
      {'label': "Drivers",'icon': Icons.people_outline,'route': '/drivers','needsArgs': true},
      {'label': "Vehicles",'icon': Icons.directions_car,'route': '/vehicles','needsArgs': true},
      {'label': "Users",'icon': Icons.people,'route': '/users','needsArgs': true},
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
              onTap: () async {
                await ApiService().logout();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
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
        title: const Text('All Tours'),
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
                side: BorderSide.none,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.add, size: 22, color: Colors.white),
              label: const Text('Add Tour'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TourCreateScreen()),
                );
                if (result is Map && result["success"] == true) {
                  _showTopNotification("Tour created successfully.", color: Colors.green);
                  _loadTours();
                }
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _toursFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 20, color: Color(0xFF007AFF)),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text("Failed to load tours:\n${snapshot.error}"));
              }
              if (_allTours.isEmpty && snapshot.hasData) {
                final tours = List<Map<String, dynamic>>.from(snapshot.data!);
                _sortToursByCreatedDateDesc(tours);
                _allTours = tours;
                _filteredTours = tours;
              }
              return Column(
                children: [
                  _buildSearchAndFilterBar(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _pullRefresh,
                      child: _filteredTours.isEmpty
                          ? const Center(child: Text("No tours found."))
                          : ListView.builder(
                        itemCount: _filteredTours.length,
                        itemBuilder: (context, index) {
                          final tour = _filteredTours[index];
                          final tourName = tour['tour_name'] ?? '[No Name]';
                          final leadName = tour['lead_name'] ?? '';
                          final type = tour['tour_type'] ?? '';

                          final isLongPressed = _longPressedIndex == index;

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
                                      leadName.isNotEmpty
                                          ? leadName[0].toUpperCase()
                                          : '',
                                      style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                  ),
                                  title: Text(tourName),
                                  subtitle: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          leadName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black54),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(type).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          type.isEmpty ? "NA" : type,
                                          style: TextStyle(
                                            color: _getTypeColor(type),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TourDetailScreen(tourId: tour['id']), // Pass tour ID
                                      ),
                                    ).then((_) {
                                      setState(() {
                                        _loadTours();
                                      });
                                    });

                                    // Refresh list if detail screen indicated changes
                                    if (result is Map && result['updated'] == true) {
                                      _loadTours(); // reload from API
                                    }
                                  },
                                  onLongPress: () {
                                    setState(() {
                                      _longPressedIndex =
                                      _longPressedIndex == index ? null : index;
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
                                        label: const Text("Cancel",
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                                        label: const Text("Delete",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          final success = await ApiService().deleteTour(tour['id']);
                                          if (success) {
                                            _showTopNotification("Tour deleted successfully", color: Colors.green);
                                            _loadTours();
                                          } else {
                                            _showTopNotification("Failed to delete tour");
                                          }
                                          setState(() {
                                            _longPressedIndex = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                )
                            ],
                          );
                        },
                      ),
                    ),
                  )
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
