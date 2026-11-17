import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/theme/typography/app_typography_extension.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _districtExpanded = false;
  bool _talukaExpanded = false;

  bool _isLoading = true;
  String _appVersion = '';
  String _buildNumber = '';
  String _name = '';
  String _mobile = '';
  String _email = '';
  String _state = '';
  String _district = '';
  String _taluka = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });

      debugPrint('APP VERSION: $_appVersion');
      debugPrint('BUILD NUMBER: $_buildNumber');
    } catch (e) {
      debugPrint('APP VERSION ERROR: $e');
    }
  }
  // ============================================================
  // LOAD USER DATA FROM SECURE STORAGE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      final userDataString = await _storage.read(key: 'user_data');

      debugPrint('PROFILE USER DATA: $userDataString');

      if (userDataString == null || userDataString.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> userData = jsonDecode(userDataString);

      debugPrint('PROFILE JSON: $userData');

      setState(() {
        _name = _getValue(userData, [
          'user_name',
          'userName',
          'name',
          'fld_user_name',
          'fld_name',
        ]);

        _mobile = _getValue(userData, [
          'mobile',
          'mobile_no',
          'mobileNo',
          'phone',
          'phone_no',
          'fld_mobile',
          'fld_mobile_no',
        ]);

        _email = _getValue(userData, [
          'email',
          'email_id',
          'user_email',
          'fld_email',
        ]);

        _state = _getValue(userData, [
          'States',
          'state_name',
          'stateName',
          'fld_state',
          'fld_state_name',
        ]);

        _district = _getValue(userData, [
          'Districts',
          'district_name',
          'districtName',
          'fld_district',
          'fld_district_name',
        ]);

        _taluka = _getValue(userData, [
          'Taluka',
          'taluka_name',
          'talukaName',
          'fld_taluka',
          'fld_taluka_name',
        ]);

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // VALUE READER
  // ============================================================

  String _getValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String _getInitials() {
    if (_name.trim().isEmpty) {
      return 'U';
    }

    final words = _name.trim().split(' ').where((e) => e.isNotEmpty).toList();

    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }

    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: CustomAppBar(
        title: 'My Profile',
        showBackButton: true,
        onBackTap: () {
          context.go(AppRouter.home);
        },
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: context.primaryColor),
            )
          : RefreshIndicator(
              color: context.primaryColor,
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    _buildProfileHeader(),

                    SizedBox(height: 16.h),

                    _buildDetailsCard(),

                    SizedBox(height: 20.h),

                    CustomButton(
                      text: 'Change Password',
                      backgroundColor: context.primaryColor,
                      textColor: context.onPrimaryColor,
                      icon: Icon(Icons.lock_outline_rounded, size: 20.sp),
                      onPressed: () {
                        context.push('/changePassword');
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Icon
          Container(
            width: 88.w,
            height: 88.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.primaryColor.withValues(alpha: 0.10),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.20),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: context.appTextStyles.displayMedium.copyWith(
                  color: context.primaryColor,
                ),
              ),
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            _name.isEmpty ? 'User' : _name,
            textAlign: TextAlign.center,
            style: context.appTextStyles.headingLarge,
          ),

          SizedBox(height: 5.h),

          if (_mobile.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 14.sp,
                  color: context.secondaryTextColor,
                ),
                SizedBox(width: 5.w),
                Text(_mobile, style: context.appTextStyles.cardSubtitle),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS CARD
  // ============================================================

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: context.appTextStyles.cardTitle.copyWith(
              color: context.primaryTextColor,
            ),
          ),

          SizedBox(height: 12.h),

          _profileItem(Icons.person_outline_rounded, 'Full Name', _name),

          _divider(),

          _profileItem(Icons.phone_outlined, 'Mobile Number', _mobile),

          _divider(),

          _profileItem(Icons.email_outlined, 'Email Address', _email),

          _divider(),

          _profileItem(Icons.map_outlined, 'State', _state),

          _divider(),

          _profileItem(
            Icons.location_city_outlined,
            'District',
            _district,
            expandable: true,
            isExpanded: _districtExpanded,
            onTap: () {
              setState(() {
                _districtExpanded = !_districtExpanded;
              });
            },
          ),

          _divider(),

          _profileItem(
            Icons.place_outlined,
            'Taluka',
            _taluka,
            expandable: true,
            isExpanded: _talukaExpanded,
            onTap: () {
              setState(() {
                _talukaExpanded = !_talukaExpanded;
              });
            },
          ),

          _divider(),

          _profileItem(
            Icons.info_outline_rounded,
            'App Version',
            _appVersion.isEmpty ? '' : '$_appVersion ($_buildNumber)',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE ITEM
  // ============================================================

  Widget _profileItem(
    IconData icon,
    String title,
    String value, {
    bool expandable = false,
    bool isExpanded = false,
    VoidCallback? onTap,
  }) {
    final bool hasValue = value.trim().isNotEmpty;

    return InkWell(
      onTap: expandable && hasValue ? onTap : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: context.primaryColor, size: 20.sp),
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.appTextStyles.labelSmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),

                  SizedBox(height: 3.h),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Text(
                      hasValue ? value : 'Not available',
                      maxLines: expandable ? (isExpanded ? 4 : 2) : 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.bodyMedium,
                    ),
                  ),

                  if (expandable && hasValue)
                    Padding(
                      padding: EdgeInsets.only(top: 3.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isExpanded ? 'Show less' : 'Show more',
                            style: context.appTextStyles.helperText.copyWith(
                              color: context.primaryColor,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 15.sp,
                            color: context.primaryColor,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, thickness: 0.7, color: context.borderColor);
  }
}
