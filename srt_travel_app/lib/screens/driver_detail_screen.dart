import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'package:flutter/cupertino.dart';

class DriverDetailScreen extends StatefulWidget {
  final dynamic driverId;
  const DriverDetailScreen({super.key, required this.driverId});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  late Future<Map<String, dynamic>?> _driverFuture;
  Map<String, dynamic>? driverData;
  Map<String, dynamic>? initialData;

  String? editingField;
  final Map<String, TextEditingController> _controllers = {};

  String? notificationMessage;
  bool showNotification = false;
  Color notificationColor = Colors.blue;

  bool showSaveReset = false;
  bool _isSaving = false;
  bool _hasSavedAnyChange = false;

  final List<String> statusOptions = ["Available", "On Duty"];
  String? _phoneBeforeEdit, _licenseBeforeEdit, _aadharBeforeEdit;

  bool get isChanged {
    if (driverData == null || initialData == null) return false;
    for (final key in [
      'name',
      'phone',
      'email',
      'status',
      'license_number',
      'aadhar_card',
    ]) {
      if ((driverData![key]?.trim() ?? '') != (initialData![key]?.trim() ?? '')) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> get updatedFields {
    final updated = <String, dynamic>{};
    if (driverData == null || initialData == null) return updated;
    for (final key in [
      'name',
      'phone',
      'email',
      'status',
      'license_number',
      'aadhar_card'
    ]) {
      if ((driverData![key]?.trim() ?? '') != (initialData![key]?.trim() ?? '')) {
        updated[key] = driverData![key].toString().trim();
      }
    }
    return updated;
  }

  @override
  void initState() {
    super.initState();
    _driverFuture = _fetchDriver();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchDriver() async {
    final data = await ApiService().getDriverById(widget.driverId);
    setState(() {
      driverData = {...data};
      initialData = {...data};
      for (var key in [
        'name',
        'phone',
        'email',
        'license_number',
        'aadhar_card'
      ]) {
        _controllers[key] = TextEditingController(text: data[key]?.toString() ?? '');
      }
    });
    return data;
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

  void _startEdit(String fieldName) {
    setState(() {
      _controllers[fieldName] ??= TextEditingController(text: driverData?[fieldName]?.toString() ?? '');
      _controllers[fieldName]!.text = driverData?[fieldName]?.toString() ?? '';
      editingField = fieldName;
      if (fieldName == 'phone') _phoneBeforeEdit = driverData?['phone']?.toString() ?? '';
      if (fieldName == 'license_number') _licenseBeforeEdit = driverData?['license_number']?.toString() ?? '';
      if (fieldName == 'aadhar_card') _aadharBeforeEdit = driverData?['aadhar_card']?.toString() ?? '';
    });
  }

  Future<void> _finishEdit(String fieldName) async {
    final rawValue = _controllers[fieldName]?.text ?? '';
    final value = rawValue.trim();

    // PHONE validation
    if (fieldName == 'phone') {
      if (value != (_phoneBeforeEdit ?? '')) {
        if (value.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(value)) {
          _showNotification("Mobile must be a 10-digit number.", color: Colors.red);
          await Future.delayed(Duration(milliseconds: 200));
          _controllers['phone']?.text = _phoneBeforeEdit ?? '';
          setState(() {
            editingField = null;
            driverData?['phone'] = _phoneBeforeEdit ?? '';
            showSaveReset = false;
          });
          return;
        }
      }
    }
    // LICENSE validation (optional, but not empty string)
    if (fieldName == 'license_number') {
      if (value.isNotEmpty && value.length < 4) {
        _showNotification("License must be at least 4 characters.", color: Colors.red);
        await Future.delayed(Duration(milliseconds: 200));
        _controllers['license_number']?.text = _licenseBeforeEdit ?? '';
        setState(() {
          editingField = null;
          driverData?['license_number'] = _licenseBeforeEdit ?? '';
          showSaveReset = false;
        });
        return;
      }
    }
    // AADHAR validation (optional)
    if (fieldName == 'aadhar_card') {
      if (value.isNotEmpty && !RegExp(r'^\d{12}$').hasMatch(value)) {
        _showNotification("Aadhar must be a 12-digit number.", color: Colors.red);
        await Future.delayed(Duration(milliseconds: 200));
        _controllers['aadhar_card']?.text = _aadharBeforeEdit ?? '';
        setState(() {
          editingField = null;
          driverData?['aadhar_card'] = _aadharBeforeEdit ?? '';
          showSaveReset = false;
        });
        return;
      }
    }
    setState(() {
      driverData?[fieldName] = value;
      editingField = null;
      showSaveReset = isChanged;
    });
  }

  void _resetChanges() {
    setState(() {
      if (initialData == null) return;
      driverData = {...initialData!};
      for (var key in [
        'name',
        'phone',
        'email',
        'license_number',
        'aadhar_card'
      ]) {
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

  Future<bool> _saveChanges({bool andPop = false}) async {
    setState(() {_isSaving = true;});
    final updated = updatedFields;
    bool allBlank = !updated.values.any((v) => v != null && v.toString().trim().isNotEmpty);
    if (allBlank) {
      _showNotification("Cannot update with all fields blank.", color: Colors.red);
      setState(() {_isSaving = false;});
      return false;
    }
    if (updated.containsKey('phone')) {
      final phone = updated['phone']!.trim();
      if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
        _showNotification("Mobile must be exactly 10 digits.", color: Colors.red);
        _controllers['phone']?.text = initialData?['phone']?.toString() ?? '';
        driverData?['phone'] = initialData?['phone']?.toString() ?? '';
        setState(() {
          showSaveReset = false; _isSaving = false;
        });
        return false;
      }
    }
    if (updated.containsKey('license_number')) {
      final lic = updated['license_number']!.trim();
      if (lic.isNotEmpty && lic.length < 4) {
        _showNotification("License must be at least 4 characters.", color: Colors.red);
        _controllers['license_number']?.text = initialData?['license_number']?.toString() ?? '';
        driverData?['license_number'] = initialData?['license_number']?.toString() ?? '';
        setState(() {
          showSaveReset = false; _isSaving = false;
        });
        return false;
      }
    }
    if (updated.containsKey('aadhar_card')) {
      final aad = updated['aadhar_card']!.trim();
      if (aad.isNotEmpty && !RegExp(r'^\d{12}$').hasMatch(aad)) {
        _showNotification("Aadhar must be exactly 12 digits.", color: Colors.red);
        _controllers['aadhar_card']?.text = initialData?['aadhar_card']?.toString() ?? '';
        driverData?['aadhar_card'] = initialData?['aadhar_card']?.toString() ?? '';
        setState(() {
          showSaveReset = false; _isSaving = false;
        });
        return false;
      }
    }

    try {
      final result = await ApiService().updateDriver(widget.driverId, updated);
      // Fetch fresh details for update
      final fresh = await ApiService().getDriverById(widget.driverId);
      setState(() {
        notificationMessage = result['message'] ?? "Driver updated!";
        notificationColor = Colors.green;
        showNotification = true;
        driverData = {...fresh};
        initialData = {...fresh};
        for (var key in [
          'name',
          'phone',
          'email',
          'license_number',
          'aadhar_card'
        ]) {
          _controllers[key]?.text = driverData?[key] ?? '';
        }
        showSaveReset = false;
        _hasSavedAnyChange = true;
      });
      if (andPop && mounted) {
        Future.delayed(
            const Duration(milliseconds: 400),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Unsaved Changes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'Data has not been saved. Do you want to save changes?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
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

  Widget _buildEditablePicklist({
    required String label,
    required String fieldName,
    required List<String> options,
    required IconData icon,
  }) {
    final val = (driverData?[fieldName] ?? '').toString();
    if (editingField == fieldName) {
      return Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          leading: Icon(icon, color: Colors.blue[300]),
          title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          subtitle: DropdownButtonFormField<String>(
            value: options.contains(val) ? val : options.first,
            items: options.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (selected) {
              setState(() {
                driverData?[fieldName] = selected ?? options.first;
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
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          leading: Icon(icon, color: Colors.blue[300]),
          title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          subtitle: Text(val.isEmpty ? 'NA' : val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
            onPressed: () => _startEdit(fieldName),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        ),
      );
    }
  }

  Widget _buildEditableTextField({
    required String label,
    required String fieldName,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final val = (driverData?[fieldName] ?? '').toString();
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
            : Text(val.isEmpty ? 'NA' : val,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: isEditing
            ? IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: () async => await _finishEdit(fieldName),
            tooltip: "Done"
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
        title: const Text('Driver Details', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _driverFuture,
            builder: (context, snapshot) {
              if ((snapshot.connectionState == ConnectionState.waiting && driverData == null)) {
                return const Center(child: CupertinoActivityIndicator(radius: 20, color: Color(0xFF007AFF)));
              }
              final driver = driverData ?? snapshot.data;
              if (driver == null || driver.isEmpty) {
                return const Center(child: Text('Driver not found.'));
              }
              final name = driver['name'] ?? '[No Name]';
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
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildEditableTextField(
                        label: 'License Number',
                        fieldName: 'license_number',
                        icon: Icons.badge,
                      ),
                      _buildEditableTextField(
                        label: 'Aadhar Card',
                        fieldName: 'aadhar_card',
                        icon: Icons.credit_card,
                        keyboardType: TextInputType.number,
                      ),
                      _buildEditablePicklist(
                        label: 'Status',
                        fieldName: 'status',
                        options: statusOptions,
                        icon: Icons.flag,
                      ),
                      _buildReadonlyRow(
                        label: 'Created Date',
                        value: _formatDateTimeIST(driver['created_at']),
                        icon: Icons.calendar_today,
                      ),
                      _buildReadonlyRow(
                        label: 'Last Modified Date',
                        value: _formatDateTimeIST(driver['updated_at']),
                        icon: Icons.update,
                      ),
                      if (showSaveReset && isChanged)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async => await _saveChanges(andPop: false),
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
