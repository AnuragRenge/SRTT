import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';

class DriverCreateScreen extends StatefulWidget {
  const DriverCreateScreen({super.key});

  @override
  State<DriverCreateScreen> createState() => _DriverCreateScreenState();
}

class _DriverCreateScreenState extends State<DriverCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _licenseCtrl = TextEditingController();
  final TextEditingController _aadharCtrl = TextEditingController();

  late FocusNode _companyFocus;
  late FocusNode _statusFocus;

  List<Map<String, dynamic>> _companies = [];
  dynamic _selectedCompanyId;

  final List<String> _statusOptions = ['Available', 'On Duty'];
  String? _status;

  bool _isSaving = false;
  String? _notifMsg;
  Color _notifColor = Colors.red;
  bool _showNotif = false;

  @override
  void initState() {
    super.initState();
    _companyFocus = FocusNode();
    _statusFocus = FocusNode();
    _fetchCompanies();
    _status = _statusOptions.first;
  }

  @override
  void dispose() {
    _companyFocus.dispose();
    _statusFocus.dispose();

    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _aadharCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCompanies() async {
    try {
      final companies = await ApiService().getCompanypicklist();
      setState(() {
        _companies = companies;
        if (_companies.any((c) => c['id'] == 1)) {
          _selectedCompanyId = 1;
        } else if (_companies.isNotEmpty) {
          _selectedCompanyId = _companies.first['id'];
        } else {
          _selectedCompanyId = null;
        }
      });
    } catch (e) {
      _showNotification('Failed to load companies: $e');
      setState(() {
        _companies = [];
        _selectedCompanyId = null;
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
      if (mounted) {
        setState(() {
          _showNotif = false;
        });
      }
    });
  }

  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompanyId == null) {
      _showNotification('Please select a company.', color: Colors.red);
      return;
    }
    if (_status == null) {
      _showNotification('Please select a status.', color: Colors.red);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final formData = {
        "name": _nameCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "phone": _phoneCtrl.text.trim(),
        "license_number": _licenseCtrl.text.trim(),
        "aadhar_card": _aadharCtrl.text.trim(),
        "status": _status!,
        "company_id": _selectedCompanyId,
      };
      final driverId = await ApiService().createDriver(formData);
      Navigator.of(context).pop({"success": true, "id": driverId});
    } catch (e) {
      _showNotification(e.toString(), color: Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) return "Phone is required";
    if (!RegExp(r'^\d{10}$').hasMatch(val.trim())) return "Enter valid 10-digit number";
    return null;
  }

  String? _validateAadhar(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    if (!RegExp(r'^\d{12}$').hasMatch(val.trim())) return "Must be 12-digit Aadhar";
    return null;
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Driver", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _isSaving,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 55),
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
                          decoration: _picklistDecoration('Company', _companyFocus).copyWith(
                            prefixIcon: const Icon(Icons.business, color: Colors.black54),
                          ),
                          hint: const Text('Select Company',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                          items: _companies
                              .map(
                                (c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text(
                                (c['name'] ?? '').toString(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                              ),
                            ),
                          )
                              .toList(),
                          onChanged: _companies.isEmpty
                              ? null
                              : (val) {
                            setState(() {
                              _selectedCompanyId = val;
                            });
                            FocusScope.of(context).requestFocus(_statusFocus);
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
                          controller: _nameCtrl,
                          decoration: _fieldDecoration("Driver Name", Icons.person),
                          style: const TextStyle(color: Colors.black),
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                          v == null || v.trim().isEmpty ? "Name required" : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: _fieldDecoration("Mobile Number", Icons.phone),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: _fieldDecoration("Email", Icons.email),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _licenseCtrl,
                          decoration: _fieldDecoration("License Number", Icons.badge),
                          style: const TextStyle(color: Colors.black),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _aadharCtrl,
                          decoration: _fieldDecoration("Aadhar Card Number", Icons.credit_card)
                              .copyWith(helperText: "12-digit optional"),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: _validateAadhar,
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
                            child: Text(s,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black)),
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
                            onPressed: _isSaving ? null : _saveDriver,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              foregroundColor: Colors.white,
                              textStyle:
                              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSaving
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : const Text('Create Driver'),
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
