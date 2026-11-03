import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:solufine/core/secure_storage/secure_storage.dart';

import '../bloc/complaint_bloc.dart';
import '../bloc/complaint_event.dart';
import '../bloc/complaint_state.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:solufine/core/router/app_router.dart';

import 'dart:async';

import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/image_compression.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_dropdown.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';

// Import your existing:
// CustomDropdown
// CustomTextFormField
// Theme extensions (context.appPrimary, etc.)

class ComplaintForm extends StatefulWidget {
  const ComplaintForm({
    super.key,
    // this.onCropSearch,
    // this.onSubcategorySearch,
    // this.onVarietySearch,
    // this.onSubmit,
  });

  @override
  State<ComplaintForm> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  final ValueChanged<String>? onCropSearch = (value) {};
  final ValueChanged<String>? onSubcategorySearch = (value) {};
  final ValueChanged<String>? onVarietySearch =
      null; // Or omit since it's already nullable
  final ValueChanged<Map<String, dynamic>>? onSubmit = (map) {};

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 2.5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  String _customerType = 'Dealer';
  String? _cropSeason;

  final List<String> _customerTypes = ['Dealer', 'Farmer'];
  bool _picking = false;
  final List<String> _cropSeasons = ['Kharif', 'Rabi', 'Spring'];

  final _cropController = TextEditingController();
  final _distributorController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _varietyController = TextEditingController();

  final _lotNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _sourceController = TextEditingController();
  final _complaintController = TextEditingController();
  final _emailController = TextEditingController();
  final List<String> _pictures = [];
  late final ComplaintBloc _complaintBloc;
  Timer? _outletTimer;
  int _outletVersion = 0;
  bool _showOutlets = false;
  bool _showCrops = false;
  String? _selectedCategoryId;
  bool _showSubcategories = false;
  bool _showVarieties = false;

  @override
  void initState() {
    super.initState();
    _complaintBloc = context.read<ComplaintBloc>();
  }

  void _searchOutlet(String value) {
    _outletTimer?.cancel();
    final version = ++_outletVersion;
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

  Timer? _cropTimer;
  Timer? _subcategoryTimer;
  Timer? _varietyTimer;

  bool _isSubmitting = false;
  final _picker = ImagePicker();
  @override
  void dispose() {
    _cropTimer?.cancel();
    _subcategoryTimer?.cancel();
    _varietyTimer?.cancel();

    _outletTimer?.cancel();

    _distributorController.dispose();
    _cropController.dispose();
    _subcategoryController.dispose();
    _varietyController.dispose();

    _lotNumberController.dispose();
    _addressController.dispose();
    _sourceController.dispose();
    _complaintController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  void _clearSignature() {
    signatureController.clear();

    setState(() {});
  }

  // ==========================================
  // SEARCH DEBOUNCE
  // ==========================================

  void _searchCrop(String value) {
    _cropTimer?.cancel();
    _subcategoryTimer?.cancel();
    _selectedCategoryId = null;
    _varietyTimer?.cancel();
    _showVarieties = false;
    _showSubcategories = false;
    _subcategoryController.clear();
    _varietyController.clear();
    setState(() => _showCrops = false);
    if (value.trim().isEmpty) return;
    _cropTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _complaintBloc.add(const GetCropCategoryListEvent());
      setState(() => _showCrops = true);
    });
  }

  void _toast(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _searchSubcategory(String value) {
    _subcategoryTimer?.cancel();
    setState(() => _showSubcategories = false);
    if (value.trim().isEmpty) return;
    final categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId.isEmpty) {
      _toast('Please select a crop from the search results first');
      return;
    }
    _subcategoryTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || _selectedCategoryId != categoryId) return;
      _complaintBloc.add(GetSubCategoryListEvent(categoryId: categoryId));
      setState(() => _showSubcategories = true);
    });
  }

  void _searchVariety(String value) {
    _varietyTimer?.cancel();
    setState(() => _showVarieties = false);
    if (value.trim().isEmpty) return;
    final categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId.isEmpty) {
      _toast('Please select a crop from the search results first');
      return;
    }
    _varietyTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || _selectedCategoryId != categoryId) return;
      _complaintBloc.add(GetVarietyListEvent(categoryId: categoryId));
      setState(() => _showVarieties = true);
    });
  }
  // ==========================================
  // VALIDATION
  // ==========================================

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // ==========================================
  // SUBMIT
  // ==========================================

  void _submitForm() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_isSubmitting) return;

    final Map<String, dynamic> formData = {
      'customerType': _customerType,
      'cropSeason': _cropSeason ?? '',
      'crop': _cropController.text.trim(),
      'subcategory': _subcategoryController.text.trim(),
      'variety': _varietyController.text.trim(),
      'lotNumber': _lotNumberController.text.trim(),
      'address': _addressController.text.trim(),
      'sourceOfProduct': _sourceController.text.trim(),
      'complaintDetails': _complaintController.text.trim(),
      'emailId': _emailController.text.trim(),
    };

    debugPrint('========== COMPLAINT FORM ==========');

    for (final entry in formData.entries) {
      debugPrint('${entry.key}: ${entry.value}');
    }

    debugPrint('====================================');

    // Pass validated form data to the parent.
    // API integration will be added later.
    if (onSubmit != null) {
      onSubmit!(formData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form validated. Connect the Submit Complaint API.'),
        ),
      );
    }
  }

  // ==========================================
  // MAIN UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,

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
        title: 'Complaint Form',
        showBackButton: true,
        onBackTap: () => context.go(AppRouter.home),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          children: [
            // ==================================
            // CUSTOMER DETAILS
            // ==================================
            _sectionTitle('Customer Information', Icons.person_outline_rounded),

            const SizedBox(height: 12),

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
                  _outletTimer?.cancel();
                  _outletVersion++;
                  _showOutlets = false;
                  _distributorController.clear();
                });
              },
              validator: (value) =>
                  value == null ? 'Select customer type' : null,
            ),

            const SizedBox(height: 12),

            CustomTextFormField(
              controller: _distributorController,
              hintText: _customerType == 'Farmer'
                  ? 'Farmer Name *'
                  : 'Distributor Name *',
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
              validator: _requiredValidator,
              textInputAction: TextInputAction.next,
            ),

            if (_showOutlets)
              BlocBuilder<ComplaintBloc, ComplaintFormState>(
                bloc: _complaintBloc,
                builder: (context, state) {
                  if (state.status == ComplaintFormStatus.loading)
                    return const LinearProgressIndicator();
                  if (state.status == ComplaintFormStatus.failure)
                    return Text(
                      state.errorMessage ?? 'Unable to search outlets',
                    );
                  final outlets = state.outletListEntity?.result ?? [];
                  if (outlets.isEmpty) return const Text('No matching results');
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: outlets.length,
                      itemBuilder: (context, index) {
                        final outlet = outlets[index];
                        return ListTile(
                          title: Text(outlet.outletName),
                          // subtitle: Text(outlet.outletAddress),
                          onTap: () => setState(() {
                            _distributorController.text = outlet.outletName;
                            _showOutlets = false;
                          }),
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),

            CustomDropdown<String>(
              hintText: 'Crop Season *',
              prefixIcon: Icons.calendar_today_outlined,
              value: _cropSeason,
              items: _cropSeasons.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _cropSeason = value;
                });
              },
              validator: (value) => value == null ? 'Select crop season' : null,
            ),

            const SizedBox(height: 18),

            // ==================================
            // CROP INFORMATION
            // ==================================
            _sectionTitle('Crop Information', Icons.grass_rounded),

            const SizedBox(height: 12),

            CustomTextFormField(
              controller: _cropController,
              hintText: 'Search Crop *',
              prefixIcon: Icons.eco_outlined,
              suffixIcon: _cropController.text.isEmpty
                  ? Icons.search_rounded
                  : Icons.close_rounded,
              onSuffixIconTap: _cropController.text.isEmpty
                  ? null
                  : () {
                      _cropController.clear();
                      _searchCrop('');
                    },
              onChanged: _searchCrop,
              validator: _requiredValidator,
              textInputAction: TextInputAction.next,
            ),

            if (_showCrops)
              BlocBuilder<ComplaintBloc, ComplaintFormState>(
                bloc: _complaintBloc,
                builder: (context, state) {
                  if (state.cropStatus == ComplaintFormStatus.loading) {
                    return const LinearProgressIndicator();
                  }
                  if (state.cropStatus == ComplaintFormStatus.failure) {
                    return Text(state.cropErrorMessage);
                  }
                  final query = _cropController.text.trim().toLowerCase();
                  final crops =
                      state.cropCategoryListEntity?.result
                          .where(
                            (crop) =>
                                crop.categoryName.toLowerCase().contains(query),
                          )
                          .toList() ??
                      [];
                  if (crops.isEmpty) return const Text('No matching crops');
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: crops.length,
                      itemBuilder: (context, index) {
                        final crop = crops[index];
                        return ListTile(
                          title: Text(crop.categoryName),
                          onTap: () => setState(() {
                            _cropTimer?.cancel();
                            _cropController.text = crop.categoryName;
                            _selectedCategoryId = crop.categoryId;
                            _varietyTimer?.cancel();
                            _showVarieties = false;
                            _showSubcategories = false;
                            _subcategoryTimer?.cancel();
                            _subcategoryController.clear();
                            _varietyController.clear();
                            _showCrops = false;
                          }),
                        );
                      },
                    ),
                  );
                },
              ),
            _searchHelper(),

            const SizedBox(height: 10),

            CustomTextFormField(
              controller: _subcategoryController,
              hintText: 'Search Subcategories *',
              prefixIcon: Icons.category_outlined,
              suffixIcon: _subcategoryController.text.isEmpty
                  ? Icons.search_rounded
                  : Icons.close_rounded,
              onSuffixIconTap: _subcategoryController.text.isEmpty
                  ? null
                  : () {
                      _subcategoryController.clear();
                      _searchSubcategory('');
                    },
              onChanged: _searchSubcategory,
              validator: _requiredValidator,
              textInputAction: TextInputAction.next,
            ),

            if (_showSubcategories)
              BlocBuilder<ComplaintBloc, ComplaintFormState>(
                bloc: _complaintBloc,
                builder: (context, state) {
                  if (state.subcategoryStatus == ComplaintFormStatus.loading) {
                    return const LinearProgressIndicator();
                  }
                  if (state.subcategoryStatus == ComplaintFormStatus.failure) {
                    return Text(state.subcategoryErrorMessage);
                  }
                  final query = _subcategoryController.text
                      .trim()
                      .toLowerCase();
                  final items =
                      state.subCategoryListEntity?.result
                          .where(
                            (item) => item.subcategoryName
                                .toLowerCase()
                                .contains(query),
                          )
                          .toList() ??
                      [];
                  if (items.isEmpty)
                    return const Text('No matching subcategories');
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.subcategoryName),
                          onTap: () => setState(() {
                            _subcategoryTimer?.cancel();
                            _subcategoryController.text = item.subcategoryName;
                            _varietyTimer?.cancel();
                            _showVarieties = false;
                            _varietyController.clear();
                            _showSubcategories = false;
                          }),
                        );
                      },
                    ),
                  );
                },
              ),
            _searchHelper(),

            const SizedBox(height: 10),

            CustomTextFormField(
              controller: _varietyController,
              hintText: 'Search Variety *',
              prefixIcon: Icons.spa_outlined,
              suffixIcon: _varietyController.text.isEmpty
                  ? Icons.search_rounded
                  : Icons.close_rounded,
              onSuffixIconTap: _varietyController.text.isEmpty
                  ? null
                  : () {
                      _varietyController.clear();
                      _searchVariety('');
                    },
              onChanged: _searchVariety,
              validator: _requiredValidator,
              textInputAction: TextInputAction.next,
            ),

            if (_showVarieties)
              BlocBuilder<ComplaintBloc, ComplaintFormState>(
                bloc: _complaintBloc,
                builder: (context, state) {
                  if (state.varietyStatus == ComplaintFormStatus.loading) {
                    return const LinearProgressIndicator();
                  }
                  if (state.varietyStatus == ComplaintFormStatus.failure) {
                    return Text(state.varietyErrorMessage);
                  }
                  final query = _varietyController.text.trim().toLowerCase();
                  final items =
                      state.varietyListEntity?.result
                          .where(
                            (item) =>
                                item.productName.toLowerCase().contains(query),
                          )
                          .toList() ??
                      [];
                  if (items.isEmpty) return const Text('No matching varieties');
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.productName),
                          onTap: () => setState(() {
                            _varietyTimer?.cancel();
                            _varietyController.text = item.productName;
                            _showVarieties = false;
                          }),
                        );
                      },
                    ),
                  );
                },
              ),
            _searchHelper(),

            const SizedBox(height: 10),

            CustomTextFormField(
              controller: _lotNumberController,
              hintText: 'Lot / Batch Number *',
              prefixIcon: Icons.qr_code_rounded,
              validator: _requiredValidator,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 18),

            // ==================================
            // COMPLAINT INFORMATION
            // ==================================
            _sectionTitle('Complaint Information', Icons.assignment_outlined),

            const SizedBox(height: 12),

            CustomTextFormField(
              controller: _addressController,
              hintText: 'Address *',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
              validator: _requiredValidator,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 12),

            // CustomTextFormField(
            //   controller: _sourceController,
            //   hintText: 'Source of Product Supplied (Dealer / Retailer)',
            //   prefixIcon: Icons.storefront_outlined,
            //   suffixIcon: Icons.search_rounded,
            //   textInputAction: TextInputAction.next,
            // ),

            // const SizedBox(height: 12),
            CustomTextFormField(
              controller: _complaintController,
              hintText: 'Complaint Details (Max 100 Words) *',
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
              validator: (value) {
                final error = _requiredValidator(value);
                if (error != null) return error;

                final words = value!.trim().split(RegExp(r'\s+'));

                if (words.length > 100) {
                  return 'Maximum 100 words allowed';
                }

                return null;
              },
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 12),

            CustomTextFormField(
              controller: _emailController,
              hintText: 'Email ID (Optional)',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
              textInputAction: TextInputAction.done,
            ),

            _section(
              'Field Photos',
              'Attach up to 11 field photos',
              Icons.photo_library_outlined,
            ),

            const SizedBox(height: 5),
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

            _section(
              'Signature *',
              'Please provide your signature below',
              Icons.draw_rounded,
            ),

            _buildCompactSignatureSection(),
          ],
        ),
      ),

      // ==================================
      // BOTTOM SUBMIT BUTTON
      // ==================================
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
              onPressed: _isSubmitting ? null : _submitForm,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 21),
              label: const Text(
                'Submit Complaint',
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
    );
  }

  Widget _buildCompactSignatureSection() {
    return Container(
      width: double.infinity,
      height: 145.h,

      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.appBorder),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        children: [
          // ============================================================
          // SIGNATURE PAD
          // ============================================================
          Expanded(
            child: Signature(
              controller: signatureController,
              backgroundColor: Colors.white,
            ),
          ),

          // ============================================================
          // BOTTOM
          // ============================================================
          Container(
            height: 32.h,

            padding: EdgeInsets.symmetric(horizontal: 7.w),

            decoration: BoxDecoration(
              color: context.appInputBackground,
              border: Border(top: BorderSide(color: context.appBorder)),
            ),

            child: Row(
              children: [
                Icon(
                  Icons.gesture_rounded,
                  size: 13.sp,
                  color: context.appSubText,
                ),

                SizedBox(width: 4.w),

                Expanded(
                  child: Text(
                    'Sign here',
                    style: AppTextStyles.helperText.copyWith(
                      color: context.appSubText,
                    ),
                  ),
                ),

                InkWell(
                  onTap: _clearSignature,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 13.sp,
                          color: context.appError,
                        ),

                        SizedBox(width: 2.w),

                        Text(
                          'Clear',
                          style: AppTextStyles.badge.copyWith(
                            color: context.appError,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: context.appPrimary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: context.appPrimary),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SEARCH HELPER
  // ==========================================

  Widget _searchHelper() {
    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 5),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: context.appSubText),
          const SizedBox(width: 5),
          Text(
            'Search results appear after 1 second',
            style: TextStyle(fontSize: 10, color: context.appSubText),
          ),
        ],
      ),
    );
  }
}
