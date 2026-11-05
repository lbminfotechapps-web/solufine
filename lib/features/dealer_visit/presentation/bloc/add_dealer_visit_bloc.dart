import 'dart:async';
import 'dart:io';

import 'package:solufine/core/utility/image_compression.dart';
import 'package:solufine/features/dealer_visit/presentation/bloc/add_dealer_visit_state.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/repository/farmerregistration_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/usecases/add_ramark.dart';
import 'add_dealer_visit_event.dart';

class AddDealerVisitBlock
    extends Bloc<AddDealerRemarkEvent, AddDealerVisitState> {
  final AddRemark addLeave;
  final FarmerregistrationRepository repositoryProvider;

  AddDealerVisitBlock(this.addLeave, this.repositoryProvider)
    : super(const AddDealerVisitState()) {
    on<AddDealerRemarkSubmitEvent>(_onAddRemark);
    on<GetPurposeEvent>(_onGetPurpose);
    on<GetFollowupEvent>(_onGetFollowup);
    on<AddDealerFollowUpEvent>(_onAddDealerFollowUp);
    on<StateListEvent>(_onStateListGet);
    on<DistrictEvent>(_onDistrictGet);
    on<UpdateDealerEvent>(_onUpdateDealer);
  }


  Future<void> _onAddRemark(
  AddDealerRemarkSubmitEvent event,
  Emitter<AddDealerVisitState> emit,
) async {
  // ============================================================
  // 1. SET LOADING STATE
  // ============================================================

  emit(
    state.copyWith(
      addLeaveStatus: AddDealerVisitStatus.loading,
      clearError: true,
      clearSuccess: true,
    ),
  );

  try {
    debugPrint('==========================================');
    debugPrint('ADD DEALER REMARK');
    debugPrint('==========================================');

    // ============================================================
    // 2. CHECK + COMPRESS DEALER IMAGE
    // ============================================================

    File? dealerImageFile;

    debugPrint('==========================================');
    debugPrint('DEALER FOLLOWUP IMAGE CHECK');
    debugPrint('EVENT IMAGE PATH: ${event.imagePath}');
    debugPrint('==========================================');

    if (event.imagePath != null &&
        event.imagePath!.trim().isNotEmpty) {
      final File originalFile = File(
        event.imagePath!.trim(),
      );

      final bool exists =
          await originalFile.exists();

      debugPrint(
        'ORIGINAL IMAGE EXISTS: $exists',
      );

      if (exists) {
        debugPrint(
          'ORIGINAL IMAGE PATH: ${originalFile.path}',
        );

        debugPrint(
          'ORIGINAL IMAGE SIZE: '
          '${await originalFile.length()} bytes',
        );

        // ========================================================
        // COMPRESS IMAGE
        // ========================================================

        final File? compressedFile =
            await ImageCompression.compressImage(
          originalFile,
          maxWidth: 450,
          maxHeight: 450,
          quality: 45,
        );

        // ========================================================
        // USE COMPRESSED IMAGE IF AVAILABLE
        // OTHERWISE USE ORIGINAL
        // ========================================================

        if (compressedFile != null &&
            await compressedFile.exists()) {
          dealerImageFile = compressedFile;

          debugPrint(
            'USING COMPRESSED DEALER IMAGE',
          );

          debugPrint(
            'COMPRESSED PATH: '
            '${dealerImageFile.path}',
          );

          debugPrint(
            'COMPRESSED SIZE: '
            '${await dealerImageFile.length()} bytes',
          );
        } else {
          dealerImageFile = originalFile;

          debugPrint(
            'COMPRESSION FAILED - '
            'USING ORIGINAL DEALER IMAGE',
          );

          debugPrint(
            'IMAGE PATH: '
            '${dealerImageFile.path}',
          );

          debugPrint(
            'IMAGE SIZE: '
            '${await dealerImageFile.length()} bytes',
          );
        }
      } else {
        debugPrint(
          'DEALER IMAGE FILE DOES NOT EXIST',
        );
      }
    } else {
      debugPrint(
        'DEALER IMAGE NOT SELECTED',
      );
    }

    // ============================================================
    // 3. PREPARE REQUEST DATA
    // ============================================================

    final Map<String, dynamic> formData = {
      'user_id': event.userId,
      'outlet_id': event.outletId,
      'purposeId': event.purposeId,
      'amount': event.amount,
      'followUpDate': event.followUpDate,
      'followUpType': event.followUpType,
      'remark': event.remark,

      // Location
      'latitude': event.latitude,
      'longitude': event.longitude,

      // Network Location
      'networkLatitude': event.networkLatitude,
      'networkLongitude': event.networkLongitude,

      // GPS Location
      'gpsLatitude': event.gpsLatitude,
      'gpsLongitude': event.gpsLongitude,

      // Address
      'geoAddress': event.geoAddress,

      // Device Information
      'strNetworkInfo': event.strNetworkInfo,
      'strBatteryInfo': event.strBatteryInfo,

      // Activity
      'activityId': event.activityId,

      // ========================================================
      // IMAGE
      // IMPORTANT:
      // Keep it as File here.
      // Datasource will convert it to MultipartFile.
      // ========================================================

      if (dealerImageFile != null)
        'selfie_capture_image': dealerImageFile,
    };

    // ============================================================
    // 4. PRINT NORMAL REQUEST DATA
    // ============================================================

    debugPrint('');
    debugPrint('==========================================');
    debugPrint('DEALER REMARK REQUEST DATA');
    debugPrint('==========================================');

    formData.forEach(
      (key, value) {
        if (key == 'selfie_capture_image' &&
            value is File) {
          debugPrint(
            '$key: FILE -> ${value.path}',
          );
        } else {
          debugPrint(
            '$key: $value',
          );
        }
      },
    );

    debugPrint('==========================================');

    // ============================================================
    // 5. PRINT IMAGE INFORMATION
    // ============================================================

    debugPrint('==========================================');
    debugPrint('DEALER IMAGE TO REPOSITORY');
    debugPrint('==========================================');

    if (dealerImageFile != null) {
      debugPrint(
        'IMAGE AVAILABLE',
      );

      debugPrint(
        'PATH: ${dealerImageFile.path}',
      );

      debugPrint(
        'EXISTS: ${await dealerImageFile.exists()}',
      );

      debugPrint(
        'SIZE: ${await dealerImageFile.length()} bytes',
      );
    } else {
      debugPrint(
        'IMAGE FILE IS NULL',
      );
    }

    debugPrint('==========================================');

    // ============================================================
    // 6. CALL DEALER VISIT API
    // ============================================================

    final response =
        await addLeave.call(
      formData,
    );

    // ============================================================
    // 7. PRINT RESPONSE
    // ============================================================

    debugPrint(
      '========== ADD REMARK RESPONSE ==========',
    );

    debugPrint(
      '$response',
    );

    debugPrint(
      '=========================================',
    );

    // Example:
    //
    // {status: success-5}
    // {status: success-48}
    // {status: success-125}

    final String responseStatus =
        response['status']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';

    debugPrint(
      'FULL API STATUS: "$responseStatus"',
    );

    // ============================================================
    // 8. EXTRACT STATUS + DAILY TRAN ID
    // ============================================================

    final List<String> parts =
        responseStatus.split('-');

    final String mainStatus =
        parts.isNotEmpty
            ? parts.first.trim()
            : '';

    final String dailyTranId =
        parts.length > 1
            ? parts[1].trim()
            : '';

    debugPrint('==========================================');
    debugPrint('DEALER VISIT RESPONSE PARSED');

    // FIXED:
    // Your previous log was printing dailyTranId here.
    debugPrint(
      'MAIN API STATUS : "$mainStatus"',
    );

    debugPrint(
      'DAILY TRAN ID   : "$dailyTranId"',
    );

    debugPrint('==========================================');

    // ============================================================
    // 9. SUCCESS
    // ============================================================

    if (mainStatus == 'success') {
      if (dailyTranId.isEmpty) {
        debugPrint('==========================================');
        debugPrint('WARNING');
        debugPrint(
          'Dealer API succeeded but dailyTranId is empty',
        );
        debugPrint(
          'Original status: $responseStatus',
        );
        debugPrint('==========================================');

        emit(
          state.copyWith(
            addLeaveStatus:
                AddDealerVisitStatus.failure,
            errorMessage:
                'Dealer visit saved but transaction ID was not received',
          ),
        );

        return;
      }

      debugPrint('==========================================');
      debugPrint('DEALER VISIT SUCCESS');
      debugPrint(
        'Daily Tran ID saved in state: $dailyTranId',
      );
      debugPrint('==========================================');

      emit(
        state.copyWith(
          addLeaveStatus:
              AddDealerVisitStatus
                  .dealerAddedSuccess,
          dailyTranId: dailyTranId,
          errorMessage: null,
        ),
      );

      return;
    }

    // ============================================================
    // 10. API FAILURE
    // ============================================================

    final String errorMessage =
        response['message']?.toString() ??
        'Unable to add dealer follow up';

    debugPrint('==========================================');
    debugPrint('DEALER VISIT FAILED');
    debugPrint(
      'Message: $errorMessage',
    );
    debugPrint('==========================================');

    emit(
      state.copyWith(
        addLeaveStatus:
            AddDealerVisitStatus.failure,
        errorMessage: errorMessage,
      ),
    );
  } catch (e, stackTrace) {
    // ============================================================
    // 11. EXCEPTION
    // ============================================================

    debugPrint('==========================================');
    debugPrint('ADD REMARK ERROR');
    debugPrint('ERROR: $e');
    debugPrint('STACK TRACE:');
    debugPrint('$stackTrace');
    debugPrint('==========================================');

    String message =
        'Unable to add dealer follow-up';

    if (e is ServerException ||
        e is NetworkException) {
      message = e.toString();
    }

    emit(
      state.copyWith(
        addLeaveStatus:
            AddDealerVisitStatus.failure,
        errorMessage: message,
        clearSuccess: true,
      ),
    );
  }
}

  // Future<void> _onAddRemark(
  //   AddDealerRemarkSubmitEvent event,
  //   Emitter<AddDealerVisitState> emit,
  // ) async {
  //   // ============================================================
  //   // 1. SET LOADING STATE
  //   // ============================================================
  //   emit(
  //     state.copyWith(
  //       addLeaveStatus: AddDealerVisitStatus.loading,
  //       clearError: true,
  //       clearSuccess: true,
  //     ),
  //   );

  //   try {
  //     debugPrint('==========================================');
  //     debugPrint('ADD DEALER REMARK');
  //     debugPrint('==========================================');

  //     // ============================================================
  //     // 2. PREPARE REQUEST DATA
  //     // ============================================================
  //     final Map<String, dynamic> formData = {
  //       'user_id': event.userId,
  //       'outlet_id': event.outletId,
  //       'purposeId': event.purposeId,
  //       'amount': event.amount,
  //       'followUpDate': event.followUpDate,
  //       'followUpType': event.followUpType,
  //       'remark': event.remark,

  //       // Location
  //       'latitude': event.latitude,
  //       'longitude': event.longitude,

  //       // Network Location
  //       'networkLatitude': event.networkLatitude,
  //       'networkLongitude': event.networkLongitude,

  //       // GPS Location
  //       'gpsLatitude': event.gpsLatitude,
  //       'gpsLongitude': event.gpsLongitude,

  //       // Address
  //       'geoAddress': event.geoAddress,

  //       // Device Information
  //       'strNetworkInfo': event.strNetworkInfo,
  //       'strBatteryInfo': event.strBatteryInfo,

  //       // Activity
  //       'activityId': event.activityId,
  //     };

  //     // ============================================================
  //     // 3. PRINT REQUEST
  //     // ============================================================
  //     debugPrint('========== REQUEST DATA ==========');

  //     formData.forEach((key, value) {
  //       debugPrint('$key : $value');
  //     });

  //     debugPrint('==================================');

  //     // ============================================================
  //     // 4. CALL DEALER VISIT API
  //     // ============================================================
  //     final response = await addLeave.call(formData);

  //     // ============================================================
  //     // 5. PRINT RESPONSE
  //     // ============================================================
  //     debugPrint('========== ADD REMARK RESPONSE ==========');
  //     debugPrint('$response');
  //     debugPrint('=========================================');

  //     // Example:
  //     //
  //     // {status: success-5}
  //     // {status: success-48}
  //     // {status: success-125}

  //     final String responseStatus =
  //         response['status']?.toString().trim().toLowerCase() ?? '';

  //     debugPrint('FULL API STATUS: "$responseStatus"');

  //     // ============================================================
  //     // 6. EXTRACT STATUS + DAILY TRAN ID
  //     // ============================================================
  //     //
  //     // success-5
  //     //    ↓
  //     // parts[0] = success
  //     // parts[1] = 5
  //     //
  //     // 5 = dailyTranId
  //     // ============================================================

  //     final List<String> parts = responseStatus.split('-');

  //     final String mainStatus = parts.isNotEmpty ? parts.first.trim() : '';

  //     final String dailyTranId = parts.length > 1 ? parts[1].trim() : '';

  //     debugPrint('==========================================');
  //     debugPrint('DEALER VISIT RESPONSE PARSED');
  //     debugPrint('MAIN API STATUS : "$dailyTranId"');
  //     debugPrint('DAILY TRAN ID   : "$dailyTranId"');
  //     debugPrint('==========================================');

  //     // ============================================================
  //     // 7. SUCCESS
  //     // ============================================================
  //     if (mainStatus == 'success') {
  //       // Safety check:
  //       // Store-location API needs dailyTranId.
  //       if (dailyTranId.isEmpty) {
  //         debugPrint('==========================================');
  //         debugPrint('WARNING');
  //         debugPrint('Dealer API succeeded but dailyTranId is empty');
  //         debugPrint('Original status: $responseStatus');
  //         debugPrint('==========================================');

  //         emit(
  //           state.copyWith(
  //             addLeaveStatus: AddDealerVisitStatus.failure,
  //             errorMessage:
  //                 'Dealer visit saved but transaction ID was not received',
  //           ),
  //         );

  //         return;
  //       }

  //       debugPrint('==========================================');
  //       debugPrint('DEALER VISIT SUCCESS');
  //       debugPrint('Daily Tran ID saved in state: $dailyTranId');
  //       debugPrint('==========================================');

  //       emit(
  //         state.copyWith(
  //           addLeaveStatus: AddDealerVisitStatus.dealerAddedSuccess,

  //           // IMPORTANT
  //           // We will use this from UI when calling
  //           // StoreTrackLocation.
  //           dailyTranId: dailyTranId,

  //           errorMessage: null,
  //         ),
  //       );

  //       return;
  //     }

  //     // ============================================================
  //     // 8. API FAILURE
  //     // ============================================================
  //     final String errorMessage =
  //         response['message']?.toString() ?? 'Unable to add dealer follow up';

  //     debugPrint('==========================================');
  //     debugPrint('DEALER VISIT FAILED');
  //     debugPrint('Message: $errorMessage');
  //     debugPrint('==========================================');

  //     emit(
  //       state.copyWith(
  //         addLeaveStatus: AddDealerVisitStatus.failure,
  //         errorMessage: errorMessage,
  //       ),
  //     );
  //   } catch (e, stackTrace) {
  //     // ============================================================
  //     // 9. EXCEPTION
  //     // ============================================================
  //     debugPrint('==========================================');
  //     debugPrint('ADD REMARK ERROR');
  //     debugPrint('ERROR: $e');
  //     debugPrint('STACK TRACE:');
  //     debugPrint('$stackTrace');
  //     debugPrint('==========================================');

  //     String message = 'Unable to add dealer follow-up';

  //     if (e is ServerException || e is NetworkException) {
  //       message = e.toString();
  //     }

  //     emit(
  //       state.copyWith(
  //         addLeaveStatus: AddDealerVisitStatus.failure,
  //         errorMessage: message,
  //         clearSuccess: true,
  //       ),
  //     );
  //   }
  // }

  Future<void> _onGetPurpose(
    GetPurposeEvent event,
    Emitter<AddDealerVisitState> emit,
  ) async {
    emit(state.copyWith(addLeaveStatus: AddDealerVisitStatus.loading));

    try {
      final purpose = await addLeave.getPurpose(event.userId);
      print('bloc response$purpose');
      emit(
        state.copyWith(
          addLeaveStatus: AddDealerVisitStatus.success,
          purpose: purpose,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          addLeaveStatus: AddDealerVisitStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onGetFollowup(
    GetFollowupEvent event,
    Emitter<AddDealerVisitState> emit,
  ) async {
    emit(state.copyWith(addLeaveStatus: AddDealerVisitStatus.loading));

    try {
      final followupList = await addLeave.getFollowupList(event.outlet_id);

      print('Followup List: $followupList');
      print('Followup List Size: ${followupList.length}');

      emit(
        state.copyWith(
          addLeaveStatus: AddDealerVisitStatus.success,
          followupList: followupList,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          addLeaveStatus: AddDealerVisitStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onStateListGet(
    StateListEvent event,
    Emitter<AddDealerVisitState> emit,
  ) async {
    print('================================');
    print('STATE API CALLED');
    print('USER ID: ${event.userId}');
    print('================================');

    emit(state.copyWith(addLeaveStatus: AddDealerVisitStatus.loading));

    try {
      final response = await repositoryProvider.getStates(event.userId);

      print('REPOSITORY RESPONSE LENGTH: ${response.length}');

      for (final item in response) {
        print(
          'REPOSITORY ITEM -> ID: ${item.stateId} | NAME: ${item.stateName}',
        );
      }

      if (response.isEmpty) {
        print('STATE RESPONSE EMPTY');

        emit(
          state.copyWith(
            addLeaveStatus: AddDealerVisitStatus.failure,
            statentity: [],
          ),
        );

        return;
      }

      emit(
        state.copyWith(
          addLeaveStatus: AddDealerVisitStatus.success,
          statentity: response,
        ),
      );

      print('================================');
      print('BLOC STATUS: SUCCESS');
      // print('BLOC STATE COUNT: ${state.statentity.length}');
      print('================================');
    } catch (e, stackTrace) {
      print('STATE BLOC ERROR: $e');
      print(stackTrace);

      emit(
        state.copyWith(
          addLeaveStatus: AddDealerVisitStatus.failure,
          statentity: [],
        ),
      );
    }
  }

  Future<void> _onDistrictGet(
    DistrictEvent event,
    Emitter<AddDealerVisitState> emit,
  ) async {
    emit(
      state.copyWith(
        addLeaveStatus: AddDealerVisitStatus.loading,
        errorMessage: null,
        districtList: [],
      ),
    );

    try {
      final districts = await repositoryProvider.getDistrict(
        event.userId,
        event.stateId,
      );

      print('bloc response $districts');

      emit(
        state.copyWith(
          addLeaveStatus: AddDealerVisitStatus.success,
          districtList: districts,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          addLeaveStatus: AddDealerVisitStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // Future<void> _onAddDealerFollowUp(
  //   AddDealerFollowUpEvent event,
  //   Emitter<AddDealerVisitState> emit,
  // ) async {
  //   emit(
  //     state.copyWith(
  //       addLeaveStatus: AddDealerVisitStatus.loading,
  //       errorMessage: null,
  //     ),
  //   );

  //   try {
  //     File? selfieImageFile;

  //     // ============================================
  //     // COMPRESS SELFIE IMAGE
  //     // ============================================
  //     if (event.selfieCaptureImage.isNotEmpty) {
  //       final originalFile = File(event.selfieCaptureImage);

  //       if (await originalFile.exists()) {
  //         selfieImageFile = await ImageCompression.compressImage(
  //           originalFile,
  //           maxWidth: 450,
  //           maxHeight: 450,
  //           quality: 45,
  //         );

  //         if (selfieImageFile == null) {
  //           throw Exception('Unable to compress selfie image');
  //         }
  //       } else {
  //         print(
  //           'Selfie image file not found: '
  //           '${event.selfieCaptureImage}',
  //         );
  //       }
  //     }

  //     // ============================================
  //     // REQUEST DATA
  //     // ============================================
  //     final jsonData = <String, dynamic>{
  //       'user_id': event.userId,
  //       'type': event.type,
  //       'outlet_name': event.outletName,
  //       'contact_person': event.contactPerson,
  //       'gst_no': event.gstNo,
  //       'mobile_no': event.mobileNo,
  //       'mobile_no2': event.mobileNo2,
  //       'email_id': event.emailId,
  //       'address': event.address,

  //       'state': event.state,
  //       'district': event.district,
  //       'taluka': event.taluka,

  //       'remark': event.remark,
  //       'city': event.city,

  //       'latitude': event.latitude,
  //       'longitude': event.longitude,
  //       'networkLatitude': event.networkLatitude,
  //       'networkLongitude': event.networkLongitude,
  //       'gpsLatitude': event.gpsLatitude,
  //       'gpsLongitude': event.gpsLongitude,

  //       'geoAddress': event.geoAddress,
  //       'differenceByAndroid': event.differenceByAndroid,

  //       'mobile_info': event.mobileInfo,
  //       'mobile_imei': event.mobileImei,

  //       'followUpDate': event.followUpDate,
  //       'followUpType': event.followUpType,

  //       'strNetworkInfo': event.strNetworkInfo,
  //       'strBatteryInfo': event.strBatteryInfo,

  //       'registrationType': event.registrationType,
  //       'flag': event.flag,
  //       'dealerCode': event.dealerCode,
  //       'activityId': event.activityId,
  //     };

  //     // ============================================
  //     // ADD SELFIE IMAGE FILE
  //     // ============================================
  //     if (selfieImageFile != null) {
  //       jsonData['selfie_capture_image'] = selfieImageFile;
  //     }

  //     // ============================================
  //     // DEBUG
  //     // ============================================
  //     print('========== DEALER FOLLOW UP REQUEST ==========');

  //     print(
  //       'user_id: '
  //       '${event.userId}',
  //     );

  //     print(
  //       'type: '
  //       '${event.type}',
  //     );

  //     print(
  //       'outlet_name: '
  //       '${event.outletName}',
  //     );

  //     print(
  //       'contact_person: '
  //       '${event.contactPerson}',
  //     );

  //     print(
  //       'gst_no: '
  //       '${event.gstNo}',
  //     );

  //     print(
  //       'mobile_no: '
  //       '${event.mobileNo}',
  //     );

  //     print(
  //       'mobile_no2: '
  //       '${event.mobileNo2}',
  //     );

  //     print(
  //       'email_id: '
  //       '${event.emailId}',
  //     );

  //     print(
  //       'address: '
  //       '${event.address}',
  //     );

  //     print(
  //       'state: '
  //       '${event.state}',
  //     );

  //     print(
  //       'district: '
  //       '${event.district}',
  //     );

  //     print(
  //       'taluka: '
  //       '${event.taluka}',
  //     );

  //     print(
  //       'remark: '
  //       '${event.remark}',
  //     );

  //     print(
  //       'city: '
  //       '${event.city}',
  //     );

  //     print(
  //       'latitude: '
  //       '${event.latitude}',
  //     );

  //     print(
  //       'longitude: '
  //       '${event.longitude}',
  //     );

  //     print(
  //       'networkLatitude: '
  //       '${event.networkLatitude}',
  //     );

  //     print(
  //       'networkLongitude: '
  //       '${event.networkLongitude}',
  //     );

  //     print(
  //       'gpsLatitude: '
  //       '${event.gpsLatitude}',
  //     );

  //     print(
  //       'gpsLongitude: '
  //       '${event.gpsLongitude}',
  //     );

  //     print(
  //       'geoAddress: '
  //       '${event.geoAddress}',
  //     );

  //     print(
  //       'differenceByAndroid: '
  //       '${event.differenceByAndroid}',
  //     );

  //     print(
  //       'mobile_info: '
  //       '${event.mobileInfo}',
  //     );

  //     print(
  //       'mobile_imei: '
  //       '${event.mobileImei}',
  //     );

  //     print(
  //       'followUpDate: '
  //       '${event.followUpDate}',
  //     );

  //     print(
  //       'followUpType: '
  //       '${event.followUpType}',
  //     );

  //     print(
  //       'strNetworkInfo: '
  //       '${event.strNetworkInfo}',
  //     );

  //     print(
  //       'strBatteryInfo: '
  //       '${event.strBatteryInfo}',
  //     );

  //     print(
  //       'registrationType: '
  //       '${event.registrationType}',
  //     );

  //     print(
  //       'flag: '
  //       '${event.flag}',
  //     );

  //     print(
  //       'dealerCode: '
  //       '${event.dealerCode}',
  //     );

  //     print(
  //       'activityId: '
  //       '${event.activityId}',
  //     );

  //     print(
  //       'selfie_capture_image: '
  //       '${selfieImageFile?.path ?? 'NO FILE'}',
  //     );

  //     print('==============================================');

  //     // ============================================
  //     // CALL API
  //     // ============================================
  //     final response = await addLeave.addDealerFollowUp(jsonData);

  //     print('Dealer follow up response: $response');

  //     // ============================================
  //     // SUCCESS
  //     // ============================================
  //     final responseStatus = response['status']
  //         ?.toString()
  //         .toLowerCase()
  //         .trim();

  //     debugPrint('API STATUS: "$responseStatus"');

  //     if (responseStatus == 'success' ||
  //         responseStatus == 'true' ||
  //         responseStatus == '1' ||
  //         responseStatus!.startsWith('success-')) {
  //       emit(
  //         state.copyWith(
  //           addLeaveStatus: AddDealerVisitStatus.dealerAddedSuccess,
  //           errorMessage: null,
  //         ),
  //       );
  //     } else {
  //       emit(
  //         state.copyWith(
  //           addLeaveStatus: AddDealerVisitStatus.failure,
  //           errorMessage:
  //               response['message']?.toString() ??
  //               'Unable to add dealer follow up',
  //         ),
  //       );
  //     }
  //   } catch (error) {
  //     print('Dealer follow up error: $error');

  //     // ============================================
  //     // FAILURE
  //     // ============================================
  //     emit(
  //       state.copyWith(
  //         addLeaveStatus: AddDealerVisitStatus.failure,
  //         errorMessage: error.toString(),
  //       ),
  //     );
  //   }
  // }


  Future<void> _onAddDealerFollowUp(
  AddDealerFollowUpEvent event,
  Emitter<AddDealerVisitState> emit,
) async {
  emit(
    state.copyWith(
      addLeaveStatus: AddDealerVisitStatus.loading,
      errorMessage: null,
    ),
  );

  try {
    // ============================================================
    // 1. PREPARE SELFIE IMAGE
    // ============================================================

    File? selfieImageFile;

    debugPrint('==========================================');
    debugPrint('DEALER SELFIE IMAGE');
    debugPrint('ORIGINAL PATH: ${event.selfieCaptureImage}');
    debugPrint('==========================================');

    if (event.selfieCaptureImage.trim().isNotEmpty) {
      final originalFile = File(
        event.selfieCaptureImage.trim(),
      );

      final bool exists = await originalFile.exists();

      debugPrint('ORIGINAL IMAGE EXISTS: $exists');

      if (exists) {
        debugPrint(
          'ORIGINAL IMAGE SIZE: '
          '${await originalFile.length()} bytes',
        );

        // ========================================================
        // COMPRESS IMAGE
        // ========================================================

        final compressedFile =
            await ImageCompression.compressImage(
          originalFile,
          maxWidth: 450,
          maxHeight: 450,
          quality: 45,
        );

        if (compressedFile != null &&
            await compressedFile.exists()) {
          selfieImageFile = compressedFile;

          debugPrint(' COMPRESSED IMAGE READY');
          debugPrint(
            'COMPRESSED IMAGE PATH: ${selfieImageFile.path}',
          );
          debugPrint(
            'COMPRESSED IMAGE SIZE: '
            '${await selfieImageFile.length()} bytes',
          );
        } else {
          // If compression fails, use original file.
          selfieImageFile = originalFile;

          debugPrint(
            ' IMAGE COMPRESSION FAILED',
          );
          debugPrint(
            'USING ORIGINAL IMAGE',
          );
        }
      } else {
        debugPrint(
          ' SELFIE IMAGE FILE NOT FOUND',
        );

        debugPrint(
          'PATH: ${event.selfieCaptureImage}',
        );
      }
    } else {
      debugPrint(
        ' SELFIE IMAGE PATH IS EMPTY',
      );
    }

   

    final Map<String, dynamic> jsonData = {
      'user_id': event.userId,
      'type': event.type,
      'outlet_name': event.outletName,
      'contact_person': event.contactPerson,
      'gst_no': event.gstNo,
      'mobile_no': event.mobileNo,
      'mobile_no2': event.mobileNo2,
      'email_id': event.emailId,
      'address': event.address,

      'state': event.state,
      'district': event.district,
      'taluka': event.taluka,

      'remark': event.remark,
      'city': event.city,

      'latitude': event.latitude,
      'longitude': event.longitude,

      'networkLatitude': event.networkLatitude,
      'networkLongitude': event.networkLongitude,

      'gpsLatitude': event.gpsLatitude,
      'gpsLongitude': event.gpsLongitude,

      'geoAddress': event.geoAddress,
      'differenceByAndroid': event.differenceByAndroid,

      'mobile_info': event.mobileInfo,
      'mobile_imei': event.mobileImei,

      'followUpDate': event.followUpDate,
      'followUpType': event.followUpType,

      'strNetworkInfo': event.strNetworkInfo,
      'strBatteryInfo': event.strBatteryInfo,

      'registrationType': event.registrationType,
      'flag': event.flag,
      'dealerCode': event.dealerCode,
      'dealercategory': event.dealerCategory,
      'dealeraddtionaljson': event.dealerAdditionalJson,
      'activityId': event.activityId,
    };

    // ============================================================
    // 3. PRINT NORMAL REQUEST DATA
    // ============================================================

    debugPrint('');
    debugPrint(
      '========== DEALER FOLLOW UP REQUEST ==========',
    );

    jsonData.forEach((key, value) {
      debugPrint(
        '$key: $value',
      );
    });

    debugPrint(
      '===============================================',
    );

    // ============================================================
    // 4. PRINT IMAGE INFORMATION
    // ============================================================

    debugPrint('');
    debugPrint(
      '========== DEALER SELFIE IMAGE ==========',
    );

    if (selfieImageFile != null) {
      debugPrint(
        ' SELFIE IMAGE AVAILABLE',
      );

      debugPrint(
        'IMAGE PATH: ${selfieImageFile.path}',
      );

      final bool imageExists =
          await selfieImageFile.exists();

      debugPrint(
        'IMAGE EXISTS: $imageExists',
      );

      if (imageExists) {
        final int imageSize =
            await selfieImageFile.length();

        debugPrint(
          'IMAGE SIZE: $imageSize bytes',
        );
      }
    } else {
      debugPrint(
        ' SELFIE IMAGE FILE IS NULL',
      );
    }

    debugPrint(
      '=========================================',
    );

   
    final response =
        await addLeave.addDealerFollowUp(
      jsonData,
      selfieImageFile,
    );

    // ============================================================
    // 6. PRINT RESPONSE
    // ============================================================

    debugPrint('');
    debugPrint(
      '========== DEALER FOLLOW UP RESPONSE ==========',
    );

    debugPrint(
      '$response',
    );

    debugPrint(
      '================================================',
    );

    // ============================================================
    // 7. GET RESPONSE STATUS
    // ============================================================

    final String responseStatus =
        response['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    debugPrint(
      'API STATUS: "$responseStatus"',
    );

    // ============================================================
    // 8. SUCCESS
    // ============================================================

    if (responseStatus == 'success' ||
        responseStatus == 'true' ||
        responseStatus == '1' ||
        responseStatus.startsWith('success-')) {
      debugPrint(
        '==========================================',
      );
      debugPrint(
        ' DEALER FOLLOW UP SUCCESS',
      );
      debugPrint(
        '==========================================',
      );

      emit(
        state.copyWith(
          addLeaveStatus:
              AddDealerVisitStatus.dealerAddedSuccess,
          errorMessage: null,
        ),
      );

      return;
    }

    // ============================================================
    // 9. API FAILURE
    // ============================================================

    final String errorMessage =
        response['message']?.toString() ??
        'Unable to add dealer follow up';

    debugPrint(
      '==========================================',
    );
    debugPrint(
      ' DEALER FOLLOW UP FAILED',
    );
    debugPrint(
      'MESSAGE: $errorMessage',
    );
    debugPrint(
      '==========================================',
    );

    emit(
      state.copyWith(
        addLeaveStatus:
            AddDealerVisitStatus.failure,
        errorMessage: errorMessage,
      ),
    );
  } catch (error, stackTrace) {
    // ============================================================
    // 10. EXCEPTION
    // ============================================================

    debugPrint(
      '==========================================',
    );

    debugPrint(
      ' DEALER FOLLOW UP ERROR',
    );

    debugPrint(
      'ERROR: $error',
    );

    debugPrint(
      'STACK TRACE:',
    );

    debugPrint(
      '$stackTrace',
    );

    debugPrint(
      '==========================================',
    );

    emit(
      state.copyWith(
        addLeaveStatus:
            AddDealerVisitStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}


  FutureOr<void> _onUpdateDealer(
    UpdateDealerEvent event,
    Emitter<AddDealerVisitState> emit,
  ) async {
    emit(
      state.copyWith(
        addLeaveStatus: AddDealerVisitStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      // ============================================
      // REQUEST DATA
      // ============================================
      final jsonData = <String, dynamic>{
        'outlet_id': event.outletId,

        'user_id': event.userId,
        'type': event.type,
        'outlet_name': event.outletName,
        'contact_person': event.contactPerson,
        'gst_no': event.gstNo,
        'mobile_no': event.mobileNo,
        'mobile_no2': event.mobileNo2,
        'email_id': event.emailId,
        'address': event.address,

        'state': event.state,
        'district': event.district,
        'taluka': event.taluka,

        'remark': event.remark,
        'city': event.city,

        // ============================================
        // KOTLIN UPDATE DOES NOT SEND LOCATION
        // ============================================
        'latitude': '',
        'longitude': '',

        'dealerCode': event.dealerCode,
        'activityId': event.activityId,
        'followUpType': event.followUpType,
        'registrationType': event.registrationType,
      };

      // ============================================
      // DEBUG
      // ============================================
      print('========== UPDATE DEALER REQUEST ==========');

      print(
        'outlet_id: '
        '${event.outletId}',
      );

      print(
        'user_id: '
        '${event.userId}',
      );

      print(
        'type: '
        '${event.type}',
      );

      print(
        'outlet_name: '
        '${event.outletName}',
      );

      print(
        'contact_person: '
        '${event.contactPerson}',
      );

      print(
        'gst_no: '
        '${event.gstNo}',
      );

      print(
        'mobile_no: '
        '${event.mobileNo}',
      );

      print(
        'mobile_no2: '
        '${event.mobileNo2}',
      );

      print(
        'email_id: '
        '${event.emailId}',
      );

      print(
        'address: '
        '${event.address}',
      );

      print(
        'state: '
        '${event.state}',
      );

      print(
        'district: '
        '${event.district}',
      );

      print(
        'taluka: '
        '${event.taluka}',
      );

      print(
        'remark: '
        '${event.remark}',
      );

      print(
        'city: '
        '${event.city}',
      );

      print('latitude: ');

      print('longitude: ');

      print(
        'dealerCode: '
        '${event.dealerCode}',
      );

      print(
        'activityId: '
        '${event.activityId}',
      );

      print(
        'followUpType: '
        '${event.followUpType}',
      );

      print(
        'registrationType: '
        '${event.registrationType}',
      );

      print('===========================================');

      // ============================================
      // CALL UPDATE API
      // ============================================
      final response = await addLeave.updateDealerFollowUp(jsonData);

      print('Update dealer response: $response');

      // ============================================
      // SUCCESS
      // ============================================
      final responseStatus = response['status'];

      if (responseStatus == true) {
        emit(
          state.copyWith(
            addLeaveStatus: AddDealerVisitStatus.dealerUpdateSucess,
            errorMessage: response['message']?.toString(),
          ),
        );
      } else {
        emit(
          state.copyWith(
            addLeaveStatus: AddDealerVisitStatus.failure,
            errorMessage:
                response['message']?.toString() ?? 'Unable to update dealer',
          ),
        );
      }
    } catch (error) {
      print('Update dealer error: $error');

      // ============================================
      // FAILURE
      // ============================================
      emit(
        state.copyWith(
          addLeaveStatus: AddDealerVisitStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
