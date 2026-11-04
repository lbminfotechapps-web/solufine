import 'package:flutter/foundation.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/location_util.dart';
import '../../meeting_dependencies.dart';
import '../../data/models/meeting_form_mapper.dart';
import '../../domain/entities/meeting_customer.dart';
import '../../domain/entities/meeting_option.dart';
import '../../domain/entities/meeting_submission.dart';
import '../cubit/meeting_submission_cubit.dart';
import 'meeting_approver_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'meeting_distributor_dialog.dart';
import 'meeting_location_search.dart';
import 'meeting_crop_search.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  final _services = MeetingDependencies();
  bool _submitting = false;
  bool _submitted = false;
  String _approverId = '';
  List<MeetingOption> _seasons = [];
  String? _seasonId;
  String? _seasonError;
  bool _loadingSeasons = false;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _loadingSeasons = true;
      _seasonError = null;
    });
    try {
      final seasons = await _services.options.seasons();
      if (!mounted) return;
      setState(() {
        _seasons = seasons;
        _loadingSeasons = false;
        if (seasons.isEmpty) _seasonError = 'No seasons available';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSeasons = false;
        _seasonError = 'Unable to load seasons';
      });
    }
  }

  Widget _seasonPicker() => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _seasonId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Select Season *',
            border: OutlineInputBorder(),
          ),
          items: _seasons
              .map(
                (option) => DropdownMenuItem(
                  value: option.id,
                  child: Text(option.name),
                ),
              )
              .toList(),
          onChanged: _loadingSeasons
              ? null
              : (id) => setState(() {
                  _seasonId = id;
                  _season = _seasons
                      .firstWhere((option) => option.id == id)
                      .name;
                }),
          validator: (id) =>
              id == null || id.isEmpty ? 'Please select a season' : null,
        ),
        if (_loadingSeasons) const LinearProgressIndicator(),
        if (_seasonError != null)
          TextButton.icon(
            onPressed: _loadSeasons,
            icon: const Icon(Icons.refresh),
            label: Text('$_seasonError. Retry'),
          ),
      ],
    ),
  );

  final _formKey = GlobalKey<FormState>();
  String _stateId = '';
  String _districtId = '';
  final _locationIds = <String, String>{};
  final _cropIds = <String, Object>{};
  final _fields = <String, TextEditingController>{
    for (final name in [
      'Customer details',
      'Meeting date',
      'Place of meeting',
      'Objective of meeting',
      'State',
      'District',
      'Block',
      'Budget approved by',
      'Crop',
      'Product',
      'Future sale plan quantity',
      'Total members attending',
      'Total meeting expenses',
      'Budget Sanction per head Rs.',
    ])
      name: TextEditingController(),
  };
  final _customerSelections = <String, MeetingDistributorSelection>{};

  String _selectionSummary(String type) {
    final count = _customerSelections[type]?.selectedMobiles.length ?? 0;
    return count == 0 ? '' : 'Selected ${type.toLowerCase()}s: $count';
  }

  Future<void> _openDistributorDetails() async {
    FocusScope.of(context).unfocus();
    final type = _customerType;
    final saved = _customerSelections[type];
    final selection = await showDialog<MeetingDistributorSelection>(
      context: context,
      builder: (_) => MeetingDistributorDialog(
        customerType: type,
        distributors: saved?.distributors ?? const [],
        selectedMobiles: saved?.selectedMobiles ?? const {},
      ),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _customerSelections[type] = selection;
      _fields['Customer details']!.text = _selectionSummary(_customerType);
    });
  }

  String _customerType = 'Distributor';
  String _farmerMeetingType = 'Pre Meeting';
  String _season = '';
  String _budgetType = 'Budget Meeting';
  DateTime? _date;
  final _imagePicker = ImagePicker();
  Uint8List? _meetingPhoto;
  String? _meetingPhotoName;
  bool _pickingPhoto = false;

  Future<void> _pickMeetingPhoto() async {
    if (_pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _meetingPhoto = bytes;
        _meetingPhotoName = photo.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open photo. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Widget _meetingPhotoPicker() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Meeting Photo', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          if (_meetingPhoto != null) ...[
            Image.memory(
              _meetingPhoto!,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stackTrace) =>
                  const Text('Photo preview unavailable'),
            ),
            const SizedBox(height: 8),
            Text(_meetingPhotoName ?? '', overflow: TextOverflow.ellipsis),
          ],
          OutlinedButton.icon(
            onPressed: _pickingPhoto ? null : _pickMeetingPhoto,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              _pickingPhoto
                  ? 'Opening gallery...'
                  : _meetingPhoto == null
                  ? 'Choose from gallery'
                  : 'Change photo',
            ),
          ),
          if (_meetingPhoto != null)
            TextButton.icon(
              onPressed: _pickingPhoto
                  ? null
                  : () => setState(() {
                      _meetingPhoto = null;
                      _meetingPhotoName = null;
                    }),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove photo'),
            ),
        ],
      ),
    );
  }

  double get _costPerHead {
    final members = int.tryParse(_fields['Total members attending']!.text) ?? 0;
    final expenses =
        double.tryParse(_fields['Total meeting expenses']!.text) ?? 0;
    return members > 0 ? expenses / members : 0;
  }

  @override
  void dispose() {
    _services.submission.close();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,

      suffixIcon: icon == Icons.calendar_today_outlined
          ? Icon(icon, size: 22, color: context.primaryColor)
          : null,
      filled: true,
      fillColor: context.backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: context.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
      errorMaxLines: 2,
    );
  }

  Widget _field(
    String name,
    IconData icon, {
    bool required = true,
    bool number = false,
    bool integer = false,
    bool readOnly = false,
    int lines = 1,
    VoidCallback? onTap,
    String? label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        controller: _fields[name],
        readOnly: readOnly,
        onTap: onTap,
        maxLines: lines,
        keyboardType: number
            ? TextInputType.numberWithOptions(decimal: !integer)
            : lines > 1
            ? TextInputType.multiline
            : TextInputType.text,
        textInputAction: lines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        inputFormatters: number
            ? [
                if (integer)
                  FilteringTextInputFormatter.digitsOnly
                else
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) =>
                        RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newValue.text)
                        ? newValue
                        : oldValue,
                  ),
              ]
            : null,
        decoration: _decoration('${label ?? name}${required ? ' *' : ''}', icon)
            .copyWith(
              helperText:
                  const {
                    'State',
                    'District',
                    'Block',
                    'Budget approved by',
                    'Crop',
                    'Product',
                  }.contains(name)
                  ? '(After searching characters, wait for 1 sec..!)'
                  : null,
              helperStyle: const TextStyle(color: Colors.red, fontSize: 12),
              helperMaxLines: 2,
            ),
        onChanged: number ? (_) => setState(() {}) : null,
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Please enter ${(label ?? name).toLowerCase()}';
          }
          if (number && value != null && value.isNotEmpty) {
            final parsed = double.tryParse(value);
            if (parsed == null ||
                !parsed.isFinite ||
                parsed < 0 ||
                (name == 'Total members attending' && parsed <= 0)) {
              return name == 'Total members attending'
                  ? 'Enter at least one member'
                  : 'Enter a valid amount';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _dropdown(
    String label,
    IconData icon,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: context.primaryColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label *', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: context.primaryColor),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (selected) {
              if (selected != null) setState(() => onChanged(selected));
            },
          ),
        ],
      ),
    );
  }

  Widget _section(
    String number,
    String title,
    String subtitle,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _date = selected;
      _fields['Meeting date']!.text = DateFormat('dd-MM-yyyy').format(selected);
    });
  }

  Future<void> _review() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review meeting',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('Check your details below, then submit your meeting.'),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final entry in <String, String>{
                        'Customer type': _customerType,
                        if (_customerType == 'Farmer')
                          'Farmer meeting type': _farmerMeetingType,
                        for (final field in _fields.entries)
                          field.key: field.value.text.trim(),
                        'Meeting photo': _meetingPhotoName ?? 'Not selected',
                        'Season': _season,
                        'Budget type': _budgetType,
                        'Cost per head':
                            'Rs. ${_costPerHead.toStringAsFixed(2)}',
                      }.entries)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.key),
                          subtitle: Text(
                            entry.value.isEmpty ? 'Not provided' : entry.value,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Submit meeting'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: const Text('Back to editing'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) await _submit();
  }

  Future<void> _submit() async {
    if (_submitting || _submitted || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final user = await SecureStorage.instance.getUserData();
      final userId = (user?['user_id'] ?? user?['userId'] ?? '')
          .toString()
          .trim();
      if (userId.isEmpty || userId == '0') {
        throw const MeetingSubmissionException(
          'Please sign in again before submitting',
        );
      }
      final location = await LocationUtil.instance.getCurrentLocation().timeout(
        const Duration(seconds: 30),
      );
      if (!mounted) return;
      if (location == null) {
        throw const MeetingSubmissionException(
          'Enable location access and try again',
        );
      }
      final address = await LocationUtil.instance
          .getAddress(location.latitude, location.longitude)
          .timeout(const Duration(seconds: 10), onTimeout: () => '');
      if (!mounted) return;
      final type = switch (_customerType) {
        'Farmer' => MeetingCustomerType.farmer,
        'Retailer' => MeetingCustomerType.retailer,
        _ => MeetingCustomerType.dealer,
      };
      final submission = MeetingFormMapper.build(
        userId: userId,
        customerType: _customerType,
        customers: _customerSelections[_customerType]?.toCustomers(type) ?? [],
        date: _date!,
        values: {
          for (final entry in _fields.entries) entry.key: entry.value.text,
        },
        stateId: _stateId,
        districtId: _districtId,
        blockId: _locationIds['Block'] ?? '',
        approverId: _approverId,
        cropId: _cropIds['categoryId'] as String? ?? '',
        classIds: _cropIds['classIds'] as List<String>? ?? [],
        productIds: _cropIds['productIds'] as List<String>? ?? [],
        seasonId: _seasonId ?? '',
        budgetType: _budgetType,
        farmerType: _farmerMeetingType,
        costPerHead: _costPerHead.toStringAsFixed(2),
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
        pictures: [
          if (_meetingPhoto != null)
            MeetingAttachment(
              filename: _meetingPhotoName ?? 'meeting.jpg',
              bytes: _meetingPhoto!,
            ),
        ],
      );
      await _services.submission.submit(submission);
      if (!mounted) return;
      final state = _services.submission.state;
      if (state.status == MeetingSubmissionStatus.success) {
        setState(() {
          _submitted = true;
          _submitting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message)));
        await WidgetsBinding.instance.endOfFrame;
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw MeetingSubmissionException(state.message);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('MEETING FORM/LOCATION ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is MeetingSubmissionException
                ? error.message
                : 'Unable to submit meeting. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: AbsorbPointer(
        absorbing: _submitting || _submitted,
        child: Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: const CustomAppBar(title: 'Meeting', showBackButton: true),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: context.onPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submitting || _submitted ? null : _review,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: Text(
                  _submitting
                      ? 'Submitting...'
                      : _submitted
                      ? 'Meeting submitted'
                      : 'Review meeting',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    _section(
                      '01',
                      'Meeting details',
                      'Who you are meeting and why',
                      [
                        _dropdown(
                          'Select Customer Type',
                          Icons.people_outline,
                          _customerType,
                          const ['Distributor', 'Dealer', 'Retailer', 'Farmer'],
                          (value) {
                            _customerType = value;
                            _fields['Customer details']!.text =
                                _selectionSummary(value);
                          },
                        ),
                        if (_customerType == 'Farmer')
                          _dropdown(
                            'Select Meeting Type',
                            Icons.groups_outlined,
                            _farmerMeetingType,
                            const ['Pre Meeting', 'Crop Show'],
                            (value) => _farmerMeetingType = value,
                          ),
                        _field(
                          'Customer details',
                          Icons.person_add_alt_1_outlined,
                          label: 'Add $_customerType Details',
                          readOnly: true,
                          onTap: _openDistributorDetails,
                        ),
                        _field(
                          'Meeting date',
                          Icons.calendar_today_outlined,
                          readOnly: true,
                          onTap: _pickDate,
                        ),
                        _field('Place of meeting', Icons.location_on_outlined),
                        _field(
                          'Objective of meeting',
                          Icons.flag_outlined,
                          label: 'Objective of Meeting',
                        ),
                      ],
                    ),
                    _section(
                      '02',
                      'Location & approval',
                      'Meeting area and budget approver',
                      [
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
                          onSelected: (location) => setState(
                            () => _locationIds['Block'] = location.id,
                          ),
                          onEdited: () =>
                              setState(() => _locationIds.remove('Block')),
                        ),
                        MeetingApproverSearch(
                          controller: _fields['Budget approved by']!,
                          options: _services.options,
                          onSelected: (option) => _approverId = option.id,
                          onEdited: () => _approverId = '',
                        ),
                      ],
                    ),
                    _section(
                      '03',
                      'Crop & season',
                      'Set the agricultural focus',
                      [
                        MeetingCropSearch(
                          crop: _fields['Crop']!,
                          subcategory: _fields['Product']!,
                          onChanged: (selection) {
                            _cropIds['categoryId'] = selection.cropId;
                            _cropIds['productIds'] = selection.productIds;
                            _cropIds['classIds'] = selection.classIds;
                          },
                        ),
                        _seasonPicker(),
                      ],
                    ),
                    _section(
                      '04',
                      'Planning & budget',
                      'Attendance, sales and meeting expenses',
                      [
                        _dropdown(
                          'Select Budget Type',
                          Icons.account_balance_wallet_outlined,
                          _budgetType,
                          const ['Budget Meeting', 'Non Budget Meeting'],
                          (value) => _budgetType = value,
                        ),
                        _field(
                          'Future sale plan quantity',
                          Icons.trending_up_rounded,
                          label: 'Future Sale Plan Qty',
                          number: true,
                        ),
                        _field(
                          'Total members attending',
                          Icons.groups_outlined,
                          label: 'Total Member Attend',
                          number: true,
                          integer: true,
                        ),
                        _field(
                          'Total meeting expenses',

                          Icons.currency_rupee_rounded,
                          label: 'Total Meeting Expenses Rs.',
                          number: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: InputDecorator(
                            decoration:
                                _decoration(
                                  'Cost Per Head Rs. *',
                                  Icons.currency_rupee_rounded,
                                ).copyWith(
                                  labelText: 'Cost Per Head Rs. *',
                                  hintText: null,
                                ),
                            child: Text(_costPerHead.toStringAsFixed(2)),
                          ),
                        ),
                        _field(
                          'Budget Sanction per head Rs.',
                          Icons.currency_rupee_rounded,
                          number: true,
                        ),
                        _meetingPhotoPicker(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
