import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'package:flutter/cupertino.dart';
import 'driver_detail_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final dynamic vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Future<Map<String, dynamic>?> _vehicleFuture;
  Map<String, dynamic>? vehicleData;
  Map<String, dynamic>? initialData;

  String? editingField;
  final Map<String, TextEditingController> _controllers = {};

  String? notificationMessage;
  bool showNotification = false;
  Color notificationColor = Colors.blue;
  bool showSaveReset = false;
  bool _isSaving = false;
  bool _hasSavedAnyChange = false;

  final List<String> statusOptions = ["Available", "Booked"];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _drivers = [];
  int? _selectedCompanyId;
  int? _selectedOwnerDriverId;
  int? _selectedAssignedDriverId;

  @override
  void initState() {
    super.initState();
    _vehicleFuture = _fetchVehicle();
    _fetchCompanyPicklist();
    _fetchDriverPicklist();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchVehicle() async {
    final data = await ApiService().getVehicleById(widget.vehicleId);
    setState(() {
      vehicleData = {...data};
      initialData = {...data};
      _controllers.clear();
      for (final key in [
        'name',
        'company',
        'registration_number',
        'make',
        'capacity',
      ]) {
        _controllers[key] = TextEditingController(text: data[key]?.toString() ?? '');
      }
      _selectedCompanyId = data['company_id'];
      _selectedOwnerDriverId = data['owner_driver_id'];
      _selectedAssignedDriverId = data['assigned_driver_id'];
    });
    return data;
  }

  Future<void> _fetchCompanyPicklist() async {
    final companies = await ApiService().getCompanypicklist();
    setState(() => _companies = companies);
  }

  Future<void> _fetchDriverPicklist() async {
    final drivers = await ApiService().getDriverpicklist();
    setState(() => _drivers = drivers);
  }

  String _getInitials(String? name, String? company) {
    final full = ('${company ?? ''} ${name ?? ''}').trim();
    if (full.isEmpty) return "";
    final parts = full.split(RegExp(r'\s+'));
    return parts.length == 1 ? parts[0][0].toUpperCase() : (parts[0][0] + parts.last[0]).toUpperCase();
  }

  String _formatDateTimeIST(String? utcString) {
    if (utcString == null || utcString.isEmpty) return 'NA';
    DateTime? utcDate = DateTime.tryParse(utcString);
    if (utcDate == null) return 'NA';
    final istDate = utcDate.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd/MM/yyyy, h:mm a').format(istDate);
  }

  bool get isChanged {
    if (vehicleData == null || initialData == null) return false;
    for (final key in [
      'name',
      'company',
      'registration_number',
      'make',
      'capacity',
      'available_status',
      'company_id',
      'owner_driver_id',
      'assigned_driver_id',
    ]) {
      if ((vehicleData![key]?.toString().trim() ?? '') !=
          (initialData![key]?.toString().trim() ?? '')) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> get updatedFields {
    final updated = <String, dynamic>{};
    if (vehicleData == null || initialData == null) return updated;
    for (final key in [
      'name',
      'company',
      'registration_number',
      'make',
      'capacity',
      'available_status',
      'company_id',
      'owner_driver_id',
      'assigned_driver_id',
    ]) {
      if ((vehicleData![key]?.toString().trim() ?? '') !=
          (initialData![key]?.toString().trim() ?? '')) {
        updated[key] = vehicleData![key];
      }
    }
    return updated;
  }

  void _startEdit(String fieldName) {
    setState(() {
      _controllers[fieldName] ??= TextEditingController(text: vehicleData?[fieldName]?.toString() ?? '');
      _controllers[fieldName]!.text = vehicleData?[fieldName]?.toString() ?? '';
      editingField = fieldName;
    });
  }

  Future<void> _finishEdit(String fieldName) async {
    final rawValue = _controllers[fieldName]?.text ?? '';
    final value = rawValue.trim();

    if (fieldName == 'capacity') {
      if (value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) {
        _showNotification("Capacity must be a positive number.", color: Colors.red);
        _controllers['capacity']?.text = initialData?['capacity']?.toString() ?? '';
        setState(() {
          editingField = null;
          vehicleData?['capacity'] = initialData?['capacity']?.toString() ?? '';
          showSaveReset = false;
        });
        return;
      }
      vehicleData?['capacity'] = int.tryParse(value) ?? 0;
    } else {
      if (["name", "company", "registration_number", "make"].contains(fieldName) && value.isEmpty) {
        _showNotification("$fieldName cannot be empty.", color: Colors.red);
        _controllers[fieldName]?.text = initialData?[fieldName]?.toString() ?? '';
        setState(() {
          editingField = null;
          vehicleData?[fieldName] = initialData?[fieldName]?.toString() ?? '';
          showSaveReset = false;
        });
        return;
      }
      vehicleData?[fieldName] = value;
    }

    setState(() {
      editingField = null;
      showSaveReset = isChanged;
    });
  }

  void _resetChanges() {
    setState(() {
      if (initialData == null) return;
      vehicleData = {...initialData!};
      for (var key in [
        'name',
        'company',
        'registration_number',
        'make',
        'capacity',
      ]) {
        _controllers[key]?.text = initialData?[key]?.toString() ?? '';
      }
      _selectedCompanyId = initialData?['company_id'];
      _selectedOwnerDriverId = initialData?['owner_driver_id'];
      _selectedAssignedDriverId = initialData?['assigned_driver_id'];
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

  Future<bool> _saveChanges({bool andPop = false}) async {
    setState(() { _isSaving = true; });
    final updated = updatedFields;
    if (updated.isEmpty) {
      _showNotification("No changes to save.", color: Colors.red);
      setState(() { _isSaving = false; }); return false;
    }
    for (final f in ['name', 'company', 'registration_number', 'make']) {
      if ((vehicleData?[f]?.toString().trim() ?? '').isEmpty) {
        _showNotification("${f.replaceAll('_', ' ').toUpperCase()} is required.", color: Colors.red);
        setState(() { _isSaving = false; }); return false;
      }
    }
    if (vehicleData?['capacity'] == null ||
        int.tryParse(vehicleData?['capacity'].toString() ?? '') == null ||
        int.parse(vehicleData?['capacity'].toString() ?? '0') <= 0) {
      _showNotification("Capacity is required and must be > 0.", color: Colors.red);
      setState(() { _isSaving = false; }); return false;
    }
    if (vehicleData?['company_id'] == null) {
      _showNotification("Picklist company is required.", color: Colors.red);
      setState(() { _isSaving = false; }); return false;
    }
    if (vehicleData?['owner_driver_id'] == null) {
      _showNotification("Owner driver is required.", color: Colors.red);
      setState(() { _isSaving = false; }); return false;
    }
    if (vehicleData?['assigned_driver_id'] == null) {
      _showNotification("Assigned driver is required.", color: Colors.red);
      setState(() { _isSaving = false; }); return false;
    }
    if ((vehicleData?['available_status'] ?? '').toString().isEmpty) {
      _showNotification("Status is required.", color: Colors.red);
      setState(() { _isSaving = false; }); return false;
    }

    try {
      final result = await ApiService().updateVehicle(widget.vehicleId, updated);
      final fresh = await ApiService().getVehicleById(widget.vehicleId);
      setState(() {
        notificationMessage = result['message'] ?? "Vehicle updated!";
        notificationColor = Colors.green;
        showNotification = true;
        vehicleData = {...fresh};
        initialData = {...fresh};
        for (final key in [
          'name',
          'company',
          'registration_number',
          'make',
          'capacity',
        ]) {
          _controllers[key]?.text = vehicleData?[key]?.toString() ?? '';
        }
        _selectedCompanyId = vehicleData?['company_id'];
        _selectedOwnerDriverId = vehicleData?['owner_driver_id'];
        _selectedAssignedDriverId = vehicleData?['assigned_driver_id'];
        showSaveReset = false;
        _hasSavedAnyChange = true;
      });
      if (andPop && mounted) {
        Future.delayed(const Duration(milliseconds: 400),
                () => Navigator.of(context).pop({'updated': true}));
      }
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => showNotification = false);
      });
      return true;
    } catch (e) {
      setState(() {
        notificationMessage = e.toString();
        notificationColor = Colors.red;
        showNotification = true;
      });
      return false;
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  Future<bool> _maybeShowDiscardDialog() async {
    if (isChanged) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: const Text('Data has not been saved. Do you want to save changes?', style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      if (result == true) {
        await _saveChanges(andPop: true);
        return false;
      } else if (result == false) {
        Navigator.of(context).pop({'updated': _hasSavedAnyChange});
        return false;
      } else {
        return false;
      }
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    if (isChanged) {
      return await _maybeShowDiscardDialog();
    }
    if (_hasSavedAnyChange) {
      Navigator.of(context).pop({'updated': true});
      return false;
    }
    return true;
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

  // Helper: Only underline (not bold/blue/shadow), always clickable
  Widget _buildClickableLookupRow({
    required String label,
    required String? value,
    required int? id,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[300]),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        subtitle: id == null
            ? const Text('NA', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))
            : GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Text(
            value ?? '',
            style: const TextStyle(
              fontSize: 16,
              decoration: TextDecoration.underline,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
          onPressed: onTap != null
              ? () => setState(() => editingField = label == 'Owner Driver' ? 'owner_driver_id' : 'assigned_driver_id')
              : null,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      ),
    );
  }

  // Dropdown for editing owner/assigned driver (standard pattern)
  Widget _buildEditablePicklistId({
    required String label,
    required String fieldName,
    required IconData icon,
    required int? currentId,
    required List<Map<String, dynamic>> options,
    String displayKey = 'name',
  }) {
    final isEditing = editingField == fieldName;
    String currentLabel = '';
    if (currentId != null) {
      final found = options.firstWhere((o) => o['id'] == currentId, orElse: () => {});
      currentLabel = (found[displayKey] ?? '').toString();
    }

    // Owner/Assigned drivers: clickable-underlined label in view, dropdown in edit; Company: always dropdown
    final isDriverLookup = fieldName == 'owner_driver_id' || fieldName == 'assigned_driver_id';

    if (!isEditing && isDriverLookup) {
      return _buildClickableLookupRow(
        label: label,
        value: currentLabel,
        id: currentId,
        icon: icon,
        onTap: currentId == null
            ? null
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DriverDetailScreen(driverId: currentId),
            ),
          ).then((_) {
            setState(() {
              _vehicleFuture = _fetchVehicle();
              _fetchDriverPicklist();
            });
          });
        },
      );
    }

    // Dropdown/picklist for company/driver edit states
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[300]),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        subtitle: DropdownButtonFormField<int>(
          value: currentId,
          items: options
              .map((item) => DropdownMenuItem<int>(
            value: item['id'],
            child: Text(item[displayKey]?.toString() ?? ''),
          ))
              .toList(),
          onChanged: (selectedId) {
            setState(() {
              if (selectedId != null) {
                vehicleData?[fieldName] = selectedId;
                if (fieldName == "company_id") _selectedCompanyId = selectedId;
                if (fieldName == "owner_driver_id") _selectedOwnerDriverId = selectedId;
                if (fieldName == "assigned_driver_id") _selectedAssignedDriverId = selectedId;
                showSaveReset = isChanged;
              }
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
        trailing: isEditing
            ? IconButton(
          icon: const Icon(Icons.check, color: Colors.blue),
          onPressed: () => setState(() {
            editingField = null;
            showSaveReset = isChanged;
          }),
          tooltip: "Done",
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      ),
    );
  }

  Widget _buildEditablePicklistString({
    required String label,
    required String fieldName,
    required List<String> options,
    required IconData icon,
  }) {
    final val = (vehicleData?[fieldName] ?? '').toString();
    final isEditing = editingField == fieldName;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[300]),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        subtitle: isEditing
            ? DropdownButtonFormField<String>(
          value: options.contains(val) ? val : options.first,
          items: options.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (selected) {
            setState(() {
              vehicleData?[fieldName] = selected ?? options.first;
              showSaveReset = isChanged;
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
        )
            : Text(val.isEmpty ? 'NA' : val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: isEditing
            ? IconButton(
          icon: const Icon(Icons.check, color: Colors.blue),
          onPressed: () => setState(() {
            editingField = null;
            showSaveReset = isChanged;
          }),
          tooltip: "Done",
        )
            : IconButton(
          icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
          onPressed: () => setState(() => editingField = fieldName),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      ),
    );
  }

  Widget _buildEditableTextField({
    required String label,
    required String fieldName,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final val = (vehicleData?[fieldName] ?? '').toString();
    final isEditing = editingField == fieldName;
    final controller = _controllers[fieldName] ?? TextEditingController(text: val);

    return Card(
      color: Colors.white,
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
            : Text(val.isEmpty ? 'NA' : val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: isEditing
            ? IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: () async => await _finishEdit(fieldName),
            tooltip: "Done")
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
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[300]),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        subtitle: Text(value ?? 'NA', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _vehicleFuture,
            builder: (context, snapshot) {
              if ((snapshot.connectionState == ConnectionState.waiting && vehicleData == null)) {
                return const Center(child: CupertinoActivityIndicator(radius: 20, color: Color(0xFF007AFF)));
              }
              final v = vehicleData ?? snapshot.data;
              if (v == null || v.isEmpty) {
                return const Center(child: Text('Vehicle not found.'));
              }
              final name = v['name'] ?? '';
              final company = v['company'] ?? '';
              final fullTitle = (company.toString().trim().isNotEmpty
                  ? "${company.toString().trim()} "
                  : '') +
                  (name.toString().trim());

              return WillPopScope(
                onWillPop: _onWillPop,
                child: SingleChildScrollView(
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
                                _getInitials(name, company),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 30),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullTitle.isNotEmpty ? fullTitle : '[No Name]',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    v['registration_number'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
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
                        label: 'Vehicle Name',
                        fieldName: 'name',
                        icon: Icons.directions_car,
                      ),
                      _buildEditableTextField(
                        label: 'Vehicle Company',
                        fieldName: 'company',
                        icon: Icons.apartment,
                      ),
                      _buildEditableTextField(
                        label: 'Registration Number',
                        fieldName: 'registration_number',
                        icon: Icons.confirmation_number,
                      ),
                      _buildEditableTextField(
                        label: 'Make (Year/Model)',
                        fieldName: 'make',
                        icon: Icons.factory,
                      ),
                      editingField == 'company_id'
                          ? _buildEditablePicklistId(
                        label: 'Company (picklist)',
                        fieldName: 'company_id',
                        icon: Icons.business,
                        currentId: _selectedCompanyId,
                        options: _companies,
                      )
                          : Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: ListTile(
                          leading: Icon(Icons.business, color: Colors.blue[300]),
                          title: const Text('Company', style: TextStyle(fontSize: 14, color: Colors.black54)),
                          subtitle: Text(
                            _companies.firstWhere(
                                    (c) => c['id'] == _selectedCompanyId,
                                orElse: () => {'name': ''}
                            )['name'] ?? 'NA',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                            onPressed: () => setState(() => editingField = 'company_id'),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        ),
                      ),
                      _buildEditablePicklistId(
                        label: 'Owner Driver',
                        fieldName: 'owner_driver_id',
                        icon: Icons.person,
                        currentId: _selectedOwnerDriverId,
                        options: _drivers,
                      ),
                      _buildEditablePicklistId(
                        label: 'Assigned Driver',
                        fieldName: 'assigned_driver_id',
                        icon: Icons.person,
                        currentId: _selectedAssignedDriverId,
                        options: _drivers,
                      ),
                      _buildEditableTextField(
                        label: 'Capacity',
                        fieldName: 'capacity',
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                      ),
                      _buildEditablePicklistString(
                        label: 'Status',
                        fieldName: 'available_status',
                        options: statusOptions,
                        icon: Icons.flag,
                      ),
                      _buildReadonlyRow(
                        label: 'Created Date',
                        value: _formatDateTimeIST(v['created_at']),
                        icon: Icons.calendar_today,
                      ),
                      _buildReadonlyRow(
                        label: 'Last Modified Date',
                        value: _formatDateTimeIST(v['updated_at']),
                        icon: Icons.update,
                      ),
                      if (showSaveReset && isChanged)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : () async => await _saveChanges(andPop: false),
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
                                  onPressed: _isSaving ? null : _resetChanges,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.blue),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  child: const Text('Reset', style: TextStyle(color: Colors.blue)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (showNotification && notificationMessage != null)
            _notificationWidget(),
          if (_isSaving)
            const Opacity(
              opacity: 0.3,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          if (_isSaving)
            const Center(
              child: CupertinoActivityIndicator(radius: 20, color: Color(0xFF007AFF)),
            ),
        ],
      ),
    );
  }
}
