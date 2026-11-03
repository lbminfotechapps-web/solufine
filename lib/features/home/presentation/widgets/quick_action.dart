import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'dart:convert';

import 'package:solufine/core/di/auth_di.dart';
import 'package:solufine/core/location_tracking/app_database.dart';
import 'package:solufine/core/location_tracking/location_repository.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/app_toast.dart';
import 'package:solufine/core/utility/tab_refresh.dart';

import 'package:solufine/core/utility/appdialog.dart';
import 'package:solufine/core/utility/device_info_util.dart';
import 'package:solufine/core/utility/location_util.dart';
import 'package:solufine/core/utility/widgets/custom_card.dart';
import 'package:solufine/core/utility/widgets/custom_loader.dart';
import 'package:solufine/features/home/doman/home_entity/menu_entity.dart';
import 'package:solufine/features/home/doman/home_entity/punch_stat_entity.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_state.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show ReadContext, BlocListener;
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'voice_menu_dialog.dart';

class QuickAccessItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const QuickAccessItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
  });
}

class QuickAccessSection extends StatefulWidget {
  final List<MenuEntity> menus;
  final PunchStatEntity? punchStat;

  const QuickAccessSection({super.key, required this.menus, this.punchStat});

  @override
  State<QuickAccessSection> createState() => _QuickAccessSectionState();
}

class _QuickAccessSectionState extends State<QuickAccessSection> {
  static const int initialItemCount = 11;
  static const reportMenuIds = ['32', '63', '65', '64', '57', '86', '87', '89'];
  static const informationMenuIds = ['22', '23', '60', '19', '20', '56', '21'];
  static const marketingMenuIds = ['35', '40','41', '42', '36','97','98','37'];


  int? userId;
  int visibleItemCount = initialItemCount;
  bool _showAllReports = false;

  // ============================================================
  // SEARCH
  // ============================================================
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  GoRouterDelegate? _menuRouterDelegate;
  Uri? _lastMenuLocation;
  bool _voiceMenuOpen = false;
  bool _shareLocationPending = false;

  Future<void> _openVoiceMenu() async {
    if (_voiceMenuOpen) return;
    _voiceMenuOpen = true;
    FocusScope.of(context).unfocus();
    try {
      final menu = await showDialog<MenuEntity>(
        context: context,
        builder: (_) => VoiceMenuDialog(
          menus: widget.menus.map((menu) {
            if (menu.menuId != '17') return menu;
            return MenuEntity(
              menuId: menu.menuId,
              menuName: widget.punchStat?.inOutStatus == '0'
                  ? 'In Punch'
                  : 'Out Punch',
              iconImage: menu.iconImage,
            );
          }).toList(),
        ),
      );
      if (!mounted || menu == null) return;
      final currentMenus = widget.menus.where(
        (item) => item.menuId == menu.menuId,
      );
      if (currentMenus.isNotEmpty) {
        await _onMenuTap(context, currentMenus.first);
      }
    } finally {
      _voiceMenuOpen = false;
    }
  }

  Future<void> _submitShareLocation({required String remark}) async {
    final userData = await SecureStorage.instance.getUserData();

    debugPrint('User data: $userData');

    userId = int.tryParse(userData?['user_id']?.toString() ?? '');

    if (userId == null) {
      debugPrint('SHARE LOCATION ERROR: User ID not found');
      throw Exception('User information not found');
    }

    debugPrint('User ID: $userId');

    // ============================================
    // BATTERY
    // ============================================

    final batteryInfo = await DeviceInfoUtil.instance.getBatteryInfo();

    debugPrint('Battery Info: $batteryInfo');

    // ============================================
    // NETWORK
    // ============================================

    final networkInfo = await DeviceInfoUtil.instance.getNetworkInfo();

    debugPrint('Network Info: $networkInfo');

    // ============================================
    // LOCATION
    // ============================================

    final position = await LocationUtil.instance.getCurrentLocation();

    String latitude = '';
    String longitude = '';
    String address = '';

    if (position != null) {
      latitude = position.latitude.toString();
      longitude = position.longitude.toString();

      debugPrint('Latitude: $latitude');
      debugPrint('Longitude: $longitude');

      address = await LocationUtil.instance.getAddress(
        position.latitude,
        position.longitude,
      );

      debugPrint('Geo Address: $address');
    } else {
      debugPrint('Location: NOT AVAILABLE');
    }

    // ============================================
    // SHARE LOCATION EVENT DATA
    // ============================================

    const inOutStatus = '3';
    const differenceByAndroid = '0.0';
    const locationHistoryString = '';

    const startingClosingKmAmount = '';
    const vehicleTypeId = '';
    const route = '';

    const activityId = '27';

    debugPrint('========== FINAL SHARE LOCATION DATA ==========');

    debugPrint('user_id: $userId');
    debugPrint('in_out_status: $inOutStatus');

    debugPrint('differenceByAndroid: $differenceByAndroid');

    debugPrint('locationHistoryString: $locationHistoryString');

    debugPrint('strBatteryInfo: $batteryInfo');
    debugPrint('strNetworkInfo: $networkInfo');

    debugPrint('pinRemark: $remark');

    debugPrint(
      'strStartingClosingKmAmount: '
      '$startingClosingKmAmount',
    );

    debugPrint('strVehicleTypeId: $vehicleTypeId');
    debugPrint('route: $route');

    debugPrint('latitude: $latitude');
    debugPrint('longitude: $longitude');

    debugPrint('networkLatitude: $latitude');
    debugPrint('networkLongitude: $longitude');

    debugPrint('gpsLatitude: $latitude');
    debugPrint('gpsLongitude: $longitude');

    debugPrint('geoAddress: $address');

    debugPrint('activityId: $activityId');

    debugPrint('==============================================');

    if (!mounted) {
      return;
    }

    // ============================================
    // DISPATCH SHARE LOCATION EVENT
    // ============================================

    _shareLocationPending = true;
    context.read<QuickAcessBloc>().add(
      ShareLocationEvent(
        userId: userId!,

        inOutStatus: inOutStatus,

        differenceByAndroid: differenceByAndroid,

        locationHistoryString: locationHistoryString,

        batteryInfo: batteryInfo,

        networkInfo: networkInfo,

        pinRemark: remark,

        startingClosingKmAmount: startingClosingKmAmount,

        vehicleTypeId: vehicleTypeId,

        route: route,

        latitude: latitude,

        longitude: longitude,

        networkLatitude: latitude,

        networkLongitude: longitude,

        gpsLatitude: latitude,

        gpsLongitude: longitude,

        geoAddress: address,

        startingKmImage: '',

        closingKmImage: '',

        activityId: activityId,
      ),
    );

    debugPrint('SHARE LOCATION EVENT DISPATCHED SUCCESSFULLY');

    debugPrint('========================================');
  }

  @override
  void initState() {
    super.initState();
    TabRefresh.home.addListener(_resetMenuSearch);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = GoRouter.of(context).routerDelegate;
    if (identical(_menuRouterDelegate, delegate)) return;

    _menuRouterDelegate?.removeListener(_onMenuRouteChanged);
    _menuRouterDelegate = delegate;
    _lastMenuLocation = delegate.currentConfiguration.isEmpty
        ? null
        : delegate.state.uri;
    delegate.addListener(_onMenuRouteChanged);
  }

  void _onMenuRouteChanged() {
    final delegate = _menuRouterDelegate;
    if (!mounted || delegate == null || delegate.currentConfiguration.isEmpty) {
      return;
    }

    final location = delegate.state.uri;
    if (_lastMenuLocation == location) return;
    _lastMenuLocation = location;

    // Navigation can notify while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resetMenuSearch();
    });
  }

  void _resetMenuSearch() {
    if (_searchController.text.isEmpty && _searchText.isEmpty) return;

    _searchController.clear();
    setState(() {
      _searchText = '';
    });
  }

  @override
  void dispose() {
    TabRefresh.home.removeListener(_resetMenuSearch);
    _menuRouterDelegate?.removeListener(_onMenuRouteChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuickAccessSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.menus != widget.menus) {
      visibleItemCount = initialItemCount;
      _showAllReports = false;
    }
  }

  void _showMore() {
    setState(() {
      visibleItemCount = widget.menus.length;
    });
  }

  Future<String> _getStoredLocations() async {
    try {
      final int? parsedUserId = userId;

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
    if (widget.menus.isEmpty) {
      return const SizedBox.shrink();
    }

    final actionMenus = widget.menus
        .where(
          (menu) =>
              !informationMenuIds.contains(menu.menuId) &&
              !reportMenuIds.contains(menu.menuId) &&
              !marketingMenuIds.contains(menu.menuId),
             
        )
        .toList();

    final informationMenus =
        widget.menus
            .where((menu) => informationMenuIds.contains(menu.menuId))
            .toList()
          ..sort(
            (a, b) => informationMenuIds
                .indexOf(a.menuId)
                .compareTo(informationMenuIds.indexOf(b.menuId)),
          );

    final reportMenus =
        widget.menus
            .where((menu) => reportMenuIds.contains(menu.menuId))
            .toList()
          ..sort(
            (a, b) => reportMenuIds
                .indexOf(a.menuId)
                .compareTo(reportMenuIds.indexOf(b.menuId)),
          );

         

    final marketingMenus =
        widget.menus
            .where((menu) => marketingMenuIds.contains(menu.menuId))
            .toList()
          ..sort(
            (a, b) => marketingMenuIds
                .indexOf(a.menuId)
                .compareTo(marketingMenuIds.indexOf(b.menuId)),
          );


    final hasMore = visibleItemCount < actionMenus.length;

    return BlocListener<QuickAcessBloc, QuickAccessState>(
      listenWhen: (previous, current) =>
          _shareLocationPending &&
          previous.quickAccessStatus != current.quickAccessStatus &&
          (current.quickAccessStatus == QuickAccessStatus.locationAddedSucces ||
              current.quickAccessStatus == QuickAccessStatus.failure),
      listener: (context, state) async {
        _shareLocationPending = false;
        // ==========================================
        // SHARE LOCATION SUCCESS
        // ==========================================
        if (state.quickAccessStatus == QuickAccessStatus.locationAddedSucces) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          final String? dailyTranId = state.dailyTranId;
          if (userId == null) {
            debugPrint('STORE TRACK LOCATION NOT CALLED: userId is null');
            return;
          }

          if (dailyTranId == null || dailyTranId.isEmpty) {
            debugPrint(
              'STORE TRACK LOCATION NOT CALLED: dailyTranId is null/empty',
            );
            return;
          }

          final String strAllLocations = await _getStoredLocations();

          if (!context.mounted) return;

          if (strAllLocations == '[]') {
            debugPrint('STORE TRACK LOCATION NOT CALLED: No stored locations');
            return;
          }

          context.read<QuickAcessBloc>().add(
            StoreTrackLocation(
              userId.toString(),
              state.dailyTranId.toString(),
              strAllLocations,
            ),
          );
          AppToast.success('Location shared successfully');
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Location shared successfully'),
          //     backgroundColor: Colors.green,
          //     behavior: SnackBarBehavior.floating,
          //     duration: Duration(seconds: 2),
          //   ),
          // );
        }

        // ==========================================
        // SHARE LOCATION FAILURE
        // ==========================================
        if (state.quickAccessStatus == QuickAccessStatus.failure &&
            context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Failed to share location',
                style: AppTextStyles.body,
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },

      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // TITLE + SEARCH
            // =====================================================
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      debugPrint('Menu clicked');

                      // Add your navigation or function here
                      context.push('/plotmeasurement');
                    },
                    child: Text('Menu', style: AppTextStyles.headingLarge),
                  ),
                ),

                SizedBox(width: 10.w),

                SizedBox(
                  width: 170.w,
                  height: 42.h,
                  child: TextField(
                    style: AppTextStyles.input,
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search menu',
                      hintStyle: AppTextStyles.inputHint.copyWith(
                        color: context.appSubText,
                      ),

                      prefixIcon: Icon(Icons.search_rounded, size: 20.sp),

                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _searchText = '';
                                });
                              },
                              icon: Icon(Icons.close_rounded, size: 18.sp),
                            )
                          : null,

                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),

                      filled: true,
                      fillColor: context.appInputBackground,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: context.appBorder,
                          width: 1,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8.w),
                Tooltip(
                  message: 'Open a menu with your voice',
                  child: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: context.appBackgroundGradient,
                      boxShadow: [
                        BoxShadow(
                          color: context.appPrimary.withValues(alpha: 0.25),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _openVoiceMenu,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.mic_rounded,
                        color: context.appOnPrimary,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // =====================================================
            // MENU GRID
            // =====================================================
            LayoutBuilder(
              builder: (context, constraints) {
                const crossAxisCount = 4;

                bool matchesSearch(MenuEntity menu) =>
                    menu.menuName.toLowerCase().contains(_searchText);
                final filteredActions = actionMenus
                    .where(matchesSearch)
                    .toList();
                final filteredInformation = informationMenus
                    .where(matchesSearch)
                    .toList();
                final filteredReports = reportMenus
                    .where(matchesSearch)
                    .toList();
                 
                final filteredMarketing = marketingMenus
                    .where(matchesSearch)
                    .toList();

                final visibleReports = _searchText.isNotEmpty || _showAllReports
                    ? filteredReports
                    : filteredReports.take(5).toList();
                final visibleActions = _searchText.isNotEmpty
                    ? filteredActions
                    : filteredActions.take(visibleItemCount).toList();
                if (visibleActions.isEmpty &&
                    filteredReports.isEmpty &&
                    filteredMarketing.isEmpty &&
                    filteredInformation.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.h),
                    child: Center(
                      child: Text(
                        'No menu found',
                        style: AppTextStyles.dialogBody,
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (visibleActions.isNotEmpty) ...[
                      _groupTitle('Quick Access'),
                      _menuGrid(
                        visibleActions,
                        crossAxisCount,
                        showMore: _searchText.isEmpty && hasMore,
                      ),
                    ],

                    if (filteredReports.isNotEmpty) ...[
                      SizedBox(height: 18.h),
                      Divider(color: context.appBorder),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _groupTitle('Reports'),
                          if (_searchText.isEmpty && filteredReports.length > 5)
                            Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _showAllReports = !_showAllReports;
                                }),
                                child: Text(
                                  _showAllReports ? 'See less' : 'See all',
                                  style: AppTextStyles.button,
                                ),
                              ),
                            ),
                        ],
                      ),
                      _menuGrid(visibleReports, crossAxisCount),
                    ],


                    if (filteredMarketing.isNotEmpty) ...[
                      SizedBox(height: 18.h),
                      Divider(color: context.appBorder),
                      SizedBox(height: 10.h),
                      _groupTitle('Marketing'),
                      _menuGrid(filteredMarketing, crossAxisCount),
                    ],

                    if (filteredInformation.isNotEmpty) ...[
                      if (visibleActions.isNotEmpty ||
                          filteredReports.isNotEmpty ||
                          filteredMarketing.isNotEmpty) ...[
                        SizedBox(height: 18.h),
                        Divider(color: context.appBorder),
                        SizedBox(height: 10.h),
                      ],
                      _groupTitle('Information & Support'),
                      _menuGrid(filteredInformation, crossAxisCount),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupTitle(String title) => Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: Text(
      title,
      style: AppTextStyles.cardTitle.copyWith(color: context.appPrimary),
    ),
  );

  Widget _menuGrid(
    List<MenuEntity> menus,
    int crossAxisCount, {
    bool showMore = false,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menus.length + (showMore ? 1 : 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 10.h,

        mainAxisExtent:
            72.w +
            4.h +
            MediaQuery.textScalerOf(context).scale(9.sp) * 2.8 +
            10.h,
      ),
      itemBuilder: (context, index) {
        if (showMore && index == menus.length) {
          return _MoreItem(onTap: _showMore);
        }
        final menu = menus[index];
        return QuickAccessMenuItem(
          menu: menu,
          punchStat: widget.punchStat,
          onTap: () => _onMenuTap(context, menu),
        );
      },
    );
  }

  Future<void> _onMenuTap(BuildContext context, MenuEntity menu) async {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    if (_searchText.isNotEmpty) {
      setState(() {
        _searchText = '';
      });
    }
    debugPrint(
      'Menu clicked: '
      'ID=${menu.menuId}, '
      'Name=${menu.menuName}',
    );
    final status = widget.punchStat?.inOutStatus ?? 0;
    debugPrint('Punch status inout: ${widget.punchStat?.inOutStatus}');
    debugPrint('Punch status data: ${widget.punchStat}');

    if (menu.menuId == '17') {
      if (status == '0') {
        context.push('/punchIn', extra: widget.punchStat);
      } else if (status == '1') {
        context.push('/punchOut', extra: widget.punchStat);
      } else if (status == '2') {
        context.push('/lastPunchOut', extra: widget.punchStat);
      }
    } else if (menu.menuId == '26') {
      if (status == '1') {
        await _showShareLocationDialog(context);
      } else if (status == '2') {
        AppDialog.show(
          context: context,
          message: "Your Are Not Last Punch Out, Do You Want Continue",
          onButtonPressed: () => {
            context.push('/lastPunchOut', extra: widget.punchStat),
          },
        );
      } else {
        AppDialog.show(
          context: context,
          message: "Your Are Not Punch In, Do You Want Continue",
          onButtonPressed: () => {context.push('/punchIn')},
        );
      }
    } else if (menu.menuId == '65') {
      context.push('/notVisitDealer');
    } else if (menu.menuId == '18') {
      context.push('/scheme');
    } else if (menu.menuId == '8') {
      if (status == '1') {
        context.push('/farmers');
      } else if (status == '2') {
        AppDialog.show(
          context: context,
          message: "Your Are Not Last Punch Out, Do You Want Continue",
          onButtonPressed: () => {
            context.push('/lastPunchOut', extra: widget.punchStat),
          },
        );
      } else {
        AppDialog.show(
          context: context,
          message: "Your Are Not Punch In, Do You Want Continue",
          onButtonPressed: () => {context.push('/punchIn')},
        );
      }
    } else if (menu.menuId == '20') {
      final userData = await SecureStorage.instance.getUserData();
      final userId = userData?['user_id']?.toString();

      if (!context.mounted) return;
      // if (userId == null || userId.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('User information is not available')),
      //   );
      //   return;
      // }

      context.push('/notification', extra: userId);
    } else if (menu.menuId == '14') {
      context.push('/leaveList');
    } else if (menu.menuId == '3') {
      if (status == '1') {
        context.push('/visits');
      } else if (status == '2') {
        AppDialog.show(
          context: context,
          message: "Your Are Not Last Punch Out, Do You Want Continue",
          onButtonPressed: () => {
            context.push('/lastPunchOut', extra: widget.punchStat),
          },
        );
      } else {
        AppDialog.show(
          context: context,
          message: "Your Are Not Punch In, Do You Want Continue",
          onButtonPressed: () => {context.push('/punchIn')},
        );
      }
    } else if (menu.menuId == '2') {
      context.push('/products');
    } else if (menu.menuId == '76') {
      context.push('/addStock');
    } else if (menu.menuId == '64') {
      context.push('/topTenDealer');
    } else if (menu.menuId == '56') {
      context.push('/social');
    } else if (menu.menuId == '68') {
      context.push('/teamLeaveList');
    } else if (menu.menuId == '21') {
      context.push('/userGuide');
    } else if (menu.menuId == '22') {
      context.push('/aboutUs');
    } else if (menu.menuId == '23') {
      context.push('/contactUs');
    } else if (menu.menuId == '19') {
      context.push('/gallery');
    } else if (menu.menuId == '71') {
      context.push('/addCollection');
    } else if (menu.menuId == '72') {
      context.push('/collectionList');
    } else if (menu.menuId == '16') {
      context.push('/collectionTargetAndAchievement');
    } else if (menu.menuId == '60') {
      context.push('/cropSchedule');
    } else if (menu.menuId == '13') {
      context.push('/expenseList');
    } else if (menu.menuId == '67') {
      context.push('/teamExpenseList');
    } else if (menu.menuId == '69') {
      context.push('/placeOrder');
    } else if (menu.menuId == '77') {
      context.push('/salesReturn');
    } else if (menu.menuId == '82') {
      context.push('/salesTargetAndAchievement');
    } else if (menu.menuId == '74') {
      context.push('/orderHistoy');
    } else if (menu.menuId == '75') {
      context.push('/dispatchHistoy');
    } else if (menu.menuId == '78') {
      context.push('/salesHistoy');
    } else if (menu.menuId == '9') {
      context.push('/addExpense');
    } else if (menu.menuId == '85') {
      context.push('/selfcollectionTarget');
    } else if (menu.menuId == '84') {
      context.push('/selfAssignTargetPointWise');
    } else if (menu.menuId == '88') {
      context.push('/quickReferance');
    } else if (menu.menuId == '86') {
      context.push('/monthlyPerformanceReport');
    } else if (menu.menuId == '89') {
      context.push('/growthReport');
    } else if (menu.menuId == '87') {
      context.push('/monthlyVisitPerformanceReport');
    } else if (menu.menuId == '91') {
      context.push('/consultantDoctors');
    } 

    else if (menu.menuId == '92') {
      context.push('/plotmeasurement');
    } 

    else if (menu.menuId == '93') {
      context.push('/plantDoctor');
    } 


    else if (menu.menuId == '94') {
      context.push('/schedule');
    }

     else if (menu.menuId == '95') {
      context.push('/assignTask');
    }

     else if (menu.menuId == '96') {
      context.push('/assignTaskList');
    }

     else if (menu.menuId == '40') {
      context.push('/addActivityNewDealerDistributor');
    }

     else if (menu.menuId == '36') {
      context.push('/addFieldDayVisit');
    }

      else if (menu.menuId == '41') {
      context.push('/jeepCampaning');
    }

     else if (menu.menuId == '42') {
      context.push('/farmerCouponBooking');
    }

      else if (menu.menuId == '97') {
      context.push('/successStory');
    }

      else if (menu.menuId == '98') {
      context.push('/dsi');
    }
       else if (menu.menuId == '37') {
      context.push('/meetings');
    }


       else if (menu.menuId == '35') {
      context.push('/fieldVisitForm');
    }

    
    else if (menu.menuId == '57' ||
        menu.menuId == '63' ||
        menu.menuId == '32') {
      final userData = await SecureStorage.instance.getUserData();
      final userId = userData?['user_id']?.toString();

      if (!context.mounted) return;
      final route = switch (menu.menuId) {
        '57' => '/visitSummaryReport',
        '63' => '/empOutputReport',
        _ => '/empActivityReport',
      };

      context.push(route, extra: userId);
    }
  }

  Future<void> _showShareLocationDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final remarkController = TextEditingController();

    bool isSubmitting = false;
    final navigator = Navigator.of(context, rootNavigator: true);
    late final DialogRoute<void> route;
    route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
              contentPadding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 10.h),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: context.appPrimary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: context.appPrimary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Share Location',
                      style: AppTextStyles.headingLarge,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  style: AppTextStyles.input,
                  controller: remarkController,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Enter remark',
                    hintStyle: AppTextStyles.inputHint,
                    labelStyle: AppTextStyles.inputLabel,
                    errorStyle: AppTextStyles.inputError,
                    labelText: 'Remark',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(
                        left: 12.w,
                        right: 8.w,
                        top: 12.h,
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: context.appPrimary,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: context.appBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: context.appPrimary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter remark';
                    }

                    return null;
                  },
                ),
              ),
              actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          FocusScope.of(dialogContext).unfocus();
                          Navigator.of(dialogContext).pop();
                        },
                  child: Text('Cancel', style: AppTextStyles.button),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appPrimary,
                    foregroundColor: context.appOnPrimary,
                    disabledBackgroundColor: context.appPrimary.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final remark = remarkController.text.trim();

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            await _submitShareLocation(remark: remark);

                            if (dialogContext.mounted && route.isCurrent) {
                              FocusScope.of(dialogContext).unfocus();
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            if (!dialogContext.mounted || !route.isCurrent) {
                              return;
                            }
                            setDialogState(() {
                              isSubmitting = false;
                            });

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString(),
                                  style: AppTextStyles.body,
                                ),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.appOnPrimary,
                            ),
                          ),
                        )
                      : Text('Submit', style: AppTextStyles.button),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      await navigator.push<void>(route);
    } finally {
      // Popping resolves before the reverse animation removes the text field.
      await route.completed;
      remarkController.dispose();
    }
  }
}

class QuickAccessItemWidget extends StatelessWidget {
  final QuickAccessItem item;

  const QuickAccessItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: item.backgroundColor,
      borderRadius: 14.r,
      padding: EdgeInsets.all(8.w),
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 28.sp, color: item.iconColor),
          SizedBox(height: 6.h),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.helperText,
          ),
        ],
      ),
    );
  }
}

class QuickAccessMenuItem extends StatelessWidget {
  final MenuEntity menu;
  final PunchStatEntity? punchStat;
  final VoidCallback? onTap;

  const QuickAccessMenuItem({
    super.key,
    required this.menu,
    this.punchStat,
    this.onTap,
  });

  String get displayName {
    if (menu.menuId != '17') {
      return menu.menuName;
    }

    return punchStat?.inOutStatus == '0' ? 'In Punch' : 'Out Punch';
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.appPrimary;
    return _MenuShortcut(
      title: displayName,
      accent: accent,
      onTap: onTap,
      icon: Image.network(
        menu.iconImage,
        width: 32.w,
        height: 32.w,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.apps_rounded, size: 28.sp, color: accent),
        loadingBuilder: (context, child, loadingProgress) =>
            loadingProgress == null ? child : const CustomLoader(),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _MenuShortcut(
      title: 'More',
      accent: context.appPrimary,
      onTap: onTap,
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 30.sp,
        color: context.appPrimary,
      ),
    );
  }
}

class _MenuShortcut extends StatelessWidget {
  final String title;
  final Color accent;
  final Widget icon;
  final VoidCallback? onTap;

  const _MenuShortcut({
    required this.title,
    required this.accent,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.05),
        child: Column(
          children: [
            Container(
              width: 65.w,
              height: 65.w,
              padding: EdgeInsets.all(17.w),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: accent.withValues(alpha: 0.13)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.06),
                    blurRadius: 10.r,
                    offset: Offset(0, 3.h),
                  ),
                ],
              ),
              child: FittedBox(fit: BoxFit.contain, child: icon),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.appText,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
