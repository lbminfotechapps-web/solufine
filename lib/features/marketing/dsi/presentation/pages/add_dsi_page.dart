import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solufine/core/utility/image_compression.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/router/app_router.dart';

import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';

import '../../domain/entities/dsi_entity.dart';
import '../bloc/dsi_bloc.dart';
import '../widgets/dsi_widgets.dart';

class AddDsiPage extends StatefulWidget {
  const AddDsiPage({super.key});

  @override
  State<AddDsiPage> createState() => _AddDsiPageState();
}

class _AddDsiPageState extends State<AddDsiPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _saveTimeCtrl = TextEditingController();
  final _saveMoneyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _userId = '';
  String? _effectiveness;
  String? _photoPath;

  DateTime _date = DateTime.now();

  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      // Adjust this call only if your existing
      // SecureStorage exposes a different method.
      final user = await SecureStorage.instance.getUserData();

      if (!mounted) return;

      setState(() {
        _userId = user?['user_id']?.toString() ?? '';
      });
    } catch (e) {
      _showMessage('Unable to read logged-in user.');
    }
  }

  @override
  void dispose() {
    _saveTimeCtrl.dispose();
    _saveMoneyCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  // =====================================================
  // DATE PICKER
  // =====================================================

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (!mounted || selected == null) return;

    setState(() => _date = selected);
  }

  // =====================================================
  // CAMERA / GALLERY
  // =====================================================

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.cardBackgroundColor,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload DSI Photo',
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: context.primaryColor,
                ),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: context.primaryColor,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;

    final source = await _chooseImageSource();

    if (source == null || !mounted) return;

    setState(() => _pickingImage = true);

    try {
      final selected = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (!mounted || selected == null) return;

      final image = File(selected.path);

      if (!await image.exists()) {
        throw StateError('Selected image does not exist.');
      }

      final compressed = await ImageCompression.compressImage(image);

      if (!mounted) return;

      if (compressed == null || !await compressed.exists()) {
        throw StateError(
          'Unable to compress image. Please choose another photo.',
        );
      }

      if (!mounted) return;

      setState(() {
        _photoPath = compressed.path;
      });
    } catch (e) {
      _showMessage('Unable to select image: $e');
    } finally {
      if (mounted) {
        setState(() => _pickingImage = false);
      }
    }
  }

  // =====================================================
  // SUBMIT
  // =====================================================

  void _submit() {
    final bloc = context.read<DsiBloc>();

    if (bloc.state.submitting || _pickingImage) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_userId.isEmpty || _userId == '0') {
      _showMessage('Please log in again.');
      return;
    }

    if (_effectiveness == null) {
      _showMessage('Please select effectiveness.');
      return;
    }

    final entity = AddDsiEntity(
      userId: _userId,
      date: DateFormat('dd/MM/yyyy').format(_date),
      effectiveness: _effectiveness!,
      description: _descriptionCtrl.text.trim(),
      saveTime: _saveTimeCtrl.text.trim(),
      saveMoney: _saveMoneyCtrl.text.trim(),
      photoPath: _photoPath,
    );

    bloc.add(SubmitDsiEvent(entity));
  }

  // =====================================================
  // INPUT
  // =====================================================

  Widget _numericInput({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required int maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      style: TextStyle(fontSize: 13, color: context.primaryTextColor),
      decoration: InputDecoration(
        labelText: title,
        prefixIcon: Icon(icon, size: 19, color: context.primaryColor),
        isDense: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null;
        }

        if (int.tryParse(value) == null) {
          return 'Invalid value';
        }

        return null;
      },
    );
  }

  // =====================================================
  // PHOTO PREVIEW
  // =====================================================

  Widget _imagePickerCard() {
    return InkWell(
      onTap: _pickingImage ? null : _pickImage,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: 76,
                height: 72,
                color: context.primaryColor.withValues(alpha: .10),
                child: _photoPath == null
                    ? Icon(
                        Icons.add_photo_alternate_outlined,
                        color: context.primaryColor,
                        size: 30,
                      )
                    : Image.file(
                        File(_photoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _photoPath == null ? 'Add  Photo' : 'Photo Selected',
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _photoPath == null
                        ? 'Camera or Gallery (Optional)'
                        : 'Tap to change the photo',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            if (_photoPath != null)
              IconButton(
                tooltip: 'Remove photo',
                onPressed: () {
                  setState(() {
                    _photoPath = null;
                  });
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: context.appColors.error,
                ),
              )
            else
              Icon(Icons.add_circle_outline, color: context.primaryColor),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // MAIN BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DsiBloc, DsiState>(
      listenWhen: (previous, current) =>
          previous.success != current.success ||
          previous.error != current.error,

      listener: (context, state) {
        if (state.success != null) {
          _showMessage(state.success!);

          // Notify the DSI list to refresh.
          Navigator.of(context).pop(true);
        }

        if (state.error != null) {
          _showMessage(state.error!);
          context.read<DsiBloc>().add(const ClearDsiMessage());
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
            title: 'Add DSI',
            showBackButton: true,
            onBackTap: () => context.go(AppRouter.home),
          ),

          body: AbsorbPointer(
            absorbing: state.submitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  // HEADER

                  // const DsiSectionHeader(
                  //   title: 'DSI Details',
                  //   subtitle: 'Date and effectiveness',
                  //   icon: Icons.event_note_outlined,
                  // ),

                  // DATE
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DSI Date *',
                                  style: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_date),
                                  style: TextStyle(
                                    color: context.primaryTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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

                  const SizedBox(height: 11),

                  DropdownButtonFormField<String>(
                    dropdownColor: context.cardBackgroundColor,
                    style: TextStyle(color: context.cardTextColor),
                    iconEnabledColor: context.primaryColor,
                    isExpanded: true,
                    value: _effectiveness,
                    decoration: InputDecoration(
                      labelText: 'Effectiveness *',
                      prefixIcon: Icon(
                        Icons.tune_outlined,
                        color: context.primaryColor,
                      ),
                    ),
                    items: DsiEffectiveness.addOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(
                              option,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _effectiveness = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select effectiveness' : null,
                  ),

                  const DsiSectionHeader(
                    title: 'Measured Impact',
                    subtitle: 'How much time or money was saved?',
                    icon: Icons.trending_up_outlined,
                  ),

                  // TWO COLUMN LAYOUT
                  Row(
                    children: [
                      Expanded(
                        child: _numericInput(
                          title: 'Save Time (Min)',
                          controller: _saveTimeCtrl,
                          icon: Icons.timer_outlined,
                          maxLength: 5,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _numericInput(
                          title: 'Save Money (₹)',
                          controller: _saveMoneyCtrl,
                          icon: Icons.currency_rupee,
                          maxLength: 8,
                        ),
                      ),
                    ],
                  ),

                  const DsiSectionHeader(
                    title: 'Description *',
                    subtitle: 'Explain the improvement or outcome',
                    icon: Icons.description_outlined,
                  ),

                  TextFormField(
                    controller: _descriptionCtrl,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe the DSI activity, benefits and results...',
                      alignLabelWithHint: true,
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter DSI description';
                      }
                      return null;
                    },
                  ),

                  // const DsiSectionHeader(
                  //   title: 'Attachment',
                  //   subtitle: 'Add a photo as supporting evidence',
                  //   icon: Icons.add_photo_alternate_outlined,
                  // ),
                  _imagePickerCard(),
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
                  onPressed: state.submitting || _pickingImage ? null : _submit,
                  icon: state.submitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: context.onPrimaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    state.submitting ? 'Submitting DSI...' : 'Submit DSI',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
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
