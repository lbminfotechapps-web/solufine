// This is my updated code on date  : 24-09-2026
import 'dart:convert';
import 'dart:io';

import 'package:solufine/core/di/auth_di.dart';
import 'package:solufine/core/location_tracking/app_database.dart';
import 'package:solufine/core/location_tracking/location_repository.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/cameracapturepage.dart';
import 'package:solufine/core/utility/geo_image_stamp.dart';
import 'package:solufine/core/utility/image_compression.dart';
import 'package:solufine/core/utility/image_side_crop.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_loader.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';
import 'package:solufine/features/farmer/famerfollowup/data/model/followuplist_model.dart';
import 'package:solufine/features/farmer/famerfollowup/presentation/bloc/famerfollowup_bloc.dart';
import 'package:solufine/features/farmer/famerfollowup/presentation/bloc/famerfollowup_event.dart';
import 'package:solufine/features/farmer/famerfollowup/presentation/bloc/famerfollowup_state.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/crop_entity.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/irrigation_entity.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/selected_crop_detail.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/bloc/state_event.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/bloc/state_bloc.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/bloc/states_state.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/widgets/crop_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';

class FamerFollowupPage extends StatefulWidget {
  final String farmerId;

  const FamerFollowupPage({super.key, required this.farmerId});

  @override
  State<FamerFollowupPage> createState() => _FamerFollowupPageState();
}

class _FamerFollowupPageState extends State<FamerFollowupPage> {
  final _formKey = GlobalKey<FormState>();
  static const _fieldOrder = ['type', 'date', 'crops', 'remark'];
  final _fieldKeys = {
    for (final name in _fieldOrder) name: GlobalKey<FormFieldState>(),
  };
  final _fieldFocus = {for (final name in _fieldOrder) name: FocusNode()};
  final Geocoding _geocoding = Geocoding();
  final TextEditingController followUpDateController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  final TextEditingController cropDetailsController = TextEditingController();
  final List<SelectedCropDetail> _selectedCropDetails = [];

  String? selectedFollowUpType;
  String? imagePath;

  String? userId;

  double? latitude;
  double? longitude;

  String geoAddress = '';

  bool isLocationLoading = false;

  final List<String> followUpTypes = [
    'Call',
    'Visit',
    'Meeting',
    'Demo',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    debugPrint('FARMER ID: ${widget.farmerId}');

    _loadUserData();
    _getCurrentLocation();
    context.read<StateBloc>().add(FarmerDropEvent());
  }

  @override
  void dispose() {
    for (final node in _fieldFocus.values) {
      node.dispose();
    }
    followUpDateController.dispose();
    remarkController.dispose();
    cropDetailsController.dispose();
    super.dispose();
  }

  // ==========================================================
  // GET USER DATA
  // ==========================================================

  Future<void> _loadUserData() async {
    try {
      final userData = await SecureStorage.instance.getUserData();

      debugPrint('USER DATA: $userData');

      if (!mounted) return;

      setState(() {
        userId = userData?['user_id']?.toString();
      });

      debugPrint('LOGGED IN USER ID: $userId');
    } catch (e) {
      debugPrint('GET USER DATA ERROR: $e');

      if (!mounted) return;

      setState(() {
        userId = null;
      });
    }
  }

  // ==========================================================
  // CURRENT LOCATION
  // ==========================================================

  Future<void> _getCurrentLocation() async {
    try {
      if (!mounted) return;

      setState(() {
        isLocationLoading = true;
      });

      // ------------------------------------------------------
      // Check GPS / Location Service
      // ------------------------------------------------------

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            isLocationLoading = false;
          });

          _showMessage('Please enable location/GPS');
        }

        await Geolocator.openLocationSettings();
        return;
      }

      // ------------------------------------------------------
      // Check Permission
      // ------------------------------------------------------

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              isLocationLoading = false;
            });

            _showMessage('Location permission denied');
          }

          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            isLocationLoading = false;
          });

          _showMessage(
            'Location permission permanently denied. '
            'Please enable it from Settings.',
          );
        }

        await Geolocator.openAppSettings();
        return;
      }

      // ------------------------------------------------------
      // Get Current GPS Location
      // ------------------------------------------------------

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      latitude = position.latitude;
      longitude = position.longitude;

      debugPrint('CURRENT LATITUDE: $latitude');
      debugPrint('CURRENT LONGITUDE: $longitude');

      // ------------------------------------------------------
      // Convert Lat/Long to Address
      // ------------------------------------------------------

      try {
        final List<Placemark> placemarks = await _geocoding
            .placemarkFromCoordinates(latitude!, longitude!);

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;

          final List<String?> addressFields = [
            place.name,
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ];

          final addressParts = <String>[];
          for (final field in addressFields) {
            for (final part in (field ?? '').split(',')) {
              final value = part.trim();
              if (value.isEmpty) continue;

              final normalizedValue = value.toLowerCase();
              final alreadyIncluded = addressParts.any(
                (existing) => existing.toLowerCase().contains(normalizedValue),
              );
              if (!alreadyIncluded) {
                addressParts.add(value);
              }
            }
          }

          geoAddress = addressParts.join(', ');

          debugPrint('CURRENT ADDRESS: $geoAddress');
        }
      } catch (e) {
        debugPrint('ADDRESS ERROR: $e');

        geoAddress = 'Lat: $latitude, Long: $longitude';
      }

      if (!mounted) return;

      setState(() {
        isLocationLoading = false;
      });
    } catch (e) {
      debugPrint('LOCATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLocationLoading = false;
      });

      _showMessage('Unable to get current location');
    }
  }

  // ==========================================================
  // DATE PICKER
  // ==========================================================

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (selectedDate != null) {
      setState(() {
        followUpDateController.text =
            '${selectedDate.day.toString().padLeft(2, '0')}-'
            '${selectedDate.month.toString().padLeft(2, '0')}-'
            '${selectedDate.year}';
      });
    }
  }

  // ==========================================================
  // IMAGE PICKER - CAMERA
  // ==========================================================

  // Future<void> _captureImage() async {
  //   try {
  //     debugPrint('OPENING INTERNAL CAMERA');

  //     final String? capturedImagePath = await Navigator.of(context)
  //         .push<String>(
  //           MaterialPageRoute(builder: (_) => const CameraCapturePage()),
  //         );

  //     if (capturedImagePath == null || capturedImagePath.isEmpty) {
  //       return;
  //     }

  //     final newFile = File(capturedImagePath);

  //     if (!await newFile.exists()) {
  //       _showMessage('Captured image not found');
  //       return;
  //     }

  //     // Delete previously captured image
  //     if (imagePath != null &&
  //         imagePath!.isNotEmpty &&
  //         imagePath != capturedImagePath) {
  //       try {
  //         final oldFile = File(imagePath!);

  //         if (await oldFile.exists()) {
  //           await oldFile.delete();
  //           debugPrint('OLD IMAGE DELETED: $imagePath');
  //         }
  //       } catch (e) {
  //         debugPrint('OLD IMAGE DELETE ERROR: $e');
  //       }
  //     }

  //     if (!mounted) return;

  //     setState(() {
  //       imagePath = capturedImagePath;
  //     });

  //     debugPrint('NEW IMAGE: $imagePath');
  //   } catch (e, stackTrace) {
  //     debugPrint('CAMERA ERROR: $e');
  //     debugPrint('$stackTrace');

  //     if (!mounted) return;

  //     _showMessage('Unable to capture image');
  //   }
  // }

  Future<void> _captureImage() async {
    try {
      debugPrint('========== FARMER PHOTO CAPTURE ==========');

      // ============================================================
      // 1. OPEN EXISTING CAMERA PAGE - SAME
      // ============================================================

      final String? capturedImagePath = await Navigator.of(context)
          .push<String>(
            MaterialPageRoute(builder: (_) => const CameraCapturePage()),
          );

      if (capturedImagePath == null || capturedImagePath.isEmpty) {
        return;
      }

      final File originalImage = File(capturedImagePath);

      if (!await originalImage.exists()) {
        _showMessage('Captured image not found');
        return;
      }

      // ============================================================
      // 2. ORIGINAL IMAGE SIZE - NEW
      // ============================================================

      final int originalSize = await originalImage.length();

      debugPrint('ORIGINAL IMAGE: ${originalImage.path}');
      debugPrint(
        'ORIGINAL SIZE: '
        '${(originalSize / 1024).toStringAsFixed(2)} KB',
      );

      // ============================================================
      // 3. COMPRESS IMAGE - NEW
      // ============================================================

      // final File? compressedImage = await ImageCompression.compressImage(
      //   originalImage,
      //   maxWidth: 450,
      //   maxHeight: 450,
      //   quality: 45,
      // );

      // File finalImage = originalImage;

      // if (compressedImage != null &&
      //     await compressedImage.exists()) {
      //   finalImage = compressedImage;

      //   debugPrint(
      //     'COMPRESSED IMAGE: ${compressedImage.path}',
      //   );
      // } else {
      //   debugPrint('COMPRESSION FAILED - USING ORIGINAL');
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
      // 4. GET CURRENT LOCATION - NEW
      // ============================================================

      // Uses your existing high accuracy location flow.
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final String photoLatitude = position.latitude.toStringAsFixed(6);

      final String photoLongitude = position.longitude.toStringAsFixed(6);

      debugPrint('PHOTO LATITUDE: $photoLatitude');
      debugPrint('PHOTO LONGITUDE: $photoLongitude');
      debugPrint('ACCURACY: ${position.accuracy}');

      // ============================================================
      // 5. GET GEO ADDRESS - NEW
      // ============================================================

      String photoAddress = '';

      try {
        final List<Placemark> placemarks = await _geocoding
            .placemarkFromCoordinates(position.latitude, position.longitude);

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;

          final List<String?> addressFields = [
            place.name,
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ];

          final List<String> addressParts = [];

          for (final field in addressFields) {
            for (final part in (field ?? '').split(',')) {
              final String value = part.trim();

              if (value.isEmpty) continue;

              final String normalized = value.toLowerCase();

              final bool alreadyIncluded = addressParts.any(
                (existing) => existing.toLowerCase() == normalized,
              );

              if (!alreadyIncluded) {
                addressParts.add(value);
              }
            }
          }

          photoAddress = addressParts.join(', ');
        }
      } catch (e) {
        debugPrint('PHOTO ADDRESS ERROR: $e');
      }

      if (photoAddress.trim().isEmpty) {
        photoAddress = 'Not available';
      }

      debugPrint('PHOTO GEO ADDRESS: $photoAddress');

      // ============================================================
      // 6. PRINT GPS ON COMPRESSED IMAGE - NEW
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

      // CHANGED: Final image now includes GPS information.
      finalImage = gpsStampedImage;

      // ============================================================
      // 7. DELETE PREVIOUS IMAGE - EXISTING LOGIC
      // ============================================================

      if (imagePath != null &&
          imagePath!.isNotEmpty &&
          imagePath != finalImage.path) {
        try {
          final File oldFile = File(imagePath!);

          if (await oldFile.exists()) {
            await oldFile.delete();

            debugPrint('OLD IMAGE DELETED: $imagePath');
          }
        } catch (e) {
          debugPrint('OLD IMAGE DELETE ERROR: $e');
        }
      }

      // ============================================================
      // 8. SAVE FINAL IMAGE PATH - EXISTING
      // ============================================================

      if (!mounted) return;

      setState(() {
        imagePath = finalImage.path;
      });

      debugPrint('========== FINAL FARMER IMAGE ==========');
      debugPrint('IMAGE PATH: $imagePath');
      debugPrint('LATITUDE: $photoLatitude');
      debugPrint('LONGITUDE: $photoLongitude');
      debugPrint('ADDRESS: $photoAddress');
      debugPrint(
        'SIZE: ${(await finalImage.length() / 1024).toStringAsFixed(2)} KB',
      );
      debugPrint('=======================================');
    } catch (e, stackTrace) {
      debugPrint('CAMERA ERROR: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        _showMessage('Unable to prepare GPS photo: $e');
      }
    }
  }

  void _submitFollowup() {
    if (!_formKey.currentState!.validate()) {
      for (final entry in _fieldKeys.entries) {
        final field = entry.value.currentState;
        if (field != null && field.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            _fieldFocus[entry.key]!.requestFocus();
            final fieldContext = entry.value.currentContext;
            if (fieldContext != null) {
              Scrollable.ensureVisible(
                fieldContext,
                duration: const Duration(milliseconds: 300),
                alignment: 0.2,
              );
            }
          });
          break;
        }
      }
      return;
    }

    FocusScope.of(context).unfocus();

    // --------------------------------------------------------
    // Follow-up Type
    // --------------------------------------------------------

    if (selectedFollowUpType == null || selectedFollowUpType!.isEmpty) {
      _showMessage('Please select follow-up type');
      return;
    }

    // --------------------------------------------------------
    // Date
    // --------------------------------------------------------

    if (followUpDateController.text.trim().isEmpty) {
      _showMessage('Please select next follow-up date');
      return;
    }

    // --------------------------------------------------------
    // User ID
    // --------------------------------------------------------

    if (userId == null || userId!.trim().isEmpty) {
      _showMessage('User information not available');
      return;
    }

    // --------------------------------------------------------
    // Farmer ID
    // --------------------------------------------------------

    if (widget.farmerId.trim().isEmpty) {
      _showMessage('Farmer ID not available');
      return;
    }

    // --------------------------------------------------------
    // Location
    // --------------------------------------------------------

    if (latitude == null || longitude == null) {
      _showMessage('Getting current location. Please try again.');

      _getCurrentLocation();
      return;
    }

    debugPrint('================ FOLLOW-UP SUBMIT ================');

    debugPrint('FARMER ID: ${widget.farmerId}');

    debugPrint('USER ID: $userId');

    debugPrint(
      'FOLLOW-UP DATE: '
      '${followUpDateController.text.trim()}',
    );

    debugPrint('FOLLOW-UP TYPE: $selectedFollowUpType');
    assert(() {
      debugPrint('SELECTED CROP DETAILS JSON:');
      debugPrint(
        jsonEncode(_selectedCropDetails.map((crop) => crop.toJson()).toList()),
      );
      return true;
    }());

    debugPrint('REMARK: ${remarkController.text.trim()}');

    debugPrint('LATITUDE: $latitude');

    debugPrint('LONGITUDE: $longitude');

    debugPrint('ADDRESS: $geoAddress');

    debugPrint('IMAGE: $imagePath');

    debugPrint('===================================================');

    // --------------------------------------------------------
    // Dispatch Event
    // --------------------------------------------------------

    context.read<FamerfollowupBloc>().add(
      SubmitFollowupEvent(
        farmerId: widget.farmerId,
        userId: userId!,

        followUpDate: followUpDateController.text.trim(),

        followUpType: selectedFollowUpType!,

        remark: remarkController.text.trim(),

        latitude: latitude!,

        longitude: longitude!,

        networkLatitude: latitude!,

        networkLongitude: longitude!,

        gpsLatitude: latitude!,

        gpsLongitude: longitude!,

        geoAddress: geoAddress,

        networkInfo: '',

        batteryInfo: '',

        differenceByAndroid: '0',

        statusOfFarmer: '',

        activityId: '6',
        cropDetails: jsonEncode(
          _selectedCropDetails.map((crop) => crop.toJson()).toList(),
        ),

        imagePath: imagePath,
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTextStyles.body),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<String> _getStoredLocations() async {
    try {
      final int? parsedUserId = int.tryParse(userId.toString());

      if (parsedUserId == null) {
        debugPrint('LOCATION: Invalid userId = $userId');
        return '[]';
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

      // ============================================================
      // CREATE DATA FOR STORE LOCATION API
      // ============================================================

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

      // ============================================================
      // JSON ARRAY -> STRING
      // ============================================================

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

      return '[]';
    }
  }

  Future<void> _showCropDetailsDialog(
    List<CropEntity> cropList,
    List<IrrigationEntity> irrigationList,
  ) async {
    if (cropList.isEmpty) {
      _showMessage('Crop data not available');
      return;
    }

    if (irrigationList.isEmpty) {
      _showMessage('Irrigation data not available');
      return;
    }

    final result = await showDialog<List<SelectedCropDetail>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CropDetailsDialog(
        cropList: cropList,
        irrigationList: irrigationList,
        existingSelections: _selectedCropDetails,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedCropDetails
          ..clear()
          ..addAll(result);
        cropDetailsController.text = _selectedCropDetails
            .map((item) => item.cropName)
            .join(', ');
      });
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamerfollowupBloc, FamerfollowupState>(
      listener: (context, state) async {
        // ----------------------------------------------------
        // SUCCESS
        // ----------------------------------------------------

        if (state.status == FamerfollowupStatus.farmerFollowUpSuccess) {
          debugPrint('DAILY TRAN ID FROM STATE: ${state.dailyTranId}');

          final String strAllLocations = await _getStoredLocations();
          debugPrint('========================================');
          debugPrint('CALLING STORE TRACK LOCATION API');
          debugPrint('USER ID: $userId');
          debugPrint('DAILY TRAN ID: ${state.dailyTranId}');
          debugPrint('STR ALL LOCATIONS: $strAllLocations');
          debugPrint('========================================');

          context.read<QuickAcessBloc>().add(
            StoreTrackLocation(
              userId.toString(),
              state.dailyTranId!,
              strAllLocations,
            ),
          );

          AppDialog.show(
            context: context,
            type: DialogType.success,
            title: 'Successful',
            message: 'Farmer Visit successfully.',
            buttonText: 'OK',
            onButtonPressed: () {
              context.go(AppRouter.home);
            },
          );
        }

        // ----------------------------------------------------
        // FAILURE
        // ----------------------------------------------------

        if (state.status == FamerfollowupStatus.failure) {
          _showMessage(state.errorMessage ?? 'Failed to submit record');
        }
      },

      child: Scaffold(
        backgroundColor: context.appBackground,

        // ====================================================
        // APP BAR
        // ====================================================
        appBar: CustomAppBar(
          title: 'Farmer Follow-up',
          // subtitle: 'Add farmer follow-up',
          showBackButton: true,
          onBackTap: () => Navigator.pop(context),
        ),

        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 14.h),
                  _buildHistoryStrip(),
                  const SizedBox(height: 18),

                  _sectionTitle(
                    icon: Icons.event_note_rounded,
                    title: 'Follow-up Details',
                  ),

                  const SizedBox(height: 12),

                  _buildFollowUpType(),

                  const SizedBox(height: 14),

                  _buildDateField(),

                  const SizedBox(height: 14),

                  _buildCropDetailsField(),

                  const SizedBox(height: 14),

                  _buildRemarkField(),

                  const SizedBox(height: 22),

                  _sectionTitle(
                    icon: Icons.photo_camera_back_rounded,
                    title: 'Follow-up Image',
                  ),

                  const SizedBox(height: 12),

                  _buildImagePicker(),

                  const SizedBox(height: 24),

                  _buildLocationCard(),

                  const SizedBox(height: 16),

                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ),

        // ====================================================
        // BOTTOM SUBMIT BUTTON
        // ====================================================
        bottomSheet: BlocBuilder<FamerfollowupBloc, FamerfollowupState>(
          builder: (context, state) {
            final bool loading = state.status == FamerfollowupStatus.loading;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: context.appCard,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 15,
                    offset: const Offset(0, -3),
                    color: Colors.black.withOpacity(0.06),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submitFollowup,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appPrimary,
                      foregroundColor: context.appOnPrimary,
                      elevation: 0,
                      disabledBackgroundColor: context.appPrimary.withValues(
                        alpha: 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    child: loading
                        ? SizedBox(
                            height: 23,
                            width: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: context.appOnPrimary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 21,
                              ),

                              SizedBox(width: 9),

                              Text(
                                'Submit Follow-up',
                                style: AppTextStyles.button,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCropDetailsField() {
    return BlocBuilder<StateBloc, StatsState>(
      builder: (context, state) {
        final cropList = state.farmerDetailsEntity?.cropDetailsData ?? [];
        final irrigationList =
            state.farmerDetailsEntity?.irrigationDetailsData ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop Details',
              style: AppTextStyles.labelLarge.copyWith(
                color: context.appOnCard,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: cropDetailsController,
              hintText: 'Select Land and Crop Details',
              fieldKey: _fieldKeys['crops'],
              focusNode: _fieldFocus['crops'],
              isValid: _selectedCropDetails.isNotEmpty,
              prefixIcon: Icons.grass_outlined,
              readOnly: true,
              onTap: () {
                _showCropDetailsDialog(cropList, irrigationList);
              },
              validator: (value) {
                if (_selectedCropDetails.isEmpty) {
                  return 'Please select crop details';
                }

                return null;
              },
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              context.appPrimary.withValues(alpha: 0.1),
              context.appCard,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: context.appPrimary),
        ),

        const SizedBox(width: 9),

        Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(color: context.appOnCard),
        ),
      ],
    );
  }

  Widget _buildHistoryStrip() {
    return Material(
      color: context.appCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _showFollowupHistory,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    context.appPrimary.withValues(alpha: 0.1),
                    context.appCard,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: context.appPrimary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Follow-up History',
                      style: AppTextStyles.listTitle.copyWith(
                        color: context.appOnCard,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'View previous farmer follow-ups',
                      style: AppTextStyles.caption.copyWith(
                        color: context.appSubText,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: context.appInputBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: context.appPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFollowupHistory() {
    context.read<FamerfollowupBloc>().add(
      GetRemarkHistoryEvent(farmerId: widget.farmerId),
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _FollowupHistoryDialog(farmerId: widget.farmerId);
      },
    );
  }
  // ==========================================================
  // FOLLOW-UP TYPE
  // ==========================================================

  Widget _buildFollowUpType() {
    return DropdownButtonFormField<String>(
      style: AppTextStyles.input.copyWith(color: context.appOnCard),
      dropdownColor: context.appCard,
      isExpanded: true,
      key: _fieldKeys['type'],
      focusNode: _fieldFocus['type'],
      value: selectedFollowUpType,

      decoration: _inputDecoration(
        label: 'Follow-up Type',
        icon: Icons.call_merge_rounded,
      ),

      hint: Text(
        'Select follow-up type',
        style: AppTextStyles.inputHint.copyWith(color: context.appSubText),
      ),

      icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.appPrimary),

      items: followUpTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: AppTextStyles.bodyMedium.copyWith(color: context.appOnCard),
          ),
        );
      }).toList(),

      onChanged: (value) {
        setState(() {
          selectedFollowUpType = value;
        });
      },

      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select follow-up type';
        }

        return null;
      },
    );
  }

  // ==========================================================
  // DATE
  // ==========================================================

  Widget _buildDateField() {
    return TextFormField(
      style: AppTextStyles.input,
      key: _fieldKeys['date'],
      focusNode: _fieldFocus['date'],
      controller: followUpDateController,
      readOnly: true,
      onTap: _selectDate,

      decoration: _inputDecoration(
        label: 'Next Follow-up Date',
        icon: Icons.calendar_today_rounded,
        suffix: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: context.appSubText,
        ),
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please select next follow-up date';
        }

        return null;
      },
    );
  }

  // ==========================================================
  // REMARK
  // ==========================================================

  Widget _buildRemarkField() {
    return TextFormField(
      style: AppTextStyles.input,
      key: _fieldKeys['remark'],
      focusNode: _fieldFocus['remark'],
      controller: remarkController,
      maxLines: 5,
      minLines: 4,
      textInputAction: TextInputAction.newline,

      decoration: _inputDecoration(
        label: 'Remark',
        icon: Icons.notes_rounded,
        hintText: 'Enter remark',
        alignLabelWithHint: true,
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
        contentPadding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter remark';
        }

        if (value.trim().length < 3) {
          return 'Remark is too short';
        }

        return null;
      },
    );
  }

  // ==========================================================
  // IMAGE PICKER
  // ==========================================================

  Widget _buildImagePicker() {
    if (imagePath != null) {
      return Stack(
        children: [
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(20),
          //   child: Image.file(
          //     File(imagePath!),
          //     width: double.infinity,
          //     height: 210,
          //     fit: BoxFit.cover,
          //   ),
          // ),

          // CHANGED: Full image without cropping GPS address.
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: double.infinity,
              child: Image.file(
                File(imagePath!),
                key: ValueKey(imagePath),
                width: double.infinity,

                height: 260.h,
                fit: BoxFit.fitWidth,
                alignment: Alignment.center,
                gaplessPlayback: false,
              ),
            ),
          ),

          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _imageActionButton(
                  icon: Icons.refresh_rounded,
                  onTap: _captureImage,
                ),

                const SizedBox(width: 8),

                _imageActionButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: _deleteSelectedImage,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _captureImage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appBorder, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  context.appPrimary.withValues(alpha: 0.1),
                  context.appCard,
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                Icons.add_a_photo_rounded,
                color: context.appPrimary,
                size: 27,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Add Image',
              style: AppTextStyles.cardTitle.copyWith(color: context.appOnCard),
            ),

            const SizedBox(height: 4),

            Text(
              'Tap to take a photo',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(.60),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }

  // ==========================================================
  // LOCATION CARD
  // ==========================================================

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                context.appPrimary.withValues(alpha: 0.1),
                context.appCard,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: context.appPrimary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: AppTextStyles.listTitle.copyWith(
                    color: context.appOnCard,
                  ),
                ),

                const SizedBox(height: 5),

                if (isLocationLoading)
                  Row(
                    children: [
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.appPrimary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Getting location...',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.appSubText,
                        ),
                      ),
                    ],
                  )
                else if (latitude != null && longitude != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${latitude!.toStringAsFixed(6)}, '
                        '${longitude!.toStringAsFixed(6)}',
                        style: AppTextStyles.label.copyWith(
                          color: context.appPrimary,
                        ),
                      ),

                      if (geoAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          geoAddress,
                          style: AppTextStyles.caption.copyWith(
                            color: context.appSubText,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Text(
                    'Location not available',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appSubText,
                    ),
                  ),
              ],
            ),
          ),

          IconButton(
            onPressed: isLocationLoading ? null : _getCurrentLocation,
            icon: Icon(
              Icons.refresh_rounded,
              color: context.appPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFO CARD
  // ==========================================================

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          context.appPrimary.withValues(alpha: 0.1),
          context.appCard,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: context.appPrimary, size: 20),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Add the next follow-up date and a clear remark so the farmer interaction can be tracked properly.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appOnCard,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    Widget? suffix,
    bool alignLabelWithHint = false,
    BoxConstraints? prefixIconConstraints,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      labelText: label,
      errorStyle: AppTextStyles.inputError,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,

      prefixIcon: Icon(icon, color: context.appPrimary, size: 20),
      prefixIconConstraints: prefixIconConstraints,

      suffixIcon: suffix,

      filled: true,
      fillColor: context.appCard,

      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      labelStyle: AppTextStyles.inputLabel.copyWith(color: context.appSubText),

      hintStyle: AppTextStyles.inputHint.copyWith(color: context.appSubText),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appBorder),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appBorder),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appPrimary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appError),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appError, width: 1.5),
      ),
    );
  }

  Future<void> _deleteSelectedImage() async {
    final String? path = imagePath;

    if (path == null || path.trim().isEmpty) {
      return;
    }

    try {
      final File file = File(path);

      if (await file.exists()) {
        await file.delete();
        debugPrint('IMAGE DELETED: $path');
      }
    } catch (e) {
      debugPrint('IMAGE DELETE ERROR: $e');
    }

    if (!mounted) return;

    setState(() {
      imagePath = null;
    });
  }

  Future<void> _clearCapturedImage() async {
    final String? path = imagePath;

    if (path == null || path.trim().isEmpty) {
      return;
    }

    try {
      final File file = File(path);

      if (await file.exists()) {
        await file.delete();
        debugPrint('TEMP IMAGE DELETED AFTER SUCCESS: $path');
      }
    } catch (e) {
      debugPrint('TEMP IMAGE DELETE ERROR: $e');
    }

    if (!mounted) return;

    setState(() {
      imagePath = null;
    });
  }
}

class _FollowupHistoryDialog extends StatelessWidget {
  final String farmerId;

  const _FollowupHistoryDialog({required this.farmerId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: context.appBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),

            Expanded(
              child: BlocBuilder<FamerfollowupBloc, FamerfollowupState>(
                builder: (context, state) {
                  if (state.status == FamerfollowupStatus.loading) {
                    return CustomLoader(color: context.appPrimary);
                  }

                  if (state.status == FamerfollowupStatus.failure) {
                    return _buildError(context, state.historyError);
                  }

                  if (state.historyList.isEmpty) {
                    return _buildEmpty(context);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.historyList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = state.historyList[index];

                      return _buildHistoryItem(context, item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 16),
      decoration: BoxDecoration(
        color: context.appPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: context.appOnPrimary.withOpacity(.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.history_rounded,
              color: context.appOnPrimary,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow-up History',
                  style: AppTextStyles.dialogTitle.copyWith(
                    color: context.appOnPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Farmer ID: $farmerId',
                  style: AppTextStyles.caption.copyWith(
                    color: context.appOnPrimary.withOpacity(.8),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.close_rounded, color: context.appOnPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, RemarkListModel item) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE + TIME
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    context.appPrimary.withValues(alpha: 0.1),
                    context.appCard,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: context.appPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.fldDate,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.appPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Icon(
                Icons.access_time_rounded,
                size: 15,
                color: context.appSubText,
              ),

              const SizedBox(width: 4),

              Text(
                item.fldTime,
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.appSubText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // ADMIN
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: context.appPrimary,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  item.fldAdmName.isEmpty ? '-' : item.fldAdmName,
                  style: AppTextStyles.listTitle.copyWith(
                    color: context.appOnCard,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // OUTLET
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 18,
                color: context.appPrimary,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  item.fldFarmerName.isEmpty ? '-' : item.fldFarmerName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.appOnCard,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // REMARK
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appInputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded, size: 17, color: context.appPrimary),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    item.fldRemark.isEmpty ? 'No remark' : item.fldRemark,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appOnCard,
                      height: 1.4,
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

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 55,
              color: context.appSubText,
            ),

            SizedBox(height: 14),

            Text(
              'No Follow-up History',
              style: AppTextStyles.cardTitle.copyWith(color: context.appOnCard),
            ),

            SizedBox(height: 5),

            Text(
              'No previous follow-ups found for this farmer.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: context.appError,
            ),

            const SizedBox(height: 12),

            Text('Unable to load history', style: AppTextStyles.cardTitle),

            const SizedBox(height: 5),

            Text(
              error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
