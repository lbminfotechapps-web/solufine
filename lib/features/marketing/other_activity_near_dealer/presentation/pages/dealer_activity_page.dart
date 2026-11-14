import 'package:solufine/core/utility/image_compression.dart';
import 'dart:io';
import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/features/place_order/domain/entities/dealer_entity.dart';
import 'package:solufine/features/place_order/domain/usecases/get_dealers_usecase.dart';
import 'package:solufine/features/place_order/presentation/widgets/dealer_search_field.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:solufine/core/secure_storage/secure_storage.dart';

import '../../domain/entities/dealer_activity.dart';
import '../bloc/dealer_activity_bloc.dart';

class DealerActivityPage extends StatefulWidget {
  const DealerActivityPage({super.key});

  @override
  State<DealerActivityPage> createState() => _DealerActivityPageState();
}

class _DealerActivityPageState extends State<DealerActivityPage> {
  // ============================================================
  // COLORS
  // ============================================================

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _shopNameController = TextEditingController();

  final TextEditingController _workDetailsController = TextEditingController();

  final TextEditingController _discussionController = TextEditingController();

  final TextEditingController _workDoneController = TextEditingController();

  final TextEditingController _outputController = TextEditingController();

  final TextEditingController _kmReadingController = TextEditingController();

  final TextEditingController _manualDistanceController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // VARIABLES
  // ============================================================

  String _outletType = 'Dealer';
  DealerEntity? _selectedDealer;
  List<DealerEntity> _dealers = [];
  Timer? _dealerSearchTimer;
  int _dealerSearchVersion = 0;
  bool _dealerSearchLoading = false;
  String? _dealerSearchMessage;

  void _searchDealer(String value) {
    _dealerSearchTimer?.cancel();
    final version = ++_dealerSearchVersion;
    final query = value.trim();
    setState(() {
      _selectedDealer = null;
      _dealers = [];
      _dealerSearchLoading = query.isNotEmpty;
      _dealerSearchMessage = null;
    });
    if (query.isEmpty) return;
    _dealerSearchTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final userData = await SecureStorage.instance.getUserData();
        if (!mounted || version != _dealerSearchVersion) return;
        final userId = int.tryParse(userData?['user_id']?.toString() ?? '');
        if (userId == null || userId == 0) {
          throw Exception('Please log in again.');
        }
        final dealers = await GetIt.instance<GetDealersUseCase>()(
          userId: userId,
          searchText: query,
        );
        if (!mounted || version != _dealerSearchVersion) return;
        setState(() {
          _dealers = dealers;
          _dealerSearchLoading = false;
          _dealerSearchMessage = dealers.isEmpty ? 'No dealers found.' : null;
        });
      } catch (_) {
        if (!mounted || version != _dealerSearchVersion) return;
        setState(() {
          _dealerSearchLoading = false;
          _dealerSearchMessage = 'Unable to search dealers. Please try again.';
        });
      }
    });
  }

  void _selectDealer(DealerEntity dealer) {
    _dealerSearchTimer?.cancel();
    ++_dealerSearchVersion;
    setState(() {
      _selectedDealer = dealer;
      _shopNameController.text = dealer.name;
      _dealers = [];
      _dealerSearchLoading = false;
      _dealerSearchMessage = null;
    });
    FocusScope.of(context).unfocus();
  }

  File? _dealerProofImage;
  File? _shopBoardImage;

  bool _isPickingImage = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _dealerSearchTimer?.cancel();
    ++_dealerSearchVersion;
    _shopNameController.dispose();
    _workDetailsController.dispose();
    _discussionController.dispose();
    _workDoneController.dispose();
    _outputController.dispose();
    _kmReadingController.dispose();
    _manualDistanceController.dispose();

    super.dispose();
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  // ============================================================
  // IMAGE SOURCE DIALOG
  // ============================================================

  Future<void> _selectImage({required bool isShopBoard}) async {
    if (_isPickingImage) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  isShopBoard
                      ? 'Shop Board Image'
                      : 'Dealer / Distributor Proof',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.primaryTextColor,
                  ),
                ),

                const SizedBox(height: 14),

                ListTile(
                  leading: Icon(
                    Icons.camera_alt_outlined,
                    color: context.primaryColor,
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Capture using camera'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),

                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: context.primaryColor,
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select existing image'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    setState(() => _isPickingImage = true);

    try {
      final XFile? selected = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (selected == null || !mounted) return;

      final file = File(selected.path);

      if (!await file.exists()) {
        if (mounted) {
          _showMessage('Selected image not found.');
        }
        return;
      }

      if (!mounted) return;

      final compressed = await ImageCompression.compressImage(file);
      if (!mounted) return;
      if (compressed == null || !await compressed.exists()) {
        if (mounted) {
          _showMessage('Could not compress the photo. Please select it again.');
        }
        return;
      }
      if (!mounted) return;

      setState(() {
        if (isShopBoard) {
          _shopBoardImage = compressed;
        } else {
          _dealerProofImage = compressed;
        }
      });
    } catch (e) {
      if (mounted) {
        _showMessage('Image selection failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  // ============================================================
  // SUBMIT DATA TO BLOC
  // ============================================================

  Future<void> _submitActivity() async {
    final currentStatus = context.read<DealerActivityBloc>().state.status;

    if (currentStatus == DealerActivityStatus.submitting || _isPickingImage) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final shopId = _selectedDealer?.id ?? '';

    if (shopId.isEmpty || shopId == '0') {
      _showMessage('Please select dealer or distributor.');
      return;
    }

    if (_dealerProofImage == null) {
      _showMessage('Please capture dealer/distributor proof image.');
      return;
    }

    if (_shopBoardImage == null) {
      _showMessage('Please capture shop board image.');
      return;
    }

    final userData = await SecureStorage.instance.getUserData();

    if (!mounted) return;

    final String userId = userData?['user_id']?.toString() ?? '';

    if (userId.isEmpty || userId == '0') {
      _showMessage('Please log in again.');
      return;
    }

    final activity = DealerActivity(
      loginUserId: userId,

      // strShopId in your Java API.
      shopId: shopId,

      // These are local form values.
      shopName: _shopNameController.text.trim(),
      outletType: _outletType,

      workDetails: _workDetailsController.text.trim(),

      discussionAbout: _discussionController.text.trim(),

      workDone: _workDoneController.text.trim(),

      output: _outputController.text.trim(),

      kmReading: _kmReadingController.text.trim(),

      manualDistance: _manualDistanceController.text.trim(),

      // Multipart files:
      // uploadImage2
      dealerImagePath: _dealerProofImage!.path,

      // uploadImage3
      shopBoardImagePath: _shopBoardImage!.path,
    );

    context.read<DealerActivityBloc>().add(SubmitActivityEvent(activity));
  }

  // ============================================================
  // RESET FORM
  // ============================================================

  void _resetForm() {
    _formKey.currentState?.reset();

    _dealerSearchTimer?.cancel();
    ++_dealerSearchVersion;
    _shopNameController.clear();
    _workDetailsController.clear();
    _discussionController.clear();
    _workDoneController.clear();
    _outputController.clear();
    _kmReadingController.clear();
    _manualDistanceController.clear();

    setState(() {
      _selectedDealer = null;
      _dealers = [];
      _dealerSearchLoading = false;
      _dealerSearchMessage = null;
      _outletType = 'Dealer';
      _dealerProofImage = null;
      _shopBoardImage = null;
    });
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader(String title, IconData icon, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 7, bottom: 12),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: context.primaryColor, size: 18),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 10,
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
  // OUTLET TYPE
  // ============================================================

  Widget _outletTypeTile(String type, IconData icon) {
    final selected = _outletType == type;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _outletType = type;

            // Clear old selection when outlet type changes.
            _dealerSearchTimer?.cancel();
            ++_dealerSearchVersion;
            _shopNameController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? context.primaryColor
                : context.appTheme.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? context.primaryColor : context.borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? context.onPrimaryColor
                    : context.secondaryTextColor,
              ),

              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  type,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? context.onPrimaryColor
                        : context.primaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _inputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    bool requiredField = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType:
          keyboardType ??
          (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      inputFormatters: inputFormatters,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: context.primaryTextColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 36 : 0),
          child: Icon(icon, size: 19, color: context.primaryColor),
        ),
        labelStyle: TextStyle(color: context.secondaryTextColor, fontSize: 12),
        hintStyle: TextStyle(color: context.secondaryTextColor, fontSize: 11),
        filled: true,
        fillColor: context.appTheme.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.primaryColor, width: 1.4),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (requiredField && text.isEmpty) {
          return 'Please enter $label';
        }

        if (keyboardType ==
                const TextInputType.numberWithOptions(decimal: true) &&
            text.isNotEmpty) {
          final number = double.tryParse(text);

          if (number == null || number < 0) {
            return 'Enter a valid $label';
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // IMAGE UPLOAD CARD
  // ============================================================

  Widget _imageUploadCard({
    required String title,
    required String subtitle,
    required File? image,
    required bool isShopBoard,
    required IconData icon,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          _selectImage(isShopBoard: isShopBoard);
        },
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 158,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.appTheme.inputBackground,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: image != null
                  ? context.primaryColor.withValues(alpha: 0.5)
                  : context.borderColor,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image != null)
                      Image.file(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            Icons.broken_image_outlined,
                            color: context.secondaryTextColor,
                          );
                        },
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 43,
                            width: 43,
                            decoration: BoxDecoration(
                              color: context.primaryColor.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: context.primaryColor,
                              size: 23,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),

                    if (image != null)
                      Positioned(
                        right: 7,
                        top: 7,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: context.primaryColor,
                          child: Icon(
                            Icons.check,
                            color: context.onPrimaryColor,
                            size: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                color: context.cardBackgroundColor,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    Icon(
                      image == null
                          ? Icons.add_circle_outline
                          : Icons.edit_outlined,
                      size: 17,
                      color: context.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORM BODY
  // ============================================================

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 25),
        children: [
          // INTRODUCTION
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_turned_in_outlined,
                  color: context.primaryColor,
                  size: 27,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Field Activity',
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Record dealer or distributor visit details',
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          // OUTLET INFORMATION
          _sectionHeader('Outlet Information', Icons.storefront_outlined),

          DealerSearchField(
            controller: _shopNameController,
            dealers: _dealers,
            selectedDealer: _selectedDealer,
            onChanged: _searchDealer,
            onDealerSelected: _selectDealer,
          ),
          if (_dealerSearchLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          if (_dealerSearchMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_dealerSearchMessage!),
            ),

          const SizedBox(height: 17),
          // ACTIVITY DETAILS
          _sectionHeader(
            'Activity Details',
            Icons.edit_note_outlined,
            subtitle: 'Add visit discussion and completed work',
          ),

          _inputField(
            label: 'Work Details',
            hint: 'Describe your visit activity',
            icon: Icons.description_outlined,
            controller: _workDetailsController,
            maxLines: 2,
          ),

          const SizedBox(height: 10),

          _inputField(
            label: 'Discussion About',
            hint: 'What did you discuss?',
            icon: Icons.forum_outlined,
            controller: _discussionController,
            maxLines: 2,
          ),

          const SizedBox(height: 10),

          _inputField(
            label: 'Work Done',
            hint: 'Enter completed activities',
            icon: Icons.task_alt_outlined,
            controller: _workDoneController,
            maxLines: 2,
          ),

          const SizedBox(height: 10),

          _inputField(
            label: 'Output',
            hint: 'Enter visit results or outcome',
            icon: Icons.insights_outlined,
            controller: _outputController,
            maxLines: 2,
          ),

          // const SizedBox(height: 17),

          // // TRAVEL DETAILS
          // _sectionHeader('Travel Details', Icons.route_outlined),

          // Row(
          //   children: [
          //     Expanded(
          //       child: _inputField(
          //         label: 'KM Reading',
          //         hint: 'e.g. 1250',
          //         icon: Icons.speed_outlined,
          //         controller: _kmReadingController,
          //         requiredField: false,
          //         keyboardType: const TextInputType.numberWithOptions(
          //           decimal: true,
          //         ),
          //         inputFormatters: [
          //           FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          //         ],
          //       ),
          //     ),

          //     const SizedBox(width: 10),

          //     Expanded(
          //       child: _inputField(
          //         label: 'Manual Distance',
          //         hint: 'e.g. 12.5',
          //         icon: Icons.alt_route_outlined,
          //         controller: _manualDistanceController,
          //         requiredField: false,
          //         keyboardType: const TextInputType.numberWithOptions(
          //           decimal: true,
          //         ),
          //         inputFormatters: [
          //           FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),

          const SizedBox(height: 17),

          // IMAGE PROOF
          _sectionHeader(
            'Photo Proof',
            Icons.add_a_photo_outlined,
            subtitle: 'Capture clear visit and shop board images',
          ),

          Row(
            children: [
              _imageUploadCard(
                title: 'Dealer / Distributor *',
                subtitle: 'Add proof image',
                image: _dealerProofImage,
                isShopBoard: false,
                icon: Icons.camera_alt_outlined,
              ),

              const SizedBox(width: 10),

              _imageUploadCard(
                title: 'Shop Board Image *',
                subtitle: 'Show shop name board',
                image: _shopBoardImage,
                isShopBoard: true,
                icon: Icons.storefront_outlined,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: context.secondaryTextColor,
                size: 14,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ensure the shop name board is clearly visible '
                  'in the second image.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: context.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DealerActivityBloc, DealerActivityState>(
      listener: (context, state) {
        if (state.status == DealerActivityStatus.success) {
          _showMessage(state.message);
          context.go(AppRouter.home);
          // Reset after successful API submission.
          // _resetForm();
        }

        if (state.status == DealerActivityStatus.failure) {
          _showMessage(state.message);
        }
      },
      builder: (context, state) {
        final submitting = state.status == DealerActivityStatus.submitting;

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
            title: 'Activity Near Dealer',

            showBackButton: true,

            actionIcon: Icons.refresh_rounded,

            onBackTap: () => context.go(AppRouter.home),

            onActionIconTap: _resetForm,
          ),

          // BODY
          body: AbsorbPointer(absorbing: submitting, child: _buildForm()),

          // FIXED SUBMIT BUTTON
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: submitting || _isPickingImage
                      ? null
                      : _submitActivity,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.onPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: submitting
                      ? SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            color: context.onPrimaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    submitting ? 'Submitting Activity...' : 'Submit Activity',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
