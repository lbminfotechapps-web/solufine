import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:solufine/core/di/auth_di.dart';
import 'package:solufine/core/location_tracking/app_database.dart';
import 'package:solufine/core/location_tracking/background_location_service.dart';
import 'package:solufine/core/location_tracking/location_repository.dart';
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
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart'
    show PunchInOutDetailsAddEvent, VehicleTypeEvent, StoreTrackLocation;
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_state.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';

class PunchOutScreen extends StatefulWidget {
  final PunchStatEntity? punchStat;

  const PunchOutScreen(this.punchStat, {super.key});

  @override
  State<PunchOutScreen> createState() => _PunchOutScreenState();
}

class _PunchOutScreenState extends State<PunchOutScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _uploadedImage;

  final TextEditingController openingKmController = TextEditingController();

  final TextEditingController closingKmController = TextEditingController();

  final TextEditingController routeController = TextEditingController();

  final TextEditingController remarkController = TextEditingController();

  final TextEditingController vehicleController = TextEditingController();

  String? userId;

  bool isLoading = false;

  bool _submissionSent = false;

  bool _waitingForStoreLocation = false;
  bool _punchOutSaved = false;
  bool _finishingPunchOut = false;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    closingKmController.addListener(_updateSubmitState);
    routeController.addListener(_updateSubmitState);

    getUserId();

    openingKmController.text = widget.punchStat?.startingKm?.trim() ?? '';

    _loadVehicleTypes();
  }

  // ===========================================================================
  // USER ID
  // ===========================================================================

  Future<void> getUserId() async {
    try {
      final userData = await SecureStorage.instance.getUserData();

      debugPrint('USER DATA: $userData');

      if (!mounted) {
        return;
      }

      setState(() {
        userId = userData?['user_id']?.toString();
      });

      debugPrint('LOGGED IN USER ID: $userId');
    } catch (e) {
      debugPrint('GET USER DATA ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        userId = null;
      });
    }
  }

  // ===========================================================================
  // STORED LOCATIONS
  // ===========================================================================

  Future<String> _getStoredLocations() async {
    try {
      final int? parsedUserId = int.tryParse(userId.toString());

      if (parsedUserId == null) {
        debugPrint('LOCATION: Invalid userId = $userId');

        throw StateError('Invalid user ID for stored locations');
      }

      final LocationRepository repository = sl<LocationRepository>();

      final List<LocationHistoryData> locations = await repository
          .getAllLocations(parsedUserId);

      debugPrint('========================================');

      debugPrint('DEALER VISIT - STORED LOCATIONS');

      debugPrint('TOTAL LOCATIONS: ${locations.length}');

      debugPrint('========================================');

      for (final location in locations) {
        debugPrint(
          'ID: ${location.id} | '
          'Lat: ${location.latitude} | '
          'Lng: ${location.longitude} | '
          'Time: ${location.capturedAt} | '
          'Accuracy: ${location.accuracy} | '
          'Provider: ${location.provider} | '
          'Address: ${location.geoAddress} | '
          'Distance: ${location.distance}',
        );
      }

      final List<Map<String, dynamic>> locationList = locations.map((location) {
        return {
          'latitude': location.latitude,

          'longitude': location.longitude,

          'time': location.capturedAt,

          'accuracy': location.accuracy,

          'provider': location.provider,

          'address': location.geoAddress,

          'distance': location.distance,
        };
      }).toList();

      final String strAllLocations = jsonEncode(locationList);

      debugPrint('========================================');

      debugPrint('STR ALL LOCATIONS');

      debugPrint('TOTAL: ${locations.length}');

      debugPrint(strAllLocations);

      debugPrint('========================================');

      return strAllLocations;
    } catch (e, stackTrace) {
      debugPrint('========================================');

      debugPrint('GET STORED LOCATIONS ERROR');

      debugPrint('$e');

      debugPrint('$stackTrace');

      debugPrint('========================================');

      rethrow;
    }
  }

  // ===========================================================================
  // LOAD VEHICLE
  // ===========================================================================

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
  // MATCH VEHICLE
  // ===========================================================================

  VehicleTypeEntity? _getMatchedVehicle(QuickAccessState state) {
    try {
      return state.vehicleList.firstWhere(
        (vehicle) =>
            vehicle.vehicleTypeId.isNotEmpty &&
            vehicle.vehicleTypeId != '0' &&
            vehicle.vehicleTypeId == vehicle.vehicleTypeIdValue,
      );
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // SET VEHICLE + ROUTE
  // ===========================================================================

  void _setMatchedVehicleAndRoute(QuickAccessState state) {
    final vehicle = _getMatchedVehicle(state);

    if (vehicle == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      vehicleController.text = vehicle.vehicleType;

      routeController.text = vehicle.todaysRoute;
    });

    debugPrint('Matched Vehicle: ${vehicle.vehicleType}');

    debugPrint('Matched Vehicle ID: ${vehicle.vehicleTypeId}');

    debugPrint('Matched Route: ${vehicle.todaysRoute}');
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

      final File? originalImage = await AppImagePicker.instance
          .pickFromCamera();

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
      // // 4. USE COMPRESSED IMAGE - EXISTING
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

      if (compressedImage != null && await compressedImage.exists()) {
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
      // 5. NEW - GET CURRENT LATITUDE AND LONGITUDE
      // ============================================================

      final Position? position = await LocationUtil.instance
          .getCurrentLocation();

      if (position == null) {
        throw Exception(
          'Current GPS location unavailable. Enable GPS and retry.',
        );
      }

      final String photoLatitude = position.latitude.toStringAsFixed(6);

      final String photoLongitude = position.longitude.toStringAsFixed(6);

      debugPrint('========== PUNCH OUT PHOTO GPS ==========');
      debugPrint('LATITUDE: $photoLatitude');
      debugPrint('LONGITUDE: $photoLongitude');
      debugPrint('ACCURACY: ${position.accuracy}');

      // ============================================================
      // 6. NEW - GET CURRENT GEO ADDRESS
      // ============================================================

      String photoAddress = '';

      try {
        photoAddress = await LocationUtil.instance.getAddress(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        debugPrint('GEO ADDRESS ERROR: $e');
      }

      if (photoAddress.trim().isEmpty) {
        photoAddress = 'Not available';
      }

      debugPrint('GEO ADDRESS: $photoAddress');

      // ============================================================
      // 7. NEW - PRINT GPS DETAILS ON COMPRESSED IMAGE
      // ============================================================

      final File gpsStampedImage = await GeoImageStamp.addLocation(
        imageFile: finalImage,
        latitude: photoLatitude,
        longitude: photoLongitude,
        address: photoAddress,
      );

      if (!await gpsStampedImage.exists()) {
        throw Exception('GPS stamped image not created');
      }

      // CHANGED: Use GPS image in existing API.
      finalImage = gpsStampedImage;

      // ============================================================
      // 8. FINAL IMAGE DEBUG
      // ============================================================

      final int finalSize = await finalImage.length();

      debugPrint('========== FINAL PUNCH OUT PHOTO ==========');
      debugPrint('IMAGE PATH: ${finalImage.path}');

      debugPrint(
        'IMAGE SIZE: '
        '${(finalSize / 1024).toStringAsFixed(2)} KB',
      );

      debugPrint('LATITUDE: $photoLatitude');
      debugPrint('LONGITUDE: $photoLongitude');
      debugPrint('ADDRESS: $photoAddress');

      debugPrint('===========================================');

      // ============================================================
      // 9. SAVE FINAL IMAGE - EXISTING
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

  Future<void> _finishPunchOut({required bool locationsUploaded}) async {
    if (!mounted || _finishingPunchOut) return;
    _finishingPunchOut = true;
    _waitingForStoreLocation = false;
    try {
      // Never delete tracking data when the server rejected its upload.
      if (locationsUploaded) {
        final parsedUserId = int.tryParse(userId ?? '');
        if (parsedUserId != null) {
          await sl<LocationRepository>().deleteUserLocations(parsedUserId);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Punch out saved, local cleanup failed: $error');
      debugPrint('$stackTrace');
    }
    if (!mounted) return;
    setState(() {
      isLoading = false;
      _submissionSent = false;
    });
    AppDialog.show(
      context: context,
      allowBack: false,
      type: DialogType.success,
      title: 'Punch Out Successful',
      message:
          //  locationsUploaded
          //     ?
          'Your punch out has been submitted successfully.',
      // : 'Your punch out has been submitted successfully. Location history could not be synced. Any saved locations have been kept on this device.',
      buttonText: 'OK',
      onButtonPressed: () {
        final router = GoRouter.of(context);
        router.go(AppRouter.home);
        context.push('${AppRouter.addExpense}?refresh=true');
      },
    );
  }

  Future<void> _submitPunch() async {
    if (isLoading || _punchOutSaved) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final vehicleState = context.read<QuickAcessBloc>().state;

    final matchedVehicle = _getMatchedVehicle(vehicleState);

    if (matchedVehicle == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle type not found', style: AppTextStyles.body),
        ),
      );

      return;
    }

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
      // IMAGE
      // -----------------------------------------------------------------------

      String? closingImageBase64;

      if (_uploadedImage != null) {
        debugPrint('Closing image path: ${_uploadedImage!.path}');

        if (await _uploadedImage!.exists()) {
          final imageBytes = await _uploadedImage!.readAsBytes();

          closingImageBase64 = base64Encode(imageBytes);

          debugPrint(
            'Closing image Base64 length: '
            '${closingImageBase64.length}',
          );
        } else {
          debugPrint('Closing image file does not exist');
        }
      } else {
        debugPrint('Closing image: NOT SELECTED');
      }

      // -----------------------------------------------------------------------
      // PUNCH OUT API EVENT
      // -----------------------------------------------------------------------

      context.read<QuickAcessBloc>().add(
        PunchInOutDetailsAddEvent(
          userId: userId,

          inOutStatus: '2',

          differenceByAndroid: '0.0',

          locationHistoryString: '',

          batteryInfo: batteryInfo,

          networkInfo: networkInfo,

          pinRemark: remarkController.text.trim(),

          startingClosingKmAmount: closingKmController.text.trim(),

          vehicleTypeId: matchedVehicle.vehicleTypeId,

          route: routeController.text.trim(),

          latitude: latitude,

          longitude: longitude,

          networkLatitude: latitude,

          networkLongitude: longitude,

          gpsLatitude: latitude,

          gpsLongitude: longitude,

          geoAddress: address,

          closingKmImage: closingImageBase64,

          activityId: '4',
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
        SnackBar(content: Text(e.toString(), style: AppTextStyles.body)),
      );
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  void _updateSubmitState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    openingKmController.dispose();

    closingKmController.dispose();

    routeController.dispose();

    remarkController.dispose();

    vehicleController.dispose();

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
        title: 'Punch Out',

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
            // ---------------------------------------------------------------
            // VEHICLE API SUCCESS
            // ---------------------------------------------------------------

            if (state.quickAccessStatus == QuickAccessStatus.success &&
                !_submissionSent) {
              _setMatchedVehicleAndRoute(state);
            }

            if (!_submissionSent) {
              return;
            }

            // ---------------------------------------------------------------
            // PUNCH OUT SUCCESS
            // ---------------------------------------------------------------

            if (state.quickAccessStatus ==
                    QuickAccessStatus.punchStatusSuccess &&
                !_punchOutSaved) {
              _punchOutSaved = true;
              try {
                // Punch-out is already saved. Stop tracking before taking the
                // final history snapshot, even if its upload later fails.
                await BackgroundLocationService.stop();
                await Future<void>.delayed(const Duration(milliseconds: 500));
                if (!mounted) return;
                final dailyTranId = state.dailyTranId;
                if (userId == null ||
                    userId!.isEmpty ||
                    dailyTranId == null ||
                    dailyTranId.isEmpty) {
                  await _finishPunchOut(locationsUploaded: false);
                  return;
                }
                final strAllLocations = await _getStoredLocations();
                if (!mounted || !context.mounted) return;
                final locations = jsonDecode(strAllLocations) as List<dynamic>;
                if (locations.isEmpty) {
                  debugPrint('Punch out saved: no stored locations to upload.');
                  await _finishPunchOut(locationsUploaded: true);
                  return;
                }
                _waitingForStoreLocation = true;
                context.read<QuickAcessBloc>().add(
                  StoreTrackLocation(userId!, dailyTranId, strAllLocations),
                );
              } catch (error, stackTrace) {
                debugPrint('Punch out saved, location sync failed: $error');
                debugPrint('$stackTrace');
                await _finishPunchOut(locationsUploaded: false);
              }
              return;
            }

            if (state.quickAccessStatus ==
                    QuickAccessStatus.locationHistoryUploaded &&
                _waitingForStoreLocation) {
              await _finishPunchOut(locationsUploaded: true);
              return;
            }

            if (state.quickAccessStatus == QuickAccessStatus.failure &&
                _punchOutSaved) {
              debugPrint(
                'Punch out saved, location sync failed: ${state.errorMessage}',
              );
              await _finishPunchOut(locationsUploaded: false);
              return;
            }
            // ---------------------------------------------------------------
            // FAILURE
            // ---------------------------------------------------------------

            if (state.quickAccessStatus == QuickAccessStatus.failure) {
              setState(() {
                isLoading = false;

                _submissionSent = false;

                _waitingForStoreLocation = false;
              });

              AppDialog.show(
                context: context,

                type: DialogType.error,

                title: 'Punch Out Failed',

                message: state.errorMessage ?? 'Unable to submit punch out.',

                buttonText: 'OK',
              );
            }
          },

          // ===================================================================
          // UI
          // ===================================================================
          builder: (context, vehicleState) {
            final showKmFields =
                _getMatchedVehicle(vehicleState)?.openingClosingKm != '0';

            return Form(
              key: _formKey,

              child: Column(
                children: [
                  // -----------------------------------------------------------
                  // SCROLLABLE SECTION
                  // -----------------------------------------------------------
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),

                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,

                      padding: EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 14.h),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // ---------------------------------------------------
                          // HEADER
                          // ---------------------------------------------------
                          _compactHeader(),

                          SizedBox(height: 13.h),

                          // ---------------------------------------------------
                          // TRIP DETAILS
                          // ---------------------------------------------------
                          _compactSectionHeader(
                            icon: Icons.directions_car_filled_rounded,

                            title: 'Trip Details',

                            subtitle: 'Review journey and enter closing KM',
                          ),

                          SizedBox(height: 7.h),

                          _contentCard(
                            child: Column(
                              children: [
                                // VEHICLE
                                _modernTextField(
                                  controller: vehicleController,

                                  hintText: 'Vehicle Type',

                                  icon: Icons.directions_car_filled_outlined,

                                  enabled: false,
                                ),

                                SizedBox(height: 9.h),

                                if (showKmFields) ...[
                                  // KM ROW
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Expanded(
                                        child: _modernKmField(
                                          controller: openingKmController,

                                          hintText: 'Opening KM',

                                          enabled: false,

                                          validator: (_) => null,
                                        ),
                                      ),

                                      SizedBox(width: 9.w),

                                      Expanded(
                                        child: _modernKmField(
                                          controller: closingKmController,

                                          hintText: 'Closing KM *',

                                          enabled: true,

                                          validator: (value) =>
                                              _validateKm(value, 'Closing KM'),

                                          onChanged: (value) {
                                            _formKey.currentState?.validate();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 9.h),
                                ],

                                // ROUTE
                                _modernTextField(
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

                                SizedBox(height: 9.h),

                                // REMARK
                                _modernTextField(
                                  controller: remarkController,

                                  hintText: 'Enter Remark',

                                  icon: Icons.edit_note_rounded,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 13.h),

                          // ---------------------------------------------------
                          // PHOTO
                          // ---------------------------------------------------
                          _compactSectionHeader(
                            icon: Icons.photo_camera_rounded,

                            title: 'Closing Photo *',

                            subtitle: 'Capture photo before completing trip',
                          ),

                          SizedBox(height: 7.h),

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
                  // FIXED BOTTOM BUTTON
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
              Container(
                width: 45.w,

                height: 45.w,

                decoration: BoxDecoration(
                  color: context.appOnPrimary.withValues(alpha: 0.15),

                  borderRadius: BorderRadius.circular(13.r),
                ),

                child: Icon(
                  Icons.logout_rounded,

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
                      'End your trip',

                      style: AppTextStyles.cardTitle.copyWith(
                        color: context.appOnPrimary,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    Text(
                      'Complete trip details and punch out',

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
                      'OUT',

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
  // SECTION HEADER
  // ===========================================================================

  Widget _compactSectionHeader({
    required IconData icon,

    required String title,

    required String subtitle,
  }) {
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

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: AppTextStyles.cardTitle.copyWith(
                  color: context.appOnCard,
                ),
              ),

              SizedBox(height: 1.h),

              Text(
                subtitle,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: AppTextStyles.caption.copyWith(
                  color: context.appSubText,
                ),
              ),
            ],
          ),
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

      padding: EdgeInsets.all(10.w),

      decoration: BoxDecoration(
        color: context.appCard,

        borderRadius: BorderRadius.circular(16.r),

        border: Border.all(color: context.appBorder),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),

            blurRadius: 9,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: child,
    );
  }

  // ===========================================================================
  // TEXT FIELD
  // ===========================================================================

  Widget _modernTextField({
    required TextEditingController controller,

    required String hintText,

    required IconData icon,

    bool enabled = true,

    String? Function(String?)? validator,
  }) {
    return CustomTextFormField(
      controller: controller,

      hintText: hintText,

      labelText: hintText,

      prefixIcon: icon,

      enabled: enabled,

      validator: validator,
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

    ValueChanged<String>? onChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: Theme.of(
          context,
        ).inputDecorationTheme.copyWith(errorMaxLines: 3),
      ),
      child: CustomTextFormField(
        controller: controller,

        hintText: hintText,

        labelText: hintText,

        prefixIcon: Icons.speed_rounded,

        keyboardType: TextInputType.number,

        enabled: enabled,

        validator: enabled ? validator : null,

        onChanged: onChanged,
      ),
    );
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
      return 'Closing KM Cannot Be Less Than Opening KM';
    }

    return null;
  }

  // ===========================================================================
  // PHOTO CARD
  // ===========================================================================

  Widget _uploadPhotoCard() {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(9.w),

      decoration: BoxDecoration(
        color: context.appCard,

        borderRadius: BorderRadius.circular(16.r),

        border: Border.all(color: context.appBorder),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),

            blurRadius: 9,

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
              width: 46.w,

              height: 46.w,

              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  context.appPrimary.withValues(alpha: 0.1),
                  context.appCard,
                ),

                borderRadius: BorderRadius.circular(13.r),
              ),

              child: Icon(
                Icons.add_a_photo_rounded,

                color: context.appPrimary,

                size: 22.sp,
              ),
            ),

            SizedBox(width: 11.w),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Capture Closing Photo',

                  style: AppTextStyles.listTitle.copyWith(
                    color: context.appOnCard,
                  ),
                ),

                SizedBox(height: 3.h),

                Text(
                  'Tap to open camera',

                  style: AppTextStyles.helperText.copyWith(
                    color: context.appSubText,
                  ),
                ),

                SizedBox(height: 5.h),

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
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(13.r),

            //   child: Image.file(
            //     _uploadedImage!,

            //     width: double.infinity,

            //     height: 180.h,

            //     fit: BoxFit.cover,
            //   ),
            // ),

            // CHANGED - Full-width image without side blank space.
            ClipRRect(
              borderRadius: BorderRadius.circular(13.r),
              child: Image.file(
                _uploadedImage!,
                key: ValueKey(_uploadedImage!.path),
                width: double.infinity,

                // REMOVED fixed height: 180.h
                height: 260.h,
                fit: BoxFit.fitWidth,

                alignment: Alignment.center,
                gaplessPlayback: false,
              ),
            ),

            // ---------------------------------------------------------------
            // PHOTO ADDED
            // ---------------------------------------------------------------
            Positioned(
              top: 7.h,

              left: 7.w,

              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),

                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),

                  borderRadius: BorderRadius.circular(14.r),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.check_circle_rounded,

                      color: const Color(0xFF7DFFA9),

                      size: 12.sp,
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

            // ---------------------------------------------------------------
            // CAMERA
            // ---------------------------------------------------------------
            Positioned(
              top: 7.h,

              right: 7.w,

              child: Material(
                color: Colors.transparent,

                child: InkWell(
                  onTap: _captureImage,

                  borderRadius: BorderRadius.circular(50.r),

                  child: Container(
                    width: 30.w,

                    height: 30.w,

                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),

                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      Icons.camera_alt_rounded,

                      color: Colors.white,

                      size: 15.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 6.h),

        // -------------------------------------------------------------------
        // RETAKE
        // -------------------------------------------------------------------
        InkWell(
          onTap: _captureImage,

          borderRadius: BorderRadius.circular(10.r),

          child: Container(
            width: double.infinity,

            padding: EdgeInsets.symmetric(vertical: 7.h),

            decoration: BoxDecoration(
              color: Color.alphaBlend(
                context.appPrimary.withValues(alpha: 0.1),
                context.appCard,
              ),

              borderRadius: BorderRadius.circular(10.r),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(
                  Icons.refresh_rounded,

                  color: context.appPrimary,

                  size: 15.sp,
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
  // BOTTOM BUTTON
  // ===========================================================================

  Widget _bottomSubmitSection() {
    final vehicle = _getMatchedVehicle(context.read<QuickAcessBloc>().state);
    final requiresKm = vehicle?.openingClosingKm != '0';
    final canSubmit =
        vehicle != null &&
        routeController.text.trim().isNotEmpty &&
        _uploadedImage != null &&
        (!requiresKm ||
            _validateKm(closingKmController.text, 'Closing KM') == null) &&
        !isLoading &&
        !_punchOutSaved;
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

                      // Container(
                      //   width: 28.w,

                      //   height: 28.w,

                      //   decoration: BoxDecoration(
                      //     color: context.appOnPrimary.withValues(alpha: 0.15),

                      //     borderRadius: BorderRadius.circular(8.r),
                      //   ),

                      //   child: Icon(
                      //     Icons.logout_rounded,

                      //     color: context.appOnPrimary,

                      //     size: 16.sp,
                      //   ),
                      // ),
                      SizedBox(width: 8.w),

                      Text(
                        'PUNCH OUT',

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
