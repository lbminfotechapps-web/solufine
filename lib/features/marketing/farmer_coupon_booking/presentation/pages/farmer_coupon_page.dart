import 'package:solufine/core/utility/image_compression.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/router/app_router.dart';

import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';

import '../../domain/entities/farmer_coupon_entity.dart';
import '../bloc/farmer_coupon_bloc.dart';

class FarmerCouponPage extends StatefulWidget {
  const FarmerCouponPage({super.key, this.onAddFarmer});

  // Connect to your existing farmer-registration route.
  final VoidCallback? onAddFarmer;

  @override
  State<FarmerCouponPage> createState() => _FarmerCouponPageState();
}

class _FarmerCouponPageState extends State<FarmerCouponPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _couponNumberController = TextEditingController();
  final _giftController = TextEditingController();
  final _bookingAmountController = TextEditingController();
  final _quantityController = TextEditingController();

  final _farmerController = TextEditingController();
  final _farmerFieldKey = GlobalKey<FormFieldState<String>>();
  Timer? _farmerTimer;
  String _farmerQuery = '';
  String _userId = '';
  String _farmerId = '';

  String _selectedProductId = '';
  final _productFieldKey = GlobalKey<FormFieldState<String>>();
  final _productController = TextEditingController();
  String _productQuery = '';

  String? _couponImagePath;
  bool _picking = false;

  // Replace with the exact value of your old
  // Android R.string.cupenDetails if different.
  static const String couponDetails = 'Coupon Details';

  @override
  void initState() {
    super.initState();

    _loadUser();

    _bookingAmountController.addListener(_refreshTotal);
    _quantityController.addListener(_refreshTotal);

    context.read<FarmerCouponBloc>().add(const LoadCouponProducts());
  }

  Future<void> _loadUser() async {
    final data = await SecureStorage.instance.getUserData();

    if (!mounted) return;

    setState(() {
      _userId = (data?['user_id'] ?? data?['userId'] ?? '').toString().trim();
    });
  }

  @override
  void dispose() {
    _farmerTimer?.cancel();
    _farmerController.dispose();
    _productController.dispose();
    _couponNumberController.dispose();
    _giftController.dispose();
    _bookingAmountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  double get _totalAmount {
    final amount = double.tryParse(_bookingAmountController.text.trim()) ?? 0;

    final count = int.tryParse(_quantityController.text.trim()) ?? 0;

    return amount * count;
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
      );
  }

  // ===================================================
  // FARMER SEARCH - SAME 2 SECOND DELAY AS JAVA
  // ===================================================

  // ===================================================
  // PRODUCT MULTI-SELECTION
  // ===================================================

  // ===================================================
  // IMAGE SOURCE
  // ===================================================

  Future<void> _pickCouponImage() async {
    if (_picking) return;

    final source = await showModalBottomSheet<ImageSource>(
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
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(sheet, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: context.primaryColor,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(sheet, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    setState(() => _picking = true);

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image == null || !mounted) return;

      final compressed = await ImageCompression.compressImage(File(image.path));
      if (!mounted) return;
      if (compressed == null || !await compressed.exists()) {
        _message('Could not compress the photo. Please select it again.');
        return;
      }
      if (!mounted) return;

      setState(() {
        _couponImagePath = compressed.path;
      });
    } catch (error) {
      _message('Unable to select image: $error');
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  // ===================================================
  // VALIDATION + SUBMIT
  // ===================================================

  void _submit() {
    final bloc = context.read<FarmerCouponBloc>();

    if (bloc.state.submitting || _picking) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_userId.isEmpty || _userId == '0') {
      _message('Please log in again.');
      return;
    }

    if (_farmerId.isEmpty) {
      _message('Please select farmer from the list.');
      return;
    }

    if (_selectedProductId.isEmpty) {
      _message('Please select a product.');
      return;
    }

    if (_couponImagePath == null) {
      _message('Please select coupon image.');
      return;
    }

    final coupon = FarmerCouponEntity(
      userId: _userId,
      farmerId: _farmerId,
      couponDetails: couponDetails,
      productIds: [_selectedProductId],
      couponNumber: _couponNumberController.text.trim(),
      giftGiven: _giftController.text.trim(),
      bookingAmount: _bookingAmountController.text.trim(),
      noOfCouponBook: _quantityController.text.trim(),
      imagePath: _couponImagePath!,
    );

    bloc.add(SubmitCouponBooking(coupon));
  }

  // ===================================================
  // REUSABLE FIELD
  // ===================================================

  Widget _field({
    required String title,
    required TextEditingController controller,
    required String hint,
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
      decoration: InputDecoration(
        labelText: '$title *',
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: context.cardBackgroundColor,
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

        if (text.isEmpty) {
          return 'Enter $title';
        }

        if (numeric) {
          final number = double.tryParse(text);

          if (number == null || number <= 0) {
            return 'Enter valid $title';
          }

          if (!decimal && int.tryParse(text) == null) {
            return 'Enter a whole number';
          }
        }

        return null;
      },
    );
  }

  // ===================================================
  // SECTION HEADER
  // ===================================================

  Widget _section(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 17, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: context.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
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

  // ===================================================
  // FARMER SEARCH UI
  // ===================================================

  void _searchFarmers(String value) {
    _farmerTimer?.cancel();
    final query = value.trim();
    setState(() {
      _farmerQuery = query;
      _farmerId = '';
    });
    final bloc = context.read<FarmerCouponBloc>();
    bloc.add(const ClearCouponFarmers());
    if (query.length < 3) return;
    _farmerTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      bloc.add(SearchCouponFarmer(userId: _userId, searchText: query));
    });
  }

  Widget _farmerSearchField(FarmerCouponState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: _farmerFieldKey,
          controller: _farmerController,
          enabled: !state.submitting,
          onChanged: _searchFarmers,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (_) =>
              _farmerId.isEmpty ? 'Choose a farmer from search results' : null,
          decoration: InputDecoration(
            labelText: 'Farmer Name *',
            filled: true,
            fillColor: context.cardBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primaryColor, width: 1.5),
            ),
            hintText: 'Type at least 3 characters to search',
            prefixIcon: Icon(Icons.search, color: context.primaryColor),
            suffixIcon: state.searchingFarmers
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _farmerId.isNotEmpty
                ? Icon(Icons.check_circle, color: context.primaryColor)
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_farmerId.isEmpty && state.farmers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: context.cardBackgroundColor,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                primary: false,
                shrinkWrap: true,
                separatorBuilder: (_, index) => Divider(
                  height: 1,
                  indent: 66,
                  endIndent: 14,
                  color: context.borderColor,
                ),
                itemCount: state.farmers.length,
                itemBuilder: (context, index) {
                  final farmer = state.farmers[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: context.primaryColor,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      farmer.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: context.secondaryTextColor,
                      size: 20,
                    ),
                    onTap: state.submitting
                        ? null
                        : () {
                            _farmerTimer?.cancel();
                            setState(() {
                              _farmerId = farmer.id;
                              _farmerController.text = farmer.name;
                            });
                            context.read<FarmerCouponBloc>().add(
                              const ClearCouponFarmers(),
                            );
                            _farmerFieldKey.currentState?.validate();
                            FocusScope.of(context).unfocus();
                          },
                  );
                },
              ),
            ),
          ),
        if (_farmerId.isEmpty &&
            !state.searchingFarmers &&
            _farmerQuery.length >= 3 &&
            state.farmers.isEmpty)
          TextButton.icon(
            onPressed: state.submitting
                ? null
                : () {
                    _farmerTimer?.cancel();
                    context.read<FarmerCouponBloc>().add(
                      SearchCouponFarmer(
                        userId: _userId,
                        searchText: _farmerQuery,
                      ),
                    );
                  },
            icon: const Icon(Icons.refresh),
            label: const Text('No farmers available. Retry'),
          ),
      ],
    );
  }
  // ===================================================
  // PRODUCT PICKER UI
  // ===================================================

  Widget _productSelector(FarmerCouponState state) {
    final matches = state.products
        .where(
          (p) =>
              _selectedProductId != p.id &&
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
            _selectedProductId = '';
            _productQuery = value.trim().toLowerCase();
          }),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (_) => _selectedProductId.isEmpty
              ? 'Choose a product from search results'
              : null,
          decoration: InputDecoration(
            labelText: 'Product *',
            hintText: 'Type product name to search',
            prefixIcon: Icon(Icons.search, color: context.primaryColor),
            filled: true,
            fillColor: context.cardBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
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
        ),
        if (state.loadingProducts)
          Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(color: context.primaryColor),
          ),
        if (_productQuery.isNotEmpty && !state.loadingProducts)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 220),
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
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                                    _selectedProductId = product.id;
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
  // ===================================================
  // COUPON PHOTO UI
  // ===================================================

  Widget _couponPhoto() {
    return InkWell(
      onTap: _pickCouponImage,
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
            Container(
              height: 77,
              width: 85,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: context.primaryColor.withValues(alpha: .08),
              ),
              child: _couponImagePath == null
                  ? Icon(
                      Icons.add_a_photo_outlined,
                      color: context.primaryColor,
                      size: 28,
                    )
                  : Image.file(File(_couponImagePath!), fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coupon Image *',
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _couponImagePath == null
                        ? 'Tap to open camera or gallery'
                        : 'Image selected • Tap to change',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _couponImagePath == null
                  ? Icons.add_circle_outline
                  : Icons.edit_outlined,
              color: context.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // MAIN SCREEN
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FarmerCouponBloc, FarmerCouponState>(
      listenWhen: (previous, current) =>
          previous.success != current.success ||
          previous.error != current.error,
      listener: (context, state) {
        if (state.success != null) {
          final message = state.success!;

          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Booking Successful'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
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
            title: 'Farmer Coupon Booking',
            showBackButton: true,
            onBackTap: () => context.go(AppRouter.home),
          ),

          body: AbsorbPointer(
            absorbing: state.submitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                children: [
                  // HERO
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          color: context.primaryColor,
                          size: 29,
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Coupon Booking',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: context.primaryTextColor,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Farmer • Products • Coupon',
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

                  // // FARMER
                  // _section(
                  //   'Farmer Details',
                  //   Icons.person_outline,
                  // ),

                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: OutlinedButton.icon(
                  //     onPressed: widget.onAddFarmer,
                  //     icon: const Icon(
                  //       Icons.person_add_alt_1_outlined,
                  //       size: 17,
                  //     ),
                  //     label: const Text('Add New Farmer'),
                  //     style: OutlinedButton.styleFrom(
                  //       foregroundColor: context.primaryColor,
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 6),

                  _farmerSearchField(state),

                  const SizedBox(height: 12),

                  _productSelector(state),

                  // COUPON
                  _section(
                    'Coupon Details',
                    Icons.confirmation_number_outlined,
                  ),

                  _couponPhoto(),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          title: 'Coupon Number',
                          hint: 'Enter number',
                          controller: _couponNumberController,
                          numeric: true,
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: _field(
                          title: 'Gift Given',
                          hint: 'Enter gift',
                          controller: _giftController,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          title: 'Booking Amount',
                          hint: 'Amount',
                          controller: _bookingAmountController,
                          numeric: true,
                          decimal: true,
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: _field(
                          title: 'Coupons Booked',
                          hint: 'Quantity',
                          controller: _quantityController,
                          numeric: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // AUTO CALCULATED TOTAL
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Booking Amount',
                                style: TextStyle(
                                  color: context.onPrimaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Calculated automatically',
                                style: TextStyle(
                                  color: context.onPrimaryColor.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${NumberFormat('#,##0.00').format(_totalAmount)}',
                          style: TextStyle(
                            color: context.onPrimaryColor,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FIXED BUTTON
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: state.submitting
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: context.onPrimaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    state.submitting
                        ? 'Submitting...'
                        : 'Submit Coupon Booking',
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
