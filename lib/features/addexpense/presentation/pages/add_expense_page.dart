import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/app_dialog.dart';
import 'package:solufine/core/utility/app_tutorial_service.dart';
import 'package:solufine/core/utility/image_compression.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/tutorial_description.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../domain/entities/expense_parameter_entity.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final openingKm = TextEditingController();
  final closingKm = TextEditingController();
  final totalKm = TextEditingController();
  final amountController = TextEditingController();
  final placeController = TextEditingController();
  final remarkController = TextEditingController();
  final dateController = TextEditingController();
  final daAmountController = TextEditingController();

  // ===========================================================================
  // STATE
  // ===========================================================================

  DateTime selectedDate = DateTime.now();

  DialogRoute<void>? _submissionDialog;

  String? daType;

  int? userId;

  double vehicleRate = 0;
  double travelAmount = 0;
  double extraExpenseTotal = 0;
  double finalTotalAmount = 0;
  double enteredKM = 0;

  final Map<String, TextEditingController> _expenseAmountControllers = {};

  final GlobalKey _expenseDateKey = GlobalKey();

  final GlobalKey _expenseDaKey = GlobalKey();

  final GlobalKey _addExpenseKey = GlobalKey();

  final GlobalKey _expenseRemarkKey = GlobalKey();

  bool _expenseTutorialRequested = false;

  bool _isTravelExpense(ExpenseParameterEntity expense) {
    final name = expense.fldExpName.trim().toLowerCase();

    return RegExp(
      r'\b(travel|traveling|travelling|travaling|traving)\b',
    ).hasMatch(name);
  }

  double _expenseAmount(ExpenseParameterEntity expense) {
    return _isTravelExpense(expense)
        ? double.tryParse(amountController.text) ?? 0
        : expense.amount;
  }

  void _showExpenseTutorialIfNeeded() {
    if (_expenseTutorialRequested) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _expenseTutorialRequested) {
        return;
      }

      // =========================================================
      // ENSURE UI TARGETS EXIST
      // =========================================================

      final bool targetsReady =
          _expenseDateKey.currentContext != null &&
          _expenseDaKey.currentContext != null &&
          _addExpenseKey.currentContext != null &&
          _expenseRemarkKey.currentContext != null;

      if (!targetsReady) {
        debugPrint('Expense tutorial targets not ready');

        return;
      }

      _expenseTutorialRequested = true;

      await AppTutorialService.showExpenseTutorial(
        context: context,

        targets: _buildExpenseTutorialTargets(),
      );
    });
  }

  List<TargetFocus> _buildExpenseTutorialTargets() {
    return [
      // ==========================================================
      // 1. EXPENSE DATE
      // ==========================================================
      TargetFocus(
        identify: 'expense_date',

        keyTarget: _expenseDateKey,

        shape: ShapeLightFocus.RRect,

        radius: 14,

        paddingFocus: 6,

        enableOverlayTab: false,
        enableTargetTab: false,

        contents: [
          TargetContent(
            align: ContentAlign.bottom,

            child: const TutorialDescription(
              step: '1 of 4',
              title: 'Expense Date',
              description:
                  'Select the date for which you want to enter your daily expense.',
            ),
          ),
        ],
      ),

      // ==========================================================
      // 2. SELECT DA
      // ==========================================================
      TargetFocus(
        identify: 'expense_da',

        keyTarget: _expenseDaKey,

        shape: ShapeLightFocus.RRect,

        radius: 12,

        paddingFocus: 6,

        enableOverlayTab: false,
        enableTargetTab: false,

        contents: [
          TargetContent(
            align: ContentAlign.top,

            child: const TutorialDescription(
              step: '2 of 4',
              title: 'Select DA',
              description:
                  'Select the applicable DA type. You can choose DA or Night Halt DA based on your eligibility.',
            ),
          ),
        ],
      ),

      // ==========================================================
      // 3. ADD EXPENSE
      // ==========================================================
      TargetFocus(
        identify: 'add_expense',

        keyTarget: _addExpenseKey,

        shape: ShapeLightFocus.RRect,

        radius: 14,

        paddingFocus: 6,

        enableOverlayTab: false,
        enableTargetTab: false,

        contents: [
          TargetContent(
            align: ContentAlign.top,

            child: const TutorialDescription(
              step: '3 of 4',
              title: 'Add Expenses',
              description:
                  'Tap here to add other expenses, enter the amount and attach the expense receipt.',
            ),
          ),
        ],
      ),

      // ==========================================================
      // 4. REMARK
      // ==========================================================
      TargetFocus(
        identify: 'expense_remark',

        keyTarget: _expenseRemarkKey,

        shape: ShapeLightFocus.RRect,

        radius: 12,

        paddingFocus: 6,

        enableOverlayTab: false,
        enableTargetTab: false,

        contents: [
          TargetContent(
            align: ContentAlign.top,

            child: const TutorialDescription(
              step: '4 of 4',
              title: 'Expense Remark',
              description:
                  'Enter any additional note or information related to this expense.',
              isLast: true,
            ),
          ),
        ],
      ),
    ];
  }

  TextEditingController _getExpenseAmountController(
    ExpenseParameterEntity expense,
  ) {
    final key = expense.fldExpId.toString();

    if (!_expenseAmountControllers.containsKey(key)) {
      _expenseAmountControllers[key] = TextEditingController(
        text: expense.amount > 0 ? expense.amount.toString() : '',
      );
    }

    return _expenseAmountControllers[key]!;
  }

  @override
  void initState() {
    super.initState();

    dateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);

    _loadInitialExpenses();
  }

  Future<void> _loadInitialExpenses() async {
    final userData = await SecureStorage.instance.getUserData();

    userId = int.tryParse(userData?['user_id']?.toString() ?? '');

    if (!mounted) {
      return;
    }

    context.read<ExpenseBloc>().add(
      LoadExpenseEvent(
        userId: userId.toString(),
        date: formatDate(dateController.text),
      ),
    );
  }

  @override
  void dispose() {
    openingKm.dispose();
    closingKm.dispose();
    totalKm.dispose();
    amountController.dispose();
    placeController.dispose();
    remarkController.dispose();
    dateController.dispose();
    daAmountController.dispose();

    for (final controller in _expenseAmountControllers.values) {
      controller.dispose();
    }

    _expenseAmountControllers.clear();

    super.dispose();
  }

  // ===========================================================================
  // DATE FORMAT
  // ===========================================================================

  String formatDate(String value) {
    final clean = value.split(' ').first;

    final date = DateFormat('dd-MM-yyyy').parse(clean);

    return DateFormat('yyyy-MM-dd').format(date);
  }

  // ===========================================================================
  // CALCULATE KM
  // ===========================================================================

  void calculateKM(ExpenseState state) {
    final open = double.tryParse(openingKm.text) ?? 0;

    final close = double.tryParse(closingKm.text) ?? 0;

    double total = close - open;

    if (total < 0) {
      total = 0;
    }

    enteredKM = total;

    totalKm.text = total.toStringAsFixed(0);

    travelAmount = total * vehicleRate;

    final da = double.tryParse(daAmountController.text) ?? 0;

    finalTotalAmount = travelAmount + da + extraExpenseTotal;

    amountController.text = travelAmount.toStringAsFixed(2);

    setState(() {});
  }

  // ===========================================================================
  // VEHICLE
  // ===========================================================================

  void selectVehicle(VehicleEntity vehicle) {
    vehicleRate = double.tryParse(vehicle.fldVehicleRateAdmin) ?? 0;

    openingKm.text = vehicle.fldStartingKm.isEmpty
        ? '0'
        : vehicle.fldStartingKm;

    closingKm.text = vehicle.fldClosingKm.isEmpty ? '0' : vehicle.fldClosingKm;

    calculateKM(context.read<ExpenseBloc>().state);
  }

  // ===========================================================================
  // DATE
  // ===========================================================================

  Future<void> pickDate(ExpenseState state) async {
    print('days is :${state.allowedDays}');

    final today = DateTime.now();

    final firstAllowed = today.subtract(Duration(days: state.allowedDays));

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstAllowed,
      lastDate: today,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = picked;

      dateController.text = DateFormat('dd-MM-yyyy').format(picked);
    });

    context.read<ExpenseBloc>().add(
      ChangeExpenseDateEvent(
        userId: userId.toString(),
        date: formatDate(dateController.text),
      ),
    );
  }

  // ===========================================================================
  // DA
  // ===========================================================================

  void selectDaType(String? value, ExpenseState state) {
    if (value == null) {
      return;
    }

    calculateKM(state);

    final kmLimit = state.apiKmLimit;

    if (enteredKM < kmLimit && state.fldOpeningClosingKm == '1') {
      AppDialog.show(
        context: context,
        message:
            'DA is not applicable for this trip. Minimum required distance is $kmLimit KM.',
        type: DialogType.error,
      );

      setState(() {
        daType = null;
      });

      return;
    }

    if (value == 'DA') {
      if (state.localDa <= 0) {
        AppDialog.show(
          context: context,
          message: 'You are not applicable for DA',
          type: DialogType.error,
        );

        setState(() {
          daType = null;

          daAmountController.clear();
        });

        calculateKM(state);

        return;
      }

      setState(() {
        daType = value;

        daAmountController.text = state.localDa.toStringAsFixed(2);
      });
    }

    if (value == 'NIGHT') {
      if (state.nightDa <= 0) {
        AppDialog.show(
          context: context,
          message: 'You are not applicable for Night Halt DA',
          type: DialogType.error,
        );

        setState(() {
          daType = null;

          daAmountController.clear();
        });

        calculateKM(state);

        return;
      }

      setState(() {
        daType = value;

        daAmountController.text = state.nightDa.toStringAsFixed(2);
      });
    }

    calculateKM(state);
  }

  // ===========================================================================
  // FIELD
  // ===========================================================================

  Widget buildField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    IconData? icon,
    double bottomPadding = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: AppTextStyles.input.copyWith(color: context.appOnCard),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.inputLabel.copyWith(
            color: context.appSubText,
          ),
          floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
            color: context.appPrimary,
          ),
          prefixIcon: icon == null
              ? null
              : Icon(icon, color: context.appPrimary, size: 19.sp),
          filled: true,
          fillColor: readOnly ? context.appInputBackground : context.appCard,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: context.appBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: context.appBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: context.appPrimary, width: 1.4),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseBloc, ExpenseState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ExpenseStatus.loaded) {
          final route = state.selectedVehicle?.fldTodaysRoute.trim() ?? '';
          if (route.isNotEmpty) {
            placeController.text = route;
          }
        }

        if (state.status != ExpenseStatus.submitting) {
          final dialog = _submissionDialog;

          _submissionDialog = null;

          if (dialog != null && dialog.isActive) {
            dialog.navigator?.removeRoute(dialog);
          }
        }

        if (state.status == ExpenseStatus.error) {
          AppDialog.show(
            context: context,
            message: state.errorMessage,
            type: DialogType.error,
          );
        }

        if (state.status == ExpenseStatus.success) {
          AppDialog.show(
            context: context,
            allowBack: false,
            message: state.successMessage ?? 'Expense Submit Successfully',
            type: DialogType.success,
            onOkPressed: () {
              if (context.mounted) {
                context.go(AppRouter.home);
              }
            },
          );
        }

        if (state.status == ExpenseStatus.submitting) {
          final dialog = DialogRoute<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => PopScope(
              canPop: false,
              child: AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Submitting expense...',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          _submissionDialog = dialog;

          Navigator.of(context, rootNavigator: true).push(dialog);
        }
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: CustomAppBar(
          title: 'Add Expense',
          showBackButton: true,
          onBackTap: () => context.go(AppRouter.home),
        ),
        body: BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            if (state.status == ExpenseStatus.loading) {
              return Center(child: CircularProgressIndicator());
            }

            if (state.status == ExpenseStatus.loaded &&
                (state.expStatus == 0 || state.expStatus == -1)) {
              _showExpenseTutorialIfNeeded();
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _expenseHeader(),

                  SizedBox(height: 12.h),

                  _dateSelector(state),

                  SizedBox(height: 12.h),

                  if (state.expStatus == 0 || state.expStatus == -1)
                    _buildExpenseForm(state)
                  else if (state.expStatus == 1)
                    _buildStatus(
                      Icons.check_circle_rounded,
                      context.appSuccess,
                      'Expenses Already Entered',
                    )
                  else if (state.expStatus == 2)
                    _buildStatus(
                      Icons.warning_amber_rounded,
                      context.appWarning,
                      'You Have Not Out-Punched Yet',
                    )
                  else
                    _buildStatus(
                      Icons.error_outline_rounded,
                      context.appSubText,
                      'You have not in-punched and out-punched',
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _expenseHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.appPrimary,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: context.appPrimary.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30.w,
            top: -35.h,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: context.appOnPrimary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: context.appOnPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: context.appOnPrimary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Expense',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: context.appOnPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Review travel and add today\'s expenses',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appOnPrimary.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: context.appOnPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'EXPENSE',
                  style: AppTextStyles.badge.copyWith(
                    color: context.appOnPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DATE
  // ===========================================================================

  Widget _dateSelector(ExpenseState state) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => pickDate(state),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          key: _expenseDateKey,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    context.appPrimary.withValues(alpha: 0.1),
                    context.appCard,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: context.appPrimary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Date',
                      style: AppTextStyles.caption.copyWith(
                        color: context.appSubText,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      dateController.text,
                      style: AppTextStyles.listTitle.copyWith(
                        color: context.appOnCard,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: context.appSubText,
                size: 21.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EXPENSE FORM
  // ===========================================================================

  Widget _buildExpenseForm(ExpenseState state) {
    final vehicle = state.selectedVehicle;

    if (vehicle != null && openingKm.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectVehicle(vehicle);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.route_rounded, 'Trip Details'),

        SizedBox(height: 7.h),

        _modernCard(
          child: Column(
            children: [
              buildField(
                'Visited Place *',
                placeController,
                icon: Icons.location_on_rounded,
              ),

              SizedBox(height: 9.h),

              _vehicleCard(state),

              if ((vehicle?.fldOpeningClosingKm ?? state.fldOpeningClosingKm) ==
                  '1') ...[
                SizedBox(height: 9.h),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: buildField(
                        'Opening KM',
                        openingKm,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: buildField(
                        'Closing KM',
                        closingKm,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: buildField('Total KM', totalKm, readOnly: true),
                    ),
                  ],
                ),

                SizedBox(height: 9.h),

                buildField(
                  'Traveling Amount',
                  amountController,
                  readOnly: true,
                  icon: Icons.currency_rupee_rounded,
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 12.h),

        _sectionTitle(Icons.account_balance_wallet_rounded, 'DA Details'),

        SizedBox(height: 7.h),

        _modernCard(
          child: Row(
            children: [
              Expanded(child: _daDropdown(state)),
              SizedBox(width: 9.w),
              Expanded(
                child: buildField(
                  'DA Amount',
                  daAmountController,
                  readOnly: true,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        _sectionTitle(Icons.add_card_rounded, 'Other Expenses'),

        SizedBox(height: 7.h),

        InkWell(
          key: _addExpenseKey,
          onTap: () {
            showExpenseSheet(state);
          },
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      context.appPrimary.withValues(alpha: 0.1),
                      context.appCard,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: context.appPrimary,
                    size: 21.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Expenses',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: context.appOnCard,
                        ),
                      ),
                      Text(
                        'Select receipt from gallery and enter amount',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: context.appSubText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: context.appSubText,
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 12.h),

        _totalCard(),

        SizedBox(height: 10.h),

        _modernCard(
          child: TextField(
            key: _expenseRemarkKey,
            style: AppTextStyles.input,
            controller: remarkController,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Remark',
              hintStyle: AppTextStyles.inputHint,
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                color: context.appPrimary,
              ),
              filled: true,
              fillColor: context.appInputBackground,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.r),
                borderSide: BorderSide(color: context.appBorder),
              ),
            ),
          ),
        ),

        SizedBox(height: 12.h),

        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: context.appPrimary,
              foregroundColor: context.appOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            onPressed: () {
              if (placeController.text.trim().isEmpty) {
                AppDialog.show(
                  context: context,
                  message: 'Please Enter Visited Place',
                  type: DialogType.error,
                );

                return;
              }

              submitExpense(state);
            },
            child: Text('SUBMIT EXPENSE', style: AppTextStyles.labelLarge),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION
  // ===========================================================================

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 29.w,
          height: 29.w,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              context.appPrimary.withValues(alpha: 0.1),
              context.appCard,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: context.appPrimary, size: 15.sp),
        ),
        SizedBox(width: 7.w),
        Text(
          title,
          style: AppTextStyles.listTitle.copyWith(color: context.appOnCard),
        ),
      ],
    );
  }

  Widget _modernCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: context.appBorder),
      ),
      child: child,
    );
  }

  // ===========================================================================
  // VEHICLE
  // ===========================================================================

  Widget _vehicleCard(ExpenseState state) {
    return IgnorePointer(
      child: Container(
        height: 47.h,
        padding: EdgeInsets.symmetric(horizontal: 11.w),
        decoration: BoxDecoration(
          color: context.appInputBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.directions_car_filled_rounded,
              color: context.appPrimary,
              size: 19.sp,
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VehicleEntity>(
                  value: state.selectedVehicle,
                  isExpanded: true,
                  items: state.vehicles.map((vehicle) {
                    return DropdownMenuItem<VehicleEntity>(
                      value: vehicle,
                      child: Text(
                        vehicle.fldVehicleType,
                        style: AppTextStyles.input,
                      ),
                    );
                  }).toList(),
                  onChanged: null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DA
  // ===========================================================================
  Widget _daDropdown(ExpenseState state) {
    return Container(
      key: _expenseDaKey,

      child: DropdownButtonFormField<String>(
        value: daType,

        isExpanded: true,

        isDense: true,

        hint: Text('Select DA Type', style: AppTextStyles.inputHint),

        decoration: InputDecoration(
          filled: true,
          fillColor: context.appCard,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        ),

        items: [
          DropdownMenuItem(
            value: 'DA',
            child: Text('DA', style: AppTextStyles.input),
          ),

          DropdownMenuItem(
            value: 'NIGHT',
            child: Text('Night Halt DA', style: AppTextStyles.input),
          ),
        ],

        onChanged: (value) => selectDaType(value, state),
      ),
    );
  }
  // Widget _daDropdown(ExpenseState state) {
  //   return DropdownButtonFormField<String>(
  //     value: daType,
  //     isExpanded: true,
  //     isDense: true,
  //     hint: Text('Select DA Type'),
  //     decoration: InputDecoration(
  //       filled: true,
  //       fillColor: context.appCard,
  //       isDense: true,
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
  //     ),
  //     items: const [
  //       DropdownMenuItem(value: 'DA', child: Text('DA')),
  //       DropdownMenuItem(value: 'NIGHT', child: Text('Night Halt DA')),
  //     ],
  //     onChanged: (value) => selectDaType(value, state),
  //   );
  // }

  // ===========================================================================
  // TOTAL
  // ===========================================================================

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          context.appPrimary.withValues(alpha: 0.1),
          context.appCard,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, color: context.appPrimary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text('Total Amount', style: AppTextStyles.labelLarge),
          ),
          Text(
            '₹ ${finalTotalAmount.toStringAsFixed(2)}',
            style: AppTextStyles.cardTitle.copyWith(color: context.appPrimary),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STATUS
  // ===========================================================================

  Widget _buildStatus(IconData icon, Color color, String text) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 35.h),
      padding: EdgeInsets.symmetric(vertical: 28.h),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48.sp, color: color),
          SizedBox(height: 12.h),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EXPENSE SHEET
  // ===========================================================================

  void showExpenseSheet(ExpenseState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.82,
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
            decoration: BoxDecoration(
              color: context.appInputBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            ),
            child: Column(
              children: [
                Container(
                  height: 4.h,
                  width: 42.w,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),

                SizedBox(height: 10.h),

                Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          context.appPrimary.withValues(alpha: 0.1),
                          context.appCard,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: context.appPrimary,
                      ),
                    ),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add Expenses', style: AppTextStyles.cardTitle),
                          Text(
                            'Enter amount and select receipt from gallery',
                            style: AppTextStyles.caption.copyWith(
                              color: context.appSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                Expanded(
                  child: BlocBuilder<ExpenseBloc, ExpenseState>(
                    builder: (blocContext, currentState) {
                      return ListView.builder(
                        itemCount: currentState.expenses.length,
                        itemBuilder: (listContext, index) {
                          final item = currentState.expenses[index];

                          final isTravelExpense = _isTravelExpense(item);

                          final expenseAmountController = isTravelExpense
                              ? amountController
                              : _getExpenseAmountController(item);

                          if (!isTravelExpense &&
                              (!expenseAmountController.selection.isValid ||
                                  !expenseAmountController
                                      .selection
                                      .isDirectional)) {
                            final expectedText = item.amount > 0
                                ? item.amount.toString()
                                : '';

                            if (expenseAmountController.text != expectedText &&
                                !expenseAmountController.selection.isValid) {
                              expenseAmountController.text = expectedText;
                            }
                          }

                          return _expenseItemCard(
                            sheetContext: sheetContext,
                            item: item,
                            index: index,
                            isTravelExpense: isTravelExpense,
                            controller: expenseAmountController,
                          );
                        },
                      );
                    },
                  ),
                ),

                SizedBox(height: 8.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text('Cancel', style: AppTextStyles.button),
                      ),
                    ),

                    SizedBox(width: 9.w),

                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appPrimary,
                          foregroundColor: context.appOnPrimary,
                        ),
                        onPressed: () {
                          final currentState = context
                              .read<ExpenseBloc>()
                              .state;

                          double tempTotal = 0.0;

                          for (final expense in currentState.expenses) {
                            final hasAmount = _expenseAmount(expense) > 0;

                            final hasImage = expense.imageFile != null;

                            if (!_isTravelExpense(expense) &&
                                hasAmount &&
                                !hasImage) {
                              Fluttertoast.showToast(
                                msg:
                                    'Please select image for ${expense.fldExpName}',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                              );

                              return;
                            }

                            if (!_isTravelExpense(expense) &&
                                hasImage &&
                                !hasAmount) {
                              Fluttertoast.showToast(
                                msg:
                                    'Please enter amount for ${expense.fldExpName}',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                              );

                              return;
                            }

                            if (!_isTravelExpense(expense)) {
                              tempTotal += expense.amount;
                            }
                          }

                          setState(() {
                            extraExpenseTotal = tempTotal;
                          });

                          calculateKM(currentState);

                          Navigator.pop(sheetContext);
                        },
                        icon: Icon(Icons.save),
                        label: Text('Save', style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _expenseItemCard({
    required BuildContext sheetContext,
    required ExpenseParameterEntity item,
    required int index,
    required bool isTravelExpense,
    required TextEditingController controller,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          // ================================================================
          // GALLERY IMAGE
          // ================================================================
          GestureDetector(
            onTap: isTravelExpense
                ? null
                : () async {
                    FocusScope.of(sheetContext).unfocus();

                    try {
                      // =====================================================
                      // NEW - OPEN GALLERY
                      // =====================================================

                      final ImagePicker picker = ImagePicker();

                      final XFile? pickedImage = await picker.pickImage(
                        source: ImageSource.gallery,

                        imageQuality: 85,
                      );

                      // User cancelled gallery
                      if (pickedImage == null ||
                          !mounted ||
                          !sheetContext.mounted) {
                        return;
                      }

                      // =====================================================
                      // SAME EXISTING COMPRESSION
                      // =====================================================

                      final file = await ImageCompression.compressImage(
                        File(pickedImage.path),
                        maxWidth: 400,
                        maxHeight: 400,
                        quality: 35,
                      );

                      if (file == null) {
                        throw Exception('Unable to compress expense image');
                      }

                      if (!mounted || !sheetContext.mounted) {
                        return;
                      }

                      final latestState = context.read<ExpenseBloc>().state;

                      if (index >= latestState.expenses.length) {
                        return;
                      }

                      final latestExpense = latestState.expenses[index];

                      // =====================================================
                      // SAME EXISTING BLOC EVENT
                      // =====================================================

                      context.read<ExpenseBloc>().add(
                        UpdateExpenseParameterEvent(
                          index: index,

                          amount: _expenseAmount(latestExpense),

                          image: file,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              'Unable to select image from gallery',
                              style: AppTextStyles.body,
                            ),
                            duration: Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    }
                  },

            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11.r),
                  child: item.imageFile != null
                      ? Image.file(
                          item.imageFile!,
                          height: 58.w,
                          width: 58.w,
                          fit: BoxFit.cover,
                        )
                      : _buildExpenseImage(item),
                ),

                if (!isTravelExpense)
                  Positioned(
                    right: 2.w,
                    bottom: 2.w,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: context.appPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        // CHANGED CAMERA ICON -> GALLERY ICON
                        Icons.photo_library_rounded,
                        size: 11.sp,
                        color: context.appOnPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(width: 10.w),

          // ================================================================
          // EXPENSE NAME + AMOUNT
          // ================================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fldExpName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(color: context.appOnCard),
                ),

                SizedBox(height: 5.h),

                SizedBox(
                  height: 42.h,
                  child: TextFormField(
                    style: AppTextStyles.input,
                    controller: controller,

                    readOnly: isTravelExpense,

                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),

                    decoration: InputDecoration(
                      hintText: 'Enter Amount',
                      hintStyle: AppTextStyles.inputHint,
                      errorStyle: AppTextStyles.inputError,

                      prefixText: '₹ ',

                      filled: true,

                      fillColor: isTravelExpense
                          ? context.appInputBackground
                          : context.appInputBackground,

                      isDense: true,

                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9.r),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9.r),
                        borderSide: BorderSide(color: context.appPrimary),
                      ),
                    ),

                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;

                      final latestState = context.read<ExpenseBloc>().state;

                      if (index >= latestState.expenses.length) {
                        return;
                      }

                      final latestExpense = latestState.expenses[index];

                      context.read<ExpenseBloc>().add(
                        UpdateExpenseParameterEvent(
                          index: index,

                          amount: amount,

                          image: latestExpense.imageFile,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DEFAULT IMAGE
  // ===========================================================================

  Widget _buildExpenseImage(ExpenseParameterEntity item) {
    return Container(
      height: 58.w,
      width: 58.w,
      decoration: BoxDecoration(
        color: context.appInputBackground,
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Icon(
        _isTravelExpense(item)
            ? Icons.directions_car_rounded
            // CHANGED CAMERA -> GALLERY
            : Icons.photo_library_outlined,
        color: context.appSubText,
        size: 21.sp,
      ),
    );
  }

  // ===========================================================================
  // SUBMIT
  // ===========================================================================

  void submitExpense(ExpenseState state) {
    final selected = state.selectedVehicle;

    final expenseJson = jsonEncode(
      state.expenses.map((e) {
        return {
          'fld_exp_id': e.fldExpId,

          'fld_exp_name': e.fldExpName,

          'Amount': _expenseAmount(e),

          'fldImageName': e.imageFile != null
              ? base64Encode(e.imageFile!.readAsBytesSync())
              : '',
        };
      }).toList(),
    );

    final fields = <String, String>{
      'user_id': userId.toString(),

      'expenses_date': DateFormat(
        'dd-MM-yyyy',
      ).format(DateFormat('yyyy-MM-dd').parse(formatDate(dateController.text))),

      'starting_kilometer': openingKm.text,

      'closing_kilometer': closingKm.text,

      'total_kilometer': totalKm.text,

      'visited_place': placeController.text.trim(),

      'journy_from': placeController.text.trim(),

      'journy_to': placeController.text.trim(),

      'travaling_amount': amountController.text.trim(),

      'travaling_mode': selected?.fldVehicleType ?? '',

      'total_amount': finalTotalAmount.toStringAsFixed(2),

      'remark': remarkController.text.trim(),

      'daAmount': daAmountController.text.trim(),

      'daType': daType ?? '',

      'vehicleTypeId': selected?.fldVehicleTypeId ?? '',

      'isExpenseExceed': '0',

      'isTotalExceedKm': '0',

      'expenseJson': expenseJson,
    };

    print('========== EXPENSE FIELDS ==========');

    fields.forEach((key, value) {
      print('$key: $value');
    });

    print('====================================');

    context.read<ExpenseBloc>().add(SubmitExpenseEvent(fields: fields));
  }
}
