import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/features/meeting/presentation/pages/meeting_crop_search.dart';
import 'package:solufine/features/meeting/presentation/pages/meeting_location_search.dart';
import '../../domain/entities/demo_distributor_entry.dart';
import '../bloc/demo_distributor_cubit.dart';
import '../widgets/demo_option_picker.dart';
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
  final _selected = <DemoLookup, DemoOption>{};
  String _userId = '';
  String? _customerType;
  DateTime? _showingDate, _tpDate;
  bool _loadingUser = true;
  bool _selectionBusy = false;
  String _stateId = '';
  String _districtId = '';
  final _locationIds = <String, String>{};
    final _cropIds = <String, Object>{};
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await SecureStorage.instance.getUserData();
      if (!mounted) return;
      setState(() {
        _userId = user?['user_id']?.toString() ?? '';
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
    for (final name in ['State', 'District', 'Block','Crop','Product'])
      name: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in [
      _village,
      _quantity,
      _previous,
      _ck,
      _fieldDay,
      _showing,
      _tp,
      ..._controllers.values,
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
    if (_locked || !_form.currentState!.validate()) return;
    if (_userId.isEmpty || _userId == '0') {
      _message('Please log in again.');
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<DemoDistributorCubit>().submit(
      DemoDistributorEntry(
        userId: _userId,
        customerType: _customerType!,
        stateId: _selected[DemoLookup.state]!.id,
        districtId: _selected[DemoLookup.district]!.id,
        blockId: _selected[DemoLookup.block]!.id,
        village: _village.text.trim(),
        cropId: _selected[DemoLookup.crop]!.id,
        subcategoryId: _selected[DemoLookup.subcategory]!.id,
        varietyId: _selected[DemoLookup.variety]!.id,
        quantity: double.parse(_quantity.text.trim()),
        showingDate: _showingDate!,
        tpDate: _tpDate!,
        previousProduct: _previous.text.trim(),
        irrigationId: _selected[DemoLookup.irrigation]?.id ?? '',
        ck: _ck.text.trim(),
        fieldDay: _fieldDay.text.trim(),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

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
                      : 'Please select $label'
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
        if (required && _required(value) != null) return _required(value);
        if (numeric) {
          final number = double.tryParse(value?.trim() ?? '');
          if (number == null || !number.isFinite || number <= 0) {
            return 'Enter a quantity greater than zero';
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
      validator: _required,
      decoration: InputDecoration(
        labelText: showing ? 'Showing Date *' : 'T P Date *',
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
        title: 'Demo Distributor Detail',
        showBackButton: true,
      ),
      body: AbsorbPointer(
        absorbing: _locked,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _customerType,
                decoration: const InputDecoration(
                  labelText: 'Select Customer Type *',
                  border: OutlineInputBorder(),
                ),
                items: ['Farmer', 'Dealer', 'Distributor']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                validator: _required,
                onChanged: (value) => setState(() => _customerType = value),
              ),
              // const SizedBox(height: 18),
              // _location(DemoLookup.state, 'Select State'),
              // _location(DemoLookup.district, 'Select District'),
              // _location(DemoLookup.block, 'Select Block'),
              MeetingLocationSearch(
                kind: 'State',
                controller: _fields['State']!,
                onSelected: (location) =>
                    setState(() => _stateId = location.id),
                onEdited: () => setState(() {
                  _stateId = '';
                  _districtId = '';
                  _locationIds.remove('Block');
                  _fields['District']!.clear();
                  _fields['Block']!.clear();
                }),
              ),
              MeetingLocationSearch(
                key: ValueKey('district-$_stateId'),
                kind: 'District',
                controller: _fields['District']!,
                parentId: _stateId,
                onSelected: (location) =>
                    setState(() => _districtId = location.id),
                onEdited: () => setState(() {
                  _districtId = '';
                  _locationIds.remove('Block');
                  _fields['Block']!.clear();
                }),
              ),
              MeetingLocationSearch(
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
              _text(_quantity, 'QTY', numeric: true),
              _date(true),
              _date(false),
              _text(
                _previous,
                'Previous Year Which Product Cultivation',
                required: false,
              ),
              _lookup(
                DemoLookup.irrigation,
                'Select Irrigation',
                required: false,
              ),
              _text(_ck, 'C K'),
              _text(_fieldDay, 'Field Day'),
            ],
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
              onPressed:
                  _locked || !context.read<DemoDistributorCubit>().canSubmit
                  ? null
                  : _submit,
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
                    _locked || !context.read<DemoDistributorCubit>().canSubmit
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
