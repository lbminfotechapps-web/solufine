import 'dealer_additional_information_dialog.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'dart:convert';
import 'dart:io';

import 'package:solufine/core/di/auth_di.dart';
import 'package:solufine/core/location_tracking/app_database.dart';
import 'package:solufine/core/location_tracking/location_repository.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/cameracapturepage.dart';
import 'package:solufine/core/utility/data_list.dart';
import 'package:solufine/core/utility/device_info_util.dart';
import 'package:solufine/core/utility/location_util.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_button.dart';
import 'package:solufine/core/utility/widgets/custom_dropdown.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';
import 'package:solufine/features/dealer_visit/presentation/bloc/add_dealer_visit_bloc.dart';
import 'package:solufine/features/dealer_visit/presentation/bloc/add_dealer_visit_event.dart';
import 'package:solufine/features/dealer_visit/presentation/bloc/add_dealer_visit_state.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/district_entity.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/state_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';

class DealerFollowupAdd extends StatefulWidget {
  const DealerFollowupAdd({super.key});

  @override
  State<DealerFollowupAdd> createState() => _DealerFollowupAddState();
}

class _DealerFollowupAddState extends State<DealerFollowupAdd> {
  DealerAdditionalInformation? _additionalInformation;

  Future<void> _openAdditionalInformation() async {
    FocusScope.of(context).unfocus();
    final result = await showDialog<DealerAdditionalInformation>(
      context: context,
      builder: (_) => DealerAdditionalInformationDialog(
        initialValue: _additionalInformation,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _additionalInformation = result);
  }

  final TextEditingController shopNameController = TextEditingController();

  final TextEditingController dealerCodeController = TextEditingController();

  final TextEditingController ownerNameController = TextEditingController();

  final TextEditingController mobileController = TextEditingController();

  final TextEditingController alternateMobileController =
      TextEditingController();

  final TextEditingController gstController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  String? _selectedStateId = '0';
  String? _selectedDistrictId = '0';
  String? _selectedTalukaId = '0';
  String? userId;
  @override
  void initState() {
    super.initState();
    _loadStates();
    getGeoAddress();
  }

  bool _submitted = false;
  bool _submissionCompleted = false;

  void _focusFirstInvalidField() {
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
              alignment: 0.2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
        break;
      }
    }
  }

  void _submit() async {
    if (isLoading || _submissionCompleted) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      _focusFirstInvalidField();
      return;
    }

    FocusScope.of(context).unfocus();

    if (_selectedStateId == null || _selectedStateId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select state', style: AppTextStyles.body),
        ),
      );
      return;
    }

    if (_selectedDistrictId == null || _selectedDistrictId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select district', style: AppTextStyles.body),
        ),
      );
      return;
    }

    if (_selectedTalukaId == null || _selectedTalukaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select taluka', style: AppTextStyles.body),
        ),
      );
      return;
    }
    // Lock before device/location lookups yield to another tap.
    setState(() {
      isLoading = true;
      _submissionSent = false;
    });

    try {
      final batteryInfo = await DeviceInfoUtil.instance.getBatteryInfo();

      final networkInfo = await DeviceInfoUtil.instance.getNetworkInfo();

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

      debugPrint('================================');
      debugPrint('FARMER REGISTRATION - ALL PARAMS');
      debugPrint('================================');

      debugPrint('FARMER LATTTT - $latitude');
      debugPrint('FARMER LONG - $longitude');
      debugPrint('================================');

      debugPrint('fld_address: ${addressController.text.trim()}');

      debugPrint('fld_category_id: ');
      debugPrint('state: ${_selectedStateId ?? '0'}');
      debugPrint('fld_demo_type_id: ');
      debugPrint('district: ${_selectedDistrictId ?? '0'}');
      debugPrint('taluka: ${_selectedTalukaId ?? '0'}');

      debugPrint('campaign_radio: Yes');

      // Mobile / contact
      debugPrint('fld_mobile_no: ${mobileController.text.trim()}');
      debugPrint('fld_mobile_no2: ${alternateMobileController.text.trim()}');
      debugPrint('fld_email_id: ${emailController.text.trim()}');

      debugPrint('geoAddress: $address');
      debugPrint('meetingLocation: ');
      debugPrint('marketNearby: ');

      // Other farmer details
      debugPrint('fld_tractor_mode: ');

      debugPrint('aadhaarNo: ');
      debugPrint('remark: ${remarkController.text.trim()}');

      debugPrint('selectedCattleId: ');
      debugPrint('selectedCattleCount: ');

      // Crop details
      debugPrint('--------------------------------');
      debugPrint('SELECTED CROP DETAILS');
      debugPrint('--------------------------------');

      // Location
      debugPrint('--------------------------------');
      debugPrint('LOCATION');
      debugPrint('--------------------------------');

      debugPrint('latitude: $latitude');
      debugPrint('longitude: $longitude');

      debugPrint('networkLatitude: $latitude');
      debugPrint('networkLongitude: $longitude');

      debugPrint('gpsLatitude: $latitude');
      debugPrint('gpsLongitude: $longitude');

      debugPrint('differenceByAndroid: 0.0');

      // Device information
      debugPrint('--------------------------------');
      debugPrint('DEVICE INFORMATION');
      debugPrint('--------------------------------');

      debugPrint('strNetworkInfo: $networkInfo');
      debugPrint('strBatteryInfo: $batteryInfo');

      // Activity
      debugPrint('activityId: 2');

      // Image
      debugPrint('--------------------------------');
      debugPrint('IMAGE');
      debugPrint('--------------------------------');

      debugPrint(
        'selfie_capture_image: '
        '${_uploadedImage?.path ?? 'No image selected'}',
      );

      debugPrint('================================');
      debugPrint('END FARMER REGISTRATION PARAMS');
      debugPrint('================================');

      debugPrint('================================');

      final userData = await SecureStorage.instance.getUserData();

      final userId = int.tryParse(userData?['user_id']?.toString() ?? '');

      debugPrint('User ID: $userId');

      if (!mounted) return;
      context.read<AddDealerVisitBlock>().add(
        AddDealerFollowUpEvent(
          userId: userId.toString(),
          type: 'Dealer',
          outletName: shopNameController.text.trim(),
          contactPerson: ownerNameController.text.trim(),
          gstNo: gstController.text.trim().toUpperCase(),
          mobileNo: mobileController.text.trim(),
          mobileNo2: alternateMobileController.text.trim(),
          emailId: emailController.text.trim(),
          address: addressController.text.trim(),
          state: _selectedStateId.toString(),
          district: _selectedDistrictId.toString(),
          taluka: _selectedTalukaId.toString(),
          remark: remarkController.text.trim(),
          city: '',
          latitude: latitude,
          longitude: longitude,
          networkLatitude: latitude,
          networkLongitude: longitude,
          gpsLatitude: latitude,
          gpsLongitude: longitude,
          geoAddress: address,
          differenceByAndroid: '0.0',
          mobileInfo: '',
          mobileImei: '',
          followUpDate: dateController.text.trim(),
          followUpType: _selectedFollowUpType.toString(),
          strNetworkInfo: '',
          strBatteryInfo: batteryInfo,
          registrationType: _selectedDealerType.toString(),
          flag: '1',
          dealerCode: _selectedDealerType == 'EXISTING'
              ? dealerCodeController.text.trim()
              : '',
          activityId: '1',
          selfieCaptureImage: _uploadedImage?.path ?? '',
        ),
      );
      _submissionSent = true;

      debugPrint('================================');
      debugPrint('FARMER SUBMIT EVENT SENT');
      debugPrint('================================');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        _submissionSent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), style: AppTextStyles.body)),
      );
    }
  }

  String latitude = '';
  String longitude = '';
  String address = '';

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
  void dispose() {
    for (final node in _fieldFocus.values) {
      node.dispose();
    }
    shopNameController.dispose();
    dealerCodeController.dispose();
    ownerNameController.dispose();
    mobileController.dispose();
    alternateMobileController.dispose();
    gstController.dispose();
    emailController.dispose();
    addressController.dispose();
    dateController.dispose();
    remarkController.dispose();
    super.dispose();
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

  Future<void> _loadStates() async {
    await getUserId();
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

    context.read<AddDealerVisitBlock>().add(
      StateListEvent(userId: userId.toString()),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;

    setState(() {
      dateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);
    });
  }

  String? _selectedDealerType;
  String? _selectedFollowUpType;

  Future<void> _captureImage() async {
    try {
      debugPrint('================================');
      debugPrint('OPENING INTERNAL CAMERA');

      final String? capturedImagePath = await Navigator.of(context)
          .push<String>(
            MaterialPageRoute(builder: (_) => const CameraCapturePage()),
          );

      // Camera cancelled
      if (capturedImagePath == null || capturedImagePath.trim().isEmpty) {
        debugPrint('CAMERA CANCELLED');
        return;
      }

      final File newFile = File(capturedImagePath);

      // Check file
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
      // OLD IMAGE
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
      // DELETE PREVIOUS CAMERA IMAGE
      // ============================================

      if (oldImage != null && oldImage.path != capturedImagePath) {
        try {
          if (await oldImage.exists()) {
            final String oldPath = oldImage.path;

            await oldImage.delete();

            debugPrint('OLD CAMERA IMAGE DELETED: $oldPath');
          }
        } catch (e) {
          debugPrint('OLD IMAGE DELETE ERROR: $e');
        }
      }

      debugPrint('CURRENT IMAGE: ${_uploadedImage?.path}');
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

  File? _uploadedImage;
  bool _submissionSent = false;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  static const _fieldOrder = [
    'dealerType',
    'shop',
    'mobile',
    'alternate',
    'gst',
    'email',
    'address',
    'state',
    'district',
    'taluka',
    'date',
    'followUpType',
    'photo',
  ];
  final _fieldKeys = {
    for (final name in _fieldOrder) name: GlobalKey<FormFieldState>(),
  };
  final _fieldFocus = {for (final name in _fieldOrder) name: FocusNode()};

  void _onDistrictSelected(String? districtId, AddDealerVisitState state) {
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

  void _onStateSelected(String? stateId, AddDealerVisitState state) async {
    if (stateId == null || stateId.isEmpty) {
      return;
    }

    debugPrint('================================');
    debugPrint('STATE SELECTED');
    debugPrint('New State ID: $stateId');
    debugPrint('================================');

    if (stateId == '0') {
      setState(() {
        _selectedStateId = '0';
        _selectedDistrictId = '0';
        _selectedTalukaId = '0';
      });

      return;
    }

    setState(() {
      _selectedStateId = stateId;

      _selectedDistrictId = '0';
      _selectedTalukaId = '0';
    });

    final userData = await SecureStorage.instance.getUserData();

    final int? userId = int.tryParse(userData?['user_id']?.toString() ?? '');

    if (userId == null) {
      debugPrint('Invalid user ID');
      return;
    }

    if (!mounted) return;
    // Load districts for NEW state
    context.read<AddDealerVisitBlock>().add(
      DistrictEvent(userId: userId.toString(), stateId: stateId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: CustomAppBar(
        title: 'Dealer Registration Form',
        showBackButton: true,
        onBackTap: () => Navigator.pop(context),
      ),
      resizeToAvoidBottomInset: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          BlocBuilder<AddDealerVisitBlock, AddDealerVisitState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: CustomButton(
                  text: 'Register Dealer',
                  onPressed: isLoading || _submissionCompleted ? null : _submit,
                  isLoading: isLoading,

                  backgroundColor: context.primaryColor,
                  textColor: context.onPrimaryColor,
                ),
              );
            },
          ),
      body: BlocConsumer<AddDealerVisitBlock, AddDealerVisitState>(
        listener: (context, state) async {
          if (!isLoading || !_submissionSent) return;
          if (state.addLeaveStatus == AddDealerVisitStatus.dealerAddedSuccess) {
            _clearCapturedImage();
            setState(() {
              _submissionCompleted = true;
              isLoading = false;
              _submissionSent = false;
            });

            final String strAllLocations = await _getStoredLocations();
            if (!mounted || !context.mounted) return;

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
              message: state.errorMessage ?? 'Dealer Added Successfully',
              onButtonPressed: () => context.push('/farmers'),
            );
          }
          // ============================================
          // API ERROR
          // ============================================
          else if (state.addLeaveStatus == AddDealerVisitStatus.failure) {
            setState(() {
              isLoading = false;
              _submissionSent = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: context.appColors.error,
                content: Text(
                  state.errorMessage ?? 'Submission failed',
                  style: AppTextStyles.body.copyWith(
                    color: context.appColors.onError,
                  ),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          DistrictEntity? selectedDistrict;

          if (_selectedDistrictId != null && _selectedDistrictId != '0') {
            for (final district in state.districtList) {
              if (district.fldDistId == _selectedDistrictId) {
                selectedDistrict = district;
                break;
              }
            }
          }
          final uniqueStates = <String, StateEntity>{};

          for (final item in state.statentity) {
            final id = item.stateId.trim();

            if (id.isEmpty) {
              continue;
            }

            if (!uniqueStates.containsKey(id)) {
              uniqueStates[id] = item;
            }
          }

          final stateItems = uniqueStates.values
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.stateId.trim(),
                  child: Text(item.stateName, style: AppTextStyles.input),
                ),
              )
              .toList();
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
          final dealerTypeItems = dealerTypeStatus.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status, style: AppTextStyles.input),
            );
          }).toList();

          final followUpTypeItem = followUpType.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status, style: AppTextStyles.input),
            );
          }).toList();
          return SafeArea(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,

              // autovalidateMode: _submitted
              //     ? AutovalidateMode.always
              //     : AutovalidateMode.disabled,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    SizedBox(height: 10.h),

                    Text(
                      'Dealer Type *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    CustomDropdown<String>(
                      value: _selectedDealerType,

                      hintText: 'Select Dealer Type',
                      fieldKey: _fieldKeys['dealerType'],
                      focusNode: _fieldFocus['dealerType'],

                      prefixIcon: Icons.person_outline,

                      enabled: true,

                      items: dealerTypeItems,

                      onChanged: (value) {
                        setState(() {
                          _selectedDealerType = value;
                          if (value != 'EXISTING') {
                            dealerCodeController.clear();
                          }
                        });

                        debugPrint(
                          'Selected Farmer Status: $_selectedDealerType',
                        );
                      },

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select Dealer type';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),
                    CustomTextFormField(
                      controller: shopNameController,
                      hintText: 'Shop Name *',
                      fieldKey: _fieldKeys['shop'],
                      focusNode: _fieldFocus['shop'],
                      labelText: 'Shop Name *',
                      prefixIcon: Icons.shop,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter Shop name';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    if (_selectedDealerType == 'EXISTING') ...[
                      CustomTextFormField(
                        controller: dealerCodeController,
                        hintText: 'Dealer Code',
                        labelText: 'Dealer Code',
                        prefixIcon: Icons.person_outline,
                      ),
                      SizedBox(height: 10.h),
                    ],

                    CustomTextFormField(
                      controller: ownerNameController,
                      hintText: 'Owner Name',
                      labelText: 'Owner Name',
                      prefixIcon: Icons.person_2_outlined,
                      maxLines: 1,
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      maxLength: 10,
                      controller: mobileController,
                      hintText: 'Mobile No *',
                      fieldKey: _fieldKeys['mobile'],
                      focusNode: _fieldFocus['mobile'],
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

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      maxLength: 10,
                      controller: alternateMobileController,
                      hintText: 'Alternate Mobile No',
                      fieldKey: _fieldKeys['alternate'],
                      focusNode: _fieldFocus['alternate'],
                      labelText: 'Alternate Mobile No',
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

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      controller: gstController,
                      hintText: 'GST No',
                      fieldKey: _fieldKeys['gst'],
                      focusNode: _fieldFocus['gst'],
                      labelText: 'GST No',
                      prefixIcon: Icons.receipt_long_outlined,
                      keyboardType: TextInputType.text,
                      maxLength: 15,
                      validator: (value) {
                        final gst = value?.trim().toUpperCase() ?? '';
                        if (gst.isEmpty) return null;
                        if (!RegExp(
                          r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
                        ).hasMatch(gst)) {
                          return 'Enter a valid 15-character GST number';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      controller: emailController,
                      hintText: 'Email Id',
                      fieldKey: _fieldKeys['email'],
                      focusNode: _fieldFocus['email'],
                      labelText: 'Email Id',
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
                      controller: addressController,
                      hintText: 'Address *',
                      fieldKey: _fieldKeys['address'],
                      focusNode: _fieldFocus['address'],
                      labelText: 'Address',
                      prefixIcon: Icons.home_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter address';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      'State *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),

                    SizedBox(height: 10.h),
                    CustomDropdown<String>(
                      value: _selectedStateId == '0' ? null : _selectedStateId,

                      hintText: 'Select State',
                      fieldKey: _fieldKeys['state'],
                      focusNode: _fieldFocus['state'],

                      prefixIcon: Icons.map_outlined,

                      compactItems: true,
                      items: stateItems,

                      onChanged: (value) {
                        _onStateSelected(value, state);
                      },

                      validator: (value) {
                        if (value == null || value == '0') {
                          return 'Please select state';
                        }

                        return null;
                      },
                    ),

                    // CustomDropdown<String>(
                    //   value: _selectedStateId == '0' ? null : _selectedStateId,

                    //   hintText: 'Select State',

                    //   prefixIcon: Icons.map_outlined,

                    //   items: state.statentity.map((item) {
                    //     return DropdownMenuItem<String>(
                    //       value: item.stateId,
                    //       child: Text(item.stateName),
                    //     );
                    //   }).toList(),

                    //   onChanged: _onStateSelected,

                    //   validator: (value) {
                    //     if (value == null || value == '0') {
                    //       return 'Please select state';
                    //     }

                    //     return null;
                    //   },
                    // ),
                    SizedBox(height: 10.h),

                    Text(
                      'District *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.primaryTextColor,
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
                      prefixIcon: Icons.location_city_outlined,
                      enabled:
                          _selectedStateId != null && _selectedStateId != '0',
                      compactItems: true,
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
                        color: context.primaryTextColor,
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
                      prefixIcon: Icons.location_on_outlined,
                      enabled:
                          _selectedDistrictId != null &&
                          _selectedDistrictId != '0' &&
                          talukaList.isNotEmpty,
                      compactItems: true,
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

                    _textField(
                      controller: dateController,
                      hintText: 'Next Followup Date *',
                      fieldKey: _fieldKeys['date'],
                      focusNode: _fieldFocus['date'],
                      icon: Icons.calendar_today_outlined,
                      readOnly: true,
                      // suffixIcon: Icons.calendar_month_outlined,
                      onSuffixIconTap: _pickDate,
                      onTap: _pickDate,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please select date';
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),

                    Text(
                      'Follow Up Type *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    CustomDropdown<String>(
                      value: _selectedFollowUpType,
                      hintText: 'Follow Up Type',
                      fieldKey: _fieldKeys['followUpType'],
                      focusNode: _fieldFocus['followUpType'],
                      prefixIcon: Icons.event_note_outlined,
                      enabled: true,
                      items: followUpTypeItem,
                      onChanged: (value) {
                        setState(() {
                          _selectedFollowUpType = value;
                        });

                        debugPrint(
                          'Selected Follow Up Type: $_selectedFollowUpType',
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select follow up type';
                        }

                        return null;
                      },
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
                                    color: context.appColors.error,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 10.h),

                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _openAdditionalInformation,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Additional information'),
                    ),
                    if (_additionalInformation != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Text(
                          'Classification: ${_additionalInformation!.classification} | '
                          'Sales potential: ${_additionalInformation!.salesPotential.length} products',
                          style: AppTextStyles.body,
                        ),
                      ),
                    SizedBox(height: 10.h),
                    CustomTextFormField(
                      controller: remarkController,
                      hintText: 'Remark',
                      labelText: "Remark",
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
    );
  }

  Widget _textField({
    GlobalKey<FormFieldState>? fieldKey,
    FocusNode? focusNode,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
  }) {
    return CustomTextFormField(
      fieldKey: fieldKey,
      focusNode: focusNode,
      controller: controller,
      hintText: hintText,
      prefixIcon: icon,
      maxLines: maxLines,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      suffixIcon: suffixIcon,
      onSuffixIconTap: onSuffixIconTap,
      validator: validator,
    );
  }

  Widget _uploadPhotoCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.borderColor),
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
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: context.primaryColor,
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
                    color: context.secondaryTextColor,
                    size: 28.sp,
                  ),
                ],
              ),
            ),
          ),

          // Image capture area
          InkWell(
            onTap: _captureImage,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              height: 200.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.appTheme.inputBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.borderColor),
              ),
              child: _uploadedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 52.sp,
                          color: context.secondaryTextColor,
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          'Tap to capture image',
                          style: AppTextStyles.body.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // Captured image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.file(
                            _uploadedImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        // Delete button
                        Positioned(
                          top: 10.h,
                          right: 10.w,
                          child: GestureDetector(
                            onTap: () async {
                              await _deleteCurrentImage();
                            },
                            child: Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: context.appColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: context.appColors.onError,
                                size: 22.sp,
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

  Future<void> _deleteCurrentImage() async {
    final File? image = _uploadedImage;

    if (image == null) return;

    try {
      if (await image.exists()) {
        final String path = image.path;

        await image.delete();

        debugPrint('TEMP IMAGE DELETED: $path');
      }
    } catch (e) {
      debugPrint('TEMP IMAGE DELETE ERROR: $e');
    }

    if (mounted) {
      setState(() {
        _uploadedImage = null;
      });
    }
  }

  Future<void> _clearCapturedImage() async {
    final File? image = _uploadedImage;

    if (image == null) {
      return;
    }

    try {
      if (await image.exists()) {
        final String path = image.path;

        await image.delete();

        debugPrint('TEMP IMAGE DELETED AFTER SUCCESS: $path');
      }
    } catch (e) {
      debugPrint('TEMP IMAGE DELETE ERROR: $e');
    }

    if (!mounted) return;

    setState(() {
      _uploadedImage = null;
    });
  }
}
