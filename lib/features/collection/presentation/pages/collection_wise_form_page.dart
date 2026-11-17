import 'package:solufine/features/collection/data/models/bank_model.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:solufine/core/di/collection_di.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/image_compression.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/features/collection/domain/entities/collection_type_entity.dart';
import 'package:solufine/features/collection/domain/entities/dealer.dart';
import 'package:solufine/features/collection/presentation/bloc/collection_bloc.dart';
import 'package:solufine/features/collection/presentation/bloc/collection_event.dart';
import 'package:solufine/features/collection/presentation/bloc/collection_state.dart';
import 'package:solufine/features/collection/presentation/pages/dealer_search_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CollectionWiseFormPage extends StatefulWidget {
  const CollectionWiseFormPage({super.key});

  @override
  State<CollectionWiseFormPage> createState() => _CollectionWiseFormPageState();
}

class _CollectionWiseFormPageState extends State<CollectionWiseFormPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController amountController = TextEditingController(
    text: '0.00',
  );

  final TextEditingController rtgsController = TextEditingController();

  final TextEditingController neftController = TextEditingController();

  final TextEditingController chequeNumberController = TextEditingController();

  final TextEditingController chequeDateController = TextEditingController();

  final TextEditingController bankNameController = TextEditingController();

  final TextEditingController depositBankNameController =
      TextEditingController();

  final TextEditingController depositBranchController = TextEditingController();
  final TextEditingController depositAccountController =
      TextEditingController();
  BankModel? _selectedDepositBank;

  final TextEditingController remarkController = TextEditingController();

  final TextEditingController upiController = TextEditingController();

  final TextEditingController upiTransactionController =
      TextEditingController();

  // ============================================================
  // IMAGE
  // ============================================================

  final ImagePicker imagePicker = ImagePicker();

  List<File> selectedImages = [];

  // ============================================================
  // BLOC
  // ============================================================

  late CollectionBloc bloc;

  // ============================================================
  // DATA
  // ============================================================

  String? paymentMode;

  String dealerId = '';
  String dealerName = '';
  String userId = '';
  String? selectedCollectionTypeId;
  String? selectedCollectionTypeName;

  // ============================================================
  // PAYMENT MODES
  // ============================================================

  final List<String> paymentModes = ['Cash', 'Cheque', 'RTGS', 'NEFT', 'UPI'];

  final Map<String, TextEditingController> collectionAmountControllers = {};

  TextEditingController _getCollectionAmountController(
    String collectionTypeId,
  ) {
    if (!collectionAmountControllers.containsKey(collectionTypeId)) {
      collectionAmountControllers[collectionTypeId] = TextEditingController();
    }

    return collectionAmountControllers[collectionTypeId]!;
  }

  double get collectionTotalAmount {
    double total = 0;

    for (final controller in collectionAmountControllers.values) {
      final double amount = double.tryParse(controller.text.trim()) ?? 0;

      total += amount;
    }

    return total;
  }

  @override
  void initState() {
    super.initState();

    bloc = sl<CollectionBloc>();

    _loadUser();
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> _loadUser() async {
    try {
      final userData = await SecureStorage.instance.getUserData();

      if (!mounted) return;

      final loadedUserId = userData?['user_id']?.toString() ?? '';

      setState(() {
        userId = loadedUserId;
      });

      debugPrint('USER ID = $userId');

      // LOAD COLLECTION TYPES
      bloc.add(const GetCollectionTypeEvent());
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    amountController.dispose();
    rtgsController.dispose();
    neftController.dispose();
    chequeNumberController.dispose();
    chequeDateController.dispose();
    bankNameController.dispose();
    depositBankNameController.dispose();
    depositBranchController.dispose();
    depositAccountController.dispose();
    remarkController.dispose();
    upiController.dispose();
    upiTransactionController.dispose();

    for (final controller in collectionAmountControllers.values) {
      controller.dispose();
    }

    bloc.close();

    super.dispose();
  }

  void _onPaymentModeChanged(String? mode) {
    if (mode == null) return;

    _clearPaymentFields();

    setState(() {
      paymentMode = mode;
    });
  }

  void _clearPaymentFields() {
    rtgsController.clear();
    neftController.clear();
    chequeNumberController.clear();
    chequeDateController.clear();
    bankNameController.clear();
    depositBankNameController.clear();
    depositBranchController.clear();
    depositAccountController.clear();
    _selectedDepositBank = null;
    upiController.clear();
    upiTransactionController.clear();
  }

  // ============================================================
  // CHEQUE DATE
  // ============================================================

  Future<void> _selectChequeDate() async {
    final today = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: context.appColors),
          child: child!,
        );
      },
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    final day = pickedDate.day.toString().padLeft(2, '0');
    final month = pickedDate.month.toString().padLeft(2, '0');

    chequeDateController.text = '$day-$month-${pickedDate.year}';

    setState(() {});
  }

  Future<void> _pickImages() async {
    try {
      // ============================================================
      // PICK MULTIPLE IMAGES
      // ============================================================

      final files = await imagePicker.pickMultiImage(
        // Keep picker quality high.
        // Actual compression will be done below.
        imageQuality: 100,
      );

      if (files.isEmpty) {
        return;
      }

      // ============================================================
      // FINAL COMPRESSED IMAGE LIST
      // ============================================================

      final List<File> compressedImages = [];

      // ============================================================
      // COMPRESS EACH IMAGE
      // ============================================================

      for (final pickedImage in files) {
        final File originalFile = File(pickedImage.path);

        if (!await originalFile.exists()) {
          debugPrint('IMAGE FILE DOES NOT EXIST: ${pickedImage.path}');

          continue;
        }

        // ========================================================
        // ORIGINAL IMAGE INFO
        // ========================================================

        final int originalSize = await originalFile.length();

        debugPrint('========================================');

        debugPrint('ORIGINAL PATH: ${originalFile.path}');

        debugPrint(
          'ORIGINAL SIZE: '
          '${(originalSize / 1024).toStringAsFixed(2)} KB',
        );

        // ========================================================
        // COMPRESS IMAGE
        // ========================================================

        final File? compressedFile = await ImageCompression.compressImage(
          originalFile,
          maxWidth: 450,
          maxHeight: 450,
          quality: 45,
        );

        // ========================================================
        // USE COMPRESSED IMAGE
        // ========================================================

        if (compressedFile != null && await compressedFile.exists()) {
          final int compressedSize = await compressedFile.length();

          debugPrint('USING COMPRESSED IMAGE');

          debugPrint('COMPRESSED PATH: ${compressedFile.path}');

          debugPrint(
            'COMPRESSED SIZE: '
            '${(compressedSize / 1024).toStringAsFixed(2)} KB',
          );

          compressedImages.add(compressedFile);
        } else {
          // ======================================================
          // COMPRESSION FAILED -> USE ORIGINAL
          // ======================================================

          debugPrint('COMPRESSION FAILED - USING ORIGINAL IMAGE');

          debugPrint('ORIGINAL PATH: ${originalFile.path}');

          compressedImages.add(originalFile);
        }

        debugPrint('========================================');
      }

      // ============================================================
      // UPDATE UI
      // ============================================================

      if (!mounted) {
        return;
      }

      setState(() {
        selectedImages = compressedImages;
      });

      debugPrint(
        'Selected compressed images = '
        '${selectedImages.length}',
      );

      // ============================================================
      // FINAL SIZE DEBUG
      // ============================================================

      for (int i = 0; i < selectedImages.length; i++) {
        final File file = selectedImages[i];

        final int bytes = await file.length();

        debugPrint(
          'Image ${i + 1} => '
          '${(bytes / 1024).toStringAsFixed(2)} KB',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Image picker/compression error: $e');

      debugPrint('$stackTrace');

      _showMessage('Unable to select images');
    }
  }

  // ============================================================
  // REMOVE IMAGE
  // ============================================================

  void _removeImage(int index) {
    if (index < 0 || index >= selectedImages.length) {
      return;
    }

    setState(() {
      selectedImages.removeAt(index);
    });
  }

  // ============================================================
  // SELECT DEALER
  // ============================================================

  Future<void> _selectDealer() async {
    if (userId.trim().isEmpty) {
      _showMessage('User information not available');

      return;
    }

    debugPrint('=========================================');
    debugPrint('OPEN DEALER SEARCH');
    debugPrint('USER ID = $userId');
    debugPrint('=========================================');

    final Dealer? selectedDealer = await showModalBottomSheet<Dealer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: bloc,
          child: DealerSearchBottomSheet(userId: userId),
        );
      },
    );

    if (!mounted || selectedDealer == null) {
      return;
    }

    setState(() {
      dealerId = selectedDealer.id;
      dealerName = selectedDealer.name;
      depositBankNameController.clear();
      depositBranchController.clear();
      depositAccountController.clear();
      _selectedDepositBank = null;
    });

    debugPrint('=========================================');
    bloc.add(GetBankDetailsEvent(dealerId: dealerId, userId: userId));
    debugPrint('DEALER SELECTED');
    debugPrint('DEALER ID = $dealerId');
    debugPrint('DEALER NAME = $dealerName');
    debugPrint('=========================================');
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validateForm() {
    // ----------------------------------------------------------
    // DEALER
    // ----------------------------------------------------------

    if (dealerId.trim().isEmpty) {
      _showMessage('Please select dealer');

      return false;
    }

    // ----------------------------------------------------------
    // AMOUNT
    // ----------------------------------------------------------

    if (amountController.text.trim().isEmpty) {
      _showMessage('Please enter amount');

      return false;
    }

    // ----------------------------------------------------------
    // PAYMENT MODE
    // ----------------------------------------------------------

    if (paymentMode == null || paymentMode!.trim().isEmpty) {
      _showMessage('Please select payment mode');

      return false;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      _showMessage('Please enter valid amount');

      return false;
    }

    // ----------------------------------------------------------
    // CHEQUE
    // ----------------------------------------------------------

    if (paymentMode == 'Cheque') {
      if (chequeNumberController.text.trim().isEmpty) {
        _showMessage('Please enter cheque number');

        return false;
      }

      if (chequeDateController.text.trim().isEmpty) {
        _showMessage('Please select cheque date');

        return false;
      }

      if (bankNameController.text.trim().isEmpty) {
        _showMessage('Please enter bank name');

        return false;
      }

      if (depositBankNameController.text.trim().isEmpty) {
        _showMessage('Please select deposit bank');

        return false;
      }

      if (depositBranchController.text.trim().isEmpty) {
        _showMessage('Please enter deposit branch');

        return false;
      }
    }

    // ----------------------------------------------------------
    // RTGS
    // ----------------------------------------------------------

    if (paymentMode == 'RTGS' && rtgsController.text.trim().isEmpty) {
      _showMessage('Please enter RTGS number');

      return false;
    }

    // ----------------------------------------------------------
    // NEFT
    // ----------------------------------------------------------

    if (paymentMode == 'NEFT' && neftController.text.trim().isEmpty) {
      _showMessage('Please enter NEFT number');

      return false;
    }

    // ----------------------------------------------------------
    // UPI
    // ----------------------------------------------------------

    if (paymentMode == 'UPI') {
      if (upiController.text.trim().isEmpty) {
        _showMessage('Please enter UPI ID');

        return false;
      }

      if (upiTransactionController.text.trim().isEmpty) {
        _showMessage('Please enter UPI transaction number');

        return false;
      }
    }

    // ----------------------------------------------------------
    // USER
    // ----------------------------------------------------------

    if (userId.trim().isEmpty) {
      _showMessage('User information not available');

      return false;
    }

    return true;
  }

  // ============================================================
  // SUBMIT
  // ============================================================
  void _submit(CollectionState state) {
    // ============================================================
    // PREVENT DUPLICATE API
    // ============================================================

    if (bloc.state.status == CollectionStatus.loading) {
      return;
    }

    // ============================================================
    // VALIDATION
    // ============================================================

    if (!_validateForm()) {
      return;
    }

    // ============================================================
    // COLLECTION TYPE DATA
    // ============================================================

    final List<Map<String, dynamic>> collectionTypeList = [];

    for (final item in state.collectionTypes) {
      final TextEditingController? controller =
          collectionAmountControllers[item.collectionTypeId];

      final String enteredAmount = controller?.text.trim() ?? '';

      final double amount = double.tryParse(enteredAmount) ?? 0;

      collectionTypeList.add({
        'collectionTypeId': item.collectionTypeId,

        'amount': amount.toStringAsFixed(2),
      });
    }

    // ============================================================
    // FINAL COLLECTION TYPE JSON
    // ============================================================

    final Map<String, dynamic> collectionTypeMap = {
      'collectionTypes': collectionTypeList,

      'totalAmount': collectionTotalAmount.toStringAsFixed(2),
    };

    final String collectionTypeData = jsonEncode(collectionTypeMap);

    // ============================================================
    // DEBUG
    // ============================================================

    debugPrint('=========================================');

    debugPrint('SUBMIT COLLECTION');

    debugPrint('=========================================');

    debugPrint('Dealer ID: $dealerId');

    debugPrint('Dealer Name: $dealerName');

    debugPrint('Payment Mode: $paymentMode');

    debugPrint(
      'Total Amount: '
      '${collectionTotalAmount.toStringAsFixed(2)}',
    );

    debugPrint('User ID: $userId');

    debugPrint('Images: ${selectedImages.length}');

    debugPrint(
      'Collection Type Data: '
      '$collectionTypeData',
    );

    debugPrint('=========================================');

    // ============================================================
    // SUBMIT EVENT
    // ============================================================

    bloc.add(
      SubmitPaymentEvent(
        dealerId: dealerId,

        paymentMode: paymentMode!,

        // If main amount should be total:
        amount: collectionTotalAmount.toStringAsFixed(2),

        rtgsNo: rtgsController.text.trim(),

        neftNo: neftController.text.trim(),

        chequeDate: chequeDateController.text.trim(),

        chequeNumber: chequeNumberController.text.trim(),

        bankName: bankNameController.text.trim(),

        depositBankName: depositBankNameController.text.trim(),

        depositBranchName: depositBranchController.text.trim(),

        remark: remarkController.text.trim(),

        transaction: upiTransactionController.text.trim(),

        userId: userId,

        images: selectedImages,

        collectionTypeData: collectionTypeData,
      ),
    );
  }
  /*
  void _submit() {
    // Prevent duplicate API calls
    if (bloc.state.status == CollectionStatus.loading) {
      return;
    }

    if (!_validateForm()) {
      return;
    }

    debugPrint('=========================================');
    debugPrint('SUBMIT COLLECTION');
    debugPrint('=========================================');

    debugPrint('Dealer ID: $dealerId');

    debugPrint('Dealer Name: $dealerName');

    debugPrint('Payment Mode: $paymentMode');

    debugPrint('Amount: ${amountController.text.trim()}');

    debugPrint('User ID: $userId');

    debugPrint('Images: ${selectedImages.length}');

    debugPrint('=========================================');

    bloc.add(
      SubmitPaymentEvent(
        dealerId: dealerId,

        paymentMode: paymentMode!,

        amount: amountController.text.trim(),

        rtgsNo: rtgsController.text.trim(),

        neftNo: neftController.text.trim(),

        chequeDate: chequeDateController.text.trim(),

        chequeNumber: chequeNumberController.text.trim(),

        bankName: bankNameController.text.trim(),

        depositBankName: depositBankNameController.text.trim(),

        depositBranchName: depositBranchController.text.trim(),

        remark: remarkController.text.trim(),

        transaction: upiTransactionController.text.trim(),

        userId: userId,

        images: selectedImages,
        collectionTypeData: 
      ),
    );
  }
*/
  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showSuccessDialog(String message) async {
    if (!mounted) return;

    final router = GoRouter.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // ==================================================
              // SUCCESS ICON
              // ==================================================
              Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  color: dialogContext.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: dialogContext.primaryColor,
                  size: 54,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // TITLE
              // ==================================================
              Text(
                'Collection Submitted!',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardValue.copyWith(
                  color: dialogContext.cardTextColor,
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // MESSAGE
              // ==================================================
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  height: 1.45,
                  color: dialogContext.secondaryTextColor,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // OK BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogContext.primaryColor,

                    foregroundColor: dialogContext.onPrimaryColor,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: Text('OK', style: AppTextStyles.labelLarge),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (router.canPop()) {
      router.pop(true);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(16),

        duration: const Duration(seconds: 2),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

        content: Text(message, style: AppTextStyles.body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,

      child: BlocConsumer<CollectionBloc, CollectionState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == CollectionStatus.success) {
            _showSuccessDialog(
              state.message ?? 'Collection submitted successfully.',
            );

            return;
          }

          if (state.status == CollectionStatus.failure) {
            _showMessage(state.message ?? 'Payment submission failed');
          }
        },

        // listener: (context, state) {
        //   // ======================================================
        //   // SUCCESS
        //   // ======================================================

        //   if (state.status == CollectionStatus.success) {
        //     _showSuccessDialog(
        //       state.message ?? 'Collection submitted successfully.',
        //     );

        //     return;
        //   }

        //   // ======================================================
        //   // FAILURE
        //   // ======================================================

        //   if (state.status == CollectionStatus.failure) {
        //     _showMessage(state.message ?? 'Payment submission failed');
        //   }
        // },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.backgroundColor,

            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            appBar: CustomAppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 19,
                  color: context.appThemeData.appBarTheme.foregroundColor,
                ),
                onPressed: () {
                  context.go(AppRouter.home);
                },
              ),
              title: 'Add Collection',
              // titleStyle: const TextStyle(
              //   fontSize: 22,
              //   fontWeight: FontWeight.w600,
              //   color: AppColors.backgroundColor,
              // ),
            ),

            body: CustomScrollView(
              slivers: [
                // ==================================================
                // HEADER
                // ==================================================
                // _buildHeader(),

                // ==================================================
                // BODY
                // ==================================================
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),

                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // DEALER
                      _buildDealerCard(state.collectionTypes),

                      if (dealerId.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),

                        if (state.collectionTypes.isNotEmpty) ...[
                          Text(
                            'Collection Type',
                            style: AppTextStyles.label.copyWith(
                              color: context.cardTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        ...state.collectionTypes.map(
                          (item) => _buildCollectionAmountRow(item: item),
                        ),

                        const SizedBox(height: 4),

                        // ============================================================
                        // TOTAL AMOUNT
                        // ============================================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total Amount',
                                  style: AppTextStyles.labelLarge,
                                ),
                              ),

                              Text(
                                '₹ ${collectionTotalAmount.toStringAsFixed(2)}',
                                style: AppTextStyles.cardTitle.copyWith(
                                  color: context.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // PAYMENT
                      _buildPaymentCard(),

                      const SizedBox(height: 12),

                      // REMARK
                      _buildRemarkCard(),

                      const SizedBox(height: 12),

                      // IMAGES
                      _buildImageCard(),

                      const SizedBox(height: 18),

                      // SUBMIT
                      _buildSubmitButton(),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionAmountRow({required CollectionTypeEntity item}) {
    final TextEditingController controller = _getCollectionAmountController(
      item.collectionTypeId,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.collectionType,
                  style: AppTextStyles.label.copyWith(
                    color: context.cardTextColor,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                width: 135,
                child: TextField(
                  style: AppTextStyles.input,
                  controller: controller,

                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],

                  onChanged: (_) {
                    amountController.text = collectionTotalAmount
                        .toStringAsFixed(2);
                    setState(() {});
                  },

                  decoration: InputDecoration(
                    hintText: 'Enter Amt',

                    prefixText: '₹ ',

                    isDense: true,

                    filled: true,

                    fillColor: context.appTheme.inputBackground,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDealerCard(List<CollectionTypeEntity> collectionTypes) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================================================
          // HEADER
          // =========================================================
          _sectionHeader(
            icon: Icons.storefront_rounded,
            title: 'Dealer',
            subtitle: 'Select dealer for this collection',
          ),

          const SizedBox(height: 12),

          // =========================================================
          // DEALER SELECTOR
          // =========================================================
          InkWell(
            onTap: _selectDealer,

            borderRadius: BorderRadius.circular(14),

            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.all(13),

              decoration: BoxDecoration(
                color: context.appTheme.inputBackground,

                borderRadius: BorderRadius.circular(14),

                border: Border.all(color: context.borderColor),
              ),

              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,

                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Icon(
                      Icons.store_rounded,
                      color: context.primaryColor,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          dealerName.isEmpty ? 'Select dealer *' : dealerName,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: AppTextStyles.labelLarge.copyWith(
                            color: dealerName.isEmpty
                                ? context.secondaryTextColor
                                : context.cardTextColor,
                          ),
                        ),

                        const SizedBox(height: 3),
                      ],
                    ),
                  ),

                  Container(
                    height: 34,
                    width: 34,

                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Icon(
                      Icons.search_rounded,
                      color: context.primaryColor,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // // =========================================================
          // // COLLECTION TYPE
          // // ONLY SHOW AFTER DEALER SELECTED
          // // =========================================================
          // if (dealerSelected) ...[
          //   const SizedBox(height: 14),

          //   Container(
          //     width: double.infinity,

          //     padding: const EdgeInsets.all(12),

          //     decoration: BoxDecoration(
          //       color: const Color(0xFFF8FAF8),

          //       borderRadius: BorderRadius.circular(14),

          //       border: Border.all(color: const Color(0xFFE2E8E5)),
          //     ),

          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,

          //       children: [
          //         // ===============================================
          //         // COLLECTION TYPE HEADER
          //         // ===============================================
          //         Row(
          //           children: [
          //             Container(
          //               width: 32,
          //               height: 32,

          //               decoration: BoxDecoration(
          //                 color: const Color(0xFFE7F5EC),

          //                 borderRadius: BorderRadius.circular(9),
          //               ),

          //               child: const Icon(
          //                 Icons.account_balance_wallet_rounded,
          //                 size: 17,
          //                 color: Color(0xFF166534),
          //               ),
          //             ),

          //             const SizedBox(width: 8),

          //             const Expanded(
          //               child: Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   Text(
          //                     'Collection Type *',
          //                     style: TextStyle(
          //                       fontSize: 13,
          //                       fontWeight: FontWeight.w800,
          //                       color: Color(0xFF17201B),
          //                     ),
          //                   ),

          //                   SizedBox(height: 2),

          //                   Text(
          //                     'Select collection year',
          //                     style: TextStyle(
          //                       fontSize: 10,
          //                       color: Color(0xFF718078),
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ],
          //         ),

          //         const SizedBox(height: 10),

          //         // ===============================================
          //         // API LOADING / EMPTY / DATA
          //         // ===============================================
          //         if (collectionTypes.isEmpty)
          //           Container(
          //             width: double.infinity,

          //             padding: const EdgeInsets.symmetric(vertical: 16),

          //             alignment: Alignment.center,

          //             child: const Text(
          //               'No collection type available',
          //               style: TextStyle(
          //                 fontSize: 11,
          //                 color: Color(0xFF718078),
          //               ),
          //             ),
          //           )
          //         else
          //           Wrap(
          //             spacing: 8,
          //             runSpacing: 8,

          //             children: collectionTypes.map((
          //               CollectionTypeEntity item,
          //             ) {
          //               final bool isSelected =
          //                   selectedCollectionTypeId == item.collectionTypeId;

          //               return InkWell(
          //                 onTap: () {
          //                   setState(() {
          //                     selectedCollectionTypeId = item.collectionTypeId;

          //                     selectedCollectionTypeName = item.collectionType;
          //                   });

          //                   debugPrint(
          //                     '========================================',
          //                   );

          //                   debugPrint('COLLECTION TYPE SELECTED');

          //                   debugPrint('ID: ${item.collectionTypeId}');

          //                   debugPrint('TYPE: ${item.collectionType}');

          //                   debugPrint(
          //                     '========================================',
          //                   );
          //                 },

          //                 borderRadius: BorderRadius.circular(10),

          //                 child: AnimatedContainer(
          //                   duration: const Duration(milliseconds: 180),

          //                   padding: const EdgeInsets.symmetric(
          //                     horizontal: 12,
          //                     vertical: 9,
          //                   ),

          //                   decoration: BoxDecoration(
          //                     color: isSelected
          //                         ? const Color(0xFFE7F5EC)
          //                         : Colors.white,

          //                     borderRadius: BorderRadius.circular(10),

          //                     border: Border.all(
          //                       color: isSelected
          //                           ? const Color(0xFF166534)
          //                           : const Color(0xFFDCE4DF),
          //                       width: isSelected ? 1.4 : 1,
          //                     ),
          //                   ),

          //                   child: Row(
          //                     mainAxisSize: MainAxisSize.min,

          //                     children: [
          //                       Container(
          //                         width: 18,
          //                         height: 18,

          //                         decoration: BoxDecoration(
          //                           shape: BoxShape.circle,

          //                           color: isSelected
          //                               ? const Color(0xFF166534)
          //                               : Colors.transparent,

          //                           border: Border.all(
          //                             color: isSelected
          //                                 ? const Color(0xFF166534)
          //                                 : const Color(0xFF9AA7A0),
          //                           ),
          //                         ),

          //                         child: isSelected
          //                             ? const Icon(
          //                                 Icons.check_rounded,
          //                                 color: Colors.white,
          //                                 size: 12,
          //                               )
          //                             : null,
          //                       ),

          //                       const SizedBox(width: 7),

          //                       Text(
          //                         item.collectionType,

          //                         style: TextStyle(
          //                           fontSize: 11.5,

          //                           fontWeight: isSelected
          //                               ? FontWeight.w800
          //                               : FontWeight.w600,

          //                           color: isSelected
          //                               ? const Color(0xFF166534)
          //                               : const Color(0xFF37443D),
          //                         ),
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               );
          //             }).toList(),
          //           ),

          //         // ===============================================
          //         // SELECTED VALUE
          //         // ===============================================
          //         if (selectedCollectionTypeId != null) ...[
          //           const SizedBox(height: 10),

          //           Container(
          //             width: double.infinity,

          //             padding: const EdgeInsets.symmetric(
          //               horizontal: 10,
          //               vertical: 8,
          //             ),

          //             decoration: BoxDecoration(
          //               color: const Color(0xFFEAF7EF),

          //               borderRadius: BorderRadius.circular(9),
          //             ),

          //             child: Row(
          //               children: [
          //                 const Icon(
          //                   Icons.check_circle_rounded,
          //                   size: 16,
          //                   color: Color(0xFF166534),
          //                 ),

          //                 const SizedBox(width: 6),

          //                 Expanded(
          //                   child: Text(
          //                     'Selected: $selectedCollectionTypeName',

          //                     style: const TextStyle(
          //                       fontSize: 10.5,

          //                       fontWeight: FontWeight.w700,

          //                       color: Color(0xFF166534),
          //                     ),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ],
          //       ],
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  // Widget _buildDealerCard(List<CollectionTypeEntity> collectionTypes) {
  //   return _buildCard(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,

  //       children: [
  //         _sectionHeader(
  //           icon: Icons.storefront_rounded,
  //           title: 'Dealer ',
  //           subtitle: 'Select dealer for this collection',
  //         ),

  //         const SizedBox(height: 12),

  //         InkWell(
  //           onTap: _selectDealer,

  //           borderRadius: BorderRadius.circular(14),

  //           child: Container(
  //             width: double.infinity,

  //             padding: const EdgeInsets.all(13),

  //             decoration: BoxDecoration(
  //               color: const Color(0xFFF5F7F6),

  //               borderRadius: BorderRadius.circular(14),

  //               border: Border.all(color: const Color(0xFFE2E8E5)),
  //             ),

  //             child: Row(
  //               children: [
  //                 Container(
  //                   height: 40,
  //                   width: 40,

  //                   decoration: BoxDecoration(
  //                     color: const Color(0xFFE7F5EC),

  //                     borderRadius: BorderRadius.circular(12),
  //                   ),

  //                   child: const Icon(
  //                     Icons.store_rounded,
  //                     color: Color(0xFF166534),
  //                     size: 21,
  //                   ),
  //                 ),

  //                 const SizedBox(width: 11),

  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,

  //                     children: [
  //                       Text(
  //                         dealerName.isEmpty ? 'Select dealer *' : dealerName,

  //                         maxLines: 1,

  //                         overflow: TextOverflow.ellipsis,

  //                         style: TextStyle(
  //                           fontSize: 14,

  //                           fontWeight: FontWeight.w700,

  //                           color: dealerName.isEmpty
  //                               ? Colors.black54
  //                               : const Color(0xFF17201B),
  //                         ),
  //                       ),

  //                       const SizedBox(height: 3),
  //                     ],
  //                   ),
  //                 ),

  //                 Container(
  //                   height: 34,
  //                   width: 34,

  //                   decoration: BoxDecoration(
  //                     color: const Color(0xFFE7F5EC),

  //                     borderRadius: BorderRadius.circular(10),
  //                   ),

  //                   child: const Icon(
  //                     Icons.search_rounded,
  //                     color: Color(0xFF166534),
  //                     size: 19,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ============================================================
  // PAYMENT CARD
  // ============================================================

  Widget _buildPaymentCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _sectionHeader(
            icon: Icons.payments_rounded,
            title: 'Payment Details',
            subtitle: 'Select method and enter amount',
          ),

          const SizedBox(height: 12),

          _buildAmountField(),

          const SizedBox(height: 12),

          _buildPaymentDropdown(),

          if (paymentMode != null) ...[
            const SizedBox(height: 12),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),

              child: _buildConditionalFields(),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // AMOUNT
  // ============================================================

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),

      decoration: BoxDecoration(
        color: context.primaryColor,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: context.borderColor),
      ),

      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,

            decoration: BoxDecoration(
              color: context.primaryColor,

              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              Icons.currency_rupee_rounded,
              color: context.onPrimaryColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: amountController,
              readOnly: true,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              style: AppTextStyles.cardValue.copyWith(color: context.appText),

              decoration: InputDecoration(
                border: InputBorder.none,

                // labelText: 'Collection Amount *',
                hintText: '0.00',
                hintStyle: AppTextStyles.inputHint.copyWith(
                  color: context.onPrimaryColor,
                ),

                labelStyle: AppTextStyles.inputLabel.copyWith(
                  color: context.onPrimaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT DROPDOWN
  // ============================================================

  Widget _buildPaymentDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: paymentMode,

      isExpanded: true,

      decoration: InputDecoration(
        labelText: 'Payment Method *',

        hintText: 'Select payment method',

        prefixIcon: Icon(
          Icons.account_balance_wallet_rounded,
          size: 20,
          color: context.primaryColor,
        ),

        filled: true,

        fillColor: context.appTheme.inputBackground,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: BorderSide(color: context.borderColor),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: BorderSide(color: context.primaryColor, width: 1.4),
        ),
      ),

      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.primaryColor,
      ),

      items: paymentModes.map((mode) {
        return DropdownMenuItem<String>(
          value: mode,

          child: Row(
            children: [
              Icon(_paymentIcon(mode), size: 19, color: context.primaryColor),

              const SizedBox(width: 10),

              Text(
                mode,

                style: AppTextStyles.labelLarge.copyWith(
                  color: context.cardTextColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),

      onChanged: _onPaymentModeChanged,
    );
  }

  // ============================================================
  // PAYMENT ICON
  // ============================================================

  IconData _paymentIcon(String mode) {
    switch (mode) {
      case 'Cash':
        return Icons.payments_outlined;

      case 'Cheque':
        return Icons.receipt_long_outlined;

      case 'RTGS':
        return Icons.account_balance_outlined;

      case 'NEFT':
        return Icons.swap_horiz_rounded;

      case 'UPI':
        return Icons.qr_code_2_rounded;

      default:
        return Icons.payment_rounded;
    }
  }

  // ============================================================
  // CONDITIONAL FIELDS
  // ============================================================

  Widget _buildConditionalFields() {
    switch (paymentMode) {
      case 'Cheque':
        return _buildChequeFields();

      case 'RTGS':
        return _buildSingleField(
          key: const ValueKey('rtgs'),

          controller: rtgsController,

          label: 'RTGS Number *',

          hint: 'Enter RTGS transaction number',

          icon: Icons.account_balance_rounded,
        );

      case 'NEFT':
        return _buildSingleField(
          key: const ValueKey('neft'),

          controller: neftController,

          label: 'NEFT Number *',

          hint: 'Enter NEFT transaction number',

          icon: Icons.swap_horiz_rounded,
        );

      case 'UPI':
        return _buildUpiFields();

      case 'Cash':
        return _buildCashInfo();

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // CASH
  // ============================================================

  Widget _buildCashInfo() {
    return Container(
      key: const ValueKey('cash'),

      width: double.infinity,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: context.borderColor),
      ),

      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: context.primaryColor,
            size: 20,
          ),

          SizedBox(width: 8),

          Expanded(
            child: Text(
              'Cash payment selected. No transaction details required.',
              style: AppTextStyles.buttonSmall.copyWith(
                color: context.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHEQUE
  // ============================================================

  Widget _buildDepositBankDropdown() {
    return BlocBuilder<CollectionBloc, CollectionState>(
      builder: (context, state) {
        final banks = state.banks
            .where(
              (bank) =>
                  bank.id != '0' &&
                  (bank.name.trim().isNotEmpty ||
                      bank.bankName.trim().isNotEmpty),
            )
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<BankModel>(
              key: ObjectKey(_selectedDepositBank),
              initialValue: banks.contains(_selectedDepositBank)
                  ? _selectedDepositBank
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Deposit Bank Name *',
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                helperText: dealerId.isEmpty
                    ? 'Select dealer first'
                    : state.bankLoading
                    ? 'Loading banks...'
                    : banks.isEmpty
                    ? (state.message ?? 'No deposit banks found')
                    : null,
              ),
              items: banks
                  .map(
                    (bank) => DropdownMenuItem(
                      value: bank,
                      child: Text(
                        bank.name.trim().isNotEmpty ? bank.name : bank.bankName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: dealerId.isEmpty || state.bankLoading
                  ? null
                  : (bank) {
                      setState(() {
                        _selectedDepositBank = bank;
                        depositBankNameController.text = bank == null
                            ? ''
                            : bank.name.trim().isNotEmpty
                            ? bank.name
                            : bank.bankName;
                        depositBranchController.text = bank?.branch ?? '';
                        depositAccountController.text = bank?.accountNo ?? '';
                      });
                    },
            ),
            if (state.bankLoading) const LinearProgressIndicator(),
            // if (dealerId.isNotEmpty && !state.bankLoading && banks.isEmpty)
            //   TextButton(
            //     onPressed: () => bloc.add(
            //       GetBankDetailsEvent(dealerId: dealerId, userId: userId),
            //     ),
            //     child: const Text('Reload banks'),
            //   ),
          ],
        );
      },
    );
  }

  Widget _buildChequeFields() {
    return Container(
      key: const ValueKey('cheque'),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: context.appTheme.inputBackground,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: context.borderColor),
      ),

      child: Column(
        children: [
          _buildInput(
            controller: chequeNumberController,

            label: 'Cheque Number *',

            hint: 'Enter cheque number',

            icon: Icons.receipt_long_rounded,
          ),

          const SizedBox(height: 10),

          _buildDateInput(),

          const SizedBox(height: 10),

          _buildInput(
            controller: bankNameController,

            label: 'Bank Name *',

            hint: 'Enter bank name',

            icon: Icons.account_balance_rounded,
          ),

          const SizedBox(height: 10),

          _buildDepositBankDropdown(),

          const SizedBox(height: 10),

          _buildInput(
            controller: depositBranchController,

            label: 'Deposit Branch *',

            hint: 'Filled from selected bank',
            readOnly: true,

            icon: Icons.location_city_rounded,
          ),
          const SizedBox(height: 10),
          _buildInput(
            controller: depositAccountController,
            label: 'Deposit Account Number',
            hint: 'Filled from selected bank',
            icon: Icons.numbers_rounded,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPI
  // ============================================================

  Widget _buildUpiFields() {
    return Container(
      key: const ValueKey('upi'),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: context.appTheme.inputBackground,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: context.borderColor),
      ),

      child: Column(
        children: [
          _buildInput(
            controller: upiController,

            label: 'UPI ID *',

            hint: 'example@upi',

            icon: Icons.qr_code_rounded,

            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 10),

          _buildInput(
            controller: upiTransactionController,

            label: 'Transaction Number *',

            hint: 'Enter UPI transaction number',

            icon: Icons.confirmation_number_rounded,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SINGLE FIELD
  // ============================================================

  Widget _buildSingleField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      key: key,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: context.appTheme.inputBackground,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: context.borderColor),
      ),

      child: _buildInput(
        controller: controller,

        label: label,

        hint: hint,

        icon: icon,
      ),
    );
  }

  // ============================================================
  // DATE INPUT
  // ============================================================

  Widget _buildDateInput() {
    return InkWell(
      onTap: _selectChequeDate,

      borderRadius: BorderRadius.circular(13),

      child: IgnorePointer(
        child: _buildInput(
          controller: chequeDateController,

          label: 'Cheque Date *',

          hint: 'Select cheque date',

          icon: Icons.calendar_month_rounded,
        ),
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,

      keyboardType: keyboardType,
      readOnly: readOnly,

      style: AppTextStyles.input,

      decoration: InputDecoration(
        labelText: label,

        hintText: hint,

        prefixIcon: Icon(icon, size: 19, color: context.secondaryTextColor),

        filled: true,

        fillColor: context.cardBackgroundColor,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),

          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),

          borderSide: BorderSide(color: context.borderColor),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),

          borderSide: BorderSide(color: context.primaryColor, width: 1.3),
        ),

        labelStyle: AppTextStyles.inputLabel,
      ),
    );
  }

  // ============================================================
  // REMARK CARD
  // ============================================================

  Widget _buildRemarkCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _sectionHeader(
            icon: Icons.notes_rounded,

            title: 'Remark',

            subtitle: 'Add additional information',
          ),

          const SizedBox(height: 12),

          TextField(
            controller: remarkController,

            maxLines: 3,

            style: AppTextStyles.input,

            decoration: InputDecoration(
              hintText: 'Write a remark...',

              filled: true,

              fillColor: context.appTheme.inputBackground,

              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 35),

                child: Icon(Icons.edit_note_rounded, size: 21),
              ),

              contentPadding: const EdgeInsets.all(13),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),

                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE CARD
  // ============================================================

  Widget _buildImageCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _sectionHeader(
            icon: Icons.photo_library_rounded,

            title: 'Payment Proof',

            subtitle: 'Attach payment related images',
          ),

          const SizedBox(height: 12),

          InkWell(
            onTap: _pickImages,

            borderRadius: BorderRadius.circular(14),

            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(vertical: 16),

              decoration: BoxDecoration(
                color: context.appTheme.inputBackground,

                borderRadius: BorderRadius.circular(14),

                border: Border.all(color: context.borderColor),
              ),

              child: Column(
                children: [
                  Container(
                    height: 42,
                    width: 42,

                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),

                      borderRadius: BorderRadius.circular(13),
                    ),

                    child: Icon(
                      Icons.add_photo_alternate_rounded,

                      color: context.primaryColor,

                      size: 22,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text('Add payment images', style: AppTextStyles.label),

                  const SizedBox(height: 3),

                  Text(
                    selectedImages.isEmpty
                        ? 'Tap to select photos'
                        : '${selectedImages.length} image(s) selected',

                    style: AppTextStyles.caption.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // SELECTED IMAGES
          // ======================================================
          if (selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: selectedImages.length,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,

                crossAxisSpacing: 7,

                mainAxisSpacing: 7,
              ),

              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: Image.file(
                          selectedImages[index],

                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 5,
                      right: 5,

                      child: GestureDetector(
                        onTap: () => _removeImage(index),

                        child: Container(
                          height: 25,
                          width: 25,

                          decoration: BoxDecoration(
                            color: context.primaryColor,

                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            Icons.close_rounded,

                            color: context.onPrimaryColor,

                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton() {
    return BlocBuilder<CollectionBloc, CollectionState>(
      builder: (context, state) {
        final bool loading = state.status == CollectionStatus.loading;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),

            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(alpha: 0.20),

                blurRadius: 15,

                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: SizedBox(
            width: double.infinity,

            height: 52,

            child: ElevatedButton(
              onPressed: loading
                  ? null
                  : () {
                      _submit(state);
                    },

              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,

                foregroundColor: context.onPrimaryColor,

                disabledBackgroundColor: context.appColors.onSurface.withValues(
                  alpha: 0.12,
                ),

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              child: loading
                  ? SizedBox(
                      height: 21,

                      width: 21,

                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,

                        color: context.onPrimaryColor,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 20),

                        SizedBox(width: 8),

                        Text(
                          'Submit Collection',
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // COMMON CARD
  // ============================================================

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: context.cardBackgroundColor,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: context.borderColor),

        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.025),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: child,
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          height: 38,

          width: 38,

          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),

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

                style: AppTextStyles.cardTitle.copyWith(
                  color: context.cardTextColor,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: AppTextStyles.caption.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
