import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/device_info_util.dart';
import 'package:solufine/core/utility/location_util.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';
import 'package:solufine/features/home/doman/home_entity/punch_stat_entity.dart';
import 'package:solufine/features/home/doman/home_entity/vehicle_type_entity.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_state.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';

import 'package:flutter/material.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LastForceOutScreen extends StatefulWidget {
  final PunchStatEntity? punchStat;

  const LastForceOutScreen(this.punchStat, {super.key});

  @override
  State<LastForceOutScreen> createState() => _LastForceOutScreenState();
}

class _LastForceOutScreenState extends State<LastForceOutScreen> {
  // ===========================================================================
  // FORM
  // ===========================================================================

  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final TextEditingController dateController = TextEditingController();

  final TextEditingController lastTimeController = TextEditingController();

  final TextEditingController newTimeController = TextEditingController();

  final TextEditingController openingKmController = TextEditingController();

  final TextEditingController closingKmController = TextEditingController();

  final TextEditingController remarkController = TextEditingController();

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool isLoading = false;

  bool _submissionSent = false;
  bool _submittedSuccessfully = false;

  String? closingKmError;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    dateController.text = _formatDate(widget.punchStat?.date.trim() ?? '');

    lastTimeController.text = widget.punchStat?.time.trim() ?? '';

    openingKmController.text = widget.punchStat?.startingKm.trim() ?? '';
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    final userData = await SecureStorage.instance.getUserData();
    final userId = int.tryParse(userData?['user_id']?.toString() ?? '');
    if (!mounted || userId == null) return;
    context.read<QuickAcessBloc>().add(
      VehicleTypeEvent(userId, DateFormat('yyyy-MM-dd').format(DateTime.now())),
    );
  }

  VehicleTypeEntity? _getMatchedVehicle(QuickAccessState state) {
    for (final vehicle in state.vehicleList) {
      if (vehicle.vehicleTypeId.isNotEmpty &&
          vehicle.vehicleTypeId != '0' &&
          vehicle.vehicleTypeId == vehicle.vehicleTypeIdValue) {
        return vehicle;
      }
    }
    return null;
  }

  bool _showKmFields(QuickAccessState state) {
    final vehicle = _getMatchedVehicle(state);
    final show = vehicle?.openingClosingKm != '0';
    debugPrint(
      'LastForceOut KM visibility: show=$show, '
      'matchedVehicleId=${vehicle?.vehicleTypeId}, '
      'vehicleTypeIdValue=${vehicle?.vehicleTypeIdValue}, '
      'openingClosingKm=${vehicle?.openingClosingKm}, '
      'vehicleCount=${state.vehicleList.length}',
    );
    return show;
  }

  // ===========================================================================
  // DATE FORMAT
  // ===========================================================================

  String _formatDate(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    final date = DateTime.tryParse(value.trim());

    if (date != null) {
      return DateFormat('dd-MM-yyyy').format(date);
    }

    try {
      final parsedDate = DateFormat('dd-MM-yyyy').parseStrict(value.trim());

      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (_) {
      return value;
    }
  }

  // ===========================================================================
  // SELECT NEW TIME
  // ===========================================================================

  Future<void> _selectNewTime() async {
    final lastTime = _parseTime(lastTimeController.text);

    final initialTime = lastTime != null
        ? TimeOfDay(hour: lastTime.hour, minute: lastTime.minute)
        : TimeOfDay.now();

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );

    if (!mounted || selectedTime == null) {
      return;
    }

    final now = DateTime.now();

    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
      0,
    );

    newTimeController.text = DateFormat('hh:mm a').format(selectedDateTime);

    _formKey.currentState?.validate();

    setState(() {});
  }

  // ===========================================================================
  // SUBMIT
  // ===========================================================================

  Future<void> _submitPunch() async {
    if (isLoading || _submittedSuccessfully) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // -------------------------------------------------------------------------
    // MANUAL CLOSING KM VALIDATION
    // -------------------------------------------------------------------------

    final kmError = _showKmFields(context.read<QuickAcessBloc>().state)
        ? _validateKm(closingKmController.text, 'Closing KM')
        : null;

    if (kmError != null) {
      setState(() {
        closingKmError = kmError;
      });

      return;
    }

    // -------------------------------------------------------------------------
    // USER
    // -------------------------------------------------------------------------

    final userData = await SecureStorage.instance.getUserData();

    final userId = int.tryParse(userData?['user_id']?.toString() ?? '');

    if (userId == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User information not found',
            style: AppTextStyles.body,
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
      _submissionSent = true;
    });

    // -------------------------------------------------------------------------
    // DISPLAY DATE -> API DATE
    // -------------------------------------------------------------------------

    String apiDate = '';

    try {
      final displayDate = DateFormat(
        'dd-MM-yyyy',
      ).parseStrict(dateController.text.trim());

      apiDate = DateFormat('yyyy-MM-dd').format(displayDate);
    } catch (e) {
      apiDate = dateController.text.trim();
    }

    debugPrint('DISPLAY DATE : ${dateController.text}');

    debugPrint('API DATE     : $apiDate');

    try {
      // -----------------------------------------------------------------------
      // BATTERY
      // -----------------------------------------------------------------------

      final batteryInfo = await DeviceInfoUtil.instance.getBatteryInfo();

      // -----------------------------------------------------------------------
      // NETWORK
      // -----------------------------------------------------------------------

      final networkInfo = await DeviceInfoUtil.instance.getNetworkInfo();

      // -----------------------------------------------------------------------
      // LOCATION
      // -----------------------------------------------------------------------

      final position = await LocationUtil.instance.getCurrentLocation();

      String latitude = '';
      String longitude = '';
      String address = '';

      if (position != null) {
        latitude = position.latitude.toString();

        longitude = position.longitude.toString();

        address = await LocationUtil.instance.getAddress(
          position.latitude,
          position.longitude,
        );
      }

      if (!mounted) {
        return;
      }

      // -----------------------------------------------------------------------
      // API EVENT
      // -----------------------------------------------------------------------

      context.read<QuickAcessBloc>().add(
        PunchInOutDetailsAddEvent(
          userId: userId,

          inOutStatus: '2',

          differenceByAndroid: '0.0',

          locationHistoryString: '',

          batteryInfo: batteryInfo,

          networkInfo: networkInfo,

          latitude: latitude,

          longitude: longitude,

          networkLatitude: latitude,

          networkLongitude: longitude,

          gpsLatitude: latitude,

          gpsLongitude: longitude,

          geoAddress: address,

          pinRemark: remarkController.text.trim(),

          startingClosingKmAmount: closingKmController.text.trim(),

          vehicleTypeId: '',

          route: '',

          activityId: '26',

          isForceOutPunch: true,

          date: apiDate,

          newTime: newTimeController.text.trim(),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        _submissionSent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e', style: AppTextStyles.body),
        ),
      );
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    dateController.dispose();

    lastTimeController.dispose();

    newTimeController.dispose();

    openingKmController.dispose();

    closingKmController.dispose();

    remarkController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(
        title: 'Last Out Punch',
        showBackButton: true,
        onBackTap: () {
          context.go(AppRouter.home);
        },
      ),

      body: SafeArea(
        child: BlocConsumer<QuickAcessBloc, QuickAccessState>(
          // ===================================================================
          // LISTENER
          // ===================================================================
          listener: (context, state) {
            // ---------------------------------------------------------------
            // SUCCESS
            // ---------------------------------------------------------------

            if (state.quickAccessStatus ==
                    QuickAccessStatus.punchStatusSuccess &&
                _submissionSent) {
              setState(() {
                isLoading = false;
                _submissionSent = false;
                _submittedSuccessfully = true;
              });

              AppDialog.show(
                context: context,
                allowBack: false,
                type: DialogType.success,
                title: 'Last Punch Successful',
                message: 'Your Last punch has been submitted successfully.',
                buttonText: 'OK',
                onButtonPressed: () {
                  final router = GoRouter.of(context);
                  router.go(AppRouter.home);
                  router.push(AppRouter.addExpense);
                },
              );
            }

            // ---------------------------------------------------------------
            // FAILURE
            // ---------------------------------------------------------------

            if (state.quickAccessStatus == QuickAccessStatus.failure &&
                _submissionSent) {
              setState(() {
                isLoading = false;
                _submissionSent = false;
              });

              AppDialog.show(
                context: context,
                type: DialogType.error,
                title: 'Last Punch Failed',
                message: state.errorMessage ?? 'Unable to submit Last Punch.',
                buttonText: 'OK',
              );
            }
          },

          // ===================================================================
          // BUILDER
          // ===================================================================
          builder: (context, state) {
            final showKmFields = _showKmFields(state);
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  // -----------------------------------------------------------
                  // SCROLL CONTENT
                  // -----------------------------------------------------------
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),

                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,

                      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // ---------------------------------------------------
                          // HEADER
                          // ---------------------------------------------------
                          _compactHeader(),

                          SizedBox(height: 14.h),

                          // ---------------------------------------------------
                          // PREVIOUS ACTIVITY
                          // ---------------------------------------------------
                          _sectionTitle(
                            icon: Icons.history_rounded,
                            title: 'Previous Activity',
                          ),

                          SizedBox(height: 8.h),

                          _contentCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Expanded(
                                  child: _modernTextField(
                                    controller: dateController,

                                    hintText: 'Date',

                                    icon: Icons.calendar_month_rounded,

                                    enabled: false,
                                  ),
                                ),

                                SizedBox(width: 10.w),

                                Expanded(
                                  child: _modernTextField(
                                    controller: lastTimeController,

                                    hintText: 'Last Time',

                                    icon: Icons.history_toggle_off_rounded,

                                    enabled: false,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 14.h),

                          // ---------------------------------------------------
                          // FORCE OUT DETAILS
                          // ---------------------------------------------------
                          _sectionTitle(
                            icon: Icons.logout_rounded,
                            title: 'Force Out Details',
                          ),

                          SizedBox(height: 8.h),

                          _contentCard(
                            child: Column(
                              children: [
                                // ---------------------------------------------
                                // PUNCH OUT TIME
                                // ---------------------------------------------
                                _modernTextField(
                                  controller: newTimeController,

                                  hintText: 'Select Time',

                                  icon: Icons.access_time_filled_rounded,

                                  required: true,

                                  readOnly: true,

                                  validator: _validateNewTime,

                                  suffixIcon: Icons.schedule_rounded,

                                  onTap: _selectNewTime,
                                ),

                                SizedBox(height: 11.h),

                                // ---------------------------------------------
                                // KM ROW
                                // ---------------------------------------------
                                if (showKmFields) Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Expanded(
                                      child: _modernKmField(
                                        controller: openingKmController,

                                        hintText: 'Opening KM',

                                        enabled: false,

                                        validator: (_) => null,
                                      ),
                                    ),

                                    SizedBox(width: 10.w),

                                    Expanded(
                                      child: _modernKmField(
                                        controller: closingKmController,

                                        hintText: 'Closing KM',

                                        enabled: true,

                                        required: true,

                                        validator: (value) {
                                          final error = _validateKm(
                                            value,
                                            'Closing KM',
                                          );

                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (mounted &&
                                                    closingKmError != error) {
                                                  setState(() {
                                                    closingKmError = error;
                                                  });
                                                }
                                              });

                                          return null;
                                        },

                                        onChanged: (value) {
                                          setState(() {
                                            closingKmError = _validateKm(
                                              value,
                                              'Closing KM',
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                // ---------------------------------------------
                                // CLOSING KM ERROR
                                // ---------------------------------------------
                                if (showKmFields && closingKmError != null) ...[
                                  SizedBox(height: 5.h),

                                  _errorMessage(closingKmError!),
                                ],

                                SizedBox(height: 11.h),

                                // ---------------------------------------------
                                // REMARK
                                // ---------------------------------------------
                                _modernTextField(
                                  controller: remarkController,

                                  hintText: 'Enter Remark',

                                  icon: Icons.edit_note_rounded,

                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 10.h),

                          // ---------------------------------------------------
                          // WARNING
                          // ---------------------------------------------------
                          _warningCard(),
                        ],
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // FIXED BUTTON
                  // -----------------------------------------------------------
                  _bottomSubmitSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // COMPACT HEADER
  // ===========================================================================

  Widget _compactHeader() {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),

      decoration: BoxDecoration(
        color: context.appPrimary,

        borderRadius: BorderRadius.circular(18.r),

        boxShadow: [
          BoxShadow(
            color: context.appPrimary.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Stack(
        children: [
          Positioned(
            right: -25.w,
            top: -30.h,
            child: Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                color: context.appOnPrimary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Row(
            children: [
              // ---------------------------------------------------------------
              // ICON
              // ---------------------------------------------------------------
              Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  color: context.appOnPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Icon(
                  Icons.schedule_send_rounded,
                  color: context.appOnPrimary,
                  size: 22.sp,
                ),
              ),

              SizedBox(width: 11.w),

              // ---------------------------------------------------------------
              // TITLE
              // ---------------------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Force Out',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: context.appOnPrimary,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    Text(
                      'Complete your previous pending punch out',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appOnPrimary.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              // ---------------------------------------------------------------
              // FORCE BADGE
              // ---------------------------------------------------------------
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: context.appOnPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: context.appOnPrimary.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    ),

                    SizedBox(width: 5.w),

                    Text(
                      'FORCE',
                      style: AppTextStyles.badge.copyWith(
                        color: context.appOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION TITLE
  // ===========================================================================

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              context.appPrimary.withValues(alpha: 0.1),
              context.appCard,
            ),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(icon, color: context.appPrimary, size: 16.sp),
        ),

        SizedBox(width: 8.w),

        Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(color: context.appOnCard),
        ),
      ],
    );
  }

  // ===========================================================================
  // CONTENT CARD
  // ===========================================================================

  Widget _contentCard({required Widget child}) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(11.w),

      decoration: BoxDecoration(
        color: context.appCard,

        borderRadius: BorderRadius.circular(16.r),

        border: Border.all(color: context.appBorder),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: child,
    );
  }

  // ===========================================================================
  // FIELD LABEL
  // ===========================================================================

  Widget _fieldLabel(String title, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w),

      child: RichText(
        text: TextSpan(
          text: title,

          style: AppTextStyles.labelSmall.copyWith(color: context.appSubText),

          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.appError,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODERN TEXT FIELD
  // ===========================================================================

  Widget _modernTextField({
    required TextEditingController controller,
    // required String title,
    required String hintText,
    required IconData icon,

    String? Function(String?)? validator,

    int maxLines = 1,

    bool enabled = true,

    bool readOnly = false,

    bool required = false,

    VoidCallback? onTap,

    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // _fieldLabel(
        //   title,
        //   required: required,
        // ),
        SizedBox(height: 4.h),

        CustomTextFormField(
          controller: controller,
          hintText: hintText,
          labelText: hintText,
          prefixIcon: icon,
          maxLines: maxLines,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          suffixIcon: suffixIcon,
          validator: validator,
        ),
      ],
    );
  }

  // ===========================================================================
  // KM FIELD
  // ===========================================================================

  Widget _modernKmField({
    required TextEditingController controller,

    required String hintText,
    required bool enabled,
    required String? Function(String?) validator,

    bool required = false,

    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        SizedBox(height: 4.h),

        CustomTextFormField(
          controller: controller,
          hintText: hintText,
          labelText: hintText,
          prefixIcon: Icons.speed_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: enabled,
          validator: enabled ? validator : null,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ===========================================================================
  // ERROR MESSAGE
  // ===========================================================================

  Widget _errorMessage(String message) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),

      decoration: BoxDecoration(
        color: Color.alphaBlend(
          context.appError.withValues(alpha: 0.08),
          context.appCard,
        ),

        borderRadius: BorderRadius.circular(8.r),

        border: Border.all(color: context.appError.withValues(alpha: 0.25)),
      ),

      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: context.appError,
            size: 14.sp,
          ),

          SizedBox(width: 5.w),

          Expanded(
            child: Text(
              message,
              style: AppTextStyles.helperText.copyWith(color: context.appError),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WARNING
  // ===========================================================================

  Widget _warningCard() {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),

      decoration: BoxDecoration(
        color: Color.alphaBlend(
          context.appWarning.withValues(alpha: 0.08),
          context.appCard,
        ),

        borderRadius: BorderRadius.circular(11.r),

        border: Border.all(color: context.appWarning.withValues(alpha: 0.25)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                context.appWarning.withValues(alpha: 0.15),
                context.appCard,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: context.appWarning,
              size: 16.sp,
            ),
          ),

          SizedBox(width: 8.w),

          Expanded(
            child: Text(
              'Punch out time cannot be earlier than your last activity time.',
              style: AppTextStyles.caption.copyWith(
                color: context.appOnCard,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM SUBMIT
  // ===========================================================================

  Widget _bottomSubmitSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 7.h, 14.w, 8.h),

      decoration: BoxDecoration(
        color: context.appCard,

        border: Border(top: BorderSide(color: context.appBorder)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: SizedBox(
          width: double.infinity,
          height: 48.h,

          child: ElevatedButton(
            onPressed: isLoading || _submittedSuccessfully
                ? null
                : _submitPunch,

            style: ElevatedButton.styleFrom(
              elevation: 0,

              backgroundColor: context.appPrimary,

              disabledBackgroundColor: context.appPrimary.withValues(
                alpha: 0.60,
              ),

              foregroundColor: context.appOnPrimary,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),

              padding: EdgeInsets.zero,
            ),

            child: isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,

                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.appOnPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Icon(Icons.fingerprint_rounded, size: 18.sp),

                      // Container(
                      //   width: 28.w,
                      //   height: 28.w,

                      //   decoration:
                      //       BoxDecoration(
                      //     color: context.appOnPrimary
                      //         .withValues(alpha: 0.15),
                      //     borderRadius:
                      //         BorderRadius.circular(
                      //       8.r,
                      //     ),
                      //   ),

                      //   child: Icon(
                      //     Icons
                      //         .schedule_send_rounded,
                      //     color: context.appOnPrimary,
                      //     size: 16.sp,
                      //   ),
                      // ),
                      SizedBox(width: 8.w),

                      Text(
                        'LAST FORCE OUT',
                        style: AppTextStyles.buttonSmall.copyWith(
                          letterSpacing: 0.3,
                        ),
                      ),

                      // SizedBox(
                      //   width: 7.w,
                      // ),

                      // Icon(
                      //   Icons
                      //       .arrow_forward_rounded,
                      //   size: 17.sp,
                      // ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // NEW TIME VALIDATION
  // ===========================================================================

  String? _validateNewTime(String? value) {
    final newTime = _parseTime(value);

    final lastTime = _parseTime(lastTimeController.text);

    debugPrint('================================');

    debugPrint('LAST TIME RAW  : "${lastTimeController.text}"');

    debugPrint('NEW TIME RAW   : "${value ?? ''}"');

    debugPrint('LAST TIME PARSED: $lastTime');

    debugPrint('NEW TIME PARSED : $newTime');

    debugPrint('================================');

    if (newTime == null) {
      return 'Please select a valid time';
    }

    if (lastTime == null) {
      return 'Last time is not available';
    }

    final lastMinutes = lastTime.hour * 60 + lastTime.minute;

    final newMinutes = newTime.hour * 60 + newTime.minute;

    if (newMinutes < lastMinutes) {
      return 'Out-Punch time can not be less than last Activity time';
    }

    return null;
  }

  // ===========================================================================
  // PARSE TIME
  // ===========================================================================

  DateTime? _parseTime(String? value) {
    if (value == null) {
      return null;
    }

    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    debugPrint('Parsing time: "$text"');

    // -------------------------------------------------------------------------
    // 12 HOUR WITH SECONDS
    // -------------------------------------------------------------------------

    try {
      return DateFormat('hh:mm:ss a').parseStrict(text);
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 12 HOUR WITHOUT SECONDS
    // -------------------------------------------------------------------------

    try {
      return DateFormat('hh:mm a').parseStrict(text);
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 24 HOUR WITH SECONDS
    // -------------------------------------------------------------------------

    try {
      return DateFormat('HH:mm:ss').parseStrict(text);
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 24 HOUR WITHOUT SECONDS
    // -------------------------------------------------------------------------

    try {
      return DateFormat('HH:mm').parseStrict(text);
    } catch (_) {}

    debugPrint('Unable to parse time: "$text"');

    return null;
  }

  // ===========================================================================
  // KM VALIDATION
  // ===========================================================================

  String? _validateKm(String? value, String fieldName) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter $fieldName';
    }

    final km = double.tryParse(text);

    if (km == null) {
      return 'Please enter a valid $fieldName';
    }

    final openingText = openingKmController.text.trim();

    final openingKm = double.tryParse(openingText);

    if (openingKm != null && km < openingKm) {
      return 'Closing KM cannot be less than Opening KM';
    }

    return null;
  }
}




/*
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/device_info_util.dart';
import 'package:solufine/core/utility/location_util.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';
import 'package:solufine/features/home/doman/home_entity/punch_stat_entity.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_state.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';

import 'package:flutter/material.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LastForceOutScreen extends StatefulWidget {
  final PunchStatEntity? punchStat;

  const LastForceOutScreen(this.punchStat, {super.key});

  @override
  State<LastForceOutScreen> createState() => _LastForceOutScreenState();
}

class _LastForceOutScreenState extends State<LastForceOutScreen> {
  // ===========================================================================
  // FORM
  // ===========================================================================

  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final TextEditingController dateController = TextEditingController();

  final TextEditingController lastTimeController = TextEditingController();

  final TextEditingController newTimeController = TextEditingController();

  final TextEditingController openingKmController = TextEditingController();

  final TextEditingController closingKmController = TextEditingController();

  final TextEditingController remarkController = TextEditingController();

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool isLoading = false;

  bool _submissionSent = false;
  bool _submittedSuccessfully = false;

  String? closingKmError;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    dateController.text = _formatDate(widget.punchStat?.date.trim() ?? '');

    lastTimeController.text = widget.punchStat?.time.trim() ?? '';

    openingKmController.text = widget.punchStat?.startingKm.trim() ?? '';
  }

  // ===========================================================================
  // DATE FORMAT
  // ===========================================================================

  String _formatDate(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    final date = DateTime.tryParse(value.trim());

    if (date != null) {
      return DateFormat('dd-MM-yyyy').format(date);
    }

    try {
      final parsedDate = DateFormat('dd-MM-yyyy').parseStrict(value.trim());

      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (_) {
      return value;
    }
  }

  // ===========================================================================
  // SELECT NEW TIME
  // ===========================================================================

  Future<void> _selectNewTime() async {
    final lastTime = _parseTime(lastTimeController.text);

    final initialTime = lastTime != null
        ? TimeOfDay(hour: lastTime.hour, minute: lastTime.minute)
        : TimeOfDay.now();

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );

    if (!mounted || selectedTime == null) {
      return;
    }

    final now = DateTime.now();

    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
      0,
    );

    newTimeController.text = DateFormat('hh:mm a').format(selectedDateTime);

    _formKey.currentState?.validate();

    setState(() {});
  }

  // ===========================================================================
  // SUBMIT
  // ===========================================================================

  Future<void> _submitPunch() async {
    if (isLoading || _submittedSuccessfully) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // -------------------------------------------------------------------------
    // MANUAL CLOSING KM VALIDATION
    // -------------------------------------------------------------------------

    final kmError = _validateKm(closingKmController.text, 'Closing KM');

    if (kmError != null) {
      setState(() {
        closingKmError = kmError;
      });

      return;
    }

    // -------------------------------------------------------------------------
    // USER
    // -------------------------------------------------------------------------

    final userData = await SecureStorage.instance.getUserData();

    final userId = int.tryParse(userData?['user_id']?.toString() ?? '');

    if (userId == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User information not found',
            style: AppTextStyles.body,
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
      _submissionSent = true;
    });

    // -------------------------------------------------------------------------
    // DISPLAY DATE -> API DATE
    // -------------------------------------------------------------------------

    String apiDate = '';

    try {
      final displayDate = DateFormat(
        'dd-MM-yyyy',
      ).parseStrict(dateController.text.trim());

      apiDate = DateFormat('yyyy-MM-dd').format(displayDate);
    } catch (e) {
      apiDate = dateController.text.trim();
    }

    debugPrint('DISPLAY DATE : ${dateController.text}');

    debugPrint('API DATE     : $apiDate');

    try {
      // -----------------------------------------------------------------------
      // BATTERY
      // -----------------------------------------------------------------------

      final batteryInfo = await DeviceInfoUtil.instance.getBatteryInfo();

      // -----------------------------------------------------------------------
      // NETWORK
      // -----------------------------------------------------------------------

      final networkInfo = await DeviceInfoUtil.instance.getNetworkInfo();

      // -----------------------------------------------------------------------
      // LOCATION
      // -----------------------------------------------------------------------

      final position = await LocationUtil.instance.getCurrentLocation();

      String latitude = '';
      String longitude = '';
      String address = '';

      if (position != null) {
        latitude = position.latitude.toString();

        longitude = position.longitude.toString();

        address = await LocationUtil.instance.getAddress(
          position.latitude,
          position.longitude,
        );
      }

      if (!mounted) {
        return;
      }

      // -----------------------------------------------------------------------
      // API EVENT
      // -----------------------------------------------------------------------

      context.read<QuickAcessBloc>().add(
        PunchInOutDetailsAddEvent(
          userId: userId,

          inOutStatus: '2',

          differenceByAndroid: '0.0',

          locationHistoryString: '',

          batteryInfo: batteryInfo,

          networkInfo: networkInfo,

          latitude: latitude,

          longitude: longitude,

          networkLatitude: latitude,

          networkLongitude: longitude,

          gpsLatitude: latitude,

          gpsLongitude: longitude,

          geoAddress: address,

          pinRemark: remarkController.text.trim(),

          startingClosingKmAmount: closingKmController.text.trim(),

          vehicleTypeId: '',

          route: '',

          activityId: '26',

          isForceOutPunch: true,

          date: apiDate,

          newTime: newTimeController.text.trim(),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        _submissionSent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e', style: AppTextStyles.body),
        ),
      );
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    dateController.dispose();

    lastTimeController.dispose();

    newTimeController.dispose();

    openingKmController.dispose();

    closingKmController.dispose();

    remarkController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(
        title: 'Last Out Punch',
        showBackButton: true,
        onBackTap: () {
          context.go(AppRouter.home);
        },
      ),

      body: SafeArea(
        child: BlocConsumer<QuickAcessBloc, QuickAccessState>(
          // ===================================================================
          // LISTENER
          // ===================================================================
          listener: (context, state) {
            // ---------------------------------------------------------------
            // SUCCESS
            // ---------------------------------------------------------------

            if (state.quickAccessStatus ==
                    QuickAccessStatus.punchStatusSuccess &&
                _submissionSent) {
              setState(() {
                isLoading = false;
                _submissionSent = false;
                _submittedSuccessfully = true;
              });

              AppDialog.show(
                context: context,
                allowBack: false,
                type: DialogType.success,
                title: 'Last Punch Successful',
                message: 'Your Last punch has been submitted successfully.',
                buttonText: 'OK',
                onButtonPressed: () {
                  final router = GoRouter.of(context);
                  router.go(AppRouter.home);
                  router.push(AppRouter.addExpense);
                },
              );
            }

            // ---------------------------------------------------------------
            // FAILURE
            // ---------------------------------------------------------------

            if (state.quickAccessStatus == QuickAccessStatus.failure &&
                _submissionSent) {
              setState(() {
                isLoading = false;
                _submissionSent = false;
              });

              AppDialog.show(
                context: context,
                type: DialogType.error,
                title: 'Last Punch Failed',
                message: state.errorMessage ?? 'Unable to submit Last Punch.',
                buttonText: 'OK',
              );
            }
          },

          // ===================================================================
          // BUILDER
          // ===================================================================
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  // -----------------------------------------------------------
                  // SCROLL CONTENT
                  // -----------------------------------------------------------
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),

                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,

                      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // ---------------------------------------------------
                          // HEADER
                          // ---------------------------------------------------
                          _compactHeader(),

                          SizedBox(height: 14.h),

                          // ---------------------------------------------------
                          // PREVIOUS ACTIVITY
                          // ---------------------------------------------------
                          _sectionTitle(
                            icon: Icons.history_rounded,
                            title: 'Previous Activity',
                          ),

                          SizedBox(height: 8.h),

                          _contentCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Expanded(
                                  child: _modernTextField(
                                    controller: dateController,

                                    hintText: 'Date',

                                    icon: Icons.calendar_month_rounded,

                                    enabled: false,
                                  ),
                                ),

                                SizedBox(width: 10.w),

                                Expanded(
                                  child: _modernTextField(
                                    controller: lastTimeController,

                                    hintText: 'Last Time',

                                    icon: Icons.history_toggle_off_rounded,

                                    enabled: false,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 14.h),

                          // ---------------------------------------------------
                          // FORCE OUT DETAILS
                          // ---------------------------------------------------
                          _sectionTitle(
                            icon: Icons.logout_rounded,
                            title: 'Force Out Details',
                          ),

                          SizedBox(height: 8.h),

                          _contentCard(
                            child: Column(
                              children: [
                                // ---------------------------------------------
                                // PUNCH OUT TIME
                                // ---------------------------------------------
                                _modernTextField(
                                  controller: newTimeController,

                                  hintText: 'Select Time',

                                  icon: Icons.access_time_filled_rounded,

                                  required: true,

                                  readOnly: true,

                                  validator: _validateNewTime,

                                  suffixIcon: Icons.schedule_rounded,

                                  onTap: _selectNewTime,
                                ),

                                SizedBox(height: 11.h),

                                // ---------------------------------------------
                                // KM ROW
                                // ---------------------------------------------
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Expanded(
                                      child: _modernKmField(
                                        controller: openingKmController,

                                        hintText: 'Opening KM',

                                        enabled: false,

                                        validator: (_) => null,
                                      ),
                                    ),

                                    SizedBox(width: 10.w),

                                    Expanded(
                                      child: _modernKmField(
                                        controller: closingKmController,

                                        hintText: 'Closing KM',

                                        enabled: true,

                                        required: true,

                                        validator: (value) {
                                          final error = _validateKm(
                                            value,
                                            'Closing KM',
                                          );

                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (mounted &&
                                                    closingKmError != error) {
                                                  setState(() {
                                                    closingKmError = error;
                                                  });
                                                }
                                              });

                                          return null;
                                        },

                                        onChanged: (value) {
                                          setState(() {
                                            closingKmError = _validateKm(
                                              value,
                                              'Closing KM',
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                // ---------------------------------------------
                                // CLOSING KM ERROR
                                // ---------------------------------------------
                                if (closingKmError != null) ...[
                                  SizedBox(height: 5.h),

                                  _errorMessage(closingKmError!),
                                ],

                                SizedBox(height: 11.h),

                                // ---------------------------------------------
                                // REMARK
                                // ---------------------------------------------
                                _modernTextField(
                                  controller: remarkController,

                                  hintText: 'Enter Remark',

                                  icon: Icons.edit_note_rounded,

                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 10.h),

                          // ---------------------------------------------------
                          // WARNING
                          // ---------------------------------------------------
                          _warningCard(),
                        ],
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // FIXED BUTTON
                  // -----------------------------------------------------------
                  _bottomSubmitSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // COMPACT HEADER
  // ===========================================================================

  Widget _compactHeader() {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),

      decoration: BoxDecoration(
        color: context.appPrimary,

        borderRadius: BorderRadius.circular(18.r),

        boxShadow: [
          BoxShadow(
            color: context.appPrimary.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Stack(
        children: [
          Positioned(
            right: -25.w,
            top: -30.h,
            child: Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                color: context.appOnPrimary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Row(
            children: [
              // ---------------------------------------------------------------
              // ICON
              // ---------------------------------------------------------------
              Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  color: context.appOnPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Icon(
                  Icons.schedule_send_rounded,
                  color: context.appOnPrimary,
                  size: 22.sp,
                ),
              ),

              SizedBox(width: 11.w),

              // ---------------------------------------------------------------
              // TITLE
              // ---------------------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Force Out',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: context.appOnPrimary,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    Text(
                      'Complete your previous pending punch out',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appOnPrimary.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              // ---------------------------------------------------------------
              // FORCE BADGE
              // ---------------------------------------------------------------
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: context.appOnPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: context.appOnPrimary.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    ),

                    SizedBox(width: 5.w),

                    Text(
                      'FORCE',
                      style: AppTextStyles.badge.copyWith(
                        color: context.appOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION TITLE
  // ===========================================================================

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              context.appPrimary.withValues(alpha: 0.1),
              context.appCard,
            ),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(icon, color: context.appPrimary, size: 16.sp),
        ),

        SizedBox(width: 8.w),

        Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(color: context.appOnCard),
        ),
      ],
    );
  }

  // ===========================================================================
  // CONTENT CARD
  // ===========================================================================

  Widget _contentCard({required Widget child}) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(11.w),

      decoration: BoxDecoration(
        color: context.appCard,

        borderRadius: BorderRadius.circular(16.r),

        border: Border.all(color: context.appBorder),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: child,
    );
  }

  // ===========================================================================
  // FIELD LABEL
  // ===========================================================================

  Widget _fieldLabel(String title, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w),

      child: RichText(
        text: TextSpan(
          text: title,

          style: AppTextStyles.labelSmall.copyWith(color: context.appSubText),

          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.appError,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODERN TEXT FIELD
  // ===========================================================================

  Widget _modernTextField({
    required TextEditingController controller,
    // required String title,
    required String hintText,
    required IconData icon,

    String? Function(String?)? validator,

    int maxLines = 1,

    bool enabled = true,

    bool readOnly = false,

    bool required = false,

    VoidCallback? onTap,

    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // _fieldLabel(
        //   title,
        //   required: required,
        // ),
        SizedBox(height: 4.h),

        CustomTextFormField(
          controller: controller,
          hintText: hintText,
          labelText: hintText,
          prefixIcon: icon,
          maxLines: maxLines,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          suffixIcon: suffixIcon,
          validator: validator,
        ),
      ],
    );
  }

  // ===========================================================================
  // KM FIELD
  // ===========================================================================

  Widget _modernKmField({
    required TextEditingController controller,

    required String hintText,
    required bool enabled,
    required String? Function(String?) validator,

    bool required = false,

    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        SizedBox(height: 4.h),

        CustomTextFormField(
          controller: controller,
          hintText: hintText,
          labelText: hintText,
          prefixIcon: Icons.speed_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: enabled,
          validator: enabled ? validator : null,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ===========================================================================
  // ERROR MESSAGE
  // ===========================================================================

  Widget _errorMessage(String message) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),

      decoration: BoxDecoration(
        color: Color.alphaBlend(
          context.appError.withValues(alpha: 0.08),
          context.appCard,
        ),

        borderRadius: BorderRadius.circular(8.r),

        border: Border.all(color: context.appError.withValues(alpha: 0.25)),
      ),

      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: context.appError,
            size: 14.sp,
          ),

          SizedBox(width: 5.w),

          Expanded(
            child: Text(
              message,
              style: AppTextStyles.helperText.copyWith(color: context.appError),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WARNING
  // ===========================================================================

  Widget _warningCard() {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),

      decoration: BoxDecoration(
        color: Color.alphaBlend(
          context.appWarning.withValues(alpha: 0.08),
          context.appCard,
        ),

        borderRadius: BorderRadius.circular(11.r),

        border: Border.all(color: context.appWarning.withValues(alpha: 0.25)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                context.appWarning.withValues(alpha: 0.15),
                context.appCard,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: context.appWarning,
              size: 16.sp,
            ),
          ),

          SizedBox(width: 8.w),

          Expanded(
            child: Text(
              'Punch out time cannot be earlier than your last activity time.',
              style: AppTextStyles.caption.copyWith(
                color: context.appOnCard,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM SUBMIT
  // ===========================================================================

  Widget _bottomSubmitSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 7.h, 14.w, 8.h),

      decoration: BoxDecoration(
        color: context.appCard,

        border: Border(top: BorderSide(color: context.appBorder)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: SizedBox(
          width: double.infinity,
          height: 48.h,

          child: ElevatedButton(
            onPressed: isLoading || _submittedSuccessfully
                ? null
                : _submitPunch,

            style: ElevatedButton.styleFrom(
              elevation: 0,

              backgroundColor: context.appPrimary,

              disabledBackgroundColor: context.appPrimary.withValues(
                alpha: 0.60,
              ),

              foregroundColor: context.appOnPrimary,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),

              padding: EdgeInsets.zero,
            ),

            child: isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,

                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.appOnPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Icon(Icons.fingerprint_rounded, size: 18.sp),

                      // Container(
                      //   width: 28.w,
                      //   height: 28.w,

                      //   decoration:
                      //       BoxDecoration(
                      //     color: context.appOnPrimary
                      //         .withValues(alpha: 0.15),
                      //     borderRadius:
                      //         BorderRadius.circular(
                      //       8.r,
                      //     ),
                      //   ),

                      //   child: Icon(
                      //     Icons
                      //         .schedule_send_rounded,
                      //     color: context.appOnPrimary,
                      //     size: 16.sp,
                      //   ),
                      // ),
                      SizedBox(width: 8.w),

                      Text(
                        'LAST FORCE OUT',
                        style: AppTextStyles.buttonSmall.copyWith(
                          letterSpacing: 0.3,
                        ),
                      ),

                      // SizedBox(
                      //   width: 7.w,
                      // ),

                      // Icon(
                      //   Icons
                      //       .arrow_forward_rounded,
                      //   size: 17.sp,
                      // ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // NEW TIME VALIDATION
  // ===========================================================================

  String? _validateNewTime(String? value) {
    final newTime = _parseTime(value);

    final lastTime = _parseTime(lastTimeController.text);

    debugPrint('================================');

    debugPrint('LAST TIME RAW  : "${lastTimeController.text}"');

    debugPrint('NEW TIME RAW   : "${value ?? ''}"');

    debugPrint('LAST TIME PARSED: $lastTime');

    debugPrint('NEW TIME PARSED : $newTime');

    debugPrint('================================');

    if (newTime == null) {
      return 'Please select a valid time';
    }

    if (lastTime == null) {
      return 'Last time is not available';
    }

    final lastMinutes = lastTime.hour * 60 + lastTime.minute;

    final newMinutes = newTime.hour * 60 + newTime.minute;

    if (newMinutes < lastMinutes) {
      return 'Out-Punch time can not be less than last Activity time';
    }

    return null;
  }

  // ===========================================================================
  // PARSE TIME
  // ===========================================================================

  DateTime? _parseTime(String? value) {
    if (value == null) {
      return null;
    }

    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    debugPrint('Parsing time: "$text"');

    // -------------------------------------------------------------------------
    // 12 HOUR WITH SECONDS
    // -------------------------------------------------------------------------

    try {
      return DateFormat('hh:mm:ss a').parseStrict(text);
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 12 HOUR WITHOUT SECONDS
    // -------------------------------------------------------------------------

    try {
      return DateFormat('hh:mm a').parseStrict(text);
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 24 HOUR WITH SECONDS
    // -------------------------------------------------------------------------

    try {
      return DateFormat('HH:mm:ss').parseStrict(text);
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 24 HOUR WITHOUT SECONDS
    // -------------------------------------------------------------------------

    try {
      return DateFormat('HH:mm').parseStrict(text);
    } catch (_) {}

    debugPrint('Unable to parse time: "$text"');

    return null;
  }

  // ===========================================================================
  // KM VALIDATION
  // ===========================================================================

  String? _validateKm(String? value, String fieldName) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter $fieldName';
    }

    final km = double.tryParse(text);

    if (km == null) {
      return 'Please enter a valid $fieldName';
    }

    final openingText = openingKmController.text.trim();

    final openingKm = double.tryParse(openingText);

    if (openingKm != null && km < openingKm) {
      return 'Closing KM cannot be less than Opening KM';
    }

    return null;
  }
}


*/