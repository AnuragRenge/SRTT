import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  late Future<List<Map<String, dynamic>>> _leadsFuture;
  List<Map<String, dynamic>> _allLeads = [];
  List<Map<String, dynamic>> _filteredLeads = [];
  String _searchQuery = '';
  // Multi-selectable status values (no 'All' here!)
  final List<String> _statusOptions = [
    'New', 'Not Answered', 'Under Follow-up', 'Lost', 'Booked'
  ];
  List<String> _selectedStatuses = [];

  @override
  void initState() {
    super.initState();
    _leadsFuture = ApiService().getLeads();
    _leadsFuture.then((leads) {
      setState(() {
        _allLeads = leads;
        _filteredLeads = leads;
      });
    });
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

        final statusMatches =
            _selectedStatuses.isEmpty ||
                _selectedStatuses
                    .map((s) => s.toLowerCase())
                    .contains(status);

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
      case 'new':
        return Colors.blueAccent;
      case 'not answered':
        return Colors.red;
      case 'under follow-up':
        return Colors.green;
      case 'lost':
        return Colors.redAccent;
      case 'booked':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  Widget _buildSearchAndFilterBar() {
    final bool filterActive = _selectedStatuses.isNotEmpty;
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
                  borderRadius: BorderRadius.circular(20),
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
                    color: filterActive ? Colors.blue : Colors.blue,
                  ),
                ),
                tooltip: "Filter by status",
                onPressed: _showStatusMultiSelect,
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

  void _showStatusMultiSelect() async {
    final List<String> result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        List<String> tempSelected = List.from(_selectedStatuses);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: MediaQuery.of(ctx).viewInsets.add(const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  ..._statusOptions.map((status) => CheckboxListTile(
                    dense: true,
                    title: Text(status),
                    value: tempSelected.contains(status),
                    onChanged: (bool? checked) {
                      setSheetState(() {
                        if (checked == true) {
                          tempSelected.add(status);
                        } else {
                          tempSelected.remove(status);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 18, color: Colors.black87),
                        label: const Text("Reset", style: TextStyle(color: Colors.black87)),
                        onPressed: () {
                          Navigator.pop(ctx, <String>[]); // Reset and close: leads update immediately
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text("Apply", style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.pop(ctx, tempSelected); // Apply and close: leads update immediately
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    ) ?? _selectedStatuses;

    setState(() {
      _selectedStatuses = result;
      _filterLeads();
    });
  }

  // Commented-out: show status filter chips (as per your instructions)
  /*
  Widget _buildStatusChips() {
    if (_selectedStatuses.isEmpty) return const SizedBox(height: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        children: _selectedStatuses
            .map((status) => Chip(
                  label: Text(status),
                  onDeleted: () {
                    setState(() {
                      _selectedStatuses.remove(status);
                      _filterLeads();
                    });
                  },
                ))
            .toList(),
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Leads"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _leadsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Failed to load leads:\n${snapshot.error}", textAlign: TextAlign.center));
          }

          if (_allLeads.isEmpty && snapshot.hasData) {
            _allLeads = snapshot.data!;
            _filteredLeads = _allLeads;
          }

          return Column(
            children: [
              _buildSearchAndFilterBar(),
              // _buildStatusChips(), // COMMENTED OUT: filter chips not required!
              Expanded(
                child: _filteredLeads.isEmpty
                    ? const Center(child: Text("No leads found."))
                    : ListView.builder(
                  itemCount: _filteredLeads.length,
                  itemBuilder: (context, index) {
                    final lead = _filteredLeads[index];
                    final name = lead['name'] ?? '[No Name]';
                    final status = lead['status'] ?? '';
                    return Card(
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
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
