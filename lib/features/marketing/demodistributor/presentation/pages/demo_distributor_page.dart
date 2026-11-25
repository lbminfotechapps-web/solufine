import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_dropdown.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_bloc.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_event.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_state.dart';
import 'package:solufine/features/meeting/presentation/pages/meeting_crop_search.dart';
import 'package:solufine/features/meeting/presentation/pages/meeting_location_search.dart';
import '../../domain/entities/demo_distributor_entry.dart';
import '../../data/models/demo_distributor_model.dart';
import '../bloc/demo_distributor_cubit.dart';
import '../widgets/demo_option_picker.dart';
import '../widgets/demo_irrigation_search.dart';
import '../widgets/demo_location_search.dart';

class DemoDistributorPage extends StatefulWidget {
  const DemoDistributorPage({super.key});
  @override
  State<DemoDistributorPage> createState() => _DemoDistributorPageState();
}

class _DemoDistributorPageState extends State<DemoDistributorPage> {
  final _form = GlobalKey<FormState>();
  final _village = TextEditingController();
  final _quantity = TextEditingController();
  final _previous = TextEditingController();
  final _ck = TextEditingController();
  final _fieldDay = TextEditingController();
  final _showing = TextEditingController();
  final _tp = TextEditingController();
  final _controllers = {
    for (final kind in DemoLookup.values) kind: TextEditingController(),
  };
  final _distributorController = TextEditingController();
  final _selected = <DemoLookup, DemoOption>{};
  bool _showOutlets = false;
  String _customerType = 'Dealer';
  String _userId = '';
  final List<String> _customerTypes = ['Dealer', 'Farmer'];
  String? _selectedCustomerId;
  String? _irrigationType;
  DateTime? _showingDate, _tpDate;
  bool _loadingUser = true;
  bool _selectionBusy = false;
  String _stateId = '';
  String _districtId = '';
  final _locationIds = <String, String>{};
  final _cropIds = <String, Object>{};
  Timer? _outletTimer;
  late final ComplaintBloc _complaintBloc;
  int _outletVersion = 0;
  @override
  void initState() {
    super.initState();
    _complaintBloc = context.read<ComplaintBloc>();
    _loadUser();
  }

  void _toast(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName field is required';
    }
    return null;
  }

  void _searchOutlet(String value) {
    _outletTimer?.cancel();
    final version = ++_outletVersion;
    _selectedCustomerId = null;
    setState(() => _showOutlets = false);
    if (value.trim().isEmpty) return;
    _outletTimer = Timer(const Duration(seconds: 1), () async {
      try {
        final user = await SecureStorage.instance.getUserData();
        if (!mounted || version != _outletVersion) return;
        final userId = (user?['user_id'] ?? user?['userId'] ?? '')
            .toString()
            .trim();
        if (userId.isEmpty) {
          _toast('Unable to load logged-in user');
          return;
        }
        _complaintBloc.add(
          GetOutletListEvent(
            userId: userId,
            dealerType: _customerType,
            dealerName: value.trim(),
          ),
        );
        setState(() => _showOutlets = true);
      } catch (e) {
        if (mounted && version == _outletVersion)
          _toast('Unable to search outlets: $e');
      }
    });
  }

  Future<void> _loadUser() async {
    try {
      final user = await SecureStorage.instance.getUserData();
      if (!mounted) return;
      setState(() {
        _userId = (user?['user_id'] ?? user?['userId'] ?? '').toString();
        _loadingUser = false;
      });
      if (_userId.isEmpty || _userId == '0') _message('Please log in again.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUser = false);
      _message('Unable to load user information. Please reopen this form.');
    }
  }

  final _fields = <String, TextEditingController>{
    for (final name in ['State', 'District', 'Block', 'Crop', 'Product'])
      name: TextEditingController(),
  };

  @override
  void dispose() {
    _outletVersion++;
    _outletTimer?.cancel();
    _distributorController.dispose();
    for (final controller in [
      _village,
      _quantity,
      _previous,
      _ck,
      _fieldDay,
      _showing,
      _tp,
      ..._controllers.values,
      ..._fields.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  bool get _locked {
    final state = context.read<DemoDistributorCubit>().state;
    return _loadingUser ||
        _selectionBusy ||
        state.submitting ||
        state.success != null;
  }

  void _clear(DemoLookup kind) {
    _selected.remove(kind);
    _controllers[kind]!.clear();
  }

  Future<void> _pick(DemoLookup kind, String label) async {
    if (_locked) return;
    final parent = switch (kind) {
      DemoLookup.district => DemoLookup.state,
      DemoLookup.block => DemoLookup.district,
      DemoLookup.subcategory || DemoLookup.variety => DemoLookup.crop,
      _ => null,
    };
    if (parent != null && !_selected.containsKey(parent)) {
      _message('Please select ${parent.name} first.');
      return;
    }
    if (kind == DemoLookup.variety &&
        !_selected.containsKey(DemoLookup.subcategory)) {
      _message('Please select subcategories first.');
      return;
    }
    final cubit = context.read<DemoDistributorCubit>();
    setState(() => _selectionBusy = true);
    final option = await showDialog<DemoOption>(
      context: context,
      builder: (_) => DemoOptionPicker(
        title: label,
        load: (query) => cubit.options(
          kind,
          userId: _userId,
          parentId: parent == null ? '' : _selected[parent]!.id,
          subcategoryId: _selected[DemoLookup.subcategory]?.id ?? '',
          query: query,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _selectionBusy = false);
    if (option != null) _applyOption(kind, option);
  }

  void _applyOption(DemoLookup kind, DemoOption option) {
    setState(() {
      final changed = _selected[kind]?.id != option.id;
      if (changed) {
        switch (kind) {
          case DemoLookup.state:
            _clear(DemoLookup.district);
            _clear(DemoLookup.block);
          case DemoLookup.district:
            _clear(DemoLookup.block);
          case DemoLookup.crop:
            _clear(DemoLookup.subcategory);
            _clear(DemoLookup.variety);
          case DemoLookup.subcategory:
            _clear(DemoLookup.variety);
          default:
            break;
        }
      }
      _selected[kind] = option;
      _controllers[kind]!.text = option.name;
    });
  }

  void _editLocation(DemoLookup kind) {
    setState(() {
      _selected.remove(kind);
      if (kind == DemoLookup.state) {
        _clear(DemoLookup.district);
        _clear(DemoLookup.block);
      } else if (kind == DemoLookup.district) {
        _clear(DemoLookup.block);
      }
    });
  }

  Widget _location(DemoLookup kind, String label) {
    final parent = switch (kind) {
      DemoLookup.district => DemoLookup.state,
      DemoLookup.block => DemoLookup.district,
      _ => null,
    };
    final parentId = parent == null ? '' : _selected[parent]?.id ?? '';
    return DemoLocationSearch(
      label: label,
      controller: _controllers[kind]!,
      selected: _selected[kind],
      parentId: parentId,
      enabled: parent == null || parentId.isNotEmpty,
      disabledHint: parent == null ? null : 'Select ${parent.name} first',
      onEdited: () => _editLocation(kind),
      onSelected: (option) => _applyOption(kind, option),
      load: (query) => context.read<DemoDistributorCubit>().options(
        kind,
        userId: _userId,
        parentId: parentId,
        query: query,
      ),
    );
  }

  Future<void> _pickDate(bool showing) async {
    if (_locked) return;
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: (showing ? _showingDate : _tpDate) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (showing) {
        _showingDate = selected;
        _showing.text = DateFormat('dd-MM-yyyy').format(selected);
      } else {
        _tpDate = selected;
        _tp.text = DateFormat('dd-MM-yyyy').format(selected);
      }
    });
  }

  void _submit() {
    if (_locked || !(_form.currentState?.validate() ?? false)) return;
    if (_userId.trim().isEmpty || _userId == '0') {
      _message('Please log in again.');
      return;
    }
    final customerId = _selectedCustomerId?.trim() ?? '';
    if (customerId.isEmpty) {
      _message(_requiredValidator(null, _customerType)!);
      return;
    }
    if (_showingDate == null || _tpDate == null) {
      _message(
        _requiredValidator(
          null,
          _showingDate == null ? 'Sowing Date' : 'T P Date',
        )!,
      );
      return;
    }
    final blockId = _locationIds['Block'] ?? '';
    final cropId = _cropIds['categoryId']?.toString() ?? '';
    final productIds = (_cropIds['productIds'] as List?) ?? const [];
    if (_stateId.isEmpty || _districtId.isEmpty || blockId.isEmpty) {
      _message(
        _requiredValidator(
          null,
          _stateId.isEmpty
              ? 'State'
              : _districtId.isEmpty
              ? 'District'
              : 'Block',
        )!,
      );
      return;
    }
    if (cropId.isEmpty || productIds.isEmpty) {
      _message(_requiredValidator(null, cropId.isEmpty ? 'Crop' : 'Product')!);
      return;
    }
    final quantity = int.tryParse(_quantity.text.trim());
    if (quantity == null || quantity <= 0) {
      _message('Quantity must be a whole number greater than zero');
      return;
    }
    FocusScope.of(context).unfocus();

    final entry = DemoDistributorEntry(
      userId: _userId,
      farmerId: _customerType == 'Farmer' ? customerId : '',
      cropId: cropId,
      noOfPkt: quantity.toString(),
      pktWt: '',
      sowingDate: _showingDate!,
      kmReading: '',
      activityId: '',
      customerType: _customerType,
      customerTypeId: '',
      customerId: customerId,
      stateId: _stateId,
      districtId: _districtId,
      blockId: blockId,
      village: _village.text.trim(),
      // There is one crop selector on this screen. Both API crop keys
      // currently use its selected ID; change if backend expects two crops.
      demoCropId: cropId,
      demoProductId: productIds.single.toString(),
      tpDate: _tpDate!,
      previousYear: _previous.text.trim(),
      irrigationId: _irrigationType ?? '',
      ck: _ck.text.trim(),
      fieldDay: _fieldDay.text.trim(),
    );

    if (kDebugMode) {
      debugPrint('DemoDistributorPage submit payload:');
      debugPrint(
        const JsonEncoder.withIndent(
          '  ',
        ).convert(DemoDistributorModel(entry).toJson()),
      );
    }
    context.read<DemoDistributorCubit>().submit(entry);
  }

  Widget _lookup(DemoLookup kind, String label, {bool required = true}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controllers[kind],
            readOnly: true,
            onTap: () => _pick(kind, label),
            validator: required
                ? (_) => _selected.containsKey(kind)
                      ? null
                      : _requiredValidator(null, label)
                : null,
            decoration: InputDecoration(
              labelText: '$label${required ? ' *' : ''}',
              suffixIcon: const Icon(Icons.arrow_drop_down),
              border: const OutlineInputBorder(),
            ),
          ),
          if (kind != DemoLookup.irrigation)
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 4, 0, 0),
              child: Text(
                'After searching, wait for 1 second.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 18),
        ],
      );

  Widget _text(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: (value) {
        if (required) {
          final error = _requiredValidator(value, label);
          if (error != null) return error;
        }
        if (numeric && (value?.trim().isNotEmpty ?? false)) {
          final number = double.tryParse(value?.trim() ?? '');
          if (number == null || !number.isFinite || number <= 0) {
            return '$label must be a number greater than zero';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _date(bool showing) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: showing ? _showing : _tp,
      readOnly: true,
      onTap: () => _pickDate(showing),
      validator: (value) =>
          _requiredValidator(value, showing ? 'Sowing Date' : 'T P Date'),
      decoration: InputDecoration(
        labelText: showing ? 'Sowing Date *' : 'T P Date *',
        suffixIcon: const Icon(Icons.calendar_month),
        border: const OutlineInputBorder(),
      ),
    ),
  );

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<DemoDistributorCubit, DemoDistributorState>(
    listener: (context, state) {
      if (state.error != null) _message(state.error!);
      if (state.success != null) {
        AppDialog.show(
          context: context,
          message: state.success!,
          title: 'Demo Distributor Saved',
          type: DialogType.success,
          allowBack: false,
          onButtonPressed: () => Navigator.of(context).maybePop(),
        );
      }
    },
    builder: (context, state) => Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: const CustomAppBar(
        title: 'Demo Distributor Details',
        showBackButton: true,
      ),
      body: AbsorbPointer(
        absorbing: _locked,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomDropdown<String>(
                  hintText: 'Customer Type *',
                  prefixIcon: Icons.people_outline_rounded,
                  value: _customerType,
                  items: _customerTypes.map((item) {
                    return DropdownMenuItem(value: item, child: Text(item));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _customerType = value ?? 'Dealer';

                      _showOutlets = false;
                      _distributorController.clear();
                      _selectedCustomerId = null;
                    });
                  },
                  validator: (value) =>
                      _requiredValidator(value, 'Customer Type'),
                ),

                const SizedBox(height: 12),

                ComplaintSearchDropdown(
                  visible: _showOutlets,
                  field: CustomTextFormField(
                    controller: _distributorController,
                    labelText: _customerType == 'Farmer'
                        ? 'Farmer Name'
                        : 'Dealer Name',
                    hintText: _customerType == 'Farmer'
                        ? 'Farmer Name *'
                        : 'Dealer Name *',
                    prefixIcon: Icons.person_outline_rounded,
                    suffixIcon: _distributorController.text.isEmpty
                        ? Icons.search_rounded
                        : Icons.close_rounded,
                    onSuffixIconTap: _distributorController.text.isEmpty
                        ? null
                        : () {
                            _distributorController.clear();
                            _searchOutlet('');
                          },
                    onChanged: _searchOutlet,
                    validator: (value) {
                      final error = _requiredValidator(
                        value,
                        _customerType == 'Farmer' ? 'Farmer' : 'Dealer',
                      );
                      if (error != null) return error;
                      if ((_selectedCustomerId ?? '').isEmpty) {
                        return _requiredValidator(
                          null,
                          _customerType == 'Farmer' ? 'Farmer' : 'Dealer',
                        );
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),

                  options: BlocBuilder<ComplaintBloc, ComplaintFormState>(
                    bloc: _complaintBloc,
                    builder: (context, state) {
                      if (state.status == ComplaintFormStatus.loading)
                        return const LinearProgressIndicator();
                      if (state.status == ComplaintFormStatus.failure)
                        return Text(
                          state.errorMessage ?? 'Unable to search outlets',
                        );
                      final outlets = state.outletListEntity?.result ?? [];
                      if (outlets.isEmpty)
                        return const Text('No matching results');
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.builder(
                          shrinkWrap: true,
                          primary: false,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.manual,
                          itemCount: outlets.length,
                          itemBuilder: (context, index) {
                            final outlet = outlets[index];
                            return ListTile(
                              title: Text(
                                "${outlet.outletName} - (${outlet.outletPersonMobile})",
                              ),
                              // subtitle: Text(outlet.outletAddress),
                              onTap: () => setState(() {
                                _distributorController.text =
                                    "${outlet.outletName} - (${outlet.outletPersonMobile})";
                                _selectedCustomerId = outlet.outletId;
                                _showOutlets = false;
                              }),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                // DropdownButtonFormField<String>(
                //   initialValue: _customerType,
                //   decoration: const InputDecoration(
                //     labelText: 'Select Customer Type *',
                //     border: OutlineInputBorder(),
                //   ),
                //   items: ['Farmer', 'Dealer']
                //       .map(
                //         (value) =>
                //             DropdownMenuItem(value: value, child: Text(value)),
                //       )
                //       .toList(),
                //   validator: _required,
                //   onChanged: (value) => setState(() => _customerType = value),
                // ),
                // const SizedBox(height: 18),
                // _location(DemoLookup.state, 'Select State'),
                // _location(DemoLookup.district, 'Select District'),
                // _location(DemoLookup.block, 'Select Block'),
                MeetingLocationSearch(
                  requiredValidator: _requiredValidator,
                  kind: 'State',
                  controller: _fields['State']!,
                  onSelected: (location) => setState(() {
                    _stateId = location.id;
                    _districtId = '';
                    _locationIds.remove('Block');
                    _fields['District']!.clear();
                    _fields['Block']!.clear();
                  }),
                  onEdited: () => setState(() {
                    _stateId = '';
                    _districtId = '';
                    _locationIds.remove('Block');
                    _fields['District']!.clear();
                    _fields['Block']!.clear();
                  }),
                ),
                MeetingLocationSearch(
                  requiredValidator: _requiredValidator,
                  key: ValueKey('district-$_stateId'),
                  kind: 'District',
                  controller: _fields['District']!,
                  parentId: _stateId,
                  onSelected: (location) => setState(() {
                    _districtId = location.id;
                    _locationIds.remove('Block');
                    _fields['Block']!.clear();
                  }),
                  onEdited: () => setState(() {
                    _districtId = '';
                    _locationIds.remove('Block');
                    _fields['Block']!.clear();
                  }),
                ),
                MeetingLocationSearch(
                  requiredValidator: _requiredValidator,
                  key: ValueKey('block-$_stateId-$_districtId'),
                  kind: 'Block',
                  controller: _fields['Block']!,
                  parentId: _districtId,
                  onSelected: (location) =>
                      setState(() => _locationIds['Block'] = location.id),
                  onEdited: () => setState(() => _locationIds.remove('Block')),
                ),
                const SizedBox(height: 10),
                _text(_village, 'Village'),
                MeetingCropSearch(
                  requiredValidator: _requiredValidator,
                  singleProduct: true,
                  crop: _fields['Crop']!,
                  subcategory: _fields['Product']!,
                  onChanged: (selection) {
                    _cropIds['categoryId'] = selection.cropId;
                    _cropIds['productIds'] = selection.productIds;
                    _cropIds['classIds'] = selection.classIds;
                  },
                ),
                // _lookup(DemoLookup.subcategory, 'Products'),
                const SizedBox(height: 10),
                _text(_quantity, 'Quantity', numeric: true),
                _date(true),
                _date(false),
                _text(
                  _previous,
                  'Previous Year Which Product Cultivation',
                  required: false,
                ),

                DemoIrrigationSearch(
                  load: () => context.read<DemoDistributorCubit>().options(
                    DemoLookup.irrigation,
                    userId: _userId,
                  ),
                  onChanged: (id) => setState(() => _irrigationType = id),
                ),
                const SizedBox(height: 15),
                _text(_ck, 'C K'),
                _text(_fieldDay, 'Field Day', numeric: true),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: context.appCard,
            border: Border(top: BorderSide(color: context.appBorder)),
          ),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _locked ? null : _submit,
              icon: state.submitting
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 21),
              label: const Text(
                'SUBMIT',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                foregroundColor: context.appOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      /*
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed:
                    _locked
                    ? null
                    : _submit,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(state.submitting ? 'Submitting...' : 'SUBMIT'),
                ),
              ),
            ),
          ),
          */
    ),
  );
}

class ComplaintSearchDropdown extends StatefulWidget {
  const ComplaintSearchDropdown({
    required this.visible,
    required this.field,
    required this.options,
  });

  final bool visible;
  final Widget field;
  final Widget options;

  @override
  State<ComplaintSearchDropdown> createState() =>
      ComplaintSearchDropdownState();
}

class ComplaintSearchDropdownState extends State<ComplaintSearchDropdown> {
  final _overlay = OverlayPortalController();

  bool _visibilityUpdateScheduled = false;

  void _scheduleVisibilityUpdate() {
    if (_visibilityUpdateScheduled) return;
    _visibilityUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityUpdateScheduled = false;
      if (!mounted || _overlay.isShowing == widget.visible) return;
      if (widget.visible) {
        _overlay.show();
      } else {
        _overlay.hide();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleVisibilityUpdate();
  }

  @override
  void didUpdateWidget(covariant ComplaintSearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _scheduleVisibilityUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlay,
      overlayChildBuilder: (context, info) {
        final field = MatrixUtils.transformRect(
          info.childPaintTransform,
          Offset.zero & info.childSize,
        );
        final visibleBottom =
            info.overlaySize.height -
            media.viewInsets.bottom -
            media.padding.bottom;
        final above = (field.top - media.padding.top).clamp(
          0.0,
          double.infinity,
        );
        final below = (visibleBottom - field.bottom).clamp(
          0.0,
          double.infinity,
        );
        final opensUp = above > below;
        final available = opensUp ? above : below;
        return Positioned(
          left: field.left,
          width: field.width,
          top: opensUp ? null : field.bottom,
          bottom: opensUp ? info.overlaySize.height - field.top : null,
          child: TextFieldTapRegion(
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: available.clamp(0.0, 240.0),
                ),
                child: widget.options,
              ),
            ),
          ),
        );
      },
      child: widget.field,
    );
  }
}
