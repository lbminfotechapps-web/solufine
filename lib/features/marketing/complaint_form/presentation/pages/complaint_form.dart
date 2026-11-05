import 'package:solufine/core/utility/app_toast.dart';
import 'package:solufine/features/marketing/complaint_form/complaint_debug.dart';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:solufine/core/secure_storage/secure_storage.dart';

import '../bloc/complaint_bloc.dart';
import '../bloc/complaint_event.dart';
import '../bloc/complaint_state.dart';
import 'dart:io';

import 'package:flutter/material.dart';

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
  const ComplaintForm({super.key});

  @override
  State<ComplaintForm> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintForm> {
  final _formKey = GlobalKey<FormState>();

  String _customerTypeId = '';
  String _complaintSupplier = '';
  Future<String> Function(Uint8List png)? _uploadSignature;

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 2.5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  String _customerType = 'Dealer';
  String? _cropSeasonId;

  final List<String> _customerTypes = ['Dealer', 'Farmer'];
  bool _picking = false;

  final _cropController = TextEditingController();
  final _distributorController = TextEditingController();
  final _productController = TextEditingController();

  final _lotNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _sourceController = TextEditingController();
  final _complaintController = TextEditingController();
  final _emailController = TextEditingController();
  final _supplierController = TextEditingController();
  final List<String> _pictures = [];
  late final ComplaintBloc _complaintBloc;
  Timer? _outletTimer;
  int _outletVersion = 0;
  bool _showOutlets = false;
  bool _showCrops = false;
  String? _selectedCategoryId;
  String? _selectedCustomerId;
  String? _selectedProductId;
  bool _showProducts = false;

  @override
  void initState() {
    super.initState();
    _complaintBloc = context.read<ComplaintBloc>();
    _complaintBloc.add(const GetSeasonListEvent());
    _supplierController.text = _complaintSupplier;
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

  Timer? _cropTimer;
  Timer? _productTimer;

  bool _isSubmitting = false;
  final _picker = ImagePicker();
  @override
  void dispose() {
    _cropTimer?.cancel();
    _productTimer?.cancel();

    _outletTimer?.cancel();

    _distributorController.dispose();
    _cropController.dispose();
    _productController.dispose();

    _lotNumberController.dispose();
    _addressController.dispose();
    _sourceController.dispose();
    _complaintController.dispose();
    _emailController.dispose();
    _supplierController.dispose();
    signatureController.dispose();

    super.dispose();
  }

  // void _clearSignature() {
  //   signatureController.clear();

  //   setState(() {});
  // }

  // ==========================================
  // SEARCH DEBOUNCE
  // ==========================================

  void _searchCrop(String value) {
    _cropTimer?.cancel();
    _selectedCategoryId = null;
    _selectedProductId = null;
    _productTimer?.cancel();
    _showProducts = false;
    _productController.clear();
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

  void _searchProduct(String value) {
    _productTimer?.cancel();
    _selectedProductId = null;
    setState(() => _showProducts = false);
    if (value.trim().isEmpty) return;
    final categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId.isEmpty) {
      _toast('Please select a crop from the search results first');
      return;
    }
    _productTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || _selectedCategoryId != categoryId) return;
      _complaintBloc.add(GetSubCategoryListEvent(categoryId: categoryId));
      setState(() => _showProducts = true);
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

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      _toast('Please fill all required fields');
      return;
    }

    // Searchable fields must have been selected from the API list.
    if (_selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
      _toast('Please select a customer from the search results');
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      _toast('Please select a crop category from search results');
      return;
    }
    if (_selectedProductId == null || _selectedProductId!.isEmpty) {
      _toast('Please select a product from the search results');
      return;
    }
    // if (signatureController.isEmpty) {
    //   _toast('Please provide your signature');
    //   return;
    // }

    // The Android API sends a signature filename, not signature bytes.
    // We cannot submit a working signature until its upload endpoint is known.
    // if (_uploadSignature == null) {
    //   _toast('Signature upload API is not connected yet');
    //   return;
    // }

    // if (_customerTypeId.trim().isEmpty) {
    //   _toast('Customer Type ID mapping is required from the backend');
    //   return;
    // }

    setState(() => _isSubmitting = true);
    try {
      final user = await SecureStorage.instance.getUserData();
      if (!mounted) return;
      final userId = (user?['user_id'] ?? user?['userId'] ?? '')
          .toString()
          .trim();
      if (userId.isEmpty) {
        _toast('Unable to find logged-in user ID');
        setState(() => _isSubmitting = false);
        return;
      }

      // final png = await signatureController.toPngBytes();
      // if (!mounted) return;
      // if (png == null || png.isEmpty) {
      //   throw StateError('Unable to export signature');
      // }
      // final signatureFileName = await _uploadSignature!(png);
      // if (!mounted) return;
      // if (signatureFileName.trim().isEmpty) {
      //   throw StateError('Signature upload did not return a filename');
      // }

      final payload = <String, dynamic>{
        'userId': userId,
        'customerType': _customerType,
        'customerTypeId': '',
        'customerId': _selectedCustomerId,
        'cropId': _selectedCategoryId,

        'lotNumber': _lotNumberController.text.trim(),
        'complaintsDetails': _complaintController.text.trim(),
        'farmerSignature': '',
        //signatureFileName.trim(),
        'activityId': '9',
        'complaintCrop': _selectedCategoryId,
        'complaintClass': '',
        'complaintVeriety': '',
        'seasionProductId': _selectedProductId,
        'ComplaintDistributerName': _distributorController.text.trim(),
        'ComplaintEmailId': _emailController.text.trim(),
        'ComplaintSupplier': _supplierController.text.trim(),
        'video': '',
        'complaintSeason': _cropSeasonId,

        'address': _addressController.text.trim(),
        'pictures[]': _pictures.map((path) => File(path)).toList(),
      };

      debugPrint('========== SUBMIT COMPLAINT ==========');
      for (final entry in payload.entries) {
        debugPrint(
          '${entry.key}: ${entry.value is File ? '(File)' : entry.value}',
        );
      }
      ComplaintDebug.log(
        'Form',
        'Dispatching SubmitComplaintFormEvent',
        payload,
      );
      _complaintBloc.add(SubmitComplaintFormEvent(jsonData: payload));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast('Unable to prepare complaint: $e');
    }
  }

  // ==========================================
  // MAIN UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<ComplaintBloc, ComplaintFormState>(
      bloc: _complaintBloc,
      listenWhen: (previous, current) =>
          _isSubmitting &&
          previous.submissionStatus != current.submissionStatus &&
          (current.submissionStatus == ComplaintFormStatus.success ||
              current.submissionStatus == ComplaintFormStatus.failure),
      listener: (context, state) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        if (state.submissionStatus == ComplaintFormStatus.success) {
          AppToast.success('Complaint submitted successfully');
          // Navigate only after successful submission.
          context.go(AppRouter.home);
        } else {
          _toast(state.errorMessage ?? 'Unable to submit complaint');
        }
      },
      child: Scaffold(
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
              _sectionTitle(
                'Customer Information',
                Icons.person_outline_rounded,
              ),

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
                    _selectedCustomerId = null;
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
                    if (outlets.isEmpty)
                      return const Text('No matching results');
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
                              _selectedCustomerId = outlet.outletId;
                              _showOutlets = false;
                            }),
                          );
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),

              BlocBuilder<ComplaintBloc, ComplaintFormState>(
                bloc: _complaintBloc,
                builder: (context, state) {
                  final seasons = state.seasonListEntity?.result ?? [];
                  final loading =
                      state.seasonStatus == ComplaintFormStatus.loading;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomDropdown<String>(
                        hintText: loading
                            ? 'Loading seasons...'
                            : 'Crop Season *',
                        prefixIcon: Icons.calendar_today_outlined,
                        value: _cropSeasonId,
                        enabled: !loading && seasons.isNotEmpty,
                        items: seasons.map((season) {
                          return DropdownMenuItem(
                            value: season.seasonId,
                            child: Text(season.seasonName),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _cropSeasonId = value),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Select crop season'
                            : null,
                      ),
                      if (loading) const LinearProgressIndicator(),
                      if (state.seasonStatus == ComplaintFormStatus.failure ||
                          (!loading &&
                              state.seasonStatus ==
                                  ComplaintFormStatus.success &&
                              seasons.isEmpty))
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.seasonErrorMessage.isNotEmpty
                                    ? state.seasonErrorMessage
                                    : 'No seasons available',
                                style: TextStyle(color: context.appError),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _complaintBloc.add(
                                const GetSeasonListEvent(),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                    ],
                  );
                },
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
                              (crop) => crop.categoryName
                                  .toLowerCase()
                                  .contains(query),
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
                              _selectedProductId = null;
                              _productTimer?.cancel();
                              _showProducts = false;
                              _productController.clear();
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
                controller: _productController,
                hintText: 'Search Product *',
                prefixIcon: Icons.spa_outlined,
                suffixIcon: _productController.text.isEmpty
                    ? Icons.search_rounded
                    : Icons.close_rounded,
                onSuffixIconTap: _productController.text.isEmpty
                    ? null
                    : () {
                        _productController.clear();
                        _searchProduct('');
                      },
                onChanged: _searchProduct,
                validator: _requiredValidator,
                textInputAction: TextInputAction.next,
              ),

              if (_showProducts)
                BlocBuilder<ComplaintBloc, ComplaintFormState>(
                  bloc: _complaintBloc,
                  builder: (context, state) {
                    if (state.varietyStatus == ComplaintFormStatus.loading) {
                      return const LinearProgressIndicator();
                    }
                    if (state.varietyStatus == ComplaintFormStatus.failure) {
                      return Text(state.varietyErrorMessage);
                    }
                    final query = _productController.text.trim().toLowerCase();
                    final items =
                        state.subCategoryListEntity?.result
                            .where(
                              (item) =>
                                  item.productId != '0' &&
                                  item.productName.toLowerCase().contains(
                                    query,
                                  ),
                            )
                            .toList() ??
                        [];
                    if (items.isEmpty)
                      return const Text('No matching products');
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
                              _productTimer?.cancel();
                              _productController.text = item.productName;
                              _selectedProductId = item.productId;
                              _showProducts = false;
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
                hintText: 'Product Batch Number',
                prefixIcon: Icons.qr_code_rounded,
                // validator: _requiredValidator,
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
                hintText: 'Address',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
                // validator: _requiredValidator,
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

              const SizedBox(height: 12),
              CustomTextFormField(
                controller: _supplierController,
                hintText: 'Complaint Supplier',
                prefixIcon: Icons.store_outlined,
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

              // _section(
              //   'Signature *',
              //   'Please provide your signature below',
              //   Icons.draw_rounded,
              // ),

              // _buildCompactSignatureSection(),
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
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 21),
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
      ),
    );
  }

  // Widget _buildCompactSignatureSection() {
  //   return Container(
  //     width: double.infinity,
  //     height: 145.h,

  //     decoration: BoxDecoration(
  //       color: context.appCard,
  //       borderRadius: BorderRadius.circular(12.r),
  //       border: Border.all(color: context.appBorder),
  //     ),

  //     clipBehavior: Clip.antiAlias,

  //     child: Column(
  //       children: [
  //         // ============================================================
  //         // SIGNATURE PAD
  //         // ============================================================
  //         Expanded(
  //           child: Signature(
  //             controller: signatureController,
  //             backgroundColor: Colors.white,
  //           ),
  //         ),

  //         // ============================================================
  //         // BOTTOM
  //         // ============================================================
  //         Container(
  //           height: 32.h,

  //           padding: EdgeInsets.symmetric(horizontal: 7.w),

  //           decoration: BoxDecoration(
  //             color: context.appInputBackground,
  //             border: Border(top: BorderSide(color: context.appBorder)),
  //           ),

  //           child: Row(
  //             children: [
  //               Icon(
  //                 Icons.gesture_rounded,
  //                 size: 13.sp,
  //                 color: context.appSubText,
  //               ),

  //               SizedBox(width: 4.w),

  //               Expanded(
  //                 child: Text(
  //                   'Sign here',
  //                   style: AppTextStyles.helperText.copyWith(
  //                     color: context.appSubText,
  //                   ),
  //                 ),
  //               ),

  //               InkWell(
  //                 onTap: _clearSignature,
  //                 child: Padding(
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: 4.w,
  //                     vertical: 4.h,
  //                   ),
  //                   child: Row(
  //                     children: [
  //                       Icon(
  //                         Icons.refresh_rounded,
  //                         size: 13.sp,
  //                         color: context.appError,
  //                       ),

  //                       SizedBox(width: 2.w),

  //                       Text(
  //                         'Clear',
  //                         style: AppTextStyles.badge.copyWith(
  //                           color: context.appError,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
