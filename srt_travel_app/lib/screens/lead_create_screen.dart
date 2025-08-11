import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateLeadScreen extends StatefulWidget {
  const CreateLeadScreen({super.key});
  @override
  State<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends State<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _status;
  String? _source;
  bool _loading = false;

  String? _errorBelowSave;

  final List<String> _statusOptions = [
    'New', 'Lost', 'Booked', 'Under Follow-up', 'Not Answered'
  ];
  final List<String> _sourceOptions = ['Website', 'Manual'];

  // FocusNodes for better field navigation
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _sourceFocus = FocusNode();
  final _statusFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _sourceFocus.dispose();
    _statusFocus.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
        fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
    filled: true,
    fillColor: Colors.grey[100],
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
  );

  InputDecoration _picklistDecoration(String label, FocusNode focus) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
        filled: true,
        fillColor: focus.hasFocus ? Colors.blue[50] : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  Future<void> _submitLead() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorBelowSave = null;
    });

    try {
      await ApiService().createLead({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'source': _source!,
        'status': _status!,
      });
      if (mounted) Navigator.pop(context, {"success": true});
    } catch (e) {
      String msg = e.toString().replaceAll("Exception: ", "");
      if (msg.contains("Duplicate")) {
        msg = "Lead already exists with this phone number!";
      }
      setState(() => _errorBelowSave = msg);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Create Lead'),
        iconTheme: const IconThemeData(color: Colors.blue),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 36),
                    padding: const EdgeInsets.all(22),
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Enter Lead Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 21,
                              color: Colors.black,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_phoneFocus),
                            style: const TextStyle(
                                color: Colors.black, fontWeight: FontWeight.w500),
                            decoration: _fieldDecoration('Name'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name required'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_emailFocus),
                            style: const TextStyle(
                                color: Colors.black, fontWeight: FontWeight.w500),
                            decoration: _fieldDecoration('Phone'),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Phone required'
                                : (RegExp(r"^[0-9+ -]{8,15}$").hasMatch(v)
                                ? null
                                : 'Enter valid phone'),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_sourceFocus),
                            style: const TextStyle(
                                color: Colors.black, fontWeight: FontWeight.w500),
                            keyboardType: TextInputType.emailAddress,
                            decoration: _fieldDecoration('Email'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Email required";
                              }
                              final emailRegex =
                              RegExp(r"^[^@]+@[^@]+\.[^@]+$");
                              if (!emailRegex.hasMatch(v.trim())) {
                                return "Enter valid email";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            value: _source,
                            focusNode: _sourceFocus,
                            decoration: _picklistDecoration('Source', _sourceFocus),
                            hint: const Text('Select Source', style: TextStyle(fontWeight: FontWeight.w500)),
                            items: _sourceOptions
                                .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _source = v);
                              FocusScope.of(context).requestFocus(_statusFocus);
                            },
                            validator: (v) => v == null ? 'Source required' : null,
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            value: _status,
                            focusNode: _statusFocus,
                            decoration: _picklistDecoration('Status', _statusFocus),
                            hint: const Text('Select Status', style: TextStyle(fontWeight: FontWeight.w500)),
                            items: _statusOptions
                                .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _status = v);
                              FocusScope.of(context).unfocus();
                            },
                            validator: (v) => v == null ? 'Status required' : null,
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.grey[200],
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            onPressed: _loading ? null : _submitLead,
                            child: _loading
                                ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    color: Colors.black))
                                : const Text('Save'),
                          ),
                          if (_errorBelowSave != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error,
                                      color: Colors.red, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _errorBelowSave!,
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
