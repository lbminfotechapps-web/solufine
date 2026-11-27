import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'dart:io';

import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/app_image_picker.dart';
import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/data_list.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart'
    show CustomAppBar;
import 'package:solufine/core/utility/widgets/custom_button.dart';
import 'package:solufine/core/utility/widgets/custom_dropdown.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';
import 'package:solufine/features/dealer/data/models/DealerListModel.dart';
import 'package:solufine/features/dealer_visit/presentation/bloc/add_dealer_visit_bloc.dart';
import 'package:solufine/features/dealer_visit/presentation/bloc/add_dealer_visit_event.dart';
import 'package:solufine/features/dealer_visit/presentation/bloc/add_dealer_visit_state.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/district_entity.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/state_entity.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/taluka_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EditUpdateDealer extends StatefulWidget {
  final DealerListModel? dealerData;
  const EditUpdateDealer(this.dealerData, {super.key});

  @override
  State<EditUpdateDealer> createState() => _EditUpdateDealerState();
}

class _EditUpdateDealerState extends State<EditUpdateDealer> {
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
  String? _selectedDealerStatus;
  String? _selectedFollowUpStatus;
  @override
  void initState() {
    super.initState();
    // _loadStates();
    if (widget.dealerData != null) {
      setData();
    }
    loadApiData();
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

  void _submit() async {
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

    // ============================================
    // VALIDATE STATE
    // ============================================
    if (_selectedStateId == null ||
        _selectedStateId!.isEmpty ||
        _selectedStateId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select state', style: AppTextStyles.body),
        ),
      );
      return;
    }

    // ============================================
    // VALIDATE DISTRICT
    // ============================================
    if (_selectedDistrictId == null ||
        _selectedDistrictId!.isEmpty ||
        _selectedDistrictId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select district', style: AppTextStyles.body),
        ),
      );
      return;
    }

    // ============================================
    // VALIDATE TALUKA
    // ============================================
    if (_selectedTalukaId == null ||
        _selectedTalukaId!.isEmpty ||
        _selectedTalukaId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select taluka', style: AppTextStyles.body),
        ),
      );
      return;
    }

    // ============================================
    // GET USER DATA
    // ============================================
    final userData = await SecureStorage.instance.getUserData();

    final userId = int.tryParse(userData?['user_id']?.toString() ?? '');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid user ID', style: AppTextStyles.body)),
      );
      return;
    }

    // ============================================
    // OUTLET ID
    // ============================================
    final outletId = widget.dealerData?.outletId.toString() ?? '';

    if (outletId.isEmpty || outletId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid dealer ID', style: AppTextStyles.body)),
      );
      return;
    }

    // ============================================
    // UPDATE DEALER DEBUG
    // ============================================
    debugPrint('========================================');
    debugPrint('UPDATE DEALER - ALL PARAMS');
    debugPrint('========================================');

    debugPrint('outlet_id: $outletId');
    debugPrint('user_id: $userId');
    debugPrint('type: Dealer');

    debugPrint('outlet_name: ${shopNameController.text.trim()}');

    debugPrint('contact_person: ${ownerNameController.text.trim()}');

    debugPrint('gst_no: ${gstController.text.trim()}');

    debugPrint('mobile_no: ${mobileController.text.trim()}');

    debugPrint('mobile_no2: ${alternateMobileController.text.trim()}');

    debugPrint('email_id: ${emailController.text.trim()}');

    debugPrint('address: ${addressController.text.trim()}');

    debugPrint('state: ${_selectedStateId ?? '0'}');

    debugPrint('district: ${_selectedDistrictId ?? '0'}');

    debugPrint('taluka: ${_selectedTalukaId ?? '0'}');

    debugPrint('remark: ${remarkController.text.trim()}');

    debugPrint('city: ');

    // Kotlin update explicitly sends empty values
    debugPrint('latitude: ');
    debugPrint('longitude: ');

    debugPrint('dealerCode: ${dealerCodeController.text.trim()}');

    debugPrint('activityId: 1');

    debugPrint('followUpType: $followUpType');

    debugPrint('registrationType: $_selectedDealerStatus');

    debugPrint('========================================');
    debugPrint('END UPDATE DEALER PARAMS');
    debugPrint('========================================');

    // ============================================
    // START LOADING
    // ============================================
    if (!mounted) return;

    setState(() {
      isLoading = true;
      _submissionSent = false;
    });

    // ============================================
    // SEND UPDATE EVENT
    // ============================================
    try {
      context.read<AddDealerVisitBlock>().add(
        UpdateDealerEvent(
          outletId: outletId,

          userId: userId.toString(),
          type: 'Dealer',

          outletName: shopNameController.text.trim(),

          contactPerson: ownerNameController.text.trim(),

          gstNo: gstController.text.trim(),

          mobileNo: mobileController.text.trim(),

          mobileNo2: alternateMobileController.text.trim(),

          emailId: emailController.text.trim(),

          address: addressController.text.trim(),

          state: _selectedStateId.toString(),

          district: _selectedDistrictId.toString(),

          taluka: _selectedTalukaId.toString(),

          remark: remarkController.text.trim(),

          city: '',

          // Kotlin update API sends empty location
          latitude: '',
          longitude: '',

          dealerCode: dealerCodeController.text.trim(),

          activityId: '1',

          followUpType: _selectedFollowUpStatus.toString(),

          registrationType: _selectedDealerStatus.toString(),
        ),
      );

      _submissionSent = true;

      debugPrint('================================');
      debugPrint('UPDATE DEALER EVENT SENT');
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

  void loadApiData() async {
    final userData = await SecureStorage.instance.getUserData();

    final userId = userData?['user_id'];
    context.read<AddDealerVisitBlock>().add(
      StateListEvent(userId: userId.toString()),
    );
    if (_selectedStateId != null && _selectedStateId != '0') {
      context.read<AddDealerVisitBlock>().add(
        DistrictEvent(userId: userId.toString(), stateId: _selectedStateId!),
      );
    }
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

    // Load districts for NEW state
    context.read<AddDealerVisitBlock>().add(
      DistrictEvent(userId: userId.toString(), stateId: stateId),
    );
  }

  // void _onStateSelected(String? stateId, AddDealerVisitState state) async {
  //   if (stateId == null || stateId.isEmpty) {
  //     return;
  //   }

  //   debugPrint('================================');
  //   debugPrint('STATE SELECTED');
  //   debugPrint('New State ID: $stateId');
  //   debugPrint('================================');

  //   if (stateId == '0') {
  //     setState(() {
  //       _selectedStateId = '0';
  //       _selectedDistrictId = '0';
  //       _selectedTalukaId = '0';
  //     });

  //     return;
  //   }

  //   setState(() {
  //     _selectedStateId = stateId;

  //     _selectedDistrictId = '0';
  //     _selectedTalukaId = '0';
  //   });

  //   final userData = await SecureStorage.instance.getUserData();

  //   final int? userId = int.tryParse(userData?['user_id']?.toString() ?? '');

  //   if (userId == null) {
  //     debugPrint('Invalid user ID');
  //     return;
  //   }

  //   // Load districts for NEW state
  //   context.read<AddDealerVisitBlock>().add(
  //     DistrictEvent(userId: userId.toString(), stateId: stateId),
  //   );
  // }

  // Future<void> getUserId() async {
  //   final userData = await SecureStorage.instance.getUserData();

  //   final userId = userData?['user_id']?.toString();

  //   if (!mounted || userId == null || userId.isEmpty) {
  //     return;
  //   }

  //   debugPrint('USER ID: $userId');

  //   context.read<AddDealerVisitBlock>().add(StateListEvent(userId: userId));
  // }

  void setData() {
    if (widget.dealerData == null) return;
    shopNameController.text = widget.dealerData!.outletName.toString();
    dealerCodeController.text = widget.dealerData!.code.toString();
    ownerNameController.text = widget.dealerData!.outletPerson.toString();
    addressController.text = widget.dealerData!.outletAddress.toString();
    mobileController.text = widget.dealerData!.outletPersonMobile.toString();

    alternateMobileController.text = widget.dealerData!.outletMobile.toString();
    emailController.text = widget.dealerData!.outletPersonEmail.toString();
    gstController.text = widget.dealerData!.gstNo.toString();
    remarkController.text = widget.dealerData!.remark.toString();
    dateController.text = _dateOnly(widget.dealerData!.lastVisitDateTime);

    final existingDealerStatus = widget.dealerData!.outletType?.trim();

    if (existingDealerStatus == null || existingDealerStatus.isEmpty) {
      _selectedDealerStatus = dealerTypeStatus.first;
    } else {
      _selectedDealerStatus = dealerTypeStatus.firstWhere(
        (status) => status.toLowerCase() == existingDealerStatus.toLowerCase(),
        orElse: () => dealerTypeStatus.first,
      );
    }

    final existingFollowUpStatus = widget.dealerData!.followupType?.trim();

    if (existingFollowUpStatus == null || existingFollowUpStatus.isEmpty) {
      _selectedFollowUpStatus = followUpType.first;
    } else {
      _selectedFollowUpStatus = followUpType.firstWhere(
        (status) =>
            status.toLowerCase() == existingFollowUpStatus.toLowerCase(),
        orElse: () => followUpType.first,
      );
    }

    _selectedStateId = _normalizeLocationId(widget.dealerData!.outletState);
    _selectedDistrictId = _normalizeLocationId(
      widget.dealerData!.outletDistrict,
    );
    _selectedTalukaId = _normalizeLocationId(widget.dealerData!.outletTaluka);
  }

  String _normalizeLocationId(String? value) {
    final id = value?.trim() ?? '';
    return id.isEmpty ? '0' : id;
  }

  String _dateOnly(String? value) {
    final rawValue = value?.trim() ?? '';
    if (rawValue.isEmpty) return '';

    for (final format in [
      DateFormat('dd-MM-yyyy hh:mm a'),
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm'),
      DateFormat('yyyy-MM-dd'),
    ]) {
      try {
        return DateFormat('dd-MM-yyyy').format(format.parseStrict(rawValue));
      } catch (_) {}
    }

    return rawValue.split(' ').first;
  }

  void _mapSelectedState(AddDealerVisitState state) {
    if (_selectedStateId == null || _selectedStateId == '0') {
      return;
    }

    final selectedStateId = _normalizeLocationId(_selectedStateId);
    final exists = state.statentity.any(
      (item) => _normalizeLocationId(item.stateId) == selectedStateId,
    );

    if (!exists) {
      debugPrint(
        'Existing state ID $_selectedStateId '
        'not found in state API',
      );

      return;
    }

    debugPrint('Existing state mapped: $_selectedStateId');
  }
  // void _mapSelectedState(AddDealerVisitState state) {
  //   if (_selectedStateId == null || _selectedStateId == '0') {
  //     return;
  //   }

  //   final exists = state.statentity.any(
  //     (item) => item.stateId == _selectedStateId,
  //   );

  //   if (!exists) {
  //     debugPrint(
  //       'Existing state ID $_selectedStateId '
  //       'not found in state API',
  //     );

  //     return;
  //   }

  //   debugPrint('Existing state mapped: $_selectedStateId');
  // }

  void _mapSelectedDistrictAndTaluka(AddDealerVisitState state) {
    if (_selectedDistrictId == null || _selectedDistrictId == '0') {
      return;
    }

    final selectedDistrictId = _normalizeLocationId(_selectedDistrictId);
    final selectedTalukaId = _normalizeLocationId(_selectedTalukaId);
    final districtExists = state.districtList.any(
      (district) =>
          _normalizeLocationId(district.fldDistId) == selectedDistrictId,
    );

    if (!districtExists) {
      debugPrint(
        'Existing district ID $_selectedDistrictId '
        'not found',
      );

      return;
    }

    final district = state.districtList.firstWhere(
      (district) =>
          _normalizeLocationId(district.fldDistId) == selectedDistrictId,
    );

    final talukaExists = district.taluka.any(
      (taluka) => _normalizeLocationId(taluka.fldTalukaId) == selectedTalukaId,
    );

    if (!talukaExists) {
      debugPrint(
        'Existing taluka ID $_selectedTalukaId '
        'not found',
      );

      return;
    }

    debugPrint('================================');
    debugPrint('EXISTING LOCATION MAPPED');
    debugPrint('State ID: $_selectedStateId');
    debugPrint('District: ${district.fldDistName}');
    debugPrint('District ID: $_selectedDistrictId');
    debugPrint('Taluka ID: $_selectedTalukaId');
    debugPrint('================================');
  }

  void _onDistrictSelected(String? districtId, AddDealerVisitState state) {
    if (districtId == null || districtId.isEmpty) {
      return;
    }

    // Reset district
    if (districtId == '0') {
      setState(() {
        _selectedDistrictId = '0';
        _selectedTalukaId = '0';
      });

      return;
    }

    DistrictEntity? selectedDistrict;

    for (final district in state.districtList) {
      if (_normalizeLocationId(district.fldDistId) ==
          _normalizeLocationId(districtId)) {
        selectedDistrict = district;
        break;
      }
    }

    if (selectedDistrict == null) {
      debugPrint('District not found: $districtId');

      return;
    }

    debugPrint('Selected District ID: ${selectedDistrict.fldDistId}');

    debugPrint('Selected District Name: ${selectedDistrict.fldDistName}');

    debugPrint('Taluka Count: ${selectedDistrict.taluka.length}');

    setState(() {
      _selectedDistrictId = _normalizeLocationId(districtId);

      // Whenever district changes,
      // old taluka must be cleared.
      _selectedTalukaId = '0';
    });
  }
  // void _onDistrictSelected(String? districtId, AddDealerVisitState state) {
  //   if (districtId == null || districtId.isEmpty) {
  //     return;
  //   }

  //   // Reset district
  //   if (districtId == '0') {
  //     setState(() {
  //       _selectedDistrictId = '0';
  //       _selectedTalukaId = '0';
  //     });

  //     return;
  //   }

  //   DistrictEntity? selectedDistrict;

  //   for (final district in state.districtList) {
  //     if (district.fldDistId == districtId) {
  //       selectedDistrict = district;
  //       break;
  //     }
  //   }

  //   if (selectedDistrict == null) {
  //     debugPrint('District not found: $districtId');

  //     return;
  //   }

  //   debugPrint('Selected District ID: ${selectedDistrict.fldDistId}');

  //   debugPrint('Selected District Name: ${selectedDistrict.fldDistName}');

  //   debugPrint('Taluka Count: ${selectedDistrict.taluka.length}');

  //   setState(() {
  //     _selectedDistrictId = districtId;

  //     // Whenever district changes,
  //     // old taluka must be cleared.
  //     _selectedTalukaId = '0';
  //   });
  // }

  String? _selectedFollowUpType;
  bool _submissionSent = false;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  static const _fieldOrder = [
    'dealerType',
    'shop',
    'mobile',
    'alternate',
    'email',
    'state',
    'district',
    'taluka',
    'date',
    'followUpType',
  ];
  final _fieldKeys = {
    for (final name in _fieldOrder) name: GlobalKey<FormFieldState>(),
  };
  final _fieldFocus = {for (final name in _fieldOrder) name: FocusNode()};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: CustomAppBar(
        title: 'Dealer Details',
        showBackButton: true,
        onBackTap: () => Navigator.pop(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          BlocBuilder<AddDealerVisitBlock, AddDealerVisitState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: CustomButton(
                  text: 'Update Dealer',
                  onPressed: _submit,
                  isLoading: isLoading,

                  backgroundColor: context.primaryColor,
                  textColor: context.onPrimaryColor,
                ),
              );
            },
          ),
      body: BlocConsumer<AddDealerVisitBlock, AddDealerVisitState>(
        listener: (context, state) {
          if (state.statentity.isNotEmpty) {
            _mapSelectedState(state);
          }

          // District API completed
          if (state.districtList.isNotEmpty) {
            _mapSelectedDistrictAndTaluka(state);
          }
          if (!isLoading || !_submissionSent) return;
          if (state.addLeaveStatus == AddDealerVisitStatus.dealerUpdateSucess) {
            setState(() {
              isLoading = false;
              _submissionSent = false;
            });

            AppDialog.show(
              context: context,
              message: state.errorMessage ?? 'Dealer Updated Successfully',
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

          final selectedDistrictId = _normalizeLocationId(_selectedDistrictId);
          final selectedTalukaId = _normalizeLocationId(_selectedTalukaId);

          for (final district in state.districtList) {
            if (_normalizeLocationId(district.fldDistId) ==
                selectedDistrictId) {
              selectedDistrict = district;
              break;
            }
          }

          final talukaList = selectedDistrict?.taluka ?? [];

          if (_selectedDistrictId != null && _selectedDistrictId != '0') {
            for (final district in state.districtList) {
              if (_normalizeLocationId(district.fldDistId) ==
                  selectedDistrictId) {
                selectedDistrict = district;
                break;
              }
            }
          }

          final Map<String, DistrictEntity> uniqueDistricts = {};

          for (final district in state.districtList) {
            final id = district.fldDistId.trim();

            if (id.isEmpty || id == '0') {
              continue;
            }

            uniqueDistricts.putIfAbsent(id, () => district);
          }

          final districtItems = <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: '0',
              child: Text('Select District', style: AppTextStyles.inputHint),
            ),
            ...uniqueDistricts.entries.map((entry) {
              final district = entry.value;

              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(district.fldDistName, style: AppTextStyles.input),
              );
            }),
          ];

          final Map<String, TalukaEntity> uniqueTalukas = {};

          for (final taluka in talukaList) {
            final id = taluka.fldTalukaId.trim();

            if (id.isEmpty || id == '0') {
              continue;
            }

            uniqueTalukas.putIfAbsent(id, () => taluka);
          }

          final talukaItems = <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: '0',
              child: Text('Select Taluka', style: AppTextStyles.inputHint),
            ),
            ...uniqueTalukas.entries.map((entry) {
              final taluka = entry.value;

              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(taluka.fldName, style: AppTextStyles.input),
              );
            }),
          ];
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
          final selectedStateValue =
              uniqueStates.containsKey(_selectedStateId?.trim())
              ? _selectedStateId?.trim()
              : null;

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

          final selectedDistrictValue =
              uniqueDistricts.containsKey(selectedDistrictId)
              ? selectedDistrictId
              : null;

          final selectedTalukaValue =
              uniqueTalukas.containsKey(selectedTalukaId)
              ? selectedTalukaId
              : null;

          return SafeArea(
            child: Form(
              key: _formKey,

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
                      value: _selectedDealerStatus,

                      hintText: 'Select Dealer Type',
                      fieldKey: _fieldKeys['dealerType'],
                      focusNode: _fieldFocus['dealerType'],

                      prefixIcon: Icons.person_outline,

                      enabled: true,

                      items: dealerTypeItems,

                      onChanged: (value) {
                        setState(() {
                          _selectedDealerStatus = value;
                        });

                        debugPrint(
                          'Selected Farmer Status: $_selectedDealerStatus',
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
                    CustomTextFormField(
                      labelText: 'Shop Name',
                      controller: shopNameController,
                      hintText: 'Shop Name *',
                      fieldKey: _fieldKeys['shop'],
                      focusNode: _fieldFocus['shop'],
                      prefixIcon: Icons.shop,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter Shop name';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      labelText: 'Dealer Code',
                      controller: dealerCodeController,
                      hintText: 'Dealer Code',
                      prefixIcon: Icons.person_outline,
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      labelText: 'Owner Name',
                      controller: ownerNameController,
                      hintText: 'Owner Name',
                      prefixIcon: Icons.person_2_outlined,
                      maxLines: 3,
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      maxLength: 10,
                      labelText: 'Mobile No',
                      controller: mobileController,
                      hintText: 'Mobile No *',
                      fieldKey: _fieldKeys['mobile'],
                      focusNode: _fieldFocus['mobile'],
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
                      labelText: 'Alternate Mobile No',
                      controller: alternateMobileController,
                      hintText: 'Alternate Mobile No',
                      fieldKey: _fieldKeys['alternate'],
                      focusNode: _fieldFocus['alternate'],
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
                      labelText: 'GST No',
                      controller: gstController,
                      hintText: 'GST No',
                      prefixIcon: Icons.receipt_long_outlined,
                      keyboardType: TextInputType.text,
                    ),

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      labelText: 'Email Id',
                      controller: emailController,
                      hintText: 'Email Id',
                      fieldKey: _fieldKeys['email'],
                      focusNode: _fieldFocus['email'],
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
                      labelText: 'Address',
                      controller: addressController,
                      hintText: 'Address',
                      prefixIcon: Icons.home_outlined,
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
                      value: selectedStateValue,

                      hintText: 'Select State',
                      fieldKey: _fieldKeys['state'],
                      focusNode: _fieldFocus['state'],

                      prefixIcon: Icons.map_outlined,

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

                    SizedBox(height: 10.h),

                    Text(
                      'District *',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    CustomDropdown<String>(
                      value: selectedDistrictValue,
                      hintText: 'Select District',
                      fieldKey: _fieldKeys['district'],
                      focusNode: _fieldFocus['district'],
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
                        color: context.primaryTextColor,
                      ),
                    ),

                    SizedBox(height: 10.h),
                    CustomDropdown<String>(
                      value: selectedTalukaValue,
                      hintText: 'Select Taluka',
                      fieldKey: _fieldKeys['taluka'],
                      focusNode: _fieldFocus['taluka'],
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

                    _textField(
                      controller: dateController,
                      hintText: 'Next Visit Date *',
                      fieldKey: _fieldKeys['date'],
                      focusNode: _fieldFocus['date'],
                      icon: Icons.calendar_today_outlined,
                      enabled: false,
                      readOnly: true,
                      // suffixIcon: Icons.calendar_month_outlined,
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
                    CustomDropdown<String>(
                      value: _selectedFollowUpStatus,
                      hintText: 'Follow Up Type',
                      fieldKey: _fieldKeys['followUpType'],
                      focusNode: _fieldFocus['followUpType'],
                      prefixIcon: Icons.event_note_outlined,
                      enabled: true,
                      items: followUpTypeItem,
                      onChanged: (value) {
                        setState(() {
                          _selectedFollowUpStatus = value;
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

                    SizedBox(height: 10.h),

                    CustomTextFormField(
                      labelText: 'Remark',
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
}
