import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'package:flutter/cupertino.dart';

class CompanyDetailsScreen extends StatefulWidget {
  final String username;
  final String email;
  final String userRole;
  final dynamic id;

  const CompanyDetailsScreen({
    super.key,
    required this.username,
    required this.email,
    required this.userRole,
    this.id,
  });

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  late Future<Map<String, dynamic>?> _companyFuture;
  Map<String, dynamic>? companyData;
  Map<String, dynamic>? initialData;

  String? editingField;
  final Map<String, TextEditingController> _controllers = {};
  bool showSaveReset = false;
  bool _isSaving = false;
  bool _hasSavedAnyChange = false;

  String? notificationMessage;
  bool showNotification = false;
  Color notificationColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _companyFuture = _fetchCompany();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // -- Pull-to-Refresh --
  Future<void> _refreshCompany() async {
    setState(() {
      editingField = null; // reset inline edits
      _companyFuture = _fetchCompany();
    });
    await _companyFuture;
  }

  // Fetch/initialize company data & controllers
  Future<Map<String, dynamic>?> _fetchCompany() async {
    final companies = await ApiService().getCompany();
    if (companies.isNotEmpty) {
      final data = {...companies[0]};
      setState(() {
        companyData = data;
        initialData = {...data};
        for (var key in [
          'name',
          'address',
          'email',
          'phone',
          'localcharge',
          'outstationcharge',
          'lumpsumcharge',
          'localdist',
          'outstationdistance'
        ]) {
          _controllers[key] = TextEditingController(text: data[key]?.toString() ?? '');
        }
      });
      return data;
    }
    return null;
  }

  bool get isChanged {
    if (companyData == null || initialData == null) return false;
    for (final key in [
      'name',
      'address',
      'email',
      'phone',
      'localcharge',
      'outstationcharge',
      'lumpsumcharge',
      'localdist',
      'outstationdistance'
    ]) {
      if ((companyData![key]?.toString() ?? '') != (initialData![key]?.toString() ?? '')) return true;
    }
    return false;
  }

  Map<String, dynamic> get updatedFields {
    final updated = <String, dynamic>{};
    if (companyData == null || initialData == null) return updated;
    for (final key in [
      'name',
      'address',
      'email',
      'phone',
      'localcharge',
      'outstationcharge',
      'lumpsumcharge',
      'localdist',
      'outstationdistance'
    ]) {
      if ((companyData![key]?.toString() ?? '') != (initialData![key]?.toString() ?? '')) {
        updated[key] = companyData![key];
      }
    }
    return updated;
  }

  void _startEdit(String fieldName) {
    setState(() {
      _controllers[fieldName] ??= TextEditingController(text: companyData?[fieldName]?.toString() ?? '');
      _controllers[fieldName]!.text = companyData?[fieldName]?.toString() ?? '';
      editingField = fieldName;
    });
  }

  Future<void> _finishEdit(String fieldName) async {
    final rawValue = _controllers[fieldName]?.text ?? '';
    final value = rawValue.trim();
    setState(() {
      companyData?[fieldName] = value;
      editingField = null;
      showSaveReset = isChanged;
    });
  }

  void _resetChanges() {
    setState(() {
      if (initialData == null) return;
      companyData = {...initialData!};
      for (var key in _controllers.keys) {
        _controllers[key]?.text = companyData?[key]?.toString() ?? '';
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

  Widget _buildEditableCard({
    required String label,
    required String fieldName,
    required IconData icon,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final val = (companyData?[fieldName] ?? '').toString();
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
              prefixText: prefix,
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
            : Text(
          (val.isEmpty ? 'NA' : (prefix != null ? '$prefix$val' : val)),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
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

  Widget _buildReadonlyCard({
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
        subtitle: Text(value == null || value.isEmpty ? 'NA' : value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      ),
    );
  }

  Future<bool> _saveChanges({bool andPop = false}) async {
    setState(() => _isSaving = true);

    final updated = updatedFields;
    bool allBlank = !updated.values.any((v) => v != null && v.toString().trim().isNotEmpty);

    if (allBlank) {
      _showNotification("Cannot update with all fields blank.", color: Colors.red);
      setState(() => _isSaving = false);
      return false;
    }

    try {
      final result = await ApiService().updateCompany(companyData?['id'], updated);
      final fresh = (await ApiService().getCompany()).first;
      setState(() {
        notificationMessage = result['message'] ?? "Company updated!";
        notificationColor = Colors.green;
        showNotification = true;
        companyData = {...fresh};
        initialData = {...fresh};
        for (var key in _controllers.keys) {
          _controllers[key]?.text = companyData?[key]?.toString() ?? '';
        }
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
      if (mounted) setState(() => _isSaving = false);
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Data has not been saved. Do you want to save changes?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (result == true) {
        // Save then pop on success
        await _saveChanges(andPop: true);
        return false; // pop will be handled by save
      } else if (result == false) {
        // Cancel was pressed - go back
        Navigator.of(context).pop({'updated': _hasSavedAnyChange});
        return false;
      } else {
        return false;
      }
    }
    if (_hasSavedAnyChange) {
      Navigator.of(context).pop({'updated': true});
      return false;
    }
    return true;
  }

  Future<bool> _onWillPop() async => await _maybeShowDiscardDialog();

  @override
  Widget build(BuildContext context) {
    final themeBg = const Color(0xFFF8FAFC);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Details', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      // Optional: add your drawer here if needed
      backgroundColor: themeBg,
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _companyFuture,
            builder: (context, snapshot) {
              if ((snapshot.connectionState == ConnectionState.waiting && companyData == null)) {
                return const Center(child: CupertinoActivityIndicator(radius: 20, color: Color(0xFF007AFF)));
              }
              final company = companyData ?? snapshot.data;
              if (company == null || company.isEmpty) {
                return const Center(child: Text('Company record not found.'));
              }
              final name = company['name'] ?? '[No Name]';

              // Pull-to-refresh enabled view
              return WillPopScope(
                onWillPop: _onWillPop,
                child: RefreshIndicator(
                  onRefresh: _refreshCompany,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 32, bottom: 8),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              _getInitials(name),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 34,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 12),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Make Name editable as a card AFTER name display
                        _buildEditableCard(
                          label: 'Company Name',
                          fieldName: 'name',
                          icon: Icons.business,
                        ),
                        const Divider(height: 4, thickness: 1, indent: 25, endIndent: 25),
                        const SizedBox(height: 10),
                        _buildEditableCard(
                          label: 'Address',
                          fieldName: 'address',
                          icon: Icons.location_on,
                        ),
                        _buildEditableCard(
                          label: 'Email',
                          fieldName: 'email',
                          icon: Icons.email,
                        ),
                        _buildEditableCard(
                          label: 'Phone',
                          fieldName: 'phone',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        _buildEditableCard(
                          label: 'Local Charge / km',
                          fieldName: 'localcharge',
                          icon: Icons.monetization_on,
                          prefix: '₹',
                          keyboardType: TextInputType.number,
                        ),
                        _buildEditableCard(
                          label: 'Outstation Charge / km',
                          fieldName: 'outstationcharge',
                          icon: Icons.directions_car,
                          prefix: '₹',
                          keyboardType: TextInputType.number,
                        ),
                        _buildEditableCard(
                          label: 'Lumpsum Charge',
                          fieldName: 'lumpsumcharge',
                          icon: Icons.attach_money,
                          prefix: '₹',
                          keyboardType: TextInputType.number,
                        ),
                        _buildEditableCard(
                          label: 'Local Distance Limit (km)',
                          fieldName: 'localdist',
                          icon: Icons.straighten,
                          keyboardType: TextInputType.number,
                        ),
                        _buildEditableCard(
                          label: 'Outstation Distance Limit (km)',
                          fieldName: 'outstationdistance',
                          icon: Icons.explore,
                          keyboardType: TextInputType.number,
                        ),
                        _buildReadonlyCard(
                          label: 'Created Date',
                          value: _formatDateTimeIST(company['created_at']),
                          icon: Icons.calendar_today,
                        ),
                        _buildReadonlyCard(
                          label: 'Last Modified Date',
                          value: _formatDateTimeIST(company['updated_at']),
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
                                    child: const Text('Reset',
                                        style: TextStyle(color: Colors.blue)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
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
