import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:solufine/features/followup/domain/entities/followup_entity.dart';

class FollowupHomeWidgetService {
  FollowupHomeWidgetService._();

  // ============================================================
  // ANDROID WIDGET CONFIGURATION
  // ============================================================

  static const String providerName = 'FollowupWidgetProvider';

  static const String qualifiedProviderName =
      'com.lbm.solufine.FollowupWidgetProvider';

  // ============================================================
  // WIDGET STORAGE KEYS
  // ============================================================

  static const String keyCount = 'followup_count';

  static const String keyDateRange = 'followup_date_range';

  static const String keySelectedType = 'followup_selected_type';

  static const String keyFollowupList = 'followup_list_json';

  static const String keyName = 'followup_name';

  static const String keyType = 'followup_type';

  static const String keyDate = 'followup_date';

  static const String keyMobile = 'followup_mobile';

  static const String keyNextDate = 'followup_next_date';

  static const String keyMode = 'followup_mode';

  // ============================================================
  // UPDATE ALL FOLLOWUPS IN HOME SCREEN WIDGET
  // ============================================================

  static Future<void> updateFollowups({
    required List<FollowupEntity> followups,
    required DateTime fromDate,
    required DateTime toDate,
    required String selectedType,
  }) async {
    try {
      debugPrint('==========================================');
      debugPrint('FOLLOWUP HOME WIDGET UPDATE START');
      debugPrint('==========================================');

      // --------------------------------------------------------
      // DATE RANGE
      // --------------------------------------------------------

      final String dateRange =
          '${_formatDate(fromDate)} - ${_formatDate(toDate)}';

      debugPrint('From Date: ${_formatDate(fromDate)}');
      debugPrint('To Date: ${_formatDate(toDate)}');
      debugPrint('Selected Type: $selectedType');
      debugPrint('Total Followups: ${followups.length}');

      // --------------------------------------------------------
      // CONVERT ALL FOLLOWUPS TO JSON
      // --------------------------------------------------------

      final List<Map<String, dynamic>> followupList =
          followups.map((item) {
        return <String, dynamic>{
          'name': item.name,
          'type': item.type,
          'date': item.date,
          'time': item.time,
          'remark': item.remark,
          'mode': item.followupType,
          'nextDate': item.followupDate,
          'outletId': item.outletId,
          'farmerId': item.farmerId,
          'mobile': item.mobileNo,
        };
      }).toList();

      // --------------------------------------------------------
      // CONVERT LIST TO JSON STRING
      // --------------------------------------------------------

      final String followupJson = jsonEncode(followupList);

      debugPrint('FOLLOWUP JSON DATA: $followupJson');

      // --------------------------------------------------------
      // SAVE TOTAL COUNT
      // --------------------------------------------------------

      await HomeWidget.saveWidgetData<int>(
        keyCount,
        followups.length,
      );

      // --------------------------------------------------------
      // SAVE DATE RANGE
      // --------------------------------------------------------

      await HomeWidget.saveWidgetData<String>(
        keyDateRange,
        dateRange,
      );

      // --------------------------------------------------------
      // SAVE SELECTED DEALER / FARMER TYPE
      // --------------------------------------------------------

      await HomeWidget.saveWidgetData<String>(
        keySelectedType,
        selectedType,
      );

      // --------------------------------------------------------
      // SAVE COMPLETE FOLLOWUP LIST
      // --------------------------------------------------------

      await HomeWidget.saveWidgetData<String>(
        keyFollowupList,
        followupJson,
      );

      // --------------------------------------------------------
      // SAVE FIRST RECORD FOR LEGACY WIDGET SUPPORT
      // --------------------------------------------------------

      if (followups.isNotEmpty) {
        final FollowupEntity firstItem = followups.first;

        await HomeWidget.saveWidgetData<String>(
          keyName,
          firstItem.name,
        );

        await HomeWidget.saveWidgetData<String>(
          keyType,
          firstItem.type,
        );

        await HomeWidget.saveWidgetData<String>(
          keyDate,
          firstItem.date,
        );

        await HomeWidget.saveWidgetData<String>(
          keyMobile,
          firstItem.mobileNo,
        );

        await HomeWidget.saveWidgetData<String>(
          keyNextDate,
          firstItem.followupDate,
        );

        await HomeWidget.saveWidgetData<String>(
          keyMode,
          firstItem.followupType,
        );
      } else {
        await HomeWidget.saveWidgetData<String>(
          keyName,
          'No upcoming followups',
        );

        for (final String key in [
          keyType,
          keyDate,
          keyMobile,
          keyNextDate,
          keyMode,
        ]) {
          await HomeWidget.saveWidgetData<String>(
            key,
            '',
          );
        }
      }

      // --------------------------------------------------------
      // REFRESH ANDROID HOME SCREEN WIDGET
      // --------------------------------------------------------

      await _refreshWidget();

      debugPrint('==========================================');
      debugPrint('FOLLOWUP HOME WIDGET UPDATED SUCCESSFULLY');
      debugPrint('Total Records: ${followups.length}');
      debugPrint('Selected Type: $selectedType');
      debugPrint('Date Range: $dateRange');
      debugPrint('==========================================');
    } catch (e, stackTrace) {
      debugPrint('FOLLOWUP HOME WIDGET UPDATE ERROR: $e');

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  // ============================================================
  // REFRESH WIDGET
  // ============================================================

  static Future<void> _refreshWidget() async {
    await HomeWidget.updateWidget(
      qualifiedAndroidName: qualifiedProviderName,
    );

    debugPrint('Android Followup widget refresh requested');
  }

  // ============================================================
  // REQUEST ADD WIDGET TO HOME SCREEN
  // ============================================================

  static Future<void> requestWidget() async {
    try {
      debugPrint('Checking Android widget pin support');

      final bool? isSupported =
          await HomeWidget.isRequestPinWidgetSupported();

      debugPrint('Widget Pin Supported: $isSupported');

      if (isSupported != true) {
        debugPrint(
          'Widget pinning not supported by launcher. '
          'Please add widget manually.',
        );

        return;
      }

      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: qualifiedProviderName,
      );

      debugPrint('Widget pin request submitted');
    } catch (e, stackTrace) {
      debugPrint('Widget pin request error: $e');

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // CLEAR ALL WIDGET DATA ON LOGOUT
  // ============================================================

  static Future<void> clearWidget() async {
    try {
      debugPrint('Clearing Followup Home Widget Data');

      // --------------------------------------------------------
      // RESET TOTAL COUNT
      // --------------------------------------------------------

      await HomeWidget.saveWidgetData<int>(
        keyCount,
        0,
      );

      // --------------------------------------------------------
      // CLEAR COMPLETE FOLLOWUP LIST
      // --------------------------------------------------------

      await HomeWidget.saveWidgetData<String>(
        keyFollowupList,
        '[]',
      );

      // --------------------------------------------------------
      // CLEAR DATE RANGE AND SELECTED TYPE
      // --------------------------------------------------------

      await HomeWidget.saveWidgetData<String>(
        keyDateRange,
        '',
      );

      await HomeWidget.saveWidgetData<String>(
        keySelectedType,
        '',
      );

      // --------------------------------------------------------
      // CLEAR FIRST FOLLOWUP DETAILS
      // --------------------------------------------------------

      await HomeWidget.saveWidgetData<String>(
        keyName,
        'No upcoming followups',
      );

      for (final String key in [
        keyType,
        keyDate,
        keyMobile,
        keyNextDate,
        keyMode,
      ]) {
        await HomeWidget.saveWidgetData<String>(
          key,
          '',
        );
      }

      // --------------------------------------------------------
      // REFRESH WIDGET AFTER LOGOUT
      // --------------------------------------------------------

      await _refreshWidget();

      debugPrint('Followup Home Widget Data Cleared');
    } catch (e, stackTrace) {
      debugPrint('Clear widget error: $e');

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }
}
