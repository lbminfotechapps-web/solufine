import '../../domain/entities/meeting_customer.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MeetingDistributor {
  const MeetingDistributor({
    this.id = '',
    this.talukaName = '',
    required this.name,
    required this.mobile,
    required this.address,
  });
  final String id;
  final String talukaName;
  final String name;

  factory MeetingDistributor.fromJson(
    Map<String, dynamic> json, {
    required bool isFarmer,
  }) {
    String read(String key) {
      final value = json[key]?.toString().trim() ?? '';
      return value.toLowerCase() == 'null' ? '' : value;
    }

    final location = [
      read('fld_village'),
      read('fld_taluka_name'),
      read('fld_dist_name'),
      read('fld_state_name').isNotEmpty
          ? read('fld_state_name')
          : read('state_name'),
    ].where((part) => part.isNotEmpty).join(', ');
    final address = read(isFarmer ? 'fld_address' : 'fld_outlet_address');
    final outletName = read('fld_outlet_name');
    return MeetingDistributor(
      id: read(isFarmer ? 'fld_farmer_id' : 'fld_outlet_id'),
      name: isFarmer
          ? read('fld_farmer_name')
          : outletName.isNotEmpty
          ? outletName
          : read('fld_outlet_person'),
      mobile: read(isFarmer ? 'fld_mobile_no' : 'fld_outletper_mobile'),
      address: location.isNotEmpty ? location : address,
      talukaName: read('fld_taluka_name'),
    );
  }
  final String mobile;
  final String address;
}

class MeetingDistributorSelection {
  const MeetingDistributorSelection(this.distributors, this.selectedMobiles);
  final List<MeetingDistributor> distributors;
  final Set<String> selectedMobiles;

  List<MeetingCustomer> toCustomers(MeetingCustomerType type) => [
    for (final customer in distributors)
      if (selectedMobiles.contains(customer.mobile))
        MeetingCustomer(
          type: type,
          id: customer.id,
          name: customer.name,
          mobile: customer.mobile,
          address: customer.address,
          talukaName: customer.talukaName,
        ),
  ];
}

class MeetingDistributorDialog extends StatefulWidget {
  final String customerType;
  const MeetingDistributorDialog({
    super.key,
    required this.customerType,
    required this.distributors,
    required this.selectedMobiles,
  });
  final List<MeetingDistributor> distributors;
  final Set<String> selectedMobiles;

  @override
  State<MeetingDistributorDialog> createState() =>
      _MeetingDistributorDialogState();
}

class _MeetingDistributorDialogState extends State<MeetingDistributorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  List<MeetingDistributor> _contacts = [];
  MeetingDistributor? _chosenContact;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final response = await DioClient().client.post(
        '${ApiClient.baseUrl}/${widget.customerType == 'Farmer' ? 'getFarmerList' : 'getDealerList'}',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
        ),
      );
      dynamic payload = response.data;
      if (payload is String) {
        var text = payload.trim();
        // The legacy API can prepend PHP warning HTML to valid JSON.
        if (text.startsWith('<') &&
            text.contains('A PHP Error was encountered')) {
          final start = RegExp(r'\{\s*"status"\s*:').firstMatch(text)?.start;
          if (start != null) text = text.substring(start);
        }
        payload = jsonDecode(text);
      }
      final dynamic raw = payload;
      if (raw is! Map) throw const FormatException('Invalid response');
      final status = raw['status'];
      if (!(status == true ||
          status == 1 ||
          status == '1' ||
          status.toString().toLowerCase() == 'true')) {
        throw StateError(
          raw['message']?.toString() ?? 'Unable to load contacts',
        );
      }
      final result = raw['result'];
      if (result is! List) throw const FormatException('Invalid contact list');
      final contacts = result
          .whereType<Map>()
          .map(
            (entry) => MeetingDistributor.fromJson(
              Map<String, dynamic>.from(entry),
              isFarmer: widget.customerType == 'Farmer',
            ),
          )
          .where((entry) => entry.name.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final endpoint = widget.customerType == 'Farmer'
          ? 'getFarmerList'
          : 'getDealerList';
      String message;
      if (error is DioException) {
        final status = error.response?.statusCode;
        message = status == 404
            ? '$endpoint was not found on the server (404).'
            : status != null
            ? 'Unable to load names: server error $status.'
            : 'Unable to connect. Check your internet and retry.';
      } else if (error is FormatException) {
        message = 'The server returned an invalid name list.';
      } else if (error is StateError) {
        message = error.message;
      } else {
        message = 'Unable to load names. Please retry.';
      }
      setState(() {
        _loading = false;
        _loadError = message;
      });
    }
  }

  Widget _nameField() {
    return RawAutocomplete<MeetingDistributor>(
      textEditingController: _name,
      focusNode: _nameFocus,
      displayStringForOption: (contact) => contact.name,
      optionsBuilder: (value) async {
        if (value.text.trim().isEmpty) {
          return const Iterable<MeetingDistributor>.empty();
        }
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return const Iterable<MeetingDistributor>.empty();
        final query = value.text.trim().toLowerCase();
        return _contacts
            .where(
              (entry) =>
                  entry.name.toLowerCase().contains(query) ||
                  entry.mobile.contains(query),
            )
            .take(30);
      },
      onSelected: (contact) {
        _chosenContact = contact;
        _mobile.text = contact.mobile;
        _address.text = contact.address;
        _nameFocus.unfocus();
      },
      fieldViewBuilder: (context, controller, focus, onSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focus,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _decoration(
              'Name *',
              Icons.person_outline,
            ).copyWith(isDense: true),
            onChanged: (_) {
              _chosenContact = null;
            },
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter name' : null,
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 64).clamp(180.0, 500.0),
            height: 180,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final contact = options.elementAt(index);
                return ListTile(
                  title: Text(contact.name),
                  subtitle: Text(contact.mobile),
                  onTap: () => onSelected(contact),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  late final List<MeetingDistributor> _distributors = List.of(
    widget.distributors,
  );
  late final Set<String> _selected = Set.of(widget.selectedMobiles);

  @override
  void dispose() {
    _nameFocus.dispose();
    _name.dispose();
    _mobile.dispose();
    _address.dispose();
    super.dispose();
  }

  void _addData() {
    if (!_formKey.currentState!.validate()) return;
    final mobile = _mobile.text.trim();
    setState(() {
      _distributors.add(
        MeetingDistributor(
          id: _chosenContact?.id ?? '0',
          name: _name.text.trim(),
          mobile: mobile,
          address: _address.text.trim(),
          talukaName: _chosenContact?.talukaName ?? '',
        ),
      );
      _selected.add(mobile);
      _chosenContact = null;
      _name.clear();
      _mobile.clear();
      _address.clear();
      _formKey.currentState!.reset();
    });
    FocusScope.of(context).unfocus();
  }

  InputDecoration _decoration(String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      errorMaxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: [
                    Icon(Icons.groups_outlined, color: colors.primary),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        '${widget.customerType} details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.customerType}s',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${_selected.length} selected',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (_loading) const LinearProgressIndicator(minHeight: 2),
              if (_loadError != null)
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _loadError!,
                        style: TextStyle(color: colors.error, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadContacts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _distributors.isEmpty ? 1 : _distributors.length,
                  itemBuilder: (context, index) {
                    if (_distributors.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No contacts added yet. Add details below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      );
                    }
                    final distributor = _distributors[index];
                    final selected = _selected.contains(distributor.mobile);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primary.withValues(alpha: .05)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? colors.primary
                              : colors.outlineVariant,
                        ),
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: Text(
                          distributor.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${distributor.mobile}\n${distributor.address}',
                        ),
                        isThreeLine: true,
                        value: selected,
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _selected.add(distributor.mobile);
                          } else {
                            _selected.remove(distributor.mobile);
                          }
                        }),
                      ),
                    );
                  },
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add ${widget.customerType.toLowerCase()}',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _nameField()),
                          const SizedBox(width: 8),

                          Expanded(
                            child: TextFormField(
                              controller: _mobile,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: _decoration(
                                'Mobile *',
                                Icons.phone_outlined,
                              ).copyWith(isDense: true),
                              validator: (value) {
                                if (value == null ||
                                    !RegExp(r'^\d{10}$').hasMatch(value)) {
                                  return 'Enter 10-digit mobile';
                                }
                                if (_distributors.any(
                                  (entry) => entry.mobile == value,
                                )) {
                                  return 'Mobile already added';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 10),
                        child: Text(
                          '(After searching characters, wait for 1 sec..!)',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      TextFormField(
                        controller: _address,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _decoration(
                          'Address *',
                          Icons.location_on_outlined,
                        ).copyWith(isDense: true),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _addData(),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter address'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _addData,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Data'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(
                      context,
                      MeetingDistributorSelection(
                        List.of(_distributors),
                        Set.of(_selected),
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: Text('Submit (${_selected.length} selected)'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
