import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'package:flutter/cupertino.dart';

class UserDetailScreen extends StatefulWidget {
  final int id;
  const UserDetailScreen({super.key, required this.id});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Future<Map<String, dynamic>?> _userFuture;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? initialData;

  String? editingField;
  final Map<String, TextEditingController> _controllers = {};
  final List<String> roleOptions = ['admin', 'agent'];

  String? notificationMessage;
  Color notificationColor = Colors.blue;
  bool showNotification = false;

  List<Map<String, dynamic>> _allOtherUsers = [];
  String? _mobileBeforeEdit;
  bool isEditingActive = false;
  bool showSaveReset = false;
  bool hasChangedAfterCheck = false;

  bool _hasSavedAnyChange = false; // <-- New: Track saved state for parent refresh

  // --- Change detection logic
  bool get isChanged {
    if (userData == null || initialData == null) return false;
    for (final key in ['username', 'email', 'mobile', 'role', 'is_active']) {
      if ((userData![key]?.toString().trim() ?? '') !=
          (initialData![key]?.toString().trim() ?? '')) return true;
    }
    return false;
  }

  Map<String, dynamic> get updatedFields {
    final updated = <String, dynamic>{};
    if (userData == null || initialData == null) return updated;
    for (final key in ['username', 'email', 'mobile', 'role', 'is_active']) {
      if ((userData![key]?.toString().trim() ?? '') !=
          (initialData![key]?.toString().trim() ?? '')) {
        updated[key] = userData![key];
      }
    }
    return updated;
  }

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUser();
    _fetchAllOtherUsers();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length == 1
        ? parts[0][0].toUpperCase()
        : (parts[0][0] + parts.last[0]).toUpperCase();
  }

  String _formatDateIST(String? utc) {
    if (utc == null || utc.isEmpty) return 'NA';
    final date = DateTime.tryParse(utc)?.toUtc();
    if (date == null) return 'NA';
    final ist = date.add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd/MM/yyyy, h:mm a').format(ist);
  }

  Future<Map<String, dynamic>?> _fetchUser() async {
    final data = await ApiService().getUserById(widget.id);
    if (mounted) {
      setState(() {
        userData = {...data};
        initialData = {...data};
        for (final key in ['username', 'email', 'mobile']) {
          _controllers[key] = TextEditingController(text: data[key]?.toString() ?? '');
        }
      });
    }
    return data;
  }

  Future<void> _fetchAllOtherUsers() async {
    final users = await ApiService().getUsers();
    _allOtherUsers = users.where((u) => u['id'].toString() != widget.id.toString()).toList();
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

  void _startEdit(String fieldName) {
    setState(() {
      _controllers[fieldName] ??= TextEditingController(
        text: userData?[fieldName]?.toString() ?? '',
      );
      _controllers[fieldName]!.text = userData?[fieldName]?.toString() ?? '';
      editingField = fieldName;
      isEditingActive = false;
    });
    if (fieldName == 'mobile') {
      _mobileBeforeEdit = userData?['mobile']?.toString() ?? '';
    }
  }

  Future<void> _finishEdit(String fieldName) async {
    final rawValue = _controllers[fieldName]?.text ?? '';
    final value = rawValue.trim();

    if (fieldName == 'mobile') {
      if (value != (_mobileBeforeEdit ?? '')) {
        if (value.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(value)) {
          _showNotification("Mobile must be a 10-digit number.", color: Colors.red);
          Future.delayed(const Duration(milliseconds: 200), () {
            _controllers['mobile']?.text = _mobileBeforeEdit ?? '';
            setState(() {
              editingField = null;
              userData?['mobile'] = _mobileBeforeEdit ?? '';
              showSaveReset = false;
            });
          });
          return;
        }
        await _fetchAllOtherUsers();
        if (value.isNotEmpty &&
            _allOtherUsers.any((u) => (u['mobile'] ?? '').toString().trim() == value)) {
          _showNotification("This mobile already exists for another user.", color: Colors.red);
          Future.delayed(const Duration(milliseconds: 200), () {
            _controllers['mobile']?.text = _mobileBeforeEdit ?? '';
            setState(() {
              editingField = null;
              userData?['mobile'] = _mobileBeforeEdit ?? '';
              showSaveReset = false;
            });
          });
          return;
        }
      }
    }

    setState(() {
      userData?[fieldName] = value;
      editingField = null;
      hasChangedAfterCheck = isChanged;  // Save/Reset only after edit is committed
      showSaveReset = hasChangedAfterCheck;
    });
  }

  void _resetChanges() {
    setState(() {
      if (initialData == null) return;
      userData = {...initialData!};
      for (final key in ['username', 'mobile', 'email']) {
        _controllers[key]?.text = initialData?[key]?.toString() ?? '';
      }
      editingField = null;
      isEditingActive = false;
      showSaveReset = false;
      hasChangedAfterCheck = false;
    });
  }

  // --- Save logic (for Save Button and for Save in dialog). Set "_hasSavedAnyChange" flag!
  Future<bool> _saveChanges({bool andPop = false}) async {
    final updated = updatedFields;
    if (updated.isEmpty) {
      _showNotification("No changes to save.", color: Colors.red);
      return false;
    }
    if (updated.containsKey('mobile')) {
      final mobile = updated['mobile']!.trim();
      if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
        _showNotification("Mobile must be exactly 10 digits.", color: Colors.red);
        _controllers['mobile']?.text = initialData?['mobile']?.toString() ?? '';
        userData?['mobile'] = initialData?['mobile']?.toString() ?? '';
        setState(() {
          showSaveReset = false;
          hasChangedAfterCheck = false;
        });
        return false;
      }
      await _fetchAllOtherUsers();
      if (_allOtherUsers.any(
              (u) => (u['mobile'] ?? '').toString().trim() == mobile)) {
        _showNotification("Another user already exists with this mobile.", color: Colors.red);
        _controllers['mobile']?.text = initialData?['mobile']?.toString() ?? '';
        userData?['mobile'] = initialData?['mobile']?.toString() ?? '';
        setState(() {
          showSaveReset = false;
          hasChangedAfterCheck = false;
        });
        return false;
      }
    }

    try {
      final result = await ApiService().updateUser(widget.id, updated);
      final fresh = await ApiService().getUserById(widget.id);
      setState(() {
        notificationMessage = result['message'] ?? "User updated!";
        notificationColor = Colors.green;
        showNotification = true;
        userData = {...fresh};
        initialData = {...fresh};
        for (final key in ['username', 'mobile', 'email']) {
          _controllers[key]?.text = userData?[key]?.toString() ?? '';
        }
        showSaveReset = false;
        hasChangedAfterCheck = false;
        editingField = null;
        isEditingActive = false;
        _hasSavedAnyChange = true; // <-- PATCH: set this!
      });
      // On Save in dialog, pop and notify parent immediately
      if (andPop && mounted) {
        Future.delayed(const Duration(milliseconds: 400),
                () => Navigator.of(context).pop({'updated': true}));
      }
      return true;
    } catch (e) {
      setState(() {
        notificationMessage = e.toString();
        notificationColor = Colors.red;
        showNotification = true;
      });
      return false;
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

  Widget _buildEditableTextField({
    required String label,
    required String fieldName,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final val = (userData?[fieldName] ?? '').toString();
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

  Widget _buildEditableRolePicklist() {
    final val = (userData?['role'] ?? '').toString();
    if (editingField == 'role') {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          leading: Icon(Icons.verified_user, color: Colors.blue[300]),
          title: const Text('Role', style: TextStyle(fontSize: 14, color: Colors.black54)),
          subtitle: DropdownButtonFormField<String>(
            value: roleOptions.contains(val) ? val : roleOptions.first,
            items: roleOptions
                .map((role) => DropdownMenuItem(
              value: role,
              child: Text(
                role[0].toUpperCase() + role.substring(1),
                style: TextStyle(
                  color: role == 'admin' ? Colors.blue : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ))
                .toList(),
            onChanged: (selected) {
              setState(() {
                userData?['role'] = selected ?? roleOptions.first;
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
            onPressed: () {
              setState(() {
                editingField = null;
                hasChangedAfterCheck = isChanged;
                showSaveReset = hasChangedAfterCheck;
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
          leading: Icon(Icons.verified_user, color: Colors.blue[300]),
          title: const Text('Role', style: TextStyle(fontSize: 14, color: Colors.black54)),
          subtitle: Text(
            val.isEmpty ? 'NA' : val[0].toUpperCase() + val.substring(1),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: val == 'admin'
                  ? Colors.blueAccent
                  : (val == 'agent' ? Colors.green : Colors.grey),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
            onPressed: () => _startEdit('role'),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        ),
      );
    }
  }

  /// Checkbox for is_active (editable only with pencil/check icon)
  Widget _buildActiveCheckbox() {
    int isActive = 0;
    final dynamic isActiveRaw = userData?['is_active'];
    if (isActiveRaw is bool) {
      isActive = isActiveRaw ? 1 : 0;
    } else if (isActiveRaw is int) {
      isActive = isActiveRaw;
    }
    final statusText = isActive == 1 ? "Active" : "Inactive";

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: const Icon(Icons.toggle_on, color: Colors.blue),
        title: const Text('Active User', style: TextStyle(fontSize: 15, color: Colors.black54)),
        subtitle: Row(
          children: [
            Checkbox(
              value: isActive == 1,
              onChanged: isEditingActive
                  ? (value) {
                setState(() {
                  userData?['is_active'] = value == true ? 1 : 0;
                  hasChangedAfterCheck = isChanged;
                  showSaveReset = hasChangedAfterCheck;
                });
              }
                  : null,
            ),
            Text(
              statusText,
              style: TextStyle(
                color: isActive == 1 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            IconButton(
              icon: Icon(
                isEditingActive ? Icons.check : Icons.edit,
                color: isEditingActive ? Colors.blue : Colors.grey,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  if (isEditingActive) {
                    isEditingActive = false;
                    hasChangedAfterCheck = isChanged;
                    showSaveReset = hasChangedAfterCheck;
                  } else {
                    editingField = null;
                    isEditingActive = true;
                  }
                });
              },
              tooltip: isEditingActive ? "Done" : "Edit",
            ),
          ],
        ),
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
        subtitle: Text(value ?? 'NA',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      ),
    );
  }

  /// --- Show dialog on back with unsaved changes
  Future<bool> _maybeShowDiscardDialog() async {
    if (isChanged) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('Data has not been saved. Do you want to save changes?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(false); // Cancel: discard & go back
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(true); // Proceed with save
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (result == true) {
        // Save then pop on success
        await _saveChanges(andPop: true);
        return false; // pop will be handled by save
      } else if (result == false) {
        Navigator.of(context).pop({'updated': _hasSavedAnyChange});
        return false;
      } else {
        return false;
      }
    }
    return true; // No unsaved edits, allow pop
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _userFuture,
            builder: (context, snapshot) {
              if ((snapshot.connectionState == ConnectionState.waiting && userData == null)) {
                return const Center(child: CupertinoActivityIndicator( radius: 20, color: Color(0xFF007AFF)));
              }
              final user = userData ?? snapshot.data;
              if (user == null || user.isEmpty) {
                return const Center(child: Text('User not found.'));
              }
              final name = user['username'] ?? '[No Name]';
              return WillPopScope(
                onWillPop: () async {
                  // If unsaved data, prompt; else, if any save happened in this session, signal parent to reload
                  if (isChanged) {
                    return _maybeShowDiscardDialog();
                  }
                  if (_hasSavedAnyChange) {
                    Navigator.of(context).pop({'updated': true});
                    return false;
                  }
                  return true;
                },
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
                                    child: editingField == 'username'
                                        ? Focus(
                                      onFocusChange: (hasFocus) async {
                                        if (!hasFocus) await _finishEdit('username');
                                      },
                                      child: TextField(
                                        controller: _controllers['username'],
                                        autofocus: true,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 26,
                                            color: Colors.black87),
                                        onEditingComplete: () async =>
                                        await _finishEdit('username'),
                                        onSubmitted: (_) async => await _finishEdit('username'),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            borderSide:
                                            const BorderSide(color: Colors.blueAccent),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            borderSide:
                                            const BorderSide(color: Colors.blue, width: 2),
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
                                  editingField == 'username'
                                      ? IconButton(
                                    icon: const Icon(Icons.check, color: Colors.blue),
                                    onPressed: () async => await _finishEdit('username'),
                                  )
                                      : IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.grey),
                                    onPressed: () => _startEdit('username'),
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
                        label: 'Mobile',
                        fieldName: 'mobile',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildEditableTextField(
                        label: 'Email',
                        fieldName: 'email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildEditableRolePicklist(),
                      _buildActiveCheckbox(),
                      _buildReadonlyRow(
                        label: 'Created Date',
                        value: _formatDateIST(user['created_at']),
                        icon: Icons.calendar_today,
                      ),
                      _buildReadonlyRow(
                        label: 'Last Modified Date',
                        value: _formatDateIST(user['updated_at']),
                        icon: Icons.update,
                      ),
                      _buildReadonlyRow(
                        label: 'Last Login',
                        value: _formatDateIST(user['last_login']),
                        icon: Icons.login,
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
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30)),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
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
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30)),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  child:
                                  const Text('Reset', style: TextStyle(color: Colors.blue)),
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
        ],
      ),
    );
  }
}
