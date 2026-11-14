import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:solufine/core/location_tracking/background_location_service.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/app_image_picker.dart';
import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/device_info_util.dart';
import 'package:solufine/core/utility/geo_image_stamp.dart';
import 'package:solufine/core/utility/image_compression.dart';
import 'package:solufine/core/utility/image_side_crop.dart';
import 'package:solufine/core/utility/location_util.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';

import 'package:solufine/features/home/doman/home_entity/punch_stat_entity.dart';
import 'package:solufine/features/home/doman/home_entity/vehicle_type_entity.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_state.dart';

class PunchScreen extends StatefulWidget {
  final PunchStatEntity? punchStat;

  const PunchScreen({super.key, this.punchStat});

  @override
  State<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  bool isLoading = false;
  bool _submissionSent = false;

  final _formKey = GlobalKey<FormState>();

  File? _uploadedImage;

  final TextEditingController openingKmController = TextEditingController();

  final TextEditingController closingKmController = TextEditingController();

  final TextEditingController routeController = TextEditingController();

  final TextEditingController remarkController = TextEditingController();

  String? selectedVehicleId;

  String latitude = '';
  String longitude = '';
  String address = '';

  Position? _punchInPosition;

  String _punchInAddress = '';

  int? _punchInUserId;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    openingKmController.addListener(_onRequiredFieldChanged);
    routeController.addListener(_onRequiredFieldChanged);

    _loadVehicleTypes();
  }

  // ===========================================================================
  // LOAD VEHICLE TYPES
  // ===========================================================================

  void _onRequiredFieldChanged() {
    setState(() {});
  }

  bool _canSubmit(VehicleTypeEntity? vehicle) {
    return !isLoading &&
        selectedVehicleId != null &&
        selectedVehicleId!.trim().isNotEmpty &&
        vehicle != null &&
        routeController.text.trim().isNotEmpty &&
        _uploadedImage != null &&
        (vehicle.openingClosingKm == '0' ||
            _validateKm(openingKmController.text, 'Opening KM') == null);
  }
  Future<void> _loadVehicleTypes() async {
    final userData = await SecureStorage.instance.getUserData();

    final userId = int.tryParse(userData?['user_id']?.toString() ?? '');

    if (!mounted || userId == null) {
      return;
    }

    context.read<QuickAcessBloc>().add(
      VehicleTypeEvent(userId, DateFormat('yyyy-MM-dd').format(DateTime.now())),
    );
  }

  // ===========================================================================
  // CAMERA
  // ===========================================================================

  

  // Future<void> _captureImage() async {
  //   try {
  //     // ============================================================
  //     // 1. CAPTURE ORIGINAL IMAGE
  //     // ============================================================

  //     final File? originalImage = await AppImagePicker.instance
  //         .pickFromCamera();

  //     if (originalImage == null) {
  //       return;
  //     }

  //     if (!await originalImage.exists()) {
  //       debugPrint('ORIGINAL IMAGE NOT FOUND');

  //       return;
  //     }

  //     // ============================================================
  //     // 2. ORIGINAL IMAGE SIZE
  //     // ============================================================

  //     final int originalSize = await originalImage.length();

  //     debugPrint('========================================');

  //     debugPrint('ORIGINAL IMAGE PATH: ${originalImage.path}');

  //     debugPrint(
  //       'ORIGINAL IMAGE SIZE: '
  //       '${(originalSize / 1024).toStringAsFixed(2)} KB',
  //     );

  //     // ============================================================
  //     // 3. COMPRESS IMAGE
  //     // ============================================================

  //     final File? compressedImage = await ImageCompression.compressImage(
  //       originalImage,
  //       maxWidth: 450,
  //       maxHeight: 450,
  //       quality: 45,
  //     );

  //     // ============================================================
  //     // 4. USE COMPRESSED IMAGE
  //     // ============================================================

  //     File finalImage = originalImage;

  //     if (compressedImage != null && await compressedImage.exists()) {
  //       finalImage = compressedImage;

  //       final compressedSize = await compressedImage.length();

  //       debugPrint(
  //         'COMPRESSED IMAGE PATH: '
  //         '${compressedImage.path}',
  //       );

  //       debugPrint(
  //         'COMPRESSED IMAGE SIZE: '
  //         '${(compressedSize / 1024).toStringAsFixed(2)} KB',
  //       );
  //     } else {
  //       debugPrint('COMPRESSION FAILED - USING ORIGINAL IMAGE');
  //     }

  //     debugPrint('========================================');

  //     // ============================================================
  //     // 5. SAVE FINAL IMAGE
  //     // ============================================================

  //     if (!mounted) {
  //       return;
  //     }

  //     setState(() {
  //       _uploadedImage = finalImage;
  //     });
  //   } catch (e, stackTrace) {
  //     debugPrint('CAPTURE IMAGE ERROR: $e');

  //     debugPrint('$stackTrace');

  //     if (!mounted) {
  //       return;
  //     }

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to capture image', style: AppTextStyles.body),
  //       ),
  //     );
  //   }
  // }



Future<void> _captureImage() async {
  try {
    // ============================================================
    // 1. CAPTURE ORIGINAL IMAGE - EXISTING
    // ============================================================

    final File? originalImage =
        await AppImagePicker.instance.pickFromCamera();

    if (originalImage == null) {
      return;
    }

    if (!await originalImage.exists()) {
      debugPrint('ORIGINAL IMAGE NOT FOUND');
      return;
    }

    // ============================================================
    // 2. ORIGINAL IMAGE SIZE - EXISTING
    // ============================================================

    final int originalSize = await originalImage.length();

    debugPrint('========================================');
    debugPrint('ORIGINAL IMAGE PATH: ${originalImage.path}');

    debugPrint(
      'ORIGINAL IMAGE SIZE: '
      '${(originalSize / 1024).toStringAsFixed(2)} KB',
    );

    // ============================================================
    // 3. COMPRESS IMAGE - EXISTING SETTINGS
    // ============================================================

    // final File? compressedImage =
    //     await ImageCompression.compressImage(
    //   originalImage,
    //   maxWidth: 450,
    //   maxHeight: 450,
    //   quality: 45,
    // );

    // // ============================================================
    // // 4. SELECT COMPRESSED IMAGE - EXISTING
    // // ============================================================

    // File finalImage = originalImage;

    // if (compressedImage != null &&
    //     await compressedImage.exists()) {
    //   finalImage = compressedImage;

    //   final int compressedSize =
    //       await compressedImage.length();

    //   debugPrint(
    //     'COMPRESSED IMAGE PATH: ${compressedImage.path}',
    //   );

    //   debugPrint(
    //     'COMPRESSED IMAGE SIZE: '
    //     '${(compressedSize / 1024).toStringAsFixed(2)} KB',
    //   );
    // } else {
    //   debugPrint(
    //     'COMPRESSION FAILED - USING ORIGINAL IMAGE',
    //   );
    // }


     final File? compressedImage = await ImageCompression.compressImage(
          originalImage,
          maxWidth: 450,
          maxHeight: 450,
          quality: 45,
        );

        File finalImage = originalImage;

        if (compressedImage != null &&
            await compressedImage.exists()) {
          finalImage = compressedImage;
        }

        // REMOVE BLACK LEFT AND RIGHT BARS BEFORE GPS STAMP
        final File croppedImage = await ImageSideCrop.crop(
          source: finalImage,
          sidePercent: 0.12,
        );

      finalImage = croppedImage;

      debugPrint('FINAL CROPPED IMAGE: ${finalImage.path}');




    // ============================================================
    // 5. NEW: GET CURRENT GPS LOCATION
    // ============================================================

    final Position? position =
        await LocationUtil.instance.getCurrentLocation();

    if (position == null) {
      throw Exception(
        'Current GPS location unavailable. '
        'Enable GPS and try again.',
      );
    }

    final String photoLatitude =
        position.latitude.toStringAsFixed(6);

    final String photoLongitude =
        position.longitude.toStringAsFixed(6);

    debugPrint('GPS LAT: $photoLatitude');
    debugPrint('GPS LONG: $photoLongitude');

    // ============================================================
    // 6. NEW: GET CURRENT GEO ADDRESS
    // ============================================================

    String photoAddress = '';

    try {
      photoAddress =
          await LocationUtil.instance.getAddress(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint('GEO ADDRESS ERROR: $e');
    }

    if (photoAddress.trim().isEmpty) {
      photoAddress = 'Not available';
    }

    debugPrint('GPS ADDRESS: $photoAddress');

    // ============================================================
    // 7. NEW: PRINT GPS ON COMPRESSED IMAGE
    // ============================================================

    final File gpsStampedImage =
        await GeoImageStamp.addLocation(
      imageFile: finalImage,
      latitude: photoLatitude,
      longitude: photoLongitude,
      address: photoAddress,
    );

    if (!await gpsStampedImage.exists()) {
      throw Exception('GPS stamped image not created');
    }

    // IMPORTANT:
    // Use GPS stamped image for preview and API submission.
    finalImage = gpsStampedImage;

    // ============================================================
    // 8. FINAL DEBUG LOGS
    // ============================================================

    final int finalSize = await finalImage.length();

    debugPrint('========== FINAL GPS PHOTO ==========');
    debugPrint('PATH: ${finalImage.path}');
    debugPrint(
      'SIZE: ${(finalSize / 1024).toStringAsFixed(2)} KB',
    );
    debugPrint('LAT: $photoLatitude');
    debugPrint('LONG: $photoLongitude');
    debugPrint('ADDRESS: $photoAddress');
    debugPrint('=====================================');

    // ============================================================
    // 9. SAVE IMAGE - EXISTING
    // ============================================================

    if (!mounted) {
      return;
    }

    setState(() {
      _uploadedImage = finalImage;
    });

  } catch (e, stackTrace) {
    debugPrint('CAPTURE IMAGE ERROR: $e');
    debugPrint('$stackTrace');

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to capture image: $e',
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}



  // ===========================================================================
  // SUBMIT PUNCH
  // ===========================================================================

  Future<void> _submitPunch() async {
    if (isLoading) {
      debugPrint('PUNCH IN: Already loading, submit ignored');

      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('PUNCH IN: Form validation failed');

      return;
    }

    final userData = await SecureStorage.instance.getUserData();

    debugPrint('========== PUNCH IN SUBMIT ==========');

    debugPrint('User data: $userData');

    final userId = int.tryParse(userData?['user_id']?.toString() ?? '');

    if (userId == null) {
      debugPrint('PUNCH IN ERROR: User ID not found');

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

    debugPrint('User ID: $userId');

    _punchInUserId = userId;

    final vehicleTypeId = selectedVehicleId;

    if (vehicleTypeId == null || vehicleTypeId.isEmpty) {
      debugPrint('PUNCH IN ERROR: Vehicle type not selected');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a vehicle type',
            style: AppTextStyles.body,
          ),
        ),
      );

      return;
    }

    debugPrint('Vehicle Type ID: $vehicleTypeId');

    setState(() {
      isLoading = true;
      _submissionSent = false;
    });

    try {
      // -----------------------------------------------------------------------
      // BATTERY
      // -----------------------------------------------------------------------

      final batteryInfo = await DeviceInfoUtil.instance.getBatteryInfo();

      debugPrint('Battery Info: $batteryInfo');

      // -----------------------------------------------------------------------
      // NETWORK
      // -----------------------------------------------------------------------

      final networkInfo = await DeviceInfoUtil.instance.getNetworkInfo();

      debugPrint('Network Info: $networkInfo');

      // -----------------------------------------------------------------------
      // LOCATION
      // -----------------------------------------------------------------------

      final position = await LocationUtil.instance.getCurrentLocation();

      if (position != null) {
        _punchInPosition = position;

        latitude = position.latitude.toString();

        longitude = position.longitude.toString();

        debugPrint('Latitude: $latitude');

        debugPrint('Longitude: $longitude');

        debugPrint('Accuracy: ${position.accuracy}');

        address = await LocationUtil.instance.getAddress(
          position.latitude,
          position.longitude,
        );

        _punchInAddress = address;

        debugPrint('Geo Address: $address');
      } else {
        _punchInPosition = null;

        _punchInAddress = '';

        debugPrint('Location: NOT AVAILABLE');
      }

      // -----------------------------------------------------------------------
      // IMAGE -> BASE64
      // -----------------------------------------------------------------------

      String? startingImageBase64;

      if (_uploadedImage != null) {
        debugPrint('Starting image path: ${_uploadedImage!.path}');

        if (await _uploadedImage!.exists()) {
          final imageBytes = await _uploadedImage!.readAsBytes();

          startingImageBase64 = base64Encode(imageBytes);

          debugPrint(
            'Starting image Base64 length: '
            '${startingImageBase64.length}',
          );
        } else {
          debugPrint('Starting image file does not exist');
        }
      } else {
        debugPrint('Starting image: NOT SELECTED');
      }

      // -----------------------------------------------------------------------
      // FORM DATA
      // -----------------------------------------------------------------------

      final pinRemark = remarkController.text.trim();

      final startingClosingKmAmount = openingKmController.text.trim();

      final route = routeController.text.trim();

      debugPrint('Pin Remark: $pinRemark');

      debugPrint(
        'Starting KM Amount: '
        '$startingClosingKmAmount',
      );

      debugPrint('Route: $route');

      // -----------------------------------------------------------------------
      // DEBUG
      // -----------------------------------------------------------------------

      debugPrint(
        'Previous Punch Status: '
        '${widget.punchStat?.inOutStatus}',
      );

      debugPrint('Current Action: PUNCH IN');

      debugPrint('In/Out Status: 1');

      debugPrint('Activity ID: 3');

      debugPrint('========== FINAL PUNCH IN DATA ==========');

      debugPrint('user_id: $userId');

      debugPrint('in_out_status: 1');

      debugPrint('differenceByAndroid: 0.0');

      debugPrint('locationHistoryString:');

      debugPrint('strBatteryInfo: $batteryInfo');

      debugPrint('strNetworkInfo: $networkInfo');

      debugPrint('pinRemark: $pinRemark');

      debugPrint(
        'strStartingClosingKmAmount: '
        '$startingClosingKmAmount',
      );

      debugPrint('strVehicleTypeId: $vehicleTypeId');

      debugPrint('route: $route');

      debugPrint('latitude: $latitude');

      debugPrint('longitude: $longitude');

      debugPrint('networkLatitude: $latitude');

      debugPrint('networkLongitude: $longitude');

      debugPrint('gpsLatitude: $latitude');

      debugPrint('gpsLongitude: $longitude');

      debugPrint('geoAddress: $address');

      debugPrint('activityId: 3');

      if (startingImageBase64 != null && startingImageBase64.isNotEmpty) {
        debugPrint(
          'startingKmImage: '
          '${startingImageBase64.length} '
          'Base64 characters',
        );
      } else {
        debugPrint('startingKmImage: NOT SENT');
      }

      debugPrint('date: NOT SENT');

      debugPrint('time: NOT SENT');

      debugPrint('closingKmImage: NOT SENT');

      debugPrint('isForceOutPunch: NOT SENT');

      debugPrint('==========================================');

      if (!mounted) {
        return;
      }

      // -----------------------------------------------------------------------
      // DISPATCH
      // -----------------------------------------------------------------------

      context.read<QuickAcessBloc>().add(
        PunchInOutDetailsAddEvent(
          userId: userId,

          inOutStatus: '1',

          differenceByAndroid: '0.0',

          locationHistoryString: '',

          batteryInfo: batteryInfo,

          networkInfo: networkInfo,

          pinRemark: pinRemark,

          startingClosingKmAmount: startingClosingKmAmount,

          vehicleTypeId: vehicleTypeId,

          route: route,

          latitude: latitude,

          longitude: longitude,

          networkLatitude: latitude,

          networkLongitude: longitude,

          gpsLatitude: latitude,

          gpsLongitude: longitude,

          geoAddress: address,

          startingKmImage: startingImageBase64,

          activityId: '3',
        ),
      );

      _submissionSent = true;

      debugPrint('PUNCH IN EVENT DISPATCHED SUCCESSFULLY');

      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('========== PUNCH IN ERROR ==========');

      debugPrint('Error: $e');

      debugPrint('StackTrace: $stackTrace');

      debugPrint('====================================');

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        _submissionSent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), style: AppTextStyles.body)),
      );
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    openingKmController.dispose();
    closingKmController.dispose();
    routeController.dispose();
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
        title: 'Punch In',

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
          listener: (context, state) async {
            if (!isLoading || !_submissionSent) {
              return;
            }

            if (state.quickAccessStatus ==
                QuickAccessStatus.punchStatusSuccess) {
              debugPrint('========================================');

              debugPrint('PUNCH API SUCCESS');

              debugPrint('NOW SAVING LOCATION TO LOCAL DB');

              debugPrint('========================================');

              if (_punchInUserId != null && _punchInPosition != null) {
                context.read<QuickAcessBloc>().add(
                  SavePunchInLocationEvent(
                    userId: _punchInUserId!,

                    latitude: _punchInPosition!.latitude.toString(),

                    longitude: _punchInPosition!.longitude.toString(),

                    geoAddress: _punchInAddress,

                    capturedAt: DateTime.now().millisecondsSinceEpoch,

                    accuracy: _punchInPosition!.accuracy,

                    provider: 'gps',
                  ),
                );

                await BackgroundLocationService.start(userId: _punchInUserId!);

                debugPrint('SavePunchInLocationEvent DISPATCHED');
              } else {
                debugPrint('PUNCH SUCCESS BUT LOCATION DATA NOT AVAILABLE');
              }

              if (!mounted) {
                return;
              }

              setState(() {
                isLoading = false;

                _submissionSent = false;
              });

              AppDialog.show(
          
                context: context,
      allowBack: false,
                type: DialogType.success,

                title: 'Punch In Successful',

                message: 'Your punch in has been submitted successfully.',

                buttonText: 'OK',

                onButtonPressed: () {
                  Navigator.pop(context, true);
                },
              );
            }
          },

          // ===================================================================
          // BUILDER
          // ===================================================================
          builder: (context, vehicleState) {
            final selectedVehicle = _selectedVehicle(vehicleState);

            return Form(
              key: _formKey,

              child: Column(
                children: [
                  // -----------------------------------------------------------
                  // SCROLLABLE CONTENT
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
                          // VEHICLE SECTION
                          // ---------------------------------------------------
                          _compactSectionTitle(
                            icon: Icons.directions_car_filled_rounded,

                            title: 'Vehicle Details',
                          ),

                          SizedBox(height: 8.h),

                          _compactCard(
                            child: Column(
                              children: [
                                _vehicleDropdown(vehicleState),

                                if (selectedVehicle?.openingClosingKm !=
                                    '0') ...[
                                  SizedBox(height: 10.h),

                                  _kmField(
                                    controller: openingKmController,

                                    hintText: 'Opening KM *',

                                    enabled: true,

                                    validator: (value) =>
                                        _validateKm(value, 'Opening KM'),
                                  ),
                                ],

                                SizedBox(height: 10.h),

                                _textField(
                                  controller: routeController,

                                  hintText: 'Enter Route *',

                                  icon: Icons.route_rounded,

                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter route';
                                    }

                                    return null;
                                  },
                                ),

                                SizedBox(height: 10.h),

                                _textField(
                                  controller: remarkController,

                                  hintText: 'Enter Remark',

                                  icon: Icons.edit_note_rounded,

                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 14.h),

                          // ---------------------------------------------------
                          // PHOTO SECTION
                          // ---------------------------------------------------
                          _compactSectionTitle(
                            icon: Icons.photo_camera_rounded,

                            title: 'Verification Photo *',
                          ),

                          SizedBox(height: 8.h),

                          FormField<bool>(
                            initialValue: _uploadedImage != null,

                            validator: (_) {
                              if (_uploadedImage == null) {
                                return 'Please upload an image';
                              }

                              return null;
                            },

                            builder: (field) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  _uploadPhotoCard(),

                                  if (field.hasError) ...[
                                    SizedBox(height: 5.h),

                                    _errorMessage(field.errorText!),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // FIXED BOTTOM SUBMIT
                  // -----------------------------------------------------------
                  _bottomSubmitSection(canSubmit: _canSubmit(selectedVehicle)),
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
        gradient: context.appBackgroundGradient,

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
              Container(
                width: 45.w,

                height: 45.w,

                decoration: BoxDecoration(
                  color: context.appOnPrimary.withValues(alpha: 0.15),

                  borderRadius: BorderRadius.circular(13.r),
                ),

                child: Icon(
                  Icons.fingerprint_rounded,

                  color: context.appOnPrimary,

                  size: 23.sp,
                ),
              ),

              SizedBox(width: 11.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Ready to start?',

                      style: AppTextStyles.cardTitle.copyWith(
                        color: context.appOnPrimary,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    Text(
                      'Enter trip details and punch in',

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
                      'IN',

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

  Widget _compactSectionTitle({required IconData icon, required String title}) {
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
  // COMPACT CARD
  // ===========================================================================

  Widget _compactCard({required Widget child}) {
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
  // SELECTED VEHICLE
  // ===========================================================================

  VehicleTypeEntity? _selectedVehicle(QuickAccessState state) {
    if (state.vehicleList.isEmpty) {
      return state.selectedVehicle;
    }

    if (selectedVehicleId != null) {
      try {
        return state.vehicleList.firstWhere(
          (vehicle) => vehicle.vehicleTypeId == selectedVehicleId,
        );
      } catch (_) {}
    }

    if (state.selectedVehicle != null) {
      return state.selectedVehicle;
    }

    return state.vehicleList.first;
  }

  // ===========================================================================
  // VEHICLE DROPDOWN
  // ===========================================================================

  Widget _vehicleDropdown(QuickAccessState state) {
    if (state.vehicleList.isNotEmpty && selectedVehicleId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final firstVehicle = state.vehicleList.first;

        setState(() {
          selectedVehicleId = firstVehicle.vehicleTypeId;
        });

        debugPrint(
          'Default vehicle selected: '
          '${firstVehicle.vehicleTypeId}',
        );
      });
    }

    VehicleTypeEntity? selectedVehicle;

    if (selectedVehicleId != null) {
      for (final vehicle in state.vehicleList) {
        if (vehicle.vehicleTypeId == selectedVehicleId) {
          selectedVehicle = vehicle;

          break;
        }
      }
    }

    selectedVehicle ??= state.vehicleList.isNotEmpty
        ? state.vehicleList.first
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _fieldLabel('Vehicle Type', required: true),

        SizedBox(height: 4.h),

        Container(
          height: 52.h,

          padding: EdgeInsets.symmetric(horizontal: 11.w),

          decoration: BoxDecoration(
            color: context.appInputBackground,

            borderRadius: BorderRadius.circular(13.r),

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

                  borderRadius: BorderRadius.circular(9.r),
                ),

                child: Icon(
                  Icons.directions_car_filled_outlined,

                  color: context.appPrimary,

                  size: 18.sp,
                ),
              ),

              SizedBox(width: 9.w),

              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedVehicle?.vehicleTypeId,

                    isExpanded: true,

                    borderRadius: BorderRadius.circular(14.r),

                    dropdownColor: context.appCard,

                    hint: Text(
                      'Select Vehicle Type',

                      style: AppTextStyles.inputHint.copyWith(
                        color: context.appSubText,
                      ),
                    ),

                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,

                      color: context.appSubText,

                      size: 22.sp,
                    ),

                    style: AppTextStyles.inputLabel.copyWith(
                      color: context.appOnCard,
                    ),

                    items: state.vehicleList.map((vehicle) {
                      return DropdownMenuItem<String>(
                        value: vehicle.vehicleTypeId,

                        child: Text(
                          vehicle.vehicleType,

                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      debugPrint('Vehicle selected from dropdown: $value');

                      setState(() {
                        selectedVehicleId = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
  // KM FIELD
  // ===========================================================================

  Widget _kmField({
    required TextEditingController controller,

    required String hintText,

    required bool enabled,

    required String? Function(String?) validator,
  }) {
    return CustomTextFormField(
      controller: controller,

      hintText: hintText,

      labelText: hintText,

      prefixIcon: Icons.speed_rounded,

      keyboardType: TextInputType.number,

      enabled: enabled,

      validator: enabled ? validator : null,
    );
  }

  // ===========================================================================
  // KM VALIDATION
  // ===========================================================================

  String? _validateKm(String? value, String fieldName) {
    final text = value?.trim() ?? '';

    final km = double.tryParse(text);

    if (text.isEmpty) {
      return '$fieldName is required';
    }

    if (km == null || km < 0) {
      return 'Enter a valid $fieldName';
    }

    return null;
  }

  // ===========================================================================
  // TEXT FIELD
  // ===========================================================================

  Widget _textField({
    required TextEditingController controller,

    required String hintText,

    required IconData icon,

    String? Function(String?)? validator,

    int maxLines = 1,
  }) {
    return CustomTextFormField(
      controller: controller,

      hintText: hintText,

      labelText: hintText,

      prefixIcon: icon,

      maxLines: maxLines,

      validator: validator,
    );
  }

  // ===========================================================================
  // PHOTO CARD
  // ===========================================================================

  Widget _uploadPhotoCard() {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(10.w),

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

      child: _uploadedImage == null ? _emptyPhotoView() : _selectedPhotoView(),
    );
  }

  // ===========================================================================
  // EMPTY PHOTO
  // ===========================================================================

  Widget _emptyPhotoView() {
    return InkWell(
      onTap: _captureImage,

      borderRadius: BorderRadius.circular(13.r),

      child: Container(
        height: 180.h,

        width: double.infinity,

        decoration: BoxDecoration(
          color: context.appInputBackground,

          borderRadius: BorderRadius.circular(13.r),

          border: Border.all(color: context.appBorder),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 48.w,

              height: 48.w,

              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  context.appPrimary.withValues(alpha: 0.1),
                  context.appCard,
                ),

                borderRadius: BorderRadius.circular(14.r),
              ),

              child: Icon(
                Icons.add_a_photo_rounded,

                color: context.appPrimary,

                size: 23.sp,
              ),
            ),

            SizedBox(width: 12.w),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Capture Photo',

                  style: AppTextStyles.listTitle.copyWith(
                    color: context.appOnCard,
                  ),
                ),

                SizedBox(height: 3.h),

                Text(
                  'Tap to open camera',

                  style: AppTextStyles.caption.copyWith(
                    color: context.appSubText,
                  ),
                ),

                SizedBox(height: 6.h),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),

                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      context.appPrimary.withValues(alpha: 0.1),
                      context.appCard,
                    ),

                    borderRadius: BorderRadius.circular(10.r),
                  ),

                  child: Text(
                    'OPEN CAMERA',

                    style: AppTextStyles.badge.copyWith(
                      color: context.appPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SELECTED PHOTO
  // ===========================================================================

  Widget _selectedPhotoView() {
    return Column(
      children: [
        Stack(
          children: [
           
          
                ClipRRect(
                  borderRadius: BorderRadius.circular(13.r),
                  child: Image.file(
                    _uploadedImage!,
                    key: ValueKey(_uploadedImage!.path),
                    width: double.infinity,

                    // CHANGED: Remove fixed height
                     height: 260.h,

                    // CHANGED: Display image at natural aspect ratio
                    fit: BoxFit.fitWidth,

                    alignment: Alignment.center,
                    gaplessPlayback: false,
                  ),
                ),

            Positioned(
              top: 8.h,

              left: 8.w,

              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),

                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),

                  borderRadius: BorderRadius.circular(15.r),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.check_circle_rounded,

                      color: const Color(0xFF7DFFA9),

                      size: 13.sp,
                    ),

                    SizedBox(width: 4.w),

                    Text(
                      'Photo Added',

                      style: AppTextStyles.badge.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 8.h,

              right: 8.w,

              child: InkWell(
                onTap: _captureImage,

                child: Container(
                  width: 32.w,

                  height: 32.w,

                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),

                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    Icons.camera_alt_rounded,

                    color: Colors.white,

                    size: 16.sp,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 7.h),

        InkWell(
          onTap: _captureImage,

          borderRadius: BorderRadius.circular(11.r),

          child: Container(
            width: double.infinity,

            padding: EdgeInsets.symmetric(vertical: 7.h),

            decoration: BoxDecoration(
              color: Color.alphaBlend(
                context.appPrimary.withValues(alpha: 0.1),
                context.appCard,
              ),

              borderRadius: BorderRadius.circular(11.r),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(
                  Icons.refresh_rounded,

                  color: context.appPrimary,

                  size: 16.sp,
                ),

                SizedBox(width: 5.w),

                Text(
                  'Retake Photo',

                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.appPrimary,
                  ),
                ),
              ],
            ),
          ),
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
  // BOTTOM SUBMIT
  // ===========================================================================

  Widget _bottomSubmitSection({required bool canSubmit}) {
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
            onPressed: canSubmit ? _submitPunch : null,

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

                      SizedBox(width: 7.w),

                      Text(
                        'PUNCH IN',

                        style: AppTextStyles.buttonSmall.copyWith(
                          letterSpacing: 0.3,
                        ),
                      ),

                      // SizedBox(width: 6.w),

                      // Icon(Icons.arrow_forward_rounded, size: 17.sp),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
