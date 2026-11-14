import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/router/app_router.dart';

import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';

import '../../domain/entities/success_story_entity.dart';
import '../bloc/success_story_bloc.dart';
import '../widgets/success_story_video_editor.dart';

class SuccessStoryPage extends StatefulWidget {
  const SuccessStoryPage({super.key});

  @override
  State<SuccessStoryPage> createState() => _SuccessStoryPageState();
}

class _SuccessStoryPageState extends State<SuccessStoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _farmerCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _alternateCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _acreageCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _cropStageCtrl = TextEditingController();
  final _employeeCtrl = TextEditingController();

  Timer? _farmerTimer;

  String _userId = '';
  String _farmerId = '';

  final Set<String> _selectedCropIds = {};

  DateTime _selectedDate = DateTime.now();

  // Holds ONLY the exported, trimmed and compressed file.
  String? _finalVideoPath;
  bool _videoBusy = false;

  @override
  void initState() {
    super.initState();

    _loadUser();

    context.read<SuccessStoryBloc>().add(const LoadSuccessStoryCrops());
  }

  Future<void> _loadUser() async {
    try {
      final data = await SecureStorage.instance.getUserData();

      if (!mounted) return;

      setState(() {
        _userId = data?['user_id']?.toString() ?? '';
      });
    } catch (e) {
      _message('Unable to load user information.');
    }
  }

  @override
  void dispose() {
    _farmerTimer?.cancel();

    _farmerCtrl.dispose();
    _mobileCtrl.dispose();
    _alternateCtrl.dispose();
    _addressCtrl.dispose();
    _acreageCtrl.dispose();
    _productCtrl.dispose();
    _cropStageCtrl.dispose();
    _employeeCtrl.dispose();

    super.dispose();
  }

  void _message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
      );
  }

  // ======================================================
  // FARMER SEARCH
  // ======================================================

  void _onFarmerChanged(String value) {
    _farmerTimer?.cancel();

    setState(() {
      _farmerId = '';
      _mobileCtrl.clear();
      _addressCtrl.clear();
    });

    context.read<SuccessStoryBloc>().add(const ClearSuccessStoryFarmers());

    final text = value.trim();

    if (text.length < 3) return;

    _farmerTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _userId.isEmpty || _farmerCtrl.text.trim() != text) {
        return;
      }

      context.read<SuccessStoryBloc>().add(
        SearchSuccessStoryFarmer(userId: _userId, searchText: text),
      );
    });
  }

  Widget _farmerField(SuccessStoryState state) {
    return Column(
      children: [
        TextFormField(
          controller: _farmerCtrl,
          onChanged: _onFarmerChanged,
          decoration: InputDecoration(
            labelText: 'Farmer Name / Mobile No. *',
            hintText: 'Search at least 3 characters',
            prefixIcon: Icon(
              Icons.person_search_outlined,
              color: context.primaryColor,
            ),
            suffixIcon: state.searchingFarmers
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _farmerId.isNotEmpty
                ? Icon(Icons.check_circle, color: context.primaryColor)
                : null,
          ),
          validator: (_) => _farmerId.isEmpty ? 'Select farmer' : null,
        ),

        if (_farmerId.isEmpty &&
            state.farmers.isNotEmpty &&
            _farmerCtrl.text.trim().length >= 3)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 180),
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
                  leading: CircleAvatar(
                    backgroundColor: context.primaryColor.withValues(
                      alpha: 0.10,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: context.primaryColor,
                    ),
                  ),
                  title: Text(farmer.name),
                  subtitle: Text(farmer.mobile),
                  onTap: () {
                    _farmerTimer?.cancel();

                    setState(() {
                      _farmerId = farmer.id;
                      _farmerCtrl.text = farmer.name;
                      _mobileCtrl.text = farmer.mobile;
                      _addressCtrl.text = farmer.address;
                    });

                    context.read<SuccessStoryBloc>().add(
                      const ClearSuccessStoryFarmers(),
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
  // CROP MULTI-SELECT
  // ======================================================

  Future<void> _pickCrops(List<SuccessStoryCrop> crops) async {
    if (crops.isEmpty) {
      _message('No crops available.');
      return;
    }

    final selected = Set<String>.from(_selectedCropIds);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cardBackgroundColor,
      builder: (sheet) => StatefulBuilder(
        builder: (context, updateSheet) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .65,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Crops',
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${selected.length} crops selected',
                      style: TextStyle(color: context.secondaryTextColor),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: crops.length,
                        itemBuilder: (context, index) {
                          final crop = crops[index];

                          return CheckboxListTile(
                            dense: true,
                            activeColor: context.primaryColor,
                            title: Text(crop.name),
                            value: selected.contains(crop.id),
                            onChanged: (value) {
                              updateSheet(() {
                                if (value == true) {
                                  selected.add(crop.id);
                                } else {
                                  selected.remove(crop.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheet, true),
                        child: const Text('Confirm Crops'),
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
        _selectedCropIds
          ..clear()
          ..addAll(selected);
      });
    }
  }

  Widget _cropField(SuccessStoryState state) {
    final selectedNames = state.crops
        .where((crop) => _selectedCropIds.contains(crop.id))
        .map((crop) => crop.name)
        .join(', ');

    return InkWell(
      onTap: state.loadingCrops ? null : () => _pickCrops(state.crops),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.grass_outlined, color: context.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.loadingCrops
                    ? 'Loading crops...'
                    : selectedNames.isEmpty
                    ? 'Select Crops *'
                    : selectedNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
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

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected != null && mounted) {
      setState(() => _selectedDate = selected);
    }
  }

  // ======================================================
  // REUSABLE UI
  // ======================================================

  Widget _section(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: context.primaryColor, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool optional = false,
    bool mobile = false,
    bool decimal = false,
    int lines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      keyboardType: mobile
          ? TextInputType.phone
          : decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      inputFormatters: mobile
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      decoration: InputDecoration(
        labelText: '$label${optional ? '' : ' *'}',
        isDense: true,
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (!optional && text.isEmpty) {
          return 'Please enter $label';
        }

        if (mobile &&
            text.isNotEmpty &&
            !RegExp(r'^[1-9][0-9]{9}$').hasMatch(text)) {
          return 'Enter valid mobile number';
        }

        if (decimal && text.isNotEmpty) {
          final value = double.tryParse(text);

          if (value == null || !value.isFinite || value <= 0) {
            return 'Enter valid acreage';
          }
        }

        return null;
      },
    );
  }

  // ======================================================
  // SUBMIT EXPORTED VIDEO
  // ======================================================

  Future<void> _submit() async {
    final bloc = context.read<SuccessStoryBloc>();

    if (bloc.state.submitting || _videoBusy) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_userId.isEmpty || _userId == '0') {
      _message('Please log in again.');
      return;
    }

    if (_farmerId.isEmpty) {
      _message('Please select farmer.');
      return;
    }

    if (_selectedCropIds.isEmpty) {
      _message('Please select crops.');
      return;
    }

    if (_finalVideoPath == null) {
      _message('Please select, trim and compress the video.');
      return;
    }

    if (!await File(_finalVideoPath!).exists()) {
      _message('Exported video file not found.');
      return;
    }

    if (!mounted) return;

    final story = SuccessStoryEntity(
      userId: _userId,
      farmerId: _farmerId,
      mobileNo: _mobileCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      cropIds: _selectedCropIds.toList(),
      cropAcrage: _acreageCtrl.text.trim(),
      usedProduct: _productCtrl.text.trim(),
      cropStage: _cropStageCtrl.text.trim(),
      alternateMobileNo: _alternateCtrl.text.trim(),
      employeeNameHq: _employeeCtrl.text.trim(),
      videoPath: _finalVideoPath,
    );

    bloc.add(SubmitSuccessStoryEvent(story));
  }

  // ======================================================
  // MAIN PAGE
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SuccessStoryBloc, SuccessStoryState>(
      listenWhen: (previous, current) =>
          previous.success != current.success ||
          previous.error != current.error,
      listener: (context, state) {
        if (state.success != null) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialog) => AlertDialog(
              title: const Text('Success Story Submitted'),
              content: Text(state.success!),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialog);
                    Navigator.of(context).maybePop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        if (state.error != null) {
          _message(state.error!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.backgroundColor,

          // APP BAR
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
            title: 'Success Story',
            showBackButton: true,
            onBackTap: () => context.go(AppRouter.home),
          ),

          body: AbsorbPointer(
            absorbing: state.submitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          color: context.primaryColor,
                          size: 29,
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Farmer Success Story',
                                style: TextStyle(
                                  color: context.primaryTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Farmer details • Crops • Video',
                                style: TextStyle(
                                  color: context.secondaryTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _section('Farmer Information', Icons.person_outline),

                  _farmerField(state),

                  const SizedBox(height: 11),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: 'Mobile No.',
                          controller: _mobileCtrl,
                          mobile: true,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _field(
                          label: 'Alternate Mobile',
                          controller: _alternateCtrl,
                          mobile: true,
                          optional: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _field(label: 'Address', controller: _addressCtrl, lines: 2),

                  _section('Crop Details', Icons.grass_outlined),

                  _cropField(state),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: 'Crop Acreage',
                          controller: _acreageCtrl,
                          decimal: true,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _field(
                          label: 'Crop Stage',
                          controller: _cropStageCtrl,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _field(label: 'Used Product', controller: _productCtrl),

                  _section('Video Trim & Compress', Icons.content_cut),

                  SuccessStoryVideoEditor(
                    uploadInProgress: state.submitting,
                    onBusyChanged: (busy) {
                      if (mounted) {
                        setState(() => _videoBusy = busy);
                      }
                    },
                    onExportChanged: (path) {
                      if (mounted) {
                        setState(() => _finalVideoPath = path);
                      }
                    },
                  ),

                  _section('Employee & Date', Icons.badge_outlined),

                  _field(
                    label: 'Employee / HQ Name',
                    controller: _employeeCtrl,
                  ),

                  const SizedBox(height: 10),

                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cardBackgroundColor,
                        border: Border.all(color: context.borderColor),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: context.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(_selectedDate),
                              style: TextStyle(
                                color: context.primaryTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: context.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FIXED SUBMIT BUTTON
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
                  onPressed: state.submitting || _videoBusy ? null : _submit,
                  icon: state.submitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: context.onPrimaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    state.submitting
                        ? 'Uploading...'
                        : _videoBusy
                        ? 'Processing Video...'
                        : 'Submit Success Story',
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
