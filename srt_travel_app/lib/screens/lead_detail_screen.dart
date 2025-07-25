import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';

class LeadDetailScreen extends StatefulWidget {
  final dynamic leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  late Future<Map<String, dynamic>?> _leadFuture;
  Map<String, dynamic>? leadData;
  Map<String, dynamic>? initialData;

  String? editingField;
  final Map<String, TextEditingController> _controllers = {};

  bool _leadJustUpdated = false;
  String? notificationMessage;
  bool showNotification = false;
  Color notificationColor = Colors.blue;

  String? _phoneBeforeEdit;

  final List<String> statusOptions = [
    "New", "Lost", "Booked", "Under Follow-up", "Not Answered"
  ];
  final List<String> sourceOptions = [
    "Website", "Manual"
  ];

  List<Map<String, dynamic>> _allOtherLeads = [];

  /// Show Save/Reset after ✔ pressed and validation passes
  bool showSaveReset = false;

  /// Logic: true if anything is changed (for Save/Reset)
  bool get isChanged {
    if (leadData == null || initialData == null) return false;
    for (final key in ['name', 'phone', 'email', 'status', 'source']) {
      if ((leadData![key]?.trim() ?? '') != (initialData![key]?.trim() ?? '')) return true;
    }
    return false;
  }

  Map<String, dynamic> get updatedFields {
    final updated = <String, dynamic>{};
    if (leadData == null || initialData == null) return updated;
    for (final key in ['name', 'phone', 'email', 'status', 'source']) {
      if ((leadData![key]?.trim() ?? '') != (initialData![key]?.trim() ?? '')) {
        updated[key] = leadData![key].toString().trim();
      }
    }
    return updated;
  }

  @override
  void initState() {
    super.initState();
    _leadFuture = _fetchLead();
    _fetchAllOtherLeads();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchLead() async {
    final data = await ApiService().getLeadById(widget.leadId);
    setState(() {
      leadData = {...?data};
      initialData = {...?data};
      for (var key in ['name', 'phone', 'email']) {
        _controllers[key] = TextEditingController(text: data?[key]?.toString() ?? '');
      }
    });
    return data;
  }

  Future<void> _fetchAllOtherLeads() async {
    final leads = await ApiService().getLeads();
    _allOtherLeads = leads.where((l) => l['id'].toString() != widget.leadId.toString()).toList();
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length == 1
        ? parts[0][0].toUpperCase()
        : (parts[0][0] + parts.last[0]).toUpperCase();
  }

  String _formatDateTimeIST(String? utcString) {
    if (utcString == null || utcString.isEmpty) return 'NA';
    DateTime? utcDate = DateTime.tryParse(utcString);
    if (utcDate == null) return 'NA';
    final istDate = utcDate.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd/MM/yyyy, h:mm a').format(istDate);
  }

  /// ---- Start editing a field. For phone, store pre-edit value.
  void _startEdit(String fieldName) {
    setState(() {
      _controllers[fieldName] ??= TextEditingController(text: leadData?[fieldName]?.toString() ?? '');
      _controllers[fieldName]!.text = leadData?[fieldName]?.toString() ?? '';
      editingField = fieldName;
      if (fieldName == 'phone') {
        _phoneBeforeEdit = leadData?['phone']?.toString() ?? '';
      }
    });
  }

  /// ---- Validation logic for phone. Sets showSaveReset only if success.
  Future<void> _finishEdit(String fieldName) async {
    final rawValue = _controllers[fieldName]?.text ?? '';
    final value = rawValue.trim();

    // --- PHONE special validation
    if (fieldName == 'phone') {
      if (value != (_phoneBeforeEdit ?? '')) {
        // 1. Must be 10 digits.
        if (value.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(value)) {
          _showNotification("Mobile must be a 10-digit number.", color: Colors.red);
          Future.delayed(Duration(milliseconds: 200), () {
            _controllers['phone']?.text = _phoneBeforeEdit ?? '';
            setState(() {
              editingField = null;
              leadData?['phone'] = _phoneBeforeEdit ?? '';
              showSaveReset = false;
            });
          });
          return;
        }
        // 2. Duplicate check.
        await _fetchAllOtherLeads();
        if (value.isNotEmpty &&
            _allOtherLeads.any((l) => (l['phone'] ?? '').toString().trim() == value)) {
          _showNotification("This mobile already exists in another lead.", color: Colors.red);
          Future.delayed(Duration(milliseconds: 200), () {
            _controllers['phone']?.text = _phoneBeforeEdit ?? '';
            setState(() {
              editingField = null;
              leadData?['phone'] = _phoneBeforeEdit ?? '';
              showSaveReset = false;
            });
          });
          return;
        }
      }
    }

    setState(() {
      leadData?[fieldName] = value;
      editingField = null;
      showSaveReset = isChanged;  // Only show Save/Reset when a change & after check is pressed
    });
  }

  void _resetChanges() {
    setState(() {
      if (initialData == null) return;
      leadData = {...initialData!};
      for (var key in ['name', 'phone', 'email']) {
        _controllers[key]?.text = initialData?[key]?.toString() ?? '';
      }
      editingField = null;
      showSaveReset = false;
    });
  }

  void _showNotification(String message, {Color? color}) {
    setState(() {
      notificationMessage = message;
      notificationColor = color ?? Colors.blue;
      showNotification = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => showNotification = false);
    });
  }

  /// ---- The Save API, fetches new details on success so Updated At refreshes
  Future<void> _saveChanges() async {
    final updated = updatedFields;
    // Validation 1: Not all blank
    bool allBlank = !updated.values.any((v) => v != null && v.toString().trim().isNotEmpty);
    if (allBlank) {
      _showNotification("Cannot update with all fields blank.", color: Colors.red);
      return;
    }
    // Validation 2: If phone in update, recheck it (shouldn't, but for safety)
    if (updated.containsKey('phone')) {
      final phone = updated['phone']!.trim();
      if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
        _showNotification("Mobile must be exactly 10 digits.", color: Colors.red);
        _controllers['phone']?.text = initialData?['phone']?.toString() ?? '';
        leadData?['phone'] = initialData?['phone']?.toString() ?? '';
        setState(() { showSaveReset = false; });
        return;
      }
      await _fetchAllOtherLeads();
      if (_allOtherLeads.any((l) => (l['phone'] ?? '').toString().trim() == phone)) {
        _showNotification("Another lead already exists with this mobile.", color: Colors.red);
        _controllers['phone']?.text = initialData?['phone']?.toString() ?? '';
        leadData?['phone'] = initialData?['phone']?.toString() ?? '';
        setState(() { showSaveReset = false; });
        return;
      }
    }

    try {
      final result = await ApiService().updateLead(widget.leadId, updated);
      // UPDATED: Fetch the new lead data again, so updated_at is correct.
      final fresh = await ApiService().getLeadById(widget.leadId);
      setState(() {
        notificationMessage = result['message'] ?? "Lead updated!";
        notificationColor = Colors.green;
        showNotification = true;
        // Set both current and initialData to match backend
        leadData = {...?fresh};
        initialData = {...?fresh};
        _controllers['name']?.text = leadData?['name'] ?? '';
        _controllers['phone']?.text = leadData?['phone'] ?? '';
        _controllers['email']?.text = leadData?['email'] ?? '';
        _leadJustUpdated = true;
        showSaveReset = false;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => showNotification = false);
      });
    } catch (e) {
      setState(() {
        notificationMessage = e.toString();
        notificationColor = Colors.red;
        showNotification = true;
      });
    }
  }

  Widget _notificationWidget() {
    if (!showNotification || notificationMessage == null) return const SizedBox();
    return Positioned(
      top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Dismissible(
        key: ValueKey(notificationMessage),
        direction: DismissDirection.up,
        onDismissed: (_) => setState(() => showNotification = false),
        child: InAppNotification(
          message: notificationMessage!,
          color: notificationColor,
          onClose: () => setState(() => showNotification = false),
        ),
      ),
    );
  }

  /// --- Editable dropdowns for status/source
  Widget _buildEditablePicklist({
    required String label,
    required String fieldName,
    required List<String> options,
    required IconData icon,
  }) {
    final val = (leadData?[fieldName] ?? '').toString();
    if (editingField == fieldName) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          leading: Icon(icon, color: Colors.blue[300]),
          title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          subtitle: DropdownButtonFormField<String>(
            value: options.contains(val) ? val : null,
            items: options
                .map((item) => DropdownMenuItem(
                value: item, child: Text(item)))
                .toList(),
            onChanged: (selected) {
              setState(() {
                leadData?[fieldName] = selected ?? '';
              });
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            borderRadius: BorderRadius.circular(18),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: () async {
              setState(() {
                editingField = null;
                showSaveReset = isChanged;
              });
            },
            tooltip: "Done",
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          leading: Icon(icon, color: Colors.blue[300]),
          title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          subtitle: Text(
            val.isEmpty ? 'NA' : val,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
            onPressed: () => _startEdit(fieldName),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        ),
      );
    }
  }

  /// --- Editable, curved TextField for all (phone with its own logic)
  Widget _buildEditableTextField({
    required String label,
    required String fieldName,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final val = (leadData?[fieldName] ?? '').toString();
    final isEditing = editingField == fieldName;
    final controller = _controllers[fieldName] ?? TextEditingController(text: val);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[300]),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        subtitle: isEditing
            ? Focus(
          onFocusChange: (hasFocus) async {
            if (!hasFocus) await _finishEdit(fieldName);
          },
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: keyboardType,
            onEditingComplete: () async => await _finishEdit(fieldName),
            onSubmitted: (_) async => await _finishEdit(fieldName),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        )
            : Text(val.isEmpty ? 'NA' : val,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: isEditing
            ? IconButton(
          icon: const Icon(Icons.check, color: Colors.blue),
          onPressed: () async => await _finishEdit(fieldName),
          tooltip: "Done",
        )
            : IconButton(
          icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
          onPressed: () => _startEdit(fieldName),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      ),
    );
  }

  Widget _buildReadonlyRow({
    required String label,
    required String? value,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[300]),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        subtitle: Text(value ?? 'NA',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_leadJustUpdated) {
          Navigator.pop(context, {'updated': true});
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lead Details', style: TextStyle(color: Colors.blue)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.blue),
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _leadFuture,
              builder: (context, snapshot) {
                if ((snapshot.connectionState == ConnectionState.waiting && leadData == null)) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lead = leadData ?? snapshot.data;
                if (lead == null || lead.isEmpty) {
                  return const Center(child: Text('Lead not found.'));
                }
                final name = lead['name'] ?? '[No Name]';
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                _getInitials(name),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 30),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: editingField == 'name'
                                        ? Focus(
                                      onFocusChange: (hasFocus) async {
                                        if (!hasFocus) await _finishEdit('name');
                                      },
                                      child: TextField(
                                        controller: _controllers['name'],
                                        autofocus: true,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 26,
                                            color: Colors.black87),
                                        onEditingComplete: () async => await _finishEdit('name'),
                                        onSubmitted: (_) async => await _finishEdit('name'),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            borderSide: const BorderSide(color: Colors.blueAccent),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                                          ),
                                        ),
                                      ),
                                    )
                                        : Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 26,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  editingField == 'name'
                                      ? IconButton(
                                    icon: const Icon(Icons.check, color: Colors.blue),
                                    onPressed: () async => await _finishEdit('name'),
                                  )
                                      : IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.grey),
                                    onPressed: () => _startEdit('name'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 4, thickness: 1, indent: 25, endIndent: 25),
                      const SizedBox(height: 10),
                      _buildEditableTextField(
                        label: 'Phone',
                        fieldName: 'phone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildEditableTextField(
                        label: 'Email',
                        fieldName: 'email',
                        icon: Icons.email,
                      ),
                      _buildEditablePicklist(
                        label: 'Status',
                        fieldName: 'status',
                        options: statusOptions,
                        icon: Icons.flag,
                      ),
                      _buildEditablePicklist(
                        label: 'Source',
                        fieldName: 'source',
                        options: sourceOptions,
                        icon: Icons.link,
                      ),
                      _buildReadonlyRow(
                        label: 'Created Date',
                        value: _formatDateTimeIST(lead['created_at']),
                        icon: Icons.calendar_today,
                      ),
                      _buildReadonlyRow(
                        label: 'Last Modified Date',
                        value: _formatDateTimeIST(lead['updated_at']),
                        icon: Icons.update,
                      ),
                      if (showSaveReset && isChanged)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  child: const Text('Save'),
                                ),
                              ),
                              const SizedBox(width: 30),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _resetChanges,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.blue),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  child: const Text('Reset',
                                      style: TextStyle(color: Colors.blue)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (showNotification && notificationMessage != null)
              _notificationWidget(),
          ],
        ),
      ),
    );
  }
}
