import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';

class VehicleCreateScreen extends StatefulWidget {
  const VehicleCreateScreen({super.key});

  @override
  State<VehicleCreateScreen> createState() => _VehicleCreateScreenState();
}

class _VehicleCreateScreenState extends State<VehicleCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _regCtrl = TextEditingController();
  final TextEditingController _makeCtrl = TextEditingController();
  final TextEditingController _capacityCtrl = TextEditingController();

  late FocusNode _companyFocus;
  late FocusNode _ownerDriverFocus;
  late FocusNode _assignedDriverFocus;
  late FocusNode _statusFocus;

  List<Map<String, dynamic>> _companies = [];
  dynamic _selectedCompanyId;
  List<Map<String, dynamic>> _drivers = [];
  dynamic _selectedOwnerDriverId;
  dynamic _selectedAssignedDriverId;

  final List<String> _statusOptions = ['Available', 'Booked'];
  String? _status;

  bool _isSaving = false;
  String? _notifMsg;
  Color _notifColor = Colors.red;
  bool _showNotif = false;

  @override
  void initState() {
    super.initState();
    _companyFocus = FocusNode();
    _ownerDriverFocus = FocusNode();
    _assignedDriverFocus = FocusNode();
    _statusFocus = FocusNode();
    _fetchCompanyPicklist();
    _fetchDriverPicklist();
    _status = _statusOptions.first;
  }

  @override
  void dispose() {
    _companyFocus.dispose();
    _ownerDriverFocus.dispose();
    _assignedDriverFocus.dispose();
    _statusFocus.dispose();

    _companyNameCtrl.dispose();
    _nameCtrl.dispose();
    _regCtrl.dispose();
    _makeCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCompanyPicklist() async {
    try {
      final companies = await ApiService().getCompanypicklist();
      setState(() {
        _companies = companies;
        _selectedCompanyId = _companies.isNotEmpty ? _companies.first['id'] : null;
      });
    } catch (e) {
      _showNotification('Failed to load companies: $e');
      setState(() {
        _companies = [];
        _selectedCompanyId = null;
      });
    }
  }

  Future<void> _fetchDriverPicklist() async {
    try {
      final drivers = await ApiService().getDriverpicklist();
      setState(() {
        _drivers = drivers;
        _selectedOwnerDriverId = null;
        _selectedAssignedDriverId =  null;
      });
    } catch (e) {
      _showNotification('Failed to load drivers: $e');
      setState(() {
        _drivers = [];
        _selectedOwnerDriverId = null;
        _selectedAssignedDriverId = null;
      });
    }
  }

  void _showNotification(String message, {Color color = Colors.red}) {
    setState(() {
      _notifMsg = message;
      _notifColor = color;
      _showNotif = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showNotif = false);
    });
  }

  String? _validateRequired(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label required';
    return null;
  }

  String? _validateCapacity(String? val) {
    if (val == null || val.trim().isEmpty) return "Capacity is required";
    final parsed = int.tryParse(val.trim());
    if (parsed == null || parsed <= 0) return "Enter valid capacity";
    return null;
  }

  String? _validateReg(String? val) {
    if (val == null || val.trim().isEmpty) return "Registration number required";
    if (val.trim().length < 5) return "Enter valid registration number";
    return null;
  }

  InputDecoration _fieldDecoration(String label, IconData icon, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      helperText: helperText,
      prefixIcon: Icon(icon, color: Colors.black54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      filled: true,
      fillColor: Colors.white,
    );
  }

  InputDecoration _picklistDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCompanyId == null) {
      _showNotification('Please select a company.', color: Colors.red);
      return;
    }
    if (_selectedOwnerDriverId == null) {
      _showNotification('Please select an owner driver.', color: Colors.red);
      return;
    }
    if (_selectedAssignedDriverId == null) {
      _showNotification('Please select an assigned driver.', color: Colors.red);
      return;
    }
    if (_status == null) {
      _showNotification('Please select a status.', color: Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final formData = {
        "company": _companyNameCtrl.text.trim(),           // free-text vehicle company
        "name": _nameCtrl.text.trim(),
        "company_id": _selectedCompanyId,                  // picklist company id
        "registration_number": _regCtrl.text.trim(),
        "make": _makeCtrl.text.trim(),
        "owner_driver_id": _selectedOwnerDriverId,
        "assigned_driver_id": _selectedAssignedDriverId,
        "capacity": int.tryParse(_capacityCtrl.text.trim()) ?? 0,
        "available_status": _status!,
      };

      final vehicleId = await ApiService().createVehicle(formData);
      if (!mounted) return;
      Navigator.of(context).pop({"success": true, "id": vehicleId});
    } catch (e) {
      _showNotification(e.toString(), color: Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add Vehicle", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _isSaving,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Form(
                key: _formKey,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      children: [
                        DropdownButtonFormField<dynamic>(
                          value: _selectedCompanyId,
                          isExpanded: true,
                          focusNode: _companyFocus,
                          decoration: _picklistDecoration('Company (picklist)', _companyFocus).copyWith(
                            prefixIcon: const Icon(Icons.business, color: Colors.black54),
                          ),
                          hint: const Text('Select Company',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                          items: _companies
                              .map((c) => DropdownMenuItem(
                            value: c['id'],
                            child: Text(
                              (c['name'] ?? '').toString(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ))
                              .toList(),
                          onChanged: _companies.isEmpty
                              ? null
                              : (val) {
                            setState(() {
                              _selectedCompanyId = val;
                            });
                          },
                          validator: (val) {
                            if (_companies.isEmpty) return "Please wait, try again";
                            if (val == null) return 'Please select a company';
                            return null;
                          },
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                          borderRadius: BorderRadius.circular(14),
                          dropdownColor: Colors.white,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _companyNameCtrl,
                          decoration: _fieldDecoration("Vehicle Company", Icons.apartment),
                          style: const TextStyle(color: Colors.black),
                          textInputAction: TextInputAction.next,
                          validator: (v) => _validateRequired(v, "Vehicle company"),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _nameCtrl,
                          decoration: _fieldDecoration("Vehicle Name", Icons.directions_car),
                          style: const TextStyle(color: Colors.black),
                          textInputAction: TextInputAction.next,
                          validator: (v) => _validateRequired(v, "Vehicle name"),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _regCtrl,
                          decoration: _fieldDecoration("Registration Number", Icons.confirmation_number),
                          style: const TextStyle(color: Colors.black),
                          textInputAction: TextInputAction.next,
                          validator: _validateReg,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _makeCtrl,
                          decoration: _fieldDecoration("Make (Year/Model)", Icons.factory),
                          style: const TextStyle(color: Colors.black),
                          textInputAction: TextInputAction.next,
                          validator: (v) => _validateRequired(v, "Vehicle make"),
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<dynamic>(
                          value: _selectedOwnerDriverId,
                          isExpanded: true,
                          focusNode: _ownerDriverFocus,
                          decoration: _picklistDecoration('Owner Driver', _ownerDriverFocus).copyWith(
                            prefixIcon: const Icon(Icons.person, color: Colors.black54),
                          ),
                          hint: const Text('Select Owner Driver',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                          items: _drivers
                              .map((d) => DropdownMenuItem(
                            value: d['id'],
                            child: Text(
                              (d['name'] ?? '').toString(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ))
                              .toList(),
                          onChanged: _drivers.isEmpty
                              ? null
                              : (val) {
                            setState(() {
                              _selectedOwnerDriverId = val;
                            });
                          },
                          validator: (val) {
                            if (_drivers.isEmpty) return "Please wait, try again";
                            if (val == null) return 'Please select an owner driver';
                            return null;
                          },
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                          borderRadius: BorderRadius.circular(14),
                          dropdownColor: Colors.white,
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<dynamic>(
                          value: _selectedAssignedDriverId,
                          isExpanded: true,
                          focusNode: _assignedDriverFocus,
                          decoration: _picklistDecoration('Assigned Driver', _assignedDriverFocus).copyWith(
                            prefixIcon: const Icon(Icons.person, color: Colors.black54),
                          ),
                          hint: const Text('Select Assigned Driver',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                          items: _drivers
                              .map((d) => DropdownMenuItem(
                            value: d['id'],
                            child: Text(
                              (d['name'] ?? '').toString(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ))
                              .toList(),
                          onChanged: _drivers.isEmpty
                              ? null
                              : (val) {
                            setState(() {
                              _selectedAssignedDriverId = val;
                            });
                          },
                          validator: (val) {
                            if (_drivers.isEmpty) return "Please wait, try again";
                            if (val == null) return 'Please select an assigned driver';
                            return null;
                          },
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                          borderRadius: BorderRadius.circular(14),
                          dropdownColor: Colors.white,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _capacityCtrl,
                          decoration: _fieldDecoration("Capacity", Icons.people),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: _validateCapacity,
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          value: _status,
                          isExpanded: true,
                          focusNode: _statusFocus,
                          decoration: _picklistDecoration('Status', _statusFocus).copyWith(
                            prefixIcon: const Icon(Icons.flag, color: Colors.black54),
                          ),
                          hint: const Text('Select Status',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                          items: _statusOptions
                              .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _status = val;
                            });
                            FocusScope.of(context).unfocus();
                          },
                          validator: (val) => val == null ? 'Status required' : null,
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                          borderRadius: BorderRadius.circular(14),
                          dropdownColor: Colors.white,
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveVehicle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSaving
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : const Text('Save Vehicle'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_showNotif && _notifMsg != null)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) => setState(() => _showNotif = false),
                child: InAppNotification(
                  message: _notifMsg!,
                  color: _notifColor,
                  onClose: () => setState(() => _showNotif = false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
