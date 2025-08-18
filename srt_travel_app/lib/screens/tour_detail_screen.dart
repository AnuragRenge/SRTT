import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'driver_detail_screen.dart';
import 'lead_detail_screen.dart';
import 'vehicles_detail_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';

class TourDetailScreen extends StatefulWidget {
  final dynamic tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  late Future<Map<String, dynamic>?> _tourFuture;
  Map<String, dynamic>? tourData;
  Map<String, dynamic>? initialData;

  String? editingField;
  final Map<String, TextEditingController> _controllers = {};

  String? notificationMessage;
  bool showNotification = false;
  Color notificationColor = Colors.blue;
  bool showSaveReset = false;
  bool _isSaving = false;
  bool _hasSavedAnyChange = false; // <-- NEW for tracking saved changes

  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _leads = [];
  List<Map<String, dynamic>> _vehicles = [];

  final List<String> tourTypeOptions = ["Local", "Lumpsum", "Outstation"];
  final List<String> _states = ["Maharashtra","Madahya Pradesh"];
  final Map<String, List<String>> _citiesByState = {
    "Maharashtra": ["Ahmednagar", "Akola", "Amravati", "Aurangabad", "Beed", "Chandrapur", "Dhule", "Kolhapur", "Latur", "Malegaon", "Miraj", "Mumbai", "Nagpur", "Nanded", "Nashik", "Osmanabad", "Panvel", "Pimpri-Chinchwad", "Pune", "Ratnagiri", "Sagling", "Satara", "Shirdi", "Solapur", "Sangli", "Thane", "Ulhasnagar", "Wardha", "Yavatmal"],
    "Madhya Pradesh": ["Bhopal", "Burhanpur", "Dewas", "Gwalior", "Indore", "Jabalpur", "Khandwa", "Morena", "Murwara", "Ratlam", "Rewa", "Sagar", "Satna", "Singrauli", "Ujjain"],
  };

  @override
  void initState() {
    super.initState();
    _tourFuture = _fetchTour();
    _fetchCompanyList();
    _fetchDriverPicklist();
    _fetchLeadPicklist();
    _fetchVehiclePicklist();
  }

  // -------- UNSAVED/DISCARD LOGIC ADDITIONS ----------
  Future<bool> _maybeShowDiscardDialog() async {
    if (isChanged) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Data has not been saved. Do you want to save changes?', style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              child: const Text('Cancel', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom( backgroundColor: Colors.blue,
                foregroundColor: Colors.white,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
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
  // ---------- END UNSAVED/DISCARD LOGIC ADDITIONS ----------

  Future<Map<String, dynamic>?> _fetchTour() async {
    final data = await ApiService().getTourById(widget.tourId);
    setState(() {
      tourData = {...data};
      initialData = {...data};
      _controllers.clear();
      for (final key in [
        'description',
        'pickup_location',
        'drop_location',
        'duration_days',
        'distance_km',
        'premium',
        'total_amount'
      ]) {
        _controllers[key] =
            TextEditingController(text: data[key]?.toString() ?? '');
      }
      showSaveReset = false;
    });
    return data;
  }

  Future<void> _fetchCompanyList() async {
    final companies = await ApiService().getCompany();
    setState(() => _companies = companies);
  }

  Future<void> _fetchDriverPicklist() async {
    final drivers = await ApiService().getDriverpicklist();
    setState(() => _drivers = drivers);
  }

  Future<void> _fetchLeadPicklist() async {
    final leads = await ApiService().getLeadpicklist();
    setState(() => _leads = leads);
  }

  Future<void> _fetchVehiclePicklist() async {
    final vehicles = await ApiService().getVehiclepicklist();
    setState(() => _vehicles = vehicles);
  }

  String _formatDateTimeIST(String? utcString) {
    if (utcString == null || utcString.isEmpty) return 'NA';
    DateTime? utcDate = DateTime.tryParse(utcString);
    if (utcDate == null) return 'NA';
    final istDate = utcDate.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd/MM/yyyy hh:mm a').format(istDate);
  }

  String _formatDateIST(String? utcString) {
    if (utcString == null || utcString.isEmpty) return 'NA';
    DateTime? utcDate = DateTime.tryParse(utcString);
    if (utcDate == null) return 'NA';
    final istDate = utcDate.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd/MM/yyyy').format(istDate);
  }

  bool get isChanged {
    if (tourData == null || initialData == null) return false;
    for (final key in [
      'description',
      'pickup_location',
      'drop_location',
      'duration_days',
      'distance_km',
      'premium',
      'total_amount',
      'company_id',
      'lead_id',
      'vehicle_id',
      'type_of_tour',
      'start_state',
      'end_state',
      'start_city',
      'end_city',
      'start_date',
      'end_date'
    ]) {
      if ((tourData?[key]?.toString() ?? '') != (initialData?[key]?.toString() ?? '')) {
        return true;
      }
    }
    return false;
  }

  void _showNotification(String message, {Color? color}) {
    setState(() {
      notificationMessage = message;
      notificationColor = color ?? Colors.blue;
      showNotification = true;
    });
    Future.delayed(const Duration(seconds: 4),
            () => setState(() => showNotification = false));
  }

  Future<void> _selectDateTime(String fieldName) async {
    DateTime? initialDate;
    try {
      initialDate = DateTime.parse(tourData?[fieldName]?.toString() ?? '');
    } catch (_) {
      initialDate = DateTime.now();
    }
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;


    // Date Validation Logic
    if (fieldName == "start_date") {
      final endDateStr = tourData?["end_date"];
      if (endDateStr != null && endDateStr.isNotEmpty) {
        final endDate = DateTime.tryParse(endDateStr);
        if (endDate != null && pickedDate.isAfter(endDate)) {
          _showNotification("Start Date cannot be after End Date.", color: Colors.red);
          return;
        }
      }
    }
    if (fieldName == "end_date") {
      final startDateStr = tourData?["start_date"];
      if (startDateStr != null && startDateStr.isNotEmpty) {
        final startDate = DateTime.tryParse(startDateStr);
        if (startDate != null && pickedDate.isBefore(startDate)) {
          _showNotification("End Date cannot be before Start Date.", color: Colors.red);
          return;
        }
      }
    }
    setState(() {
      tourData?[fieldName] = DateFormat('yyyy-MM-dd').format(pickedDate);
      showSaveReset = isChanged;
    });
  }


  // ---------- SAVE/RESET BUTTON FUNCTIONALITY ----------
  Future<bool> _saveChanges({bool andPop = false}) async {
    setState(() => _isSaving = true);
    final updated = <String, dynamic>{};
    for (final key in [
      'description', 'pickup_location', 'drop_location', 'duration_days',
      'distance_km', 'premium', 'total_amount', 'company_id', 'lead_id',
      'vehicle_id', 'type_of_tour', 'start_state', 'end_state', 'start_city',
      'end_city', 'start_date', 'end_date'
    ]) {
      if ((tourData?[key]?.toString() ?? '') != (initialData?[key]?.toString() ?? '')) {
        updated[key] = tourData?[key];
      }
    }
    if (updated.isEmpty) {
      _showNotification("No changes to save.", color: Colors.red);
      setState(() => _isSaving = false);
      return false;
    }
    try {
      final result = await ApiService().updateTour(widget.tourId, updated);
      final fresh = await ApiService().getTourById(widget.tourId);
      setState(() {
        notificationMessage = result['message'] ?? "Tour updated!";
        notificationColor = Colors.green;
        showNotification = true;
        tourData = {...fresh};
        initialData = {...fresh};
        _controllers.forEach((k, c) => c.text = tourData?[k]?.toString() ?? '');
        showSaveReset = false;
        _hasSavedAnyChange = true;
      });
      if (andPop && mounted) {
        Future.delayed(const Duration(milliseconds: 400), () => Navigator.of(context).pop({'updated': true}));
      }
      return true;
    } catch (e) {
      _showNotification(e.toString(), color: Colors.red);
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetChanges() {
    setState(() {
      if (initialData == null) return;
      tourData = {...initialData!};
      _controllers.forEach((k, c) => c.text = initialData?[k]?.toString() ?? '');
      editingField = null;
      showSaveReset = false;
    });
  }
  // ---------- END SAVE/RESET BUTTON FUNCTIONALITY ----------

  // ----------- FIELD BUILDERS remain unchanged except onChanged adds showSaveReset = isChanged (already present) -------

  Widget _buildEditableText(String label, String fieldName,
      {IconData icon = Icons.text_fields, TextInputType type = TextInputType.text}) {
    final val = (tourData?[fieldName] ?? '').toString();
    final isEditing = editingField == fieldName;
    final controller =
        _controllers[fieldName] ?? TextEditingController(text: val);

    return _fieldCard(
      icon,
      label,
      isEditing
          ? TextField(
        controller: controller,
        keyboardType: type,
        onChanged: (v) {
          tourData?[fieldName] = v;
          showSaveReset = isChanged;
        },
        autofocus: true,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        decoration: const InputDecoration(border: InputBorder.none),
      )
          : Text(val.isEmpty ? 'NA' : val,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: IconButton(
        icon: Icon(isEditing ? Icons.check : Icons.edit,
            color: isEditing ? Colors.blue : Colors.grey),
        onPressed: () {
          if (isEditing) {
            _controllers[fieldName]?.text = tourData?[fieldName]?.toString() ?? '';
            setState(() => editingField = null);
          } else {
            setState(() {
              editingField = fieldName;
            });
          }
        },
      ),
    );
  }

  Widget _buildPicklist(String label, String fieldName, List<Map<String, dynamic>> options,
      {IconData? icon, bool alsoClickable = false, String? clickType}) {
    final id = tourData?[fieldName];
    final isEditing = editingField == fieldName;
    String currentLabel = '';
    if (id != null) {
      final found = options.firstWhere((o) => o['id'].toString() == id.toString(), orElse: () => {'name': ''});
      currentLabel = found['name'] ?? '';
    }

    return _fieldCard(
      icon ?? _getIconForField(fieldName),
      label,
      isEditing
          ? DropdownSearch<Map<String, dynamic>>(
        items: (String filter, LoadProps? loadProps) {
          if (filter.isEmpty) return options;
          return options.where((opt) {
            final name = (opt['name'] ?? '').toLowerCase();
            return name.contains(filter.toLowerCase());
          }).toList();
        },
        itemAsString: (item) => item['name'] ?? '',
        selectedItem: options.firstWhere(
              (o) => o['id'].toString() == id?.toString(),
          orElse: () => {},
        ),
        compareFn: (i, s) => i['id'] == s['id'],
        onChanged: (value) {
          setState(() {
            tourData?[fieldName] = value?['id'];
            showSaveReset = isChanged;
          });
        },
        dropdownBuilder: (context, selectedItem) => Text(
          selectedItem?['name'] ?? 'Select',
          style: TextStyle(
            fontSize: 16,
            color: selectedItem == null ? Colors.grey : Colors.black,
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true,

          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(hintText: 'Search...'),
          ),
        ),
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            // labelText: label,
            // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      )
          : GestureDetector(
        onTap: alsoClickable && id != null
            ? () {
          if (clickType == 'lead') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LeadDetailScreen(leadId: id),
              ),
            ).then((_) {
              setState(() {
                _tourFuture = _fetchTour();
                _fetchLeadPicklist();
              });
            });
          } else if (clickType == 'vehicle') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VehicleDetailScreen(vehicleId: id),
              ),
            ).then((_) {
              setState(() {
                _tourFuture = _fetchTour();
                _fetchDriverPicklist();
                _fetchVehiclePicklist();
              });
            });
          }
        }
            : null,
        child: Text(
          currentLabel.isEmpty ? 'NA' : currentLabel,
          style: alsoClickable
              ? const TextStyle(
              decoration: TextDecoration.underline, fontWeight: FontWeight.w600, fontSize: 16)
              : const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      trailing: IconButton(
        icon: Icon(isEditing ? Icons.check : Icons.edit,
            color: isEditing ? Colors.blue : Colors.grey),
        onPressed: () {
          setState(() {
            editingField = isEditing ? null : fieldName;
          });
        },
      ),
    );
  }

  IconData _getIconForField(String fieldName) {
    switch (fieldName) {
      case 'company_id':
        return Icons.business;
      case 'lead_id':
        return Icons.person;
      case 'vehicle_id':
        return Icons.directions_car;
      default:
        return Icons.arrow_drop_down;
    }
  }

  Widget _buildPicklistString(String label, String fieldName, List<String> items,
      {IconData icon = Icons.arrow_drop_down}) {
    final val = (tourData?[fieldName] ?? '').toString();
    final isEditing = editingField == fieldName;

    return _fieldCard(
      icon,
      label,
      isEditing
          ? DropdownButtonFormField<String>(
        value: items.contains(val) ? val : items.first,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: (selected) {
          setState(() {
            tourData?[fieldName] = selected ?? items.first;
            showSaveReset = isChanged;
          });
        },
        decoration: const InputDecoration(border: InputBorder.none),
      )
          : Text(val.isEmpty ? 'NA' : val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: IconButton(
        icon: Icon(isEditing ? Icons.check : Icons.edit,
            color: isEditing ? Colors.blue : Colors.grey),
        onPressed: () {
          setState(() {
            editingField = isEditing ? null : fieldName;
          });
        },
      ),
    );
  }

  Widget _buildDateTime(String label, String fieldName, {IconData icon = Icons.event}) {
    final val = tourData?[fieldName];
    final isEditing = editingField == fieldName;
    final shown = _formatDateIST(val);

    return _fieldCard(
      icon,
      label,
      Text(shown, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: IconButton(
        icon: Icon(isEditing ? Icons.check : Icons.edit,
            color: isEditing ? Colors.blue : Colors.grey),
        onPressed: () async {
          if (isEditing) {
            setState(() => editingField = null);
          } else {
            setState(() => editingField = fieldName);
            await _selectDateTime(fieldName);
          }
        },
      ),
    );
  }

  Widget _buildStateCityPicklist(String stateField, String cityField, String label, {IconData icon = Icons.location_city}) {
    final stateVal = (tourData?[stateField] ?? '').toString();
    // final cityVal = (tourData?[cityField] ?? '').toString();
    final cities = _citiesByState[stateVal] ?? [];

    return Column(
      children: [
        _buildPicklistString("$label State", stateField, _states, icon: Icons.place),
        _buildPicklistString("$label City", cityField, cities, icon: icon),
      ],
    );
  }

  Widget _fieldCard(IconData icon, String label, Widget child, {Widget? trailing}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[300]),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        subtitle: child,
        trailing: trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Details', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _tourFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && tourData == null) {
                return const Center(child: CupertinoActivityIndicator(radius: 20, color: Color(0xFF007AFF)));
              }
              final t = tourData ?? snapshot.data;
              if (t == null) {
                return const Center(child: Text("Tour not found."));
              }

              // ----------- Wrap with WillPopScope -----------
              return WillPopScope(
                onWillPop: _onWillPop,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _fieldCard(Icons.tour, "Tour Name", Text(t['name']?.toString() ?? 'NA', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                      _buildPicklist("Company", "company_id", _companies),
                      _buildPicklist("Lead", "lead_id", _leads, alsoClickable: true, clickType: 'lead'),
                      _fieldCard(Icons.phone, "Lead Phone", Text(t['lead_phone']?.toString() ?? 'NA', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                      _fieldCard(Icons.email, "Lead Email", Text(t['lead_email']?.toString() ?? 'NA', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                      _fieldCard(
                        Icons.person_outline,
                        "Assigned Driver",
                        GestureDetector(
                          onTap: () {
                            final driverId = t['assigned_driver']?.toString();
                            if (driverId != null && driverId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DriverDetailScreen(driverId: driverId),
                                ),
                              ).then((_) {
                                setState(() {
                                  _tourFuture = _fetchTour();
                                  _fetchDriverPicklist();
                                });
                              });
                            }
                          },
                          child: Text(
                                () {
                              final driverId = t['assigned_driver']?.toString();
                              if (driverId == null || driverId.isEmpty) return 'NA';
                              final found = _drivers.firstWhere(
                                    (d) => d['id'].toString() == driverId,
                                orElse: () => {'name': ''},
                              );
                              return (found['name']?.toString().isNotEmpty ?? false)
                                  ? found['name'].toString()
                                  : 'NA';
                            }(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      _buildPicklist("Vehicle", "vehicle_id", _vehicles, alsoClickable: true, clickType: 'vehicle'),
                      _buildEditableText("Description", "description"),
                      _buildStateCityPicklist("start_state", "start_city", "Start"),
                      _buildStateCityPicklist("end_state", "end_city", "End"),
                      _buildEditableText("Pickup Location", "pickup_location"),
                      _buildEditableText("Drop Location", "drop_location"),
                      _buildDateTime("Start Date & Time", "start_date"),
                      _buildDateTime("End Date & Time", "end_date"),
                      _buildEditableText("Duration (days)", "duration_days", type: TextInputType.number),
                      _buildEditableText("Distance (km)", "distance_km", type: TextInputType.number),
                      _buildPicklistString("Type of Tour", "type_of_tour", tourTypeOptions),
                      _buildEditableText("Premium ₹", "premium", type: TextInputType.number),
                      //_buildEditableText("Total Amount", "total_amount", type: TextInputType.number),
                      _fieldCard(Icons.attach_money, "Total Amount", Text(t['total_amount']?.toString() ?? 'NA', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                      _fieldCard(Icons.price_change, "Price/Km", Text(t['price']?.toString() ?? 'NA', style: const TextStyle(fontWeight: FontWeight.w600,fontSize: 16))),
                      _fieldCard(Icons.calendar_today, "Created Date", Text(_formatDateTimeIST(t['created_at']),style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                      _fieldCard(Icons.update, "Last Modified Date", Text(_formatDateTimeIST(t['updated_at']),style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                      // ------------ NEW: Save & Reset Buttons ---------------
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
                      // -------------- END NEW BUTTONS --------------
                    ],
                  ),
                ),
              );
            },
          ),
          if (showNotification && notificationMessage != null)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: InAppNotification(
                message: notificationMessage!,
                color: notificationColor,
                onClose: () => setState(() => showNotification = false),
              ),
            ),
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