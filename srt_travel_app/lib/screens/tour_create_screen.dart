import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/in_app_notification.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'tour_detail_screen.dart';

class TourCreateScreen extends StatefulWidget {
  final int? leadId; // optional

  const TourCreateScreen({super.key, this.leadId});

  @override
  State<TourCreateScreen> createState() => _TourCreateScreenState();
}

class _TourCreateScreenState extends State<TourCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _pickupCtrl = TextEditingController();
  final TextEditingController _dropCtrl = TextEditingController();
  final TextEditingController _startDateCtrl = TextEditingController();
  final TextEditingController _endDateCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController();
  final TextEditingController _distanceCtrl = TextEditingController();
  final TextEditingController _premiumCtrl = TextEditingController();

  // Picklists
  List<Map<String, dynamic>> _companies = [];
  dynamic _selectedCompanyId;

  List<Map<String, dynamic>> _leads = [];
  dynamic _selectedLeadId;

  List<Map<String, dynamic>> _vehicles = [];
  dynamic _selectedVehicleId;

  final List<String> _tourTypes = ["Outstation", "Local", "Lumpsum"];
  String? _selectedTourType;

  // States & Cities
  final List<String> _states = ["Maharashtra", "Madhya Pradesh"];
  final Map<String, List<String>> _citiesByState = {
    "Maharashtra": [
      "Ahmednagar",
      "Akola",
      "Amravati",
      "Aurangabad",
      "Beed",
      "Chandrapur",
      "Dhule",
      "Kolhapur",
      "Latur",
      "Malegaon",
      "Miraj",
      "Mumbai",
      "Nagpur",
      "Nanded",
      "Nashik",
      "Osmanabad",
      "Panvel",
      "Pimpri-Chinchwad",
      "Pune",
      "Ratnagiri",
      "Sagling",
      "Satara",
      "Shirdi",
      "Solapur",
      "Sangli",
      "Thane",
      "Ulhasnagar",
      "Wardha",
      "Yavatmal",
    ],
    "Madhya Pradesh": [
      "Bhopal",
      "Burhanpur",
      "Dewas",
      "Gwalior",
      "Indore",
      "Jabalpur",
      "Khandwa",
      "Morena",
      "Murwara",
      "Ratlam",
      "Rewa",
      "Sagar",
      "Satna",
      "Singrauli",
      "Ujjain",
    ],
  };

  String? _selectedStartState;
  String? _selectedEndState;
  String? _selectedStartCity;
  String? _selectedEndCity;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  bool _isSaving = false;

  // Notification state
  String? _notifMsg;
  Color _notifColor = Colors.red;
  bool _showNotif = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanyPicklist();
    _fetchVehiclePicklist();
    if (widget.leadId != null) {
      _selectedLeadId = widget.leadId;
    } else {
      _fetchLeadPicklist();
    }

    _selectedStartState = _states.first;
    _selectedEndState = _states.first;
    _selectedStartCity = 'Nagpur';
    _selectedEndCity = 'Pune';
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _durationCtrl.dispose();
    _distanceCtrl.dispose();
    _premiumCtrl.dispose();
    super.dispose();
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

  Future<void> _fetchCompanyPicklist() async {
    try {
      final data = await ApiService().getCompanypicklist();
      setState(() {
        _companies = data;
        _selectedCompanyId = _companies.isNotEmpty
            ? _companies.first['id']
            : null;
      });
    } catch (e) {
      _showNotification("Failed to load companies: $e");
    }
  }

  Future<void> _fetchLeadPicklist() async {
    try {
      final data = await ApiService().getLeadpicklist();
      setState(() {
        _leads = data;
      });
    } catch (e) {
      _showNotification("Failed to load leads: $e");
    }
  }

  Future<void> _fetchVehiclePicklist() async {
    try {
      final data = await ApiService().getVehiclepicklist();
      setState(() {
        _vehicles = data;
      });
    } catch (e) {
      _showNotification("Failed to load vehicles: $e");
    }
  }

  String? _validateRequired(String? v, String label) {
    if (v == null || v.trim().isEmpty) return "$label required";
    return null;
  }

  String? _validateNumber(String? v, String label) {
    if (v == null || v.trim().isEmpty) return "$label required.";
    final num? parsed = num.tryParse(v);
    if (parsed == null || parsed < 0) return "Enter valid $label";
    return null;
  }

  Future<void> _pickDate(TextEditingController ctrl, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      if (isStart) {
        _selectedStartDate = pickedDate;
      } else {
        _selectedEndDate = pickedDate;
      }
      ctrl.text = DateFormat('dd-MM-yyyy').format(pickedDate);
    }
  }

  Future<void> _saveTour() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCompanyId == null) {
      _showNotification("Please select a company.");
      return;
    }
    if (_selectedVehicleId == null) {
      _showNotification("Please select a vehicle.");
      return;
    }
    if (_selectedTourType == null) {
      _showNotification("Please select tour type.");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final formData = {
        "company_id": _selectedCompanyId,
        "lead_id": _selectedLeadId,
        "vehicle_id": _selectedVehicleId,
        "description": _descriptionCtrl.text.trim(),
        "start_state": _selectedStartState,
        "end_state": _selectedEndState,
        "start_city": _selectedStartCity,
        "end_city": _selectedEndCity,
        "pickup_location": _pickupCtrl.text.trim(),
        "drop_location": _dropCtrl.text.trim(),
        "start_date": _selectedStartDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedStartDate!)
            : null,
        "end_date": _selectedEndDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedEndDate!)
            : null,
        "duration_days": int.tryParse(_durationCtrl.text.trim()) ?? 0,
        "distance_km": num.tryParse(_distanceCtrl.text.trim()) ?? 0,
        "type_of_tour": _selectedTourType,
        "premium": num.tryParse(_premiumCtrl.text.trim()) ?? 0,
      };

      final id = await ApiService().createTour(formData);
      if (!mounted) return;
      if (widget.leadId != null) {
        _showNotification(
          "Tour created successfully from lead!",
          color: Colors.green,
        );

        // Import your TourDetailScreen at the top of the file
        await Future.delayed(const Duration(milliseconds: 800));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TourDetailScreen(tourId: id),
          ),
        );
      } else {
        // Otherwise: pop back with success result
        Navigator.pop(context, {"success": true, "id": id});
      }
    }catch (e) {
      _showNotification("Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.black54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  InputDecoration _picklistDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Tour", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        DropdownButtonFormField(
                          value: _selectedCompanyId,
                          items: _companies
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['id'],
                                  child: Text(c['name']),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCompanyId = v),
                          decoration: _picklistDecoration("Company"),
                          validator: (v) => v == null ? "Required" : null,
                        ),
                        const SizedBox(height: 20),

                        // if (widget.leadId == null)
                        //   DropdownButtonFormField(
                        //     value: _selectedLeadId,
                        //     items: _leads
                        //         .map((l) => DropdownMenuItem(value: l['id'], child: Text(l['name'])))
                        //         .toList(),
                        //     onChanged: (v) => setState(() => _selectedLeadId = v),
                        //     decoration: _picklistDecoration("Lead"),
                        //   ),
                        // if (widget.leadId == null) const SizedBox(height: 20),
                        ///Lead Picklist Search
                        if (widget.leadId == null) ...[
                          DropdownSearch<Map<String, dynamic>>(
                            items: (String filter, LoadProps? loadProps) {
                              if (filter.isEmpty) {
                                return _leads.take(5).toList();
                              }
                              return _leads.where((lead) {
                                final name = (lead['name'] ?? '').toLowerCase();
                                return name.contains(filter.toLowerCase());
                              }).toList();
                            },
                            itemAsString: (item) => item['name'] ?? '',
                            selectedItem: _leads.firstWhere(
                              (l) => l['id'] == _selectedLeadId,
                              orElse: () => {},
                            ),
                            compareFn: (i, s) => i['id'] == s['id'],
                            onChanged: (value) {
                              setState(() => _selectedLeadId = value?['id']);
                            },
                            validator: (value) =>
                                value == null ? "Required" : null,

                            dropdownBuilder: (context, selectedItem) {
                              if (selectedItem == null) {
                                return Text(
                                  "Select Lead",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return Text(
                                selectedItem['name'] ?? 'Select Lead',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              );
                            },
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Search By Name',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ),
                            decoratorProps: DropDownDecoratorProps(
                              decoration: _picklistDecoration("Lead"),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        ///Lead Picklist Search End
                        DropdownSearch<Map<String, dynamic>>(
                          items: (String filter, LoadProps? loadProps) {
                            if (filter.isEmpty) {
                              return _vehicles;
                            }
                            return _vehicles.where((vehicle) {
                              final name = (vehicle['name'] ?? '')
                                  .toLowerCase();
                              return name.contains(filter.toLowerCase());
                            }).toList();
                          },
                          itemAsString: (item) => item['name'] ?? '',
                          selectedItem: _vehicles.firstWhere(
                            (v) => v['id'] == _selectedVehicleId,
                            orElse: () => {},
                          ),
                          compareFn: (i, s) => i['id'] == s['id'],
                          onChanged: (value) =>
                              setState(() => _selectedVehicleId = value?['id']),
                          validator: (value) =>
                              value == null ? "Required" : null,
                          dropdownBuilder: (context, selectedItem) => Text(
                            selectedItem?['name'] ?? 'Select Vehicle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: selectedItem == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            fit: FlexFit.loose,
                            constraints: const BoxConstraints(maxHeight: 250),
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search Vehicle...',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ),
                          decoratorProps: DropDownDecoratorProps(
                            decoration: _picklistDecoration("Vehicle"),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _descriptionCtrl,
                          decoration: _fieldDecoration(
                            "Description",
                            Icons.description,
                          ),
                          validator: (v) => _validateRequired(v, "Description"),
                        ),
                        const SizedBox(height: 20),

                        DropdownSearch<String>(
                          items: (String filter, LoadProps? loadProps) {
                            if (filter.isEmpty) {
                              return _states;
                            }
                            return _states
                                .where(
                                  (state) => state.toLowerCase().contains(
                                    filter.toLowerCase(),
                                  ),
                                )
                                .toList();
                          },
                          selectedItem: _selectedStartState,
                          onChanged: (val) {
                            setState(() {
                              _selectedStartState = val;
                              _selectedStartCity = _citiesByState[val!]!.first;
                            });
                          },
                          validator: (value) =>
                              value == null ? "Required" : null,
                          dropdownBuilder: (context, selectedItem) => Text(
                            selectedItem ?? 'Select Start State',
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedItem == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            fit: FlexFit.loose,
                            constraints: const BoxConstraints(maxHeight: 250),
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search State...',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ),
                          decoratorProps: DropDownDecoratorProps(
                            decoration: _picklistDecoration("Start State"),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// START CITY - searchable
                        DropdownSearch<String>(
                          items: (String filter, LoadProps? loadProps) {
                            final cities =
                                _citiesByState[_selectedStartState] ?? [];
                            if (filter.isEmpty) {
                              return cities;
                            }
                            return cities
                                .where(
                                  (city) => city.toLowerCase().contains(
                                    filter.toLowerCase(),
                                  ),
                                )
                                .toList();
                          },
                          selectedItem: _selectedStartCity,
                          onChanged: (val) =>
                              setState(() => _selectedStartCity = val),
                          validator: (value) =>
                              value == null ? "Required" : null,
                          dropdownBuilder: (context, selectedItem) => Text(
                            selectedItem ?? 'Select Start City',
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedItem == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            fit: FlexFit.loose,
                            constraints: const BoxConstraints(maxHeight: 250),
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search City...',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ),
                          decoratorProps: DropDownDecoratorProps(
                            decoration: _picklistDecoration("Start City"),
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// END STATE - searchable
                        DropdownSearch<String>(
                          items: (String filter, LoadProps? loadProps) {
                            if (filter.isEmpty) {
                              return _states;
                            }
                            return _states
                                .where(
                                  (state) => state.toLowerCase().contains(
                                    filter.toLowerCase(),
                                  ),
                                )
                                .toList();
                          },
                          selectedItem: _selectedEndState,
                          onChanged: (val) {
                            setState(() {
                              _selectedEndState = val;
                              _selectedEndCity = _citiesByState[val!]!.first;
                            });
                          },
                          validator: (value) =>
                              value == null ? "Required" : null,
                          dropdownBuilder: (context, selectedItem) => Text(
                            selectedItem ?? 'Select End State',
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedItem == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            fit: FlexFit.loose,
                            constraints: const BoxConstraints(maxHeight: 250),
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search State...',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ),
                          decoratorProps: DropDownDecoratorProps(
                            decoration: _picklistDecoration("End State"),
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// END CITY - searchable
                        DropdownSearch<String>(
                          items: (String filter, LoadProps? loadProps) {
                            final cities =
                                _citiesByState[_selectedEndState] ?? [];
                            if (filter.isEmpty) {
                              return cities;
                            }
                            return cities
                                .where(
                                  (city) => city.toLowerCase().contains(
                                    filter.toLowerCase(),
                                  ),
                                )
                                .toList();
                          },
                          selectedItem: _selectedEndCity,
                          onChanged: (val) =>
                              setState(() => _selectedEndCity = val),
                          validator: (value) =>
                              value == null ? "Required" : null,
                          dropdownBuilder: (context, selectedItem) => Text(
                            selectedItem ?? 'Select End City',
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedItem == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            fit: FlexFit.loose,
                            constraints: const BoxConstraints(maxHeight: 250),
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search City...',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ),
                          decoratorProps: DropDownDecoratorProps(
                            decoration: _picklistDecoration("End City"),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _pickupCtrl,
                          decoration: _fieldDecoration(
                            "Pickup Location",
                            Icons.location_on,
                          ),
                          validator: (v) =>
                              _validateRequired(v, "Pickup location"),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _dropCtrl,
                          decoration: _fieldDecoration(
                            "Drop Location",
                            Icons.flag,
                          ),
                          validator: (v) =>
                              _validateRequired(v, "Drop location"),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _startDateCtrl,
                          readOnly: true,
                          onTap: () => _pickDate(_startDateCtrl, true),
                          decoration: _fieldDecoration(
                            "Start Date",
                            Icons.date_range,
                          ),
                          validator: (v) => _validateRequired(v, "Start Date"),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _endDateCtrl,
                          readOnly: true,
                          onTap: () => _pickDate(_endDateCtrl, false),
                          decoration: _fieldDecoration(
                            "End Date",
                            Icons.date_range,
                          ),
                          validator: (v) {
                            final requiredError = _validateRequired(
                              v,
                              "End Date",
                            );
                            if (requiredError != null) return requiredError;
                            if (_startDateCtrl.text.isNotEmpty &&
                                v != null &&
                                v.isNotEmpty) {
                              try {
                                final start = DateFormat(
                                  'dd-MM-yyyy',
                                ).parse(_startDateCtrl.text.trim());
                                final end = DateFormat(
                                  'dd-MM-yyyy',
                                ).parse(v.trim());
                                if (end.isBefore(start))
                                  return "End Date cannot be before Start Date";
                              } catch (_) {
                                return "Invalid date format";
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            "Duration (days)",
                            Icons.timelapse,
                          ),
                          validator: (v) => _validateNumber(v, "Duration"),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _distanceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            "Distance (km)",
                            Icons.straighten,
                          ),
                          validator: (v) => _validateNumber(v, "Distance"),
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          value: _selectedTourType,
                          items: _tourTypes
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedTourType = val),
                          decoration: _picklistDecoration("Type of Tour"),
                          validator: (v) => v == null ? "Required" : null,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _premiumCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            "Premium",
                            Icons.currency_rupee,
                          ),
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveTour,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSaving
                                ? const CupertinoActivityIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Save Tour"),
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
              child: InAppNotification(
                message: _notifMsg!,
                color: _notifColor,
                onClose: () => setState(() => _showNotif = false),
              ),
            ),
        ],
      ),
    );
  }
}
