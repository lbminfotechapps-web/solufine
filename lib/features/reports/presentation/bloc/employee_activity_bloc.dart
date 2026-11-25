import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solufine/features/reports/domain/entities/invoice_entity.dart';
import 'package:solufine/features/reports/domain/entities/product_analysis_report.dart';

import '../../domain/usecases/get_employee_activity_details.dart';

import 'employee_activity_event.dart';
import 'employee_activity_state.dart';

class EmployeeActivityBloc
    extends Bloc<EmployeeActivityEvent, EmployeeActivityState> {
  final GetEmployeeActivityDetails getEmployeeActivityDetails;

  EmployeeActivityBloc(this.getEmployeeActivityDetails)
    : super(const EmployeeActivityState()) {
    on<GetEmployeeActivityEvent>(_getEmployeeActivity);
    on<GetTargetSummaryEvent>(_onGetTargetSummary);
    on<ClearTargetSummary>(_onClearTargetSummary);
    on<GetProductAnalysisEvent>(_onGetProductanalysis);
  }

  Future<void> _getEmployeeActivity(
    GetEmployeeActivityEvent event,
    Emitter<EmployeeActivityState> emit,
  ) async {
    print('');
    print('========================================');
    print('BLOC → EMPLOYEE ACTIVITY');
    print('========================================');

    print('User ID     : ${event.userId}');

    print('Search Date : ${event.searchDate}');

    print('Log User ID : ${event.logUserId}');

    print('========================================');

    emit(
      state.copyWith(
        status: EmployeeActivityStatus.loading,
        activities: [],
        clearErrorMessage: true,
      ),
    );

    try {
      final activities = await getEmployeeActivityDetails(
        userId: event.userId,
        searchDate: event.searchDate,
        logUserId: event.logUserId,
      );

      print('');
      print('========================================');
      print('EMPLOYEE ACTIVITY SUCCESS');
      print('========================================');

      print('Total records : ${activities.length}');

      print('========================================');

      emit(
        state.copyWith(
          status: EmployeeActivityStatus.success,
          activities: activities,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      print('');
      print('========================================');
      print('EMPLOYEE ACTIVITY FAILURE');
      print('========================================');

      print(e);

      print('========================================');

      emit(
        state.copyWith(
          status: EmployeeActivityStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetTargetSummary(
    GetTargetSummaryEvent event,
    Emitter<EmployeeActivityState> emit,
  ) async {
    if (state.status == EmployeeActivityStatus.loading) {
      return;
    }

    // STEP 3: Set loading state.
    emit(
      state.copyWith(status: EmployeeActivityStatus.loading, errorMessage: ''),
    );

    try {
      debugPrint('========== GET Target Summary ==========');
      debugPrint('Date: ${event.date}');
      debugPrint('User Id: ${event.userId}');
      debugPrint('Amount type: ${event.amountType}');

      // STEP 4: Call UseCase.
      final InvoiceEntity response = await getEmployeeActivityDetails
          .getTargetSummary(
            date: event.date,
            userId: event.userId,
            amountType: event.amountType,
          );

      debugPrint('========== Target Summary RESPONSE ==========');
      debugPrint('Status: ${response.status}');
      debugPrint('Message: ${response.message}');
      debugPrint('Response: ${response}');

      // STEP 5: Handle API failure.
      if (!response.status) {
        emit(
          state.copyWith(
            status: EmployeeActivityStatus.failure,
            errorMessage: response.message.isNotEmpty
                ? response.message
                : 'Unable to fetch Target Summary details',
          ),
        );
        return;
      }

      // STEP 6: Handle API success.
      emit(
        state.copyWith(
          status: EmployeeActivityStatus.success,
          invoiceEntity: response,
          errorMessage: response.message.isNotEmpty
              ? response.message
              : 'Target Summary fetched successfully',
        ),
      );

      debugPrint('Target Summary fetched successfully');
    } catch (e, stackTrace) {
      debugPrint('Get Target Summary Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(
        state.copyWith(
          status: EmployeeActivityStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  FutureOr<void> _onClearTargetSummary(
    ClearTargetSummary event,
    Emitter<EmployeeActivityState> emit,
  ) {
    emit(state.copyWith(invoiceEntity: null));
  }

  FutureOr<void> _onGetProductanalysis(
    GetProductAnalysisEvent event,
    Emitter<EmployeeActivityState> emit,
  ) async {
    emit(
      state.copyWith(status: EmployeeActivityStatus.loading, errorMessage: ''),
    );

    try {
      final ProductAnalysisReport response = await getEmployeeActivityDetails
          .getProductAnalysisReport(
            event.fromDate,
            event.toDate,
            event.userId,
            event.outletId,
            event.productId,
            event.packing,
          );

      debugPrint('========== Product Analysis RESPONSE ==========');
      debugPrint('Status: ${response.status}');
      debugPrint('Message: ${response.message}');
      debugPrint('Response: ${response}');

      if (!response.status) {
        emit(
          state.copyWith(
            status: EmployeeActivityStatus.failure,
            errorMessage: response.message.isNotEmpty
                ? response.message
                : 'Unable to fetch Product analysis details',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: EmployeeActivityStatus.success,
          productAnalysisReport: response,
          errorMessage: response.message.isNotEmpty
              ? response.message
              : 'Product analysis fetched successfully',
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Product analysis Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(
        state.copyWith(
          status: EmployeeActivityStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
