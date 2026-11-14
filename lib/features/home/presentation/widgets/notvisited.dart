import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/features/home/doman/home_entity/homevisit_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class NotVisitedCard extends StatelessWidget {
  final HomeVisitEntity? homeData;
  const NotVisitedCard(this.homeData, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: context.appPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.location_off_outlined,
              size: 20.sp,
              color: context.appPrimary,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not Visited',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: context.appOnCard,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'In Last 30 Days',
                  style: AppTextStyles.caption.copyWith(
                    color: context.appSubText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: _statItem(
              context,
              title: 'Dealers',
              value: homeData?.lastThirNotVisitDealer ?? '0',
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            flex: 3,
            child: _statItem(
              context,
              title: 'Farmers',
              value: homeData?.lastThirNotVisitFarmer ?? '0',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.appInputBackground,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(color: context.appSubText),
          ),
          SizedBox(height: 2.h),
          Text(
            value.isEmpty ? '0' : value,
            style: AppTextStyles.cardTitle.copyWith(color: context.appPrimary),
          ),
        ],
      ),
    );
  }
}
