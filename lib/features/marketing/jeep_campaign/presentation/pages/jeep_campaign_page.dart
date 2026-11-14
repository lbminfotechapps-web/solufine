import 'package:solufine/core/utility/image_compression.dart';
import 'package:go_router/go_router.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/theme/app_theme_context.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';

import '../../domain/entities/jeep_campaign.dart';
import '../bloc/jeep_campaign_bloc.dart';

class JeepCampaignPage extends StatefulWidget {
  const JeepCampaignPage({super.key});

  @override
  State<JeepCampaignPage> createState() => _JeepCampaignPageState();
}

class _JeepCampaignPageState extends State<JeepCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _productController = TextEditingController();
  final _productFieldKey = GlobalKey<FormFieldState<String>>();
  final _promotionController = TextEditingController();
  final _rentController = TextEditingController();
  final _daysController = TextEditingController();

  final List<String> _imagesA = [];
  final List<String> _imagesB = [];
  final List<String> _imagesC1 = [];
  final List<String> _imagesC2 = [];

  String _productQuery = '';

  String _userId = '';
  String? _seasonId;
  String? _productId;
  String? _vehicleType;

  bool _picking = false;

  static const vehicles = ['TOTO', 'AUTO', 'CAR'];

  @override
  void initState() {
    super.initState();

    _rentController.addListener(_recalculate);
    _daysController.addListener(_recalculate);

    _loadUser();

    context.read<JeepCampaignBloc>().add(const LoadJeepSeasons());
    context.read<JeepCampaignBloc>().add(
      const SearchJeepProduct(seasonId: '', searchName: ''),
    );
  }

  Future<void> _loadUser() async {
    try {
      final data = await SecureStorage.instance.getUserData();

      if (!mounted) return;

      setState(() {
        _userId = data?['user_id']?.toString() ?? '';
      });
    } catch (e) {
      _message('Unable to read user details.');
    }
  }

  @override
  void dispose() {
    _rentController.removeListener(_recalculate);
    _daysController.removeListener(_recalculate);

    _productController.dispose();
    _promotionController.dispose();
    _rentController.dispose();
    _daysController.dispose();

    super.dispose();
  }

  // ============================================================
  // CALCULATE TOTAL AMOUNT
  // ============================================================

  void _recalculate() {
    if (mounted) setState(() {});
  }

  double get _totalBill {
    final rent = double.tryParse(_rentController.text.trim()) ?? 0;

    final days = int.tryParse(_daysController.text.trim()) ?? 0;

    return rent * days;
  }

  String get _formattedTotal => NumberFormat('#,##0.00').format(_totalBill);

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ============================================================
  // PRODUCT SEARCH - DEBOUNCE 2 SECONDS
  // ============================================================

  // ============================================================
  // SELECT CAMERA OR GALLERY
  // ============================================================

  Future<ImageSource?> _selectImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.cardBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt_outlined,
                    color: context.primaryColor,
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Open camera'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: context.primaryColor,
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select up to 2 photos'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _pickImages(List<String> images) async {
    if (_picking || images.length >= 2) return;

    final source = await _selectImageSource();

    if (source == null || !mounted) return;

    setState(() => _picking = true);

    try {
      final remaining = 2 - images.length;

      List<XFile> selected = [];

      if (source == ImageSource.camera) {
        final image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1080,
          maxHeight: 1080,
        );

        if (image != null) {
          selected = [image];
        }
      } else {
        selected = await _picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1080,
          maxHeight: 1080,
        );
      }

      if (!mounted) return;

      if (selected.length > remaining) {
        _message('Only $remaining more photo(s) allowed.');
      }

      final existing = images.toSet();

      final paths = selected
          .map((image) => image.path)
          .where((path) => !existing.contains(path))
          .take(remaining)
          .toList();

      final compressedPaths = <String>[];
      var failedCount = 0;
      for (final path in paths) {
        final compressed = await ImageCompression.compressImage(File(path));
        if (!mounted) return;
        if (compressed == null || !await compressed.exists()) {
          failedCount++;
          continue;
        }
        compressedPaths.add(compressed.path);
      }

      if (!mounted) return;
      setState(() {
        images.addAll(compressedPaths);
      });
      if (failedCount > 0) {
        _message(
          'Could not compress $failedCount photo(s). Please select them again.',
        );
      }
    } catch (e) {
      _message('Failed to select images: $e');
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  void _submit() {
    final bloc = context.read<JeepCampaignBloc>();

    if (bloc.state.submitting || _picking) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userId.isEmpty || _userId == '0') {
      _message('Please log in again.');
      return;
    }

    if (_seasonId == null) {
      _message('Please select season.');
      return;
    }

    if (_productId == null) {
      _message('Please select product.');
      return;
    }

    if (_vehicleType == null) {
      _message('Please select vehicle type.');
      return;
    }

    final campaign = JeepCampaign(
      userId: _userId,
      seasonId: _seasonId!,
      productId: _productId!,
      promotionArea: _promotionController.text.trim(),
      vehicleType: _vehicleType!,
      rentPerDay: _rentController.text.trim(),
      workingDays: _daysController.text.trim(),
      attachmentA: List<String>.from(_imagesA),
      attachmentB: List<String>.from(_imagesB),
      attachmentC1: List<String>.from(_imagesC1),
      attachmentC2: List<String>.from(_imagesC2),
    );

    bloc.add(SubmitJeepCampaignEvent(campaign));
  }

  // ============================================================
  // REUSABLE SECTION TITLE
  // ============================================================

  Widget _sectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: context.primaryColor, size: 20),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    bool numeric = false,
    bool decimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric
          ? TextInputType.numberWithOptions(decimal: decimal)
          : TextInputType.text,
      inputFormatters: numeric
          ? [
              decimal
                  ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  : FilteringTextInputFormatter.digitsOnly,
            ]
          : null,
      style: TextStyle(fontSize: 13, color: context.primaryTextColor),
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: hint,
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 19, color: context.primaryColor),
        isDense: true,
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return 'Please enter $label';
        }

        if (numeric) {
          final amount = double.tryParse(text);

          if (amount == null || !amount.isFinite || amount <= 0) {
            return 'Enter valid $label';
          }

          if (!decimal && int.tryParse(text) == null) {
            return 'Enter whole number';
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // SEASON DROPDOWN
  // ============================================================

  Widget _seasonDropdown(JeepCampaignState state) {
    // Avoid a dropdown assertion if the selected season
    // is no longer present in the loaded list.
    final selectedValue = state.seasons.any((item) => item.id == _seasonId)
        ? _seasonId
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(selectedValue),
      initialValue: selectedValue,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      hint: const Text('Select season'),
      decoration: InputDecoration(
        labelText: 'Season *',
        prefixIcon: Icon(Icons.eco_outlined, color: context.primaryColor),
        suffixIcon: state.loadingSeasons
            ? const Padding(
                padding: EdgeInsets.all(15),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: state.seasons.map((season) {
        return DropdownMenuItem<String>(
          value: season.id,
          child: Text(season.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: state.loadingSeasons
          ? null
          : (value) {
              setState(() {
                _seasonId = value;
              });
            },
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select season' : null,
    );
  }

  // ============================================================
  // PRODUCT SEARCH
  // ============================================================

  Widget _productSearch(JeepCampaignState state) {
    final matches = state.products
        .where(
          (p) =>
              _productId != p.id &&
              p.name.toLowerCase().contains(_productQuery),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: _productFieldKey,
          controller: _productController,
          enabled: !state.submitting,
          onChanged: (value) => setState(() {
            _productId = null;
            _productQuery = value.trim().toLowerCase();
          }),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (_) => (_productId == null || _productId!.isEmpty)
              ? 'Choose a product from search results'
              : null,
          decoration: InputDecoration(
            labelText: 'Product *',
            hintText: 'Type product name to search',
            prefixIcon: Icon(Icons.search, color: context.primaryColor),
            filled: true,
            fillColor: context.cardBackgroundColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
        ),
        if (state.searchingProducts)
          Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(color: context.primaryColor),
          ),
        if (_productQuery.isNotEmpty && !state.searchingProducts)
          Container(
            margin: EdgeInsets.only(top: 6),
            constraints: BoxConstraints(maxHeight: 220),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: context.cardBackgroundColor,
              child: matches.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No matching products',
                        style: TextStyle(color: context.secondaryTextColor),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      primary: false,
                      padding: EdgeInsets.symmetric(vertical: 4),
                      itemCount: matches.length,
                      separatorBuilder: (_, index) => Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 14,
                        color: context.borderColor,
                      ),
                      itemBuilder: (context, index) {
                        final product = matches[index];
                        return ListTile(
                          leading: Icon(
                            Icons.inventory_2_outlined,
                            color: context.primaryColor,
                          ),
                          title: Text(
                            product.name,
                            style: TextStyle(
                              color: context.primaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            Icons.add_circle_outline,
                            color: context.primaryColor,
                          ),
                          onTap: state.submitting
                              ? null
                              : () {
                                  setState(() {
                                    _productId = product.id;
                                    _productController.text = product.name;
                                    _productQuery = '';
                                  });
                                  _productFieldKey.currentState?.validate();
                                  FocusScope.of(context).unfocus();
                                },
                        );
                      },
                    ),
            ),
          ),
      ],
    );
  }
  // ============================================================
  // VEHICLE SELECTOR
  // ============================================================

  Widget _vehicleSelector() {
    return FormField<String>(
      validator: (_) =>
          _vehicleType == null ? 'Please select vehicle type' : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: vehicles.map((vehicle) {
                final selected = _vehicleType == vehicle;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: vehicle == vehicles.last ? 0 : 8,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _vehicleType = vehicle;
                        });
                        field.didChange(vehicle);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 47,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? context.primaryColor
                              : context.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? context.primaryColor
                                : context.borderColor,
                          ),
                        ),
                        child: Text(
                          vehicle,
                          style: TextStyle(
                            color: selected
                                ? context.onPrimaryColor
                                : context.primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ATTACHMENT CARD
  // ============================================================

  Widget _attachmentCard({
    required String title,
    required List<String> images,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.primaryTextColor,
                  ),
                ),
              ),
              Text(
                '${images.length}/2',
                style: TextStyle(
                  fontSize: 10,
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          if (images.isEmpty)
            InkWell(
              onTap: () => _pickImages(images),
              child: Container(
                width: double.infinity,
                height: 69,
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: context.primaryColor,
                      size: 23,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add Photos',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(images[index]),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 70,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              images.removeAt(index);
                            });
                          },
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: context.appColors.inverseSurface,
                            child: Icon(
                              Icons.close,
                              color: context.appColors.onInverseSurface,
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 9),

          SizedBox(
            height: 34,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: images.length >= 2 || _picking
                  ? null
                  : () => _pickImages(images),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primaryColor,
                padding: EdgeInsets.zero,
                side: BorderSide(color: context.borderColor),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Images', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN PAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JeepCampaignBloc, JeepCampaignState>(
      listenWhen: (previous, current) =>
          previous.success != current.success ||
          previous.error != current.error,

      listener: (context, state) {
        if (state.success != null) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Campaign Submitted'),
                content: Text(state.success!),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
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
            title: 'Jeep Campaigning',
            showBackButton: true,
            onBackTap: () => context.go(AppRouter.home),
          ),

          // FORM
          body: AbsorbPointer(
            absorbing: state.submitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
                children: [
                  // HEADER CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 29,
                          color: context.primaryColor,
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Campaign Activity',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: context.primaryTextColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Plan and record your campaign details',
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

                  // CAMPAIGN DETAILS
                  _sectionTitle(
                    title: 'Campaign Details',
                    subtitle: 'Season, product and location',
                    icon: Icons.campaign_outlined,
                  ),

                  _seasonDropdown(state),

                  const SizedBox(height: 11),

                  _productSearch(state),

                  const SizedBox(height: 11),

                  _textField(
                    label: 'Promotion Area',
                    hint: 'Enter promotion area',
                    controller: _promotionController,
                    icon: Icons.location_on_outlined,
                  ),

                  // VEHICLE & BILLING
                  _sectionTitle(
                    title: 'Vehicle & Billing',
                    subtitle: 'Vehicle type, rent and duration',
                    icon: Icons.directions_car_outlined,
                  ),

                  _vehicleSelector(),

                  const SizedBox(height: 11),

                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          label: 'Rent Per Day',
                          hint: '₹ 0',
                          controller: _rentController,
                          numeric: true,
                          decimal: true,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _textField(
                          label: 'Working Days',
                          hint: '0',
                          controller: _daysController,
                          numeric: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  // TOTAL BILL
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Bill Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.onPrimaryColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Rent × Working Days',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.onPrimaryColor.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹$_formattedTotal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: context.onPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // IMAGE ATTACHMENTS
                  _sectionTitle(
                    title: 'Campaign Attachments',
                    subtitle: 'Four attachment groups • 2 images each',
                    icon: Icons.photo_library_outlined,
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _attachmentCard(
                          title: 'Attached A',
                          images: _imagesA,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _attachmentCard(
                          title: 'Attached B',
                          images: _imagesB,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _attachmentCard(
                          title: 'Attached C1',
                          images: _imagesC1,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _attachmentCard(
                          title: 'Attached C2',
                          images: _imagesC2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: context.secondaryTextColor,
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'You can upload up to 2 images per section. '
                          'Total bill is calculated automatically.',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.secondaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

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
                height: 49,
                child: FilledButton.icon(
                  onPressed: state.submitting || _picking ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.onPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: state.submitting
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.onPrimaryColor,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    state.submitting ? 'Submitting...' : 'Submit Jeep Campaign',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
