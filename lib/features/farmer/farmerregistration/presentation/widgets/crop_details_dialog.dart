import 'dart:convert';

import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/app_toast.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/crop_entity.dart';
import 'package:solufine/features/farmer/farmerregistration/domain/entity/irrigation_entity.dart'
    show IrrigationEntity;
import 'package:solufine/features/farmer/farmerregistration/domain/entity/selected_crop_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class CropDetailsDialog extends StatefulWidget {
  final List<CropEntity> cropList;
  final List<IrrigationEntity> irrigationList;
  final List<SelectedCropDetail> existingSelections;

  const CropDetailsDialog({
    super.key,
    required this.cropList,
    required this.irrigationList,
    required this.existingSelections,
  });

  @override
  State<CropDetailsDialog> createState() => _CropDetailsDialogState();
}

class _CropDetailsDialogState extends State<CropDetailsDialog> {
  final Map<String, bool> _selected = {};

  final Map<String, TextEditingController> _acreControllers = {};

  final Map<String, DateTime?> _dates = {};

  final Map<String, String?> _irrigationIds = {};

  @override
  void initState() {
    super.initState();

    for (final crop in widget.cropList) {
      final existing = widget.existingSelections
          .where((item) => item.cropId == crop.fldCropId)
          .firstOrNull;

      _selected[crop.fldCropId] = existing != null;

      _acreControllers[crop.fldCropId] = TextEditingController(
        text: existing?.acre ?? '',
      );

      _dates[crop.fldCropId] = existing?.date;

      _irrigationIds[crop.fldCropId] = existing?.irrigationId;
    }
  }

  @override
  void dispose() {
    for (final controller in _acreControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.90.sh),
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(12.w),
                itemCount: widget.cropList.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final crop = widget.cropList[index];

                  return _buildCropItem(crop);
                },
              ),
            ),

            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: context.appPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Row(
        children: [
          Icon(Icons.grass, color: context.appOnPrimary, size: 25.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Select Crop Details',
              style: AppTextStyles.dialogTitle.copyWith(
                color: context.appOnPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.close, color: context.appOnPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildCropItem(CropEntity crop) {
    final cropId = crop.fldCropId;
    final isSelected = _selected[cropId] ?? false;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isSelected
            ? Color.alphaBlend(
                context.appPrimary.withValues(alpha: 0.1),
                context.appCard,
              )
            : context.appCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? context.appPrimary : context.appBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: context.appPrimary,
                onChanged: (value) {
                  setState(() {
                    _selected[cropId] = value ?? false;
                  });
                },
              ),

              Expanded(
                child: Text(
                  crop.fldCropName,
                  style: AppTextStyles.listTitle.copyWith(
                    color: context.appOnCard,
                  ),
                ),
              ),
            ],
          ),

          if (isSelected) ...[
            SizedBox(height: 10.h),

            _buildDateField(crop),

            SizedBox(height: 10.h),

            _buildAcreField(crop),

            SizedBox(height: 10.h),

            _buildIrrigationDropdown(crop),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField(CropEntity crop) {
    final date = _dates[crop.fldCropId];

    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        if (selectedDate != null) {
          setState(() {
            _dates[crop.fldCropId] = selectedDate;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: Border.all(color: context.appBorder),
          borderRadius: BorderRadius.circular(10.r),
          color: context.appCard,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: context.appPrimary),

            SizedBox(width: 10.w),

            Expanded(
              child: Text(
                date == null ? 'Select Showing Date' : _formatDate(date),
                style: AppTextStyles.body.copyWith(
                  color: date == null ? context.appSubText : context.appOnCard,
                ),
              ),
            ),

            Icon(Icons.keyboard_arrow_down, color: context.appSubText),
          ],
        ),
      ),
    );
  }

  Widget _buildAcreField(CropEntity crop) {
    return TextFormField(
      style: AppTextStyles.input,
      controller: _acreControllers[crop.fldCropId],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: 'Enter Acre',
        hintStyle: AppTextStyles.inputHint,
        errorStyle: AppTextStyles.inputError,
        prefixIcon: Icon(Icons.square_foot, color: context.appPrimary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: context.appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: context.appPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildIrrigationDropdown(CropEntity crop) {
    return DropdownButtonFormField<String>(
      style: AppTextStyles.input.copyWith(color: Colors.black),
      initialValue: _irrigationIds[crop.fldCropId],
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select Irrigation',
        hintStyle: AppTextStyles.inputHint.copyWith(color: Colors.black),
        errorStyle: AppTextStyles.inputError,
        prefixIcon: Icon(Icons.water_drop_outlined, color: context.appPrimary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: context.appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: context.appPrimary, width: 1.5),
        ),
      ),
      items: widget.irrigationList.map((irrigation) {
        return DropdownMenuItem<String>(
          value: irrigation.fldId,
          child: Text(irrigation.fldIrrigationName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _irrigationIds[crop.fldCropId] = value;
        });
      },
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
                side: BorderSide(color: context.appPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.button.copyWith(color: context.appPrimary),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          Expanded(
            child: ElevatedButton(
              onPressed: _addSelectedCrops,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
                backgroundColor: context.appPrimary,
                foregroundColor: context.appOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text('Add', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }

  void _addSelectedCrops() {
    final selectedCrops = widget.cropList
        .where((crop) => _selected[crop.fldCropId] == true)
        .toList();

    if (selectedCrops.isEmpty) {
      _showError('Please select at least one crop');
      return;
    }

    final List<SelectedCropDetail> result = [];

    for (final crop in selectedCrops) {
      final cropId = crop.fldCropId;

      final date = _dates[cropId];

      final acre = _acreControllers[cropId]?.text.trim() ?? '';

      final irrigationId = _irrigationIds[cropId];

      if (date == null) {
        _showError('Please select date for ${crop.fldCropName}');
        return;
      }

      if (acre.isEmpty) {
        _showError('Please enter acre for ${crop.fldCropName}');
        return;
      }

      if (irrigationId == null || irrigationId.isEmpty) {
        _showError('Please select irrigation for ${crop.fldCropName}');
        return;
      }

      final irrigation = widget.irrigationList
          .where((item) => item.fldId == irrigationId)
          .firstOrNull;

      if (irrigation == null) {
        _showError('Please select irrigation for ${crop.fldCropName}');
        return;
      }

      result.add(
        SelectedCropDetail(
          cropId: crop.fldCropId,
          cropName: crop.fldCropName,
          date: date,
          acre: acre,
          irrigationId: irrigation.fldId,
          irrigationName: irrigation.fldIrrigationName,
        ),
      );
    }

    assert(() {
      debugPrint(jsonEncode(result.map((crop) => crop.toJson()).toList()));
      return true;
    }());

    Navigator.pop(context, result);
  }

  void _showError(String message) {
    AppToast.error(message);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(message),
    //     backgroundColor: context.appError,
    //   ),
    // );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
