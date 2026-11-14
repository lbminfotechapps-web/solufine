import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/image_compression.dart';
import 'package:intl/intl.dart';

import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';

import '../../domain/entities/field_visit_entity.dart';
import '../bloc/field_visit_bloc.dart';

class FieldVisitPage extends StatefulWidget {
  const FieldVisitPage({super.key});

  @override
  State<FieldVisitPage> createState() => _FieldVisitPageState();
}

class _FieldVisitPageState extends State<FieldVisitPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final Geocoding _geocoding = Geocoding();

  final _farmerCtrl = TextEditingController();
  final _visitWithCtrl = TextEditingController();
  final _packetsCtrl = TextEditingController();
  final _plotStatusCtrl = TextEditingController();
  final _suggestionCtrl = TextEditingController();

  Timer? _searchTimer;

  String _userId = '';
  String _reportingPersonId = '';
  String _farmerId = '';
  String? _activity;

  DateTime? _sowingDate;

  final Set<String> _cropIds = {};

  String? _plotImagePath;
  String? _visitorImagePath;

  bool _busy = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();

    _loadUser();

    context.read<FieldVisitBloc>().add(const LoadFieldVisitCrops());
  }

  Future<void> _loadUser() async {
    try {
      final data = await SecureStorage.instance.getUserData();

      if (!mounted) return;

      setState(() {
        _userId = data?['user_id']?.toString() ?? '';

        // Original Android code reads this separately
        // from SharedPreferences.
        _reportingPersonId = data?['strReportingPersonId']?.toString() ?? '';
      });
    } catch (e) {
      _message('Unable to load login information.');
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();

    _farmerCtrl.dispose();
    _visitWithCtrl.dispose();
    _packetsCtrl.dispose();
    _plotStatusCtrl.dispose();
    _suggestionCtrl.dispose();

    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ======================================================
  // FARMER SEARCH WITH 2 SECOND DEBOUNCE
  // ======================================================

  void _onFarmerSearch(String text) {
    _searchTimer?.cancel();

    setState(() => _farmerId = '');

    context.read<FieldVisitBloc>().add(const ClearFieldVisitFarmers());

    final search = text.trim();

    if (search.length < 3) return;

    _searchTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _farmerCtrl.text.trim() != search) {
        return;
      }

      context.read<FieldVisitBloc>().add(
        SearchFieldVisitFarmer(userId: _userId, searchText: search),
      );
    });
  }

  Widget _farmerPicker(FieldVisitState state) {
    return Column(
      children: [
        TextFormField(
          controller: _farmerCtrl,
          onChanged: _onFarmerSearch,
          decoration: InputDecoration(
            labelText: 'Search Farmer *',
            hintText: 'Search farmer name',
            helperText: 'Type at least 3 letters and wait 2 seconds',
            prefixIcon: Icon(
              Icons.person_search_outlined,
              color: context.primaryColor,
            ),
            suffixIcon: state.searchingFarmers
                ? Padding(
                    padding: const EdgeInsets.all(15),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.primaryColor,
                      ),
                    ),
                  )
                : _farmerId.isNotEmpty
                ? Icon(Icons.check_circle, color: context.primaryColor)
                : null,
          ),
          validator: (_) => _farmerId.isEmpty ? 'Please select a farmer' : null,
        ),

        if (_farmerId.isEmpty && state.farmers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5),
            constraints: const BoxConstraints(maxHeight: 190),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.farmers.length,
              itemBuilder: (context, index) {
                final farmer = state.farmers[index];

                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.person_outline,
                    color: context.primaryColor,
                  ),
                  title: Text(farmer.name),
                  subtitle: farmer.mobile.isEmpty ? null : Text(farmer.mobile),
                  onTap: () {
                    _searchTimer?.cancel();

                    setState(() {
                      _farmerId = farmer.id;
                      _farmerCtrl.text = farmer.name;
                    });

                    context.read<FieldVisitBloc>().add(
                      const ClearFieldVisitFarmers(),
                    );

                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // ======================================================
  // CROP AND VARIETY SELECTION
  // ======================================================

  Future<void> _openCropPicker(List<FieldVisitCrop> crops) async {
    if (crops.isEmpty) {
      _message('No crops available.');
      return;
    }
    final selected = Set<String>.from(_cropIds);
    String query = '';
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cardBackgroundColor,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) {
          final filtered = crops
              .where(
                (crop) => crop.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .65,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select Crops',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: context.cardTextColor,
                              ),
                            ),
                          ),
                          Text(
                            '${selected.length} selected',
                            style: TextStyle(color: context.secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        onChanged: (value) => updateSheet(() => query = value),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search crops',
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final crop = filtered[index];
                          return CheckboxListTile(
                            title: Text(crop.name),
                            activeColor: context.primaryColor,
                            checkColor: context.onPrimaryColor,
                            value: selected.contains(crop.id),
                            onChanged: (checked) => updateSheet(() {
                              if (checked == true) {
                                selected.add(crop.id);
                              } else {
                                selected.remove(crop.id);
                              }
                            }),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: context.onPrimaryColor,
                          ),
                          onPressed: selected.isEmpty
                              ? null
                              : () => Navigator.pop(sheetContext, true),
                          child: const Text('Confirm Crops'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _cropIds
          ..clear()
          ..addAll(selected);
      });
    }
  }

  Widget _cropField(FieldVisitState state) {
    final names = state.crops
        .where((c) => _cropIds.contains(c.id))
        .map((c) => c.name)
        .join(', ');

    return InkWell(
      onTap: state.loadingCrops ? null : () => _openCropPicker(state.crops),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.grass_outlined, color: context.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.loadingCrops
                    ? 'Loading crops...'
                    : names.isEmpty
                    ? 'Select Crops *'
                    : names,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: context.primaryTextColor),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: context.primaryColor),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // DATE PICKER
  // ======================================================

  Future<void> _selectSowingDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _sowingDate ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
    );

    if (selected != null && mounted) {
      setState(() => _sowingDate = selected);
    }
  }

  // ======================================================
  // IMAGE PICKER
  // ======================================================

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      showDragHandle: true,
      builder: (sheet) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Select Photo',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: context.primaryColor,
                ),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(sheet, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: context.primaryColor,
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(sheet, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(String type) async {
    if (_busy) return;

    final source = await _chooseImageSource();

    if (source == null || !mounted) return;

    setState(() => _busy = true);

    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );

      if (photo == null || !mounted) return;

      if (!await File(photo.path).exists()) {
        throw StateError('Image not found.');
      }

      final compressed = await ImageCompression.compressImage(File(photo.path));

      if (!mounted) return;

      if (compressed == null || !await compressed.exists()) {
        throw StateError(
          'Unable to compress image. Please choose another photo.',
        );
      }

      if (!mounted) return;

      setState(() {
        switch (type) {
          case 'plot':
            _plotImagePath = compressed.path;
            break;
          case 'visitor':
            _visitorImagePath = compressed.path;
            break;
        }
      });
    } catch (e) {
      _message('Unable to select photo: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _photoCard({
    required String title,
    required String type,
    required String? path,
    required IconData icon,
    bool requiredPhoto = false,
  }) {
    return _validatedSelection(
      validator: () => requiredPhoto && (path == null || path.isEmpty)
          ? 'Please select $title photo'
          : null,
      child: InkWell(
        onTap: _busy ? null : () => _pickPhoto(type),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 66,
                  height: 66,
                  color: context.primaryColor.withValues(alpha: .10),
                  child: path == null
                      ? Icon(icon, size: 27, color: context.primaryColor)
                      : Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title${requiredPhoto ? ' *' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      path == null
                          ? 'Tap to capture / select'
                          : 'Photo selected • Tap to change',
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              if (path == null)
                Icon(Icons.add_circle_outline, color: context.primaryColor)
              else
                IconButton(
                  icon: Icon(Icons.close, color: context.appColors.error),
                  onPressed: () {
                    setState(() {
                      switch (type) {
                        case 'plot':
                          _plotImagePath = null;
                          break;
                        case 'visitor':
                          _visitorImagePath = null;
                          break;
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // GPS LOCATION
  // ======================================================

  Future<Position> _getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw StateError('Please enable GPS/location services.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission is required.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      ),
    );

    if (position.latitude == 0 && position.longitude == 0) {
      throw StateError('Unable to obtain GPS location.');
    }

    return position;
  }

  Future<String> _resolveAddress(double latitude, double longitude) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) return '';

      final p = placemarks.first;

      return [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.postalCode,
        p.country,
      ].where((s) => s != null && s.trim().isNotEmpty).join(', ');
    } catch (_) {
      // A geocoding failure does not imply GPS failed.
      return '';
    }
  }

  // ======================================================
  // SUBMIT WITH GPS
  // ======================================================

  Future<void> _submit() async {
    final bloc = context.read<FieldVisitBloc>();

    if (bloc.state.submitting || _busy) return;

    FocusScope.of(context).unfocus();

    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    if (_userId.isEmpty) {
      _message('Please log in again.');
      return;
    }

    setState(() => _busy = true);

    try {
      final position = await _getCurrentLocation();

      final address = await _resolveAddress(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      final entity = FieldVisitEntity(
        userId: _userId,
        reportingPersonId: _reportingPersonId,
        visitWith: _visitWithCtrl.text.trim(),
        farmerId: _farmerId,
        packetSown: _packetsCtrl.text.trim(),
        sownDate: DateFormat('dd-MM-yyyy').format(_sowingDate!),
        plotStatus: _plotStatusCtrl.text.trim(),
        activity: _activity!,
        suggestion: _suggestionCtrl.text.trim(),
        cropIds: _cropIds.toList(),
        varietyIds: const [],
        latitude: position.latitude,
        longitude: position.longitude,
        geoAddress: address,
        plotImagePath: _plotImagePath!,
        visitorImagePath: _visitorImagePath!,
      );

      bloc.add(SubmitFieldVisitEvent(entity));
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // ======================================================
  // COMMON UI
  // ======================================================

  Widget _section(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 17, 0, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.primaryColor, size: 19),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _validatedSelection({
    required String? Function() validator,
    required Widget child,
  }) {
    return FormField<void>(
      validator: (_) => validator(),
      builder: (field) => InputDecorator(
        decoration: InputDecoration(
          errorText: field.errorText,
          errorMaxLines: 2,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        child: child,
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool optional = false,
    bool number = false,
    bool decimal = false,
    List<TextInputFormatter>? inputFormatters,
    int lines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : number
          ? TextInputType.number
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      inputFormatters: number
          ? [FilteringTextInputFormatter.digitsOnly]
          : decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : inputFormatters,
      decoration: InputDecoration(
        labelText: '$label${optional ? '' : ' *'}',
        isDense: true,
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (!optional && text.isEmpty) {
          return 'Please enter $label';
        }

        if (number &&
            text.isNotEmpty &&
            (int.tryParse(text) == null || int.parse(text) <= 0)) {
          return 'Enter valid $label';
        }

        if (decimal &&
            text.isNotEmpty &&
            (double.tryParse(text) == null || double.parse(text) < 0)) {
          return 'Enter valid $label';
        }

        return null;
      },
    );
  }

  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FieldVisitBloc, FieldVisitState>(
      listenWhen: (previous, current) =>
          previous.success != current.success ||
          previous.error != current.error,
      listener: (context, state) {
        if (state.success != null) {
          _message(state.success!);
          Navigator.of(context).pop(true);
        }

        if (state.error != null) {
          _message(state.error!);
          context.read<FieldVisitBloc>().add(const ClearFieldVisitMessage());
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
            title: 'Field Visit Form',

            showBackButton: true,
          ),
          // appBar: AppBar(
          //   title: const Text('Field Visit Form'),
          //   centerTitle: true,
          // ),
          body: AbsorbPointer(
            absorbing: state.submitting || _busy,
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.agriculture_outlined,
                          color: context.primaryColor,
                          size: 29,
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Field Visit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: context.primaryTextColor,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Farmer • Crop • Observation • Photos',
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

                  _section('Visit Information', Icons.groups_outlined),

                  _field(
                    label: 'Visit With',
                    controller: _visitWithCtrl,
                    lines: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _farmerPicker(state),

                  _section('Crop Information', Icons.grass_outlined),

                  _validatedSelection(
                    validator: () =>
                        _cropIds.isEmpty ? 'Please select crops' : null,
                    child: _cropField(state),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          label: 'Packets Sown',
                          controller: _packetsCtrl,
                          number: true,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _validatedSelection(
                          validator: () => _sowingDate == null
                              ? 'Please select Sowing Date'
                              : null,
                          child: InkWell(
                            onTap: _selectSowingDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Sowing Date *',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                              child: Text(
                                _sowingDate == null
                                    ? 'Select date'
                                    : DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(_sowingDate!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.primaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  _section('Field Observation', Icons.fact_check_outlined),

                  _field(label: 'Plot Status', controller: _plotStatusCtrl),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    dropdownColor: context.cardBackgroundColor,
                    style: TextStyle(color: context.cardTextColor),
                    iconEnabledColor: context.primaryColor,
                    isExpanded: true,
                    value: _activity,
                    decoration: InputDecoration(
                      labelText: 'Activity *',
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: context.primaryColor,
                      ),
                    ),
                    items: FieldVisitActivities.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _activity = value);
                    },
                    validator: (value) =>
                        value == null ? 'Please select activity' : null,
                  ),

                  const SizedBox(height: 10),

                  _field(
                    label: 'Suggestion',
                    controller: _suggestionCtrl,
                    optional: true,
                    lines: 3,
                  ),

                  _section('Field Photos', Icons.photo_camera_outlined),

                  _photoCard(
                    title: 'Visitor Within Field',
                    type: 'visitor',
                    path: _visitorImagePath,
                    icon: Icons.people_outline,
                    requiredPhoto: true,
                  ),

                  const SizedBox(height: 9),

                  _photoCard(
                    title: 'Image of Plot',
                    type: 'plot',
                    path: _plotImagePath,
                    icon: Icons.landscape_outlined,
                    requiredPhoto: true,
                  ),

                  const SizedBox(height: 10),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: context.primaryColor,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'GPS location will be captured '
                            'automatically when submitting.',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.primaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.onPrimaryColor,
                  ),
                  onPressed: state.submitting || _busy ? null : _submit,
                  icon: state.submitting || _busy
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.onPrimaryColor,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    state.submitting
                        ? 'Submitting Field Visit...'
                        : _busy
                        ? 'Getting GPS Location...'
                        : 'Submit Field Visit',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
