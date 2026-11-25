import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'dart:convert';
import 'dart:io';

import 'package:solufine/core/di/auth_di.dart';
import 'package:solufine/core/location_tracking/app_database.dart';
import 'package:solufine/core/location_tracking/location_repository.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/utility/app_image_picker.dart';
import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/cameracapturepage.dart';
import 'package:solufine/core/utility/data_list.dart';
import 'package:solufine/core/utility/device_info_util.dart';
import 'package:solufine/core/utility/location_util.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_button.dart';
import 'package:solufine/core/utility/widgets/custom_dropdown.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';
import 'package:solufine/features/farmer/farmerregistration/data/datasource/farmerregistration_datasource.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/crop_entity.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/district_entity.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/irrigation_entity.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/selected_crop_detail.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/bloc/state_bloc.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/bloc/state_event.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/bloc/states_state.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/widgets/crop_details_dialog.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/widgets/product_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';

class FarmerregistrationPage extends StatefulWidget {
  const FarmerregistrationPage({super.key});

  @override
  State<FarmerregistrationPage> createState() => _FarmerregistrationPageState();
}

class _FarmerregistrationPageState extends State<FarmerregistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fieldKeys = {
    for (final name in [
      'name',
      'address',
      'mobile',
      'alternate',
      'email',
      'state',
      'district',
      'taluka',
      'status',
      'products',
      'crops',
      'photo',
    ])
      name: GlobalKey<FormFieldState>(),
  };
  final _fieldFocus = {
    for (final name in [
      'name',
      'address',
      'mobile',
      'alternate',
      'email',
      'state',
      'district',
      'taluka',
      'status',
      'products',
      'crops',
      'photo',
    ])
      name: FocusNode(),
  };

  void _refreshRequiredFields() {
    if (mounted) setState(() {});
  }

  final TextEditingController farmerNameController = TextEditingController();

  final TextEditingController contactPersonController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  final TextEditingController mobileController = TextEditingController();

  final TextEditingController alternateMobileController =
      TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController villageController = TextEditingController();

  final TextEditingController currentProductUsedController =
      TextEditingController();

  final TextEditingController remarkController = TextEditingController();

  bool isLoading = false;
  bool _submissionSent = false;
  String? _selectedStateId = '0';
  String? _selectedDistrictId = '0';
  String? _selectedTalukaId = '0';
  String? _selectedFarmerStatus;
  String _selectedPersonCategoryId = '';
  Map<String, String> _personCategories = const {
    '2': 'currently use machine',
    '7': 'gramsevak',
    '4': 'Special persons',
    '3': 'Tractor model and hp manually add',
    '1': 'Van Campaign',
  };
  File? _uploadedImage;
  final List<String> _selectedProductIds = [];
  final List<SelectedCropDetail> _selectedCropDetails = [];
  String? userId;
  String selectedSowingDates = '';
  String selectedAcers = '';
  String selectedIrrigationId = '';
  String selectedCropId = '';
  String latitude = '';
  String longitude = '';
  String address = '';
  @override
  void initState() {
    super.initState();
    for (final controller in [
      farmerNameController,
      addressController,
      mobileController,
    ]) {
      controller.addListener(_refreshRequiredFields);
    }
    // getUserId();
    _loadStates();
    _loadPersonCategories();
    getGeoAddress();

    context.read<StateBloc>().add(FarmerDropEvent());
  }

  Future<void> _loadPersonCategories() async {
    try {
      final categories = await sl<FarmerregistrationDatasource>()
          .getPersonCategories();
      if (!mounted) return;

      setState(() {
        _personCategories = categories;
        if (!categories.containsKey(_selectedPersonCategoryId)) {
          _selectedPersonCategoryId = '';
        }
      });
    } catch (error) {
      debugPrint('Unable to load person categories: $error');
    }
  }

  Future<void> getGeoAddress() async {
    final position = await LocationUtil.instance.getCurrentLocation();

    if (position != null) {
      latitude = position.latitude.toString();
      longitude = position.longitude.toString();

      address = await LocationUtil.instance.getAddress(
        position.latitude,
        position.longitude,
      );
      addressController.text = address;
    }
  }

  Future<void> getUserId() async {
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

    context.read<StateBloc>().add(StateListEvent(userId: userId.toString()));
  }

  Future<void> _loadStates() async {
    await getUserId();
  }

  Future<void> _onStateSelected(String? stateId) async {
    if (stateId == null || stateId.isEmpty) {
      return;
    }

    debugPrint('================================');
    debugPrint('STATE SELECTED');
    debugPrint('STATE ID: $stateId');
    debugPrint('================================');

    if (stateId == '0') {
      setState(() {
        _selectedStateId = '0';

        // Reset district
        _selectedDistrictId = '0';

        // Reset taluka
        _selectedTalukaId = '0';
      });

      debugPrint('Select State selected');
      debugPrint('District reset to Select District');
      debugPrint('Taluka reset to Select Taluka');

      return;
    }

    setState(() {
      _selectedStateId = stateId;

      _selectedDistrictId = '0';
      _selectedTalukaId = '0';
    });

    final userData = await SecureStorage.instance.getUserData();

    final userId = userData?['user_id']?.toString();

    if (!mounted || userId == null || userId.isEmpty) {
      return;
    }

    debugPrint('================================');
    debugPrint('CALLING DISTRICT API');
    debugPrint('USER ID: $userId');
    debugPrint('STATE ID: $stateId');
    debugPrint('================================');

    context.read<StateBloc>().add(
      DistrictEvent(userId: userId, stateId: stateId),
    );
  }

  void _onDistrictSelected(String? districtId, StatsState state) {
    if (districtId == null || districtId.isEmpty) {
      return;
    }

    debugPrint('================================');
    debugPrint('DISTRICT SELECTED');
    debugPrint('DISTRICT ID: $districtId');
    debugPrint('================================');

    if (districtId == '0') {
      setState(() {
        _selectedDistrictId = '0';
        _selectedTalukaId = '0';
      });

      debugPrint('Select District selected');
      debugPrint('Taluka reset to Select Taluka');

      return;
    }

    DistrictEntity? selectedDistrict;

    for (final district in state.districtList) {
      if (district.fldDistId == districtId) {
        selectedDistrict = district;
        break;
      }
    }

    if (selectedDistrict == null) {
      debugPrint('Selected district not found');
      return;
    }

    debugPrint('DISTRICT NAME: ${selectedDistrict.fldDistName}');

    debugPrint('TALUKA COUNT: ${selectedDistrict.taluka.length}');

    setState(() {
      _selectedDistrictId = districtId;

      _selectedTalukaId = '0';
    });
  }

  Future<void> _captureImage() async {
    try {
      debugPrint('================================');
      debugPrint('OPENING INTERNAL CAMERA');

      // Open your custom/internal camera screen
      final String? capturedImagePath = await Navigator.of(context)
          .push<String>(
            MaterialPageRoute(builder: (_) => const CameraCapturePage()),
          );

      // User pressed back / cancelled
      if (capturedImagePath == null || capturedImagePath.trim().isEmpty) {
        debugPrint('CAMERA CANCELLED');
        return;
      }

      final File newFile = File(capturedImagePath);

      // Check captured file exists
      if (!await newFile.exists()) {
        debugPrint('CAPTURED IMAGE NOT FOUND: $capturedImagePath');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Captured image not found',
              style: AppTextStyles.body,
            ),
          ),
        );

        return;
      }

      debugPrint('NEW IMAGE PATH: $capturedImagePath');
      debugPrint('NEW IMAGE SIZE: ${await newFile.length()} bytes');

      // ============================================
      // SAVE OLD IMAGE
      // ============================================

      final File? oldImage = _uploadedImage;

      if (!mounted) return;

      // ============================================
      // SET NEW IMAGE
      // ============================================

      setState(() {
        _uploadedImage = newFile;
      });

      // ============================================
      // DELETE OLD IMAGE FROM CACHE
      // ============================================

      if (oldImage != null && oldImage.path != capturedImagePath) {
        await _deleteTempFile(oldImage);
      }

      debugPrint('CAMERA IMAGE SET SUCCESSFULLY');
      debugPrint('IMAGE PATH: ${_uploadedImage?.path}');
      debugPrint('================================');
    } catch (e, stackTrace) {
      debugPrint('CAMERA ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to capture image', style: AppTextStyles.body),
        ),
      );
    }
  }

  Future<void> _deleteTempFile(File? file) async {
    if (file == null) return;

    try {
      if (await file.exists()) {
        final String path = file.path;

        await file.delete();

        debugPrint('TEMP IMAGE DELETED: $path');
      }
    } catch (e) {
      debugPrint('TEMP IMAGE DELETE ERROR: $e');
    }
  }

  Future<void> _removeUploadedImage() async {
    final File? image = _uploadedImage;

    if (image == null) return;

    // Clear UI first
    if (mounted) {
      setState(() {
        _uploadedImage = null;
      });
    }

    // Delete actual temporary file
    await _deleteTempFile(image);
  }

  Future<void> _showCropDetailsDialog(
    List<CropEntity> cropList,
    List<IrrigationEntity> irrigationList,
  ) async {
    if (cropList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Crop data not available', style: AppTextStyles.body),
        ),
      );
      return;
    }

    if (irrigationList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Irrigation data not available',
            style: AppTextStyles.body,
          ),
        ),
      );
      return;
    }

    final result = await showDialog<List<SelectedCropDetail>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CropDetailsDialog(
          cropList: cropList,
          irrigationList: irrigationList,
          existingSelections: _selectedCropDetails,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedCropDetails
          ..clear()
          ..addAll(result);

        // ============================================
        // CONVERT DIALOG DATA TO API FORMAT
        // ============================================

        // Example:
        // 16-09-2026,14-09-2026,22-09-2026
        selectedSowingDates = _selectedCropDetails
            .map((item) => _formatApiDate(item.date))
            .join(',');

        // Example:
        // 258,523,,66,,
        selectedAcers = _selectedCropDetails
            .map((item) => item.acre.trim())
            .join(',');

        // Example:
        // 1,2,1
        selectedIrrigationId = _selectedCropDetails
            .map((item) => item.irrigationId)
            .join(',');

        // Example:
        // 145,146,148
        selectedCropId = _selectedCropDetails
            .map((item) => item.cropId)
            .join(',');
      });

      // ============================================
      // DEBUG
      // ============================================

      debugPrint('================================');
      debugPrint('SELECTED CROP DETAILS');
      debugPrint('================================');

      debugPrint('selectedSowingDates: $selectedSowingDates');

      debugPrint('selectedAcers: $selectedAcers');

      debugPrint('selectedIrrigationId: $selectedIrrigationId');

      debugPrint('selectedCropId: $selectedCropId');

      debugPrint('================================');
    }
  }

  String _formatApiDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  String get _selectedProductNames {
    final productList =
        context
            .read<StateBloc>()
            .state
            .farmerDetailsEntity
            ?.productDetailsData ??
        [];

    return productList
        .where((product) => _selectedProductIds.contains(product.fldProductId))
        .map((product) => product.fldProductName)
        .join(', ');
  }

  Future<void> _submit() async {
    if (isLoading) return;

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

    setState(() {
      isLoading = true;
      _submissionSent = false;
    });

    try {
      if (_selectedStateId == null || _selectedStateId!.isEmpty) {
        throw Exception('Please select state');
      }

      if (_selectedDistrictId == null || _selectedDistrictId!.isEmpty) {
        throw Exception('Please select district');
      }

      if (_selectedTalukaId == null || _selectedTalukaId!.isEmpty) {
        throw Exception('Please select taluka');
      }

      final batteryInfo = await DeviceInfoUtil.instance.getBatteryInfo();

      final networkInfo = await DeviceInfoUtil.instance.getNetworkInfo();

      // final position = await LocationUtil.instance.getCurrentLocation();

      // String latitude = '';
      // String longitude = '';
      // String address = '';

      // if (position != null) {
      //   latitude = position.latitude.toString();
      //   longitude = position.longitude.toString();

      //   address = await LocationUtil.instance.getAddress(
      //     position.latitude,
      //     position.longitude,
      //   );
      // }

      // final userData = await SecureStorage.instance.getUserData();

      // final userId = int.tryParse(userData?['user_id']?.toString() ?? '');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final selectedProductId = _selectedProductIds.join(',');
      print("Imagepath $_uploadedImage");
      context.read<StateBloc>().add(
        FarmerSubmitDetailsEvent(
          fldFarmerName: farmerNameController.text.trim(),

          fldAddress: addressController.text.trim(),

          userId: userId.toString(),

          fldCategoryId: _selectedPersonCategoryId,

          state: _selectedStateId ?? '0',

          district: _selectedDistrictId ?? '0',

          taluka: _selectedTalukaId ?? '0',

          statusOfFarmer: _selectedFarmerStatus ?? '',

          campaignRadio: 'Yes',

          fldMobileNo: mobileController.text.trim(),

          fldMobileNo2: alternateMobileController.text.trim(),

          fldTotalAcre: _selectedCropDetails
              .fold<double>(
                0.0,
                (sum, item) => sum + (double.tryParse(item.acre) ?? 0),
              )
              .toStringAsFixed(2),

          fldEmailId: emailController.text.trim(),

          fldTractorMode: '',

          fldVillage: villageController.text.trim(),

          selectedProductId: selectedProductId,

          selectedCropId: _selectedCropDetails
              .map((item) => item.cropId.toString())
              .join(','),

          selectedAcers: selectedAcers,

          selectedSowingDates: selectedSowingDates,

          selectedIrrigationId: selectedIrrigationId,

          selectedCattleId: '',

          selectedCattleCount: '',

          latitude: latitude,

          longitude: longitude,

          networkLatitude: latitude,

          networkLongitude: longitude,

          gpsLatitude: latitude,

          gpsLongitude: longitude,

          differenceByAndroid: '0.0',

          contactPersonName: contactPersonController.text.trim(),

          meetingLocation: '',

          marketNearby: '',

          aadhaarNo: '',

          remark: remarkController.text.trim(),

          geoAddress: address,

          strNetworkInfo: networkInfo,

          currentProductUsed: currentProductUsedController.text.trim(),

          strBatteryInfo: batteryInfo,

          activityId: '2',

          image: _uploadedImage?.path ?? '',
          fldDemoTypeId: '',
        ),
      );

      _submissionSent = true;

      debugPrint('FARMER SUBMIT EVENT SENT');
    } catch (e) {
      debugPrint('FARMER SUBMIT ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        _submissionSent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: AppTextStyles.body,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final node in _fieldFocus.values) {
      node.dispose();
    }
    farmerNameController.dispose();
    contactPersonController.dispose();
    addressController.dispose();
    mobileController.dispose();
    alternateMobileController.dispose();
    emailController.dispose();
    villageController.dispose();
    currentProductUsedController.dispose();
    remarkController.dispose();

    final File? imageToDelete = _uploadedImage;
    _uploadedImage = null;

    if (imageToDelete != null) {
      _deleteTempFile(imageToDelete);
    }

    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(
        title: 'Farmer Registration Form',
        showBackButton: true,
        onBackTap: () => Navigator.pop(context),
      ),
      resizeToAvoidBottomInset: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<StateBloc, StatsState>(
        builder: (context, state) {
          //  CustomButton(
          //                       text: 'Update Password',
          //                       backgroundColor: context.primaryColor,
          //                       textColor: context.onPrimaryColor,
          //                       icon: Icon(Icons.check_rounded, size: 20.sp),
          //                       onPressed: _submitPasswordChange,
          //                     ),

          return Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: SizedBox(
              width: double.infinity,

              height: 48.h,
              child: CustomButton(
                text: 'Register Farmer',
                onPressed: _submit,
                isLoading: isLoading,

                backgroundColor: context.appPrimary,
                textColor: context.appOnPrimary,
              ),
            ),
          );
        },
      ),

      body: BlocConsumer<StateBloc, StatsState>(
        listener: (context, state) async {
          if (!isLoading || !_submissionSent) return;
          if (state.status == StatesStatus.farmerRegiSuccess) {
            setState(() {
              isLoading = false;
              _submissionSent = false;
            });

            // debugPrint('DAILY TRAN ID FROM STATE: ${state.dailyTranId}');

            final String strAllLocations = await _getStoredLocations();

            debugPrint('========================================');
            debugPrint('CALLING STORE TRACK LOCATION API');
            debugPrint('USER ID: $userId');

            debugPrint('STR ALL LOCATIONS: $strAllLocations');
            debugPrint('========================================');

            context.read<QuickAcessBloc>().add(
              StoreTrackLocation(userId.toString(), '', strAllLocations),
            );

            AppDialog.show(
              context: context,
              message: 'Farmer Added Successfully',
              onButtonPressed: () => context.push('/farmers'),
            );
            // AppDialog.show(
            //   context: context,
            //   message: 'Farmer Added Successfully',
            //   onButtonPressed: () {
            //     if (context.canPop()) {
            //       context.pop(true);
            //     } else {
            //       context.go(AppRouter.farmers);
            //     }
            //   },
            // );
            // AppDialog.show(
            //   context: context,
            //   message: 'Farmer Added Successfully',
            //   onButtonPressed: () => {context.go('/farmers')},
            // );
          }
          // ============================================
          // API ERROR
          // ============================================
          else if (state.status == StatesStatus.failed) {
            setState(() {
              isLoading = false;
              _submissionSent = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: context.appError,
                content: Text(
                  state.errorMessage ?? 'Submission failed',
                  style: AppTextStyles.body,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final productDetailData =
              state.farmerDetailsEntity?.productDetailsData ?? [];
          DistrictEntity? selectedDistrict;

          final cropList = state.farmerDetailsEntity?.cropDetailsData ?? [];

          final irrigationList =
              state.farmerDetailsEntity?.irrigationDetailsData ?? [];

          if (_selectedDistrictId != null && _selectedDistrictId != '0') {
            for (final district in state.districtList) {
              if (district.fldDistId == _selectedDistrictId) {
                selectedDistrict = district;
                break;
              }
            }
          }

          final talukaList = selectedDistrict?.taluka ?? [];

          final districtItems = [
            DropdownMenuItem<String>(
              value: '0',
              child: Text('Select District', style: AppTextStyles.inputHint),
            ),

            ...state.districtList
                .where((district) => district.fldDistId != '0')
                .map(
                  (district) => DropdownMenuItem<String>(
                    value: district.fldDistId,
                    child: Text(
                      district.fldDistName,
                      style: AppTextStyles.input,
                    ),
                  ),
                ),
          ];

          final talukaItems = [
            DropdownMenuItem<String>(
              value: '0',
              child: Text('Select Taluka', style: AppTextStyles.inputHint),
            ),

            ...talukaList
                .where((taluka) => taluka.fldTalukaId != '0')
                .map(
                  (taluka) => DropdownMenuItem<String>(
                    value: taluka.fldTalukaId,
                    child: Text(taluka.fldName, style: AppTextStyles.input),
                  ),
                ),
          ];

          final farmerStatusItems = farmerStatus.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status, style: AppTextStyles.input),
            );
          }).toList();

          return SafeArea(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,

              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    SizedBox(height: 10.h),
                    CustomTextFormField(
                      controller: farmerNameController,
                      fieldKey: _fieldKeys['name'],
                      focusNode: _fieldFocus['name'],
                      isValid: farmerNameController.text.trim().isNotEmpty,
                      hintText: 'Farmer Name *',
                      labelText: 'Farmer Name *',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter farmer name';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      controller: contactPersonController,
                      hintText: 'Contact Person Name',
                      labelText: 'Contact Person Name',
                      prefixIcon: Icons.person_outline,
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      controller: addressController,
                      fieldKey: _fieldKeys['address'],
                      focusNode: _fieldFocus['address'],
                      isValid: addressController.text.trim().isNotEmpty,
                      hintText: 'Address *',
                      labelText: 'Address',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter address';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      maxLength: 10,
                      controller: mobileController,
                      fieldKey: _fieldKeys['mobile'],
                      focusNode: _fieldFocus['mobile'],
                      isValid: RegExp(
                        r'^\d{10}$',
                      ).hasMatch(mobileController.text.trim()),
                      hintText: 'Mobile No *',
                      labelText: 'Mobile No *',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final mobileNumber = value?.trim() ?? '';

                        if (mobileNumber.isEmpty) {
                          return 'Please enter mobile number';
                        }

                        if (!RegExp(r'^\d{10}$').hasMatch(mobileNumber)) {
                          return 'Enter valid 10 digit mobile number';
                        }

                        return null;
                      },
                    ),

                    // SizedBox(height: 10.h),
                    CustomTextFormField(
                      maxLength: 10,
                      controller: alternateMobileController,
                      fieldKey: _fieldKeys['alternate'],
                      focusNode: _fieldFocus['alternate'],
                      isValid: false,
                      hintText: 'Alternate Mobile No',
                      labelText: 'Alternate Mobile No ',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final mobileNumber = value?.trim() ?? '';

                        if (mobileNumber.isEmpty) {
                          return null;
                        }

                        if (!RegExp(r'^\d{10}$').hasMatch(mobileNumber)) {
                          return 'Enter valid 10 digit mobile number';
                        }

                        return null;
                      },
                    ),

                    // SizedBox(height: 10.h),
                    CustomTextFormField(
                      controller: emailController,
                      fieldKey: _fieldKeys['email'],
                      focusNode: _fieldFocus['email'],
                      isValid: false,
                      hintText: 'Email ID',
                      labelText: 'Email ID',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }

                        final emailRegex = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );

                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Enter valid email address';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      controller: villageController,
                      hintText: 'Village',
                      labelText: 'Village',
                      prefixIcon: Icons.location_city_outlined,
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      'State *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.appOnCard,
                      ),
                    ),

                    SizedBox(height: 10.h),
                    CustomDropdown<String>(
                      value: _selectedStateId == '0' ? null : _selectedStateId,

                      hintText: 'Select State',
                      fieldKey: _fieldKeys['state'],
                      focusNode: _fieldFocus['state'],
                      isValid:
                          _selectedStateId != null && _selectedStateId != '0',

                      prefixIcon: Icons.map_outlined,

                      items: state.statentity.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.stateId,
                          child: Text(
                            item.stateName,
                            style: AppTextStyles.input,
                          ),
                        );
                      }).toList(),

                      onChanged: _onStateSelected,

                      validator: (value) {
                        if (value == null || value == '0') {
                          return 'Please select state';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      'District *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.appOnCard,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    CustomDropdown<String>(
                      value: _selectedDistrictId == '0'
                          ? null
                          : _selectedDistrictId,

                      hintText: 'Select District',
                      fieldKey: _fieldKeys['district'],
                      focusNode: _fieldFocus['district'],
                      isValid:
                          _selectedDistrictId != null &&
                          _selectedDistrictId != '0',

                      prefixIcon: Icons.location_city_outlined,

                      enabled:
                          _selectedStateId != null && _selectedStateId != '0',

                      items: districtItems,

                      onChanged: (value) {
                        _onDistrictSelected(value, state);
                      },

                      validator: (value) {
                        if (value == null || value == '0') {
                          return 'Please select district';
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),

                    Text(
                      'Taluka *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.appOnCard,
                      ),
                    ),

                    SizedBox(height: 10.h),
                    CustomDropdown<String>(
                      value: _selectedTalukaId == '0'
                          ? null
                          : _selectedTalukaId,

                      hintText: 'Select Taluka',
                      fieldKey: _fieldKeys['taluka'],
                      focusNode: _fieldFocus['taluka'],
                      isValid:
                          _selectedTalukaId != null && _selectedTalukaId != '0',

                      prefixIcon: Icons.location_on_outlined,

                      enabled:
                          _selectedDistrictId != null &&
                          _selectedDistrictId != '0' &&
                          talukaList.isNotEmpty,

                      items: talukaItems,

                      onChanged: (value) {
                        setState(() {
                          _selectedTalukaId = value ?? '0';
                        });

                        debugPrint('Selected Taluka ID: $_selectedTalukaId');
                      },

                      validator: (value) {
                        if (value == null || value == '0') {
                          return 'Please select taluka';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      'Person Category (Optional)',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.appOnCard,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    CustomDropdown<String>(
                      key: ValueKey(_personCategories),
                      value: _selectedPersonCategoryId,
                      hintText: 'Select Person Category',
                      prefixIcon: Icons.category_outlined,
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Select Person Category'),
                        ),
                        for (final category in _personCategories.entries)
                          DropdownMenuItem<String>(
                            value: category.key,
                            child: Text(
                              category.value,
                              style: AppTextStyles.input,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedPersonCategoryId = value ?? '');
                      },
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      'Status Of Farmer *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.appOnCard,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    CustomDropdown<String>(
                      value: _selectedFarmerStatus,

                      hintText: 'Farmer Status',
                      fieldKey: _fieldKeys['status'],
                      focusNode: _fieldFocus['status'],
                      isValid: _selectedFarmerStatus?.isNotEmpty == true,

                      prefixIcon: Icons.person_outline,

                      enabled: true,

                      items: farmerStatusItems,

                      onChanged: (value) {
                        setState(() {
                          _selectedFarmerStatus = value;
                        });

                        debugPrint(
                          'Selected Farmer Status: $_selectedFarmerStatus',
                        );
                      },

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select farmer status';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      'Suggested Product *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.appOnCard,
                      ),
                    ),

                    CustomTextFormField(
                      controller: TextEditingController(
                        text: _selectedProductIds.isEmpty
                            ? ''
                            : _selectedProductNames,
                      ),
                      hintText: 'Select Suggested Product',
                      fieldKey: _fieldKeys['products'],
                      focusNode: _fieldFocus['products'],
                      isValid: _selectedProductIds.isNotEmpty,
                      prefixIcon: Icons.inventory_2_outlined,
                      readOnly: true,
                      onTap: productDetailData.isEmpty
                          ? null
                          : () async {
                              final result = await showDialog<List<String>>(
                                context: context,
                                barrierDismissible: false,
                                builder: (dialogContext) {
                                  return ProductSelectionDialog(
                                    productList: productDetailData,
                                    selectedProductIds: _selectedProductIds,
                                  );
                                },
                              );

                              if (result != null && mounted) {
                                setState(() {
                                  _selectedProductIds
                                    ..clear()
                                    ..addAll(result);
                                });

                                debugPrint(
                                  'Selected Product IDs: '
                                  '${_selectedProductIds.join(',')}',
                                );

                                debugPrint(
                                  'Selected Product IDs List: '
                                  '$_selectedProductIds',
                                );
                              }
                            },
                      validator: (value) {
                        if (_selectedProductIds.isEmpty) {
                          return 'Please select a suggested product';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      'Crop Details *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.appOnCard,
                      ),
                    ),

                    const SizedBox(height: 8),

                    CustomTextFormField(
                      controller: TextEditingController(
                        text: _selectedCropDetails.isEmpty
                            ? ''
                            : _selectedCropDetails
                                  .map((item) => item.cropName)
                                  .join(', '),
                      ),
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

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      controller: currentProductUsedController,
                      hintText: 'Current Product Used',
                      labelText: 'Current Product Used',
                      prefixIcon: Icons.note,
                      maxLines: 2,
                    ),

                    SizedBox(height: 10.h),

                    // Upload photo
                    FormField<bool>(
                      key: _fieldKeys['photo'],
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
                            if (field.hasError)
                              Padding(
                                padding: EdgeInsets.only(left: 16.w, top: 4.h),
                                child: Text(
                                  field.errorText!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.appError,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                    CustomTextFormField(
                      controller: remarkController,
                      hintText: 'Remark',
                      prefixIcon: Icons.note,
                      maxLines: 2,
                    ),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      //  BlocBuilder<StateBloc, StatsState>(
      //   builder: (context, state) {
      //   final productDetailData =
      //       state.farmerDetailsEntity?.productDetailsData ?? [];
      //   DistrictEntity? selectedDistrict;

      //   final cropList = state.farmerDetailsEntity?.cropDetailsData ?? [];

      //   final irrigationList =
      //       state.farmerDetailsEntity?.irrigationDetailsData ?? [];

      //   if (_selectedDistrictId != null && _selectedDistrictId != '0') {
      //     for (final district in state.districtList) {
      //       if (district.fldDistId == _selectedDistrictId) {
      //         selectedDistrict = district;
      //         break;
      //       }
      //     }
      //   }

      //   final talukaList = selectedDistrict?.taluka ?? [];

      //   final districtItems = [
      //     const DropdownMenuItem<String>(
      //       value: '0',
      //       child: Text('Select District'),
      //     ),

      //     ...state.districtList
      //         .where((district) => district.fldDistId != '0')
      //         .map(
      //           (district) => DropdownMenuItem<String>(
      //             value: district.fldDistId,
      //             child: Text(district.fldDistName),
      //           ),
      //         ),
      //   ];

      //   final talukaItems = [
      //     const DropdownMenuItem<String>(
      //       value: '0',
      //       child: Text('Select Taluka'),
      //     ),

      //     ...talukaList
      //         .where((taluka) => taluka.fldTalukaId != '0')
      //         .map(
      //           (taluka) => DropdownMenuItem<String>(
      //             value: taluka.fldTalukaId,
      //             child: Text(taluka.fldName),
      //           ),
      //         ),
      //   ];

      //   final farmerStatusItems = farmerStatus.map((status) {
      //     return DropdownMenuItem<String>(value: status, child: Text(status));
      //   }).toList();

      // },
      // ),
    );
  }

  Widget _uploadPhotoCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _uploadedImage != null
              ? context.appPrimary
              : context.appBorder,
        ),
      ),
      child: Column(
        children: [
          // Upload header
          InkWell(
            focusNode: _fieldFocus['photo'],
            onTap: _captureImage,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.h,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        context.appPrimary.withValues(alpha: 0.1),
                        context.appCard,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: context.appPrimary,
                      size: 22.sp,
                    ),
                  ),

                  SizedBox(width: 14.w),

                  Expanded(
                    child: Text(
                      'Upload Photo *',
                      style: AppTextStyles.cardTitle,
                    ),
                  ),

                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.appSubText,
                    size: 28.sp,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          InkWell(
            onTap: _captureImage,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              height: 260.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.appInputBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _uploadedImage != null
                      ? context.appPrimary
                      : context.appBorder,
                ),
              ),
              child: _uploadedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 52.sp,
                          color: context.appSubText,
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          'Tap to capture image',
                          style: AppTextStyles.body.copyWith(
                            color: context.appSubText,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // ============================
                        // CAPTURED IMAGE
                        // ============================
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.file(
                            _uploadedImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        // ============================
                        // RETAKE BUTTON
                        // ============================
                        Positioned(
                          top: 12.h,
                          left: 12.w,
                          child: Material(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(10.r),
                            child: InkWell(
                              onTap: _captureImage,
                              borderRadius: BorderRadius.circular(10.r),
                              child: Padding(
                                padding: EdgeInsets.all(9.r),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 22.sp,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ============================
                        // DELETE BUTTON
                        // ============================
                        Positioned(
                          top: 12.h,
                          right: 12.w,
                          child: Material(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(10.r),
                            child: InkWell(
                              onTap: _removeUploadedImage,
                              borderRadius: BorderRadius.circular(10.r),
                              child: Padding(
                                padding: EdgeInsets.all(9.r),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 22.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
