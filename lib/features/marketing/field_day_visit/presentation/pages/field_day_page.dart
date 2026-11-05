import 'package:solufine/core/utility/image_compression.dart';
import 'package:go_router/go_router.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';

import '../../domain/entities/field_day_entry.dart';
import '../bloc/field_day_bloc.dart';

class FieldDayPage extends StatefulWidget {
  const FieldDayPage({super.key});

  @override
  State<FieldDayPage> createState() => _FieldDayPageState();
}

class _FieldDayPageState extends State<FieldDayPage> {
 
  // ============================================================
  // FORM & CONTROLLERS
  // ============================================================

  final _formKey = GlobalKey<FormState>();
  bool _hasAttemptedSubmit = false;
  final _picker = ImagePicker();

  final Map<String, TextEditingController> c = {
    for (final key in [
      'activityName',
      'farmerParticipants',
      'dealerParticipants',
      'retailerParticipants',
      'meetingPlace',
      'meetingObjective',
      'attendedStaff',
      'officerName',
      'farmerOpinion',
      'packetBookedCount',
      'vehicleCharges',
      'snacks',
      'tentCharges',
      'hotelAmount',
      'miscAmount',
      'kmReading',
      'manualDistance',
      'expectedOutcome',
    ])
      key: TextEditingController(),
  };

  final Map<String, String> _expenseImages = {};
  final List<String> _pictures = [];
  final _farmerSearch = TextEditingController();

  Timer? _debounce;

  String _farmerId = '';
  String _farmerName = '';
  String _userId = '';

  bool _showTravel = false;
  bool _picking = false;

  int _searchVersion = 0;

  static const expenseLabels = {
    'vehicleCharges': 'Vehicle Hired Charges',
    'snacks': 'Snacks & Food Charges',
    'tentCharges': 'Tent Charges Charges',
    'hotelAmount': 'Hotel Charges',
    'miscAmount': 'Miscellaneous Charges',
  };

  static const expenseKeys = {
    'vehicleCharges': 'vehicle',
    'snacks': 'snacks',
    'tentCharges': 'tent',
    'hotelAmount': 'hotel',
    'miscAmount': 'misc',
  };

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadUser();

    for (final key in expenseLabels.keys) {
      c[key]!.addListener(_refreshTotal);
    }
  }

  Future<void> _loadUser() async {
    final data = await SecureStorage.instance.getUserData();

    if (mounted) {
      setState(() {
        _userId = data?['user_id']?.toString() ?? '';
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _farmerSearch.dispose();

    for (final controller in c.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _refreshTotal() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // TOTAL EXPENSE CALCULATION
  // ============================================================

  double get _total {
    return expenseLabels.keys.fold<double>(
      0,
      (sum, key) => sum + (double.tryParse(c[key]!.text) ?? 0),
    );
  }

  String _txt(String key) => c[key]!.text.trim();

  void _toast(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // FARMER SEARCH
  // ============================================================

  void _searchChanged(String value) {
    _debounce?.cancel();

    _farmerId = '';
    _farmerName = '';
    context.read<FieldDayBloc>().add(SearchFarmersEvent(_userId, ''));

    final version = ++_searchVersion;

    if (value.trim().length < 3) {
      setState(() {});
      return;
    }

    _debounce = Timer(Duration(milliseconds: 350), () {
      if (!mounted || version != _searchVersion || _userId.isEmpty) {
        return;
      }

      context.read<FieldDayBloc>().add(
        SearchFarmersEvent(_userId, value.trim()),
      );
    });

    setState(() {});
  }

  // ============================================================
  // CAMERA / GALLERY SOURCE
  // ============================================================

  Future<ImageSource?> _source() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: context.primaryColor,
                ),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(sheet, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: context.primaryColor,
                ),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(sheet, ImageSource.gallery);
                },
              ),
              SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SINGLE IMAGE PICKER
  // ============================================================

  Future<void> _pickOne(String key) async {
    if (_picking) return;

    final source = await _source();

    if (source == null || !mounted) return;

    setState(() => _picking = true);

    try {
      final result = await _picker.pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (result == null || !mounted) return;
      final compressed = await ImageCompression.compressImage(
        File(result.path),
      );
      if (!mounted) return;
      if (compressed == null || !await compressed.exists()) {
        if (mounted) {
          _toast('Could not compress the photo. Please select it again.');
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _expenseImages[key] = compressed.path;
      });
    } catch (e) {
      _toast('Could not select image: $e');
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  // ============================================================
  // MULTIPLE IMAGES - MAX 11
  // ============================================================

  Future<void> _pickMultiple() async {
    if (_picking || _pictures.length >= 11) return;

    setState(() => _picking = true);

    try {
      final items = await _picker.pickMultiImage(
        imageQuality: 72,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (!mounted) return;

      final remaining = 11 - _pictures.length;

      if (items.length > remaining) {
        _toast('Maximum 11 pictures allowed');
      }

      final compressedPaths = <String>[];
      var failedCount = 0;
      for (final item in items.take(remaining)) {
        final compressed = await ImageCompression.compressImage(
          File(item.path),
        );
        if (!mounted) return;
        if (compressed == null || !await compressed.exists()) {
          failedCount++;
          continue;
        }
        compressedPaths.add(compressed.path);
      }
      if (!mounted) return;
      setState(() {
        _pictures.addAll(compressedPaths);
      });
      if (failedCount > 0) {
        _toast(
          'Could not compress $failedCount photo(s). Please select them again.',
        );
      }
    } catch (e) {
      _toast('Unable to choose pictures: $e');
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  // ============================================================
  // SUBMIT FORM
  // ============================================================

  void _submit() {
    if (_userId.isEmpty || _userId == '0') {
      _toast('Please log in again');
      return;
    }

    setState(() => _hasAttemptedSubmit = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_farmerId.isEmpty) {
      _toast('Select farmer from search suggestions');
      return;
    }

    final entry = FieldDayEntry(
      userId: _userId,
      farmerId: _farmerId,
      activityName: _txt('activityName'),
      farmerParticipants: _txt('farmerParticipants'),
      dealerParticipants: _txt('dealerParticipants'),
      retailerParticipants: _txt('retailerParticipants'),
      meetingPlace: _txt('meetingPlace'),
      meetingObjective: _txt('meetingObjective'),
      attendedStaff: _txt('attendedStaff'),
      officerName: _txt('officerName'),
      farmerOpinion: _txt('farmerOpinion'),
      packetBookedCount: _txt('packetBookedCount'),
      vehicleCharges: _txt('vehicleCharges'),
      snacks: _txt('snacks'),
      tentCharges: _txt('tentCharges'),
      hotelAmount: _txt('hotelAmount'),
      miscAmount: _txt('miscAmount'),
      totalAmount: _total.toStringAsFixed(2),
      kmReading: _txt('kmReading'),
      manualDistance: _txt('manualDistance'),
      expectedOutcome: _txt('expectedOutcome'),
      expenseImages: Map.of(_expenseImages),
      pictures: List.of(_pictures),
    );

    context.read<FieldDayBloc>().add(SubmitFieldDayEvent(entry));
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _section(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 20, 1, 9),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: context.primaryColor.withValues(alpha: .1),
            child: Icon(icon, size: 18, color: context.primaryColor),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.primaryTextColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REUSABLE INPUT FIELD
  // ============================================================

  Widget _field(
    String key,
    String label, {
    String? hint,
    bool required = false,
    bool number = false,
    int lines = 1,
  }) {
    return TextFormField(
      controller: c[key],
      minLines: lines,
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      inputFormatters: number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: TextStyle(fontSize: 13, color: context.primaryTextColor),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.appTheme.inputBackground,
        labelText: '$label${required ? ' *' : ''}',
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.primaryColor, width: 1.5),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (required && text.isEmpty) {
          return 'Enter $label';
        }

        if (number && text.isNotEmpty) {
          final n = double.tryParse(text);

          if (n == null || n < 0) {
            return 'Enter valid $label';
          }

          if ([
                'farmerParticipants',
                'dealerParticipants',
                'retailerParticipants',
                'packetBookedCount',
                'attendedStaff',
                'expectedOutcome',
              ].contains(key) &&
              int.tryParse(text) == null) {
            return 'Enter a whole number';
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // EXPENSE ROW WITH PHOTO
  // ============================================================

  Widget _participantCountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: context.primaryColor,
                  size: 23,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participant Count',
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: context.borderColor),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  'farmerParticipants',
                  'Farmers',
                  number: true,
                  required: true,
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _field(
                  'dealerParticipants',
                  'Dealers',
                  number: true,
                  required: true,
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _field(
                  'retailerParticipants',
                  'Retailers',
                  number: true,
                  required: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _expenseRow(String field, String label) {
    final imageKey = expenseKeys[field]!;
    final path = _expenseImages[imageKey];

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(child: _field(field, label, number: true)),
          SizedBox(width: 8),
          InkWell(
            onTap: () => _pickOne(imageKey),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 58,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: context.appTheme.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: path == null
                  ? Icon(
                      Icons.add_a_photo_outlined,
                      color: context.primaryColor,
                    )
                  : Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.broken_image_outlined),
                    ),
            ),
          ),
          if (path != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _expenseImages.remove(imageKey);
                });
              },
              icon: Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // FARMER SEARCH AUTOCOMPLETE
  // ============================================================

  Widget _farmerPicker(FieldDayState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _farmerSearch,
          onChanged: _searchChanged,
          decoration: InputDecoration(
            labelText: 'Farmer Name *',
            hintText: 'Search 3+ letters',
            prefixIcon: Icon(Icons.search, color: context.primaryColor),
            suffixIcon: state.searching
                ? Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (_) =>
              _farmerId.isEmpty ? 'Select farmer from results' : null,
        ),

        if (state.farmers.isNotEmpty &&
            _farmerId.isEmpty &&
            _farmerSearch.text.length >= 3)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: BoxConstraints(maxHeight: 170),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.farmers.length,
              itemBuilder: (context, index) {
                final farmer = state.farmers[index];

                return ListTile(
                  dense: true,
                  title: Text(
                    farmer.mobileNo.isEmpty
                        ? farmer.name
                        : '${farmer.name} - ${farmer.mobileNo}',
                  ),
                  subtitle: Text(
                    farmer.talukaName.isEmpty
                        ? 'ID: ${farmer.id}'
                        : 'Taluka: ${farmer.talukaName}',
                  ),
                  onTap: () {
                    _debounce?.cancel();
                    _searchVersion++;

                    _farmerId = farmer.id;
                    _farmerName = farmer.name;
                    _farmerSearch.text = farmer.name;

                    FocusScope.of(context).unfocus();

                    setState(() {});
                  },
                );
              },
            ),
          ),

        if (_farmerId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              'Selected: $_farmerName (#$_farmerId)',
              style: TextStyle(
                color: context.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FieldDayBloc, FieldDayState>(
      listenWhen: (previous, next) =>
          previous.success != next.success || previous.error != next.error,

      listener: (context, state) {
        if (state.success != null) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text('Field Day Saved'),
                content: Text(state.success!),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.of(context).maybePop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else if (state.error != null) {
          _toast(state.error!);
        }
      },

      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.backgroundColor,

          appBar: CustomAppBar(
            backgroundColor: context.primaryColor,
            titleStyle: AppTextStyles.appBarTitle.copyWith(
              color: context.onPrimaryColor,
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: context.onPrimaryColor,
              ),
              onPressed: () => context.go(AppRouter.home),
            ),
            title: 'Field Day Visit',
            showBackButton: true,
            onBackTap: () => context.go(AppRouter.home),
          ),

          // ====================================================
          // FIXED SUBMIT BUTTON
          // ====================================================
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 9, 13, 9),
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: SizedBox(
                height: 49,
                child: FilledButton.icon(
                  onPressed: state.submitting || _picking ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.onPrimaryColor,
                  ),
                  icon: state.submitting
                      ? SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.onPrimaryColor,
                          ),
                        )
                      : Icon(Icons.check_circle_outline),
                  label: Text(
                    state.submitting ? 'Submitting...' : 'Submit Field Day',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),

          // ====================================================
          // FORM BODY
          // ====================================================
          body: AbsorbPointer(
            absorbing: state.submitting,
            child: Form(
              key: _formKey,
              autovalidateMode: _hasAttemptedSubmit
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 22),
                children: [
                  // HERO HEADER
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          color: context.primaryColor,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Field Day Program',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: context.primaryTextColor,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Activity • Attendance • Expenses • Photos',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================================================
                  // PROGRAM DETAILS
                  // =================================================
                  // _section(
                  //   'Program Details',
                  //   'Activity and selected farmer',
                  //   Icons.grass_outlined,
                  // ),
                  SizedBox(height: 9),

                  _field('activityName', 'Activity Done', required: true),

                  SizedBox(height: 9),

                  _farmerPicker(state),

                  SizedBox(height: 9),

                  _participantCountCard(),

                  // =================================================
                  // MEETING INFORMATION
                  // =================================================
                  _section(
                    'Meeting Information',
                    'Place, objective and staff attendance',
                    Icons.groups_2_outlined,
                  ),

                  _field('meetingPlace', 'Meeting Place', required: true),

                  SizedBox(height: 9),

                  _field(
                    'meetingObjective',
                    'Meeting Objective',
                    required: true,
                    lines: 2,
                  ),

                  SizedBox(height: 9),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'attendedStaff',
                          'Office Staff Count',
                          number: true,
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _field(
                          'officerName',
                          'Officer Name',
                          required: true,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 9),

                  _field('farmerOpinion', 'Farmer / Dealer Opinion', lines: 2),

                  SizedBox(height: 9),

                  _field(
                    'packetBookedCount',
                    'Packets Booked in Scheme',
                    required: true,
                    number: true,
                  ),

                  SizedBox(height: 9),

                  _field('expectedOutcome', 'Expected Outcome', number: true),

                  // =================================================
                  // EXPENSE DETAILS
                  // =================================================
                  _section(
                    'Expense Details',
                    'Enter amount and attach proof per expense',
                    Icons.receipt_long_outlined,
                  ),

                  for (final expense in expenseLabels.entries)
                    _expenseRow(expense.key, expense.value),

                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total Expenses',
                            style: TextStyle(
                              color: context.onPrimaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '₹${NumberFormat('#,##0.00').format(_total)}',
                          style: TextStyle(
                            color: context.onPrimaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  // =================================================
                  // OPTIONAL KM DETAILS
                  // =================================================

                  // =================================================
                  // EVENT PHOTOS
                  // =================================================
                  _section(
                    'Event Photos',
                    'Attach up to 11 event photos / bills',
                    Icons.photo_library_outlined,
                  ),

                  OutlinedButton.icon(
                    onPressed: _pictures.length >= 11 ? null : _pickMultiple,
                    icon: Icon(Icons.add_photo_alternate_outlined),
                    label: Text('Add Photos (${_pictures.length}/11)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      minimumSize: Size(double.infinity, 44),
                    ),
                  ),

                  if (_pictures.isNotEmpty) ...[
                    SizedBox(height: 8),

                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _pictures.length,
                        separatorBuilder: (_, __) => SizedBox(width: 7),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_pictures[index]),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _pictures.removeAt(index);
                                    });
                                  },
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: context.appColors.scrim
                                        .withValues(alpha: 0.85),
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: context.onPrimaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  SizedBox(height: 10),

                  Text(
                    'Only selected images are uploaded. '
                    'Empty expense amounts are sent as empty strings. '
                    'Total expense is calculated automatically.',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
