import 'package:solufine/features/home/doman/home_entity/monthly_performance_detail_entity.dart';
import 'package:solufine/features/home/presentation/widgets/employee_month_ranking_dialog.dart';

import 'widgets/employee_month_marquee.dart';
import 'package:solufine/core/theme/app_colors.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/theme/typography/app_typography_extension.dart';
import 'dart:io';

import 'package:solufine/core/utility/tab_refresh.dart';
import 'dart:async';
import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:geolocator/geolocator.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/core/di/auth_di.dart';

import 'package:solufine/core/location_tracking/location_repository.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/appname.dart';
import 'package:solufine/core/utility/developer_options_checker.dart';
import 'package:solufine/core/utility/locationpermissiondialog.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_card.dart';
import 'package:solufine/features/auth/provider/auth_provider.dart';
import 'package:solufine/features/home/doman/home_entity/homevisit_entity.dart';
import 'package:solufine/features/home/doman/home_entity/inpunch_pending_entity.dart';
import 'package:solufine/features/home/presentation/home_bloc/home_bloc.dart';
import 'package:solufine/features/home/presentation/home_bloc/home_event.dart';
import 'package:solufine/features/home/presentation/home_bloc/home_state.dart';

import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_state.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';
import 'package:solufine/features/home/presentation/widgets/notvisited.dart';
import 'package:solufine/features/home/presentation/widgets/quick_action.dart';
import 'package:solufine/features/home/presentation/widgets/rotating_home_card.dart';
import 'package:solufine/features/home/presentation/widgets/todays_overwiew.dart';
import 'package:solufine/features/home/presentation/widgets/visit_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solufine/features/weather/homeforecastcard.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final AuthProvider _authProvider;
  String _username = 'user';
  String? _userId;
  bool isOpen = false;

  Timer? _appBarTimer;
  bool _monthlyDetailLoading = false;
  bool _showUserInfo = true;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _onMarqueeTap() {
    if (_monthlyDetailLoading) return;

    _monthlyDetailLoading = true;

    context.read<HomeBloc>().add(GetMonthlyPerformanceDetailEvent());
  }

  void _showMonthlyRankingDialog(MonthlyPerformanceDetailEntity data) {
    showDialog<void>(
      context: context,
      builder: (_) => EmployeeMonthRankingDialog(
        data: data,

        // Replace with your actual employee image folder URL.
        imageBaseUrl: '',
      ),
    );
  }

  Future<void> _selectToDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    setState(() {
      _toDate = pickedDate;
    });

    // Trigger API/Bloc after date selection
    await _loadVisitGraph();
  }

  Future<void> _loadVisitGraph() async {
    final userData = await SecureStorage.instance.getUserData();

    final userId = int.tryParse(userData?['user_id']?.toString() ?? '') ?? 0;

    if (!mounted) return;

    if (userId == 0) {
      debugPrint('VISIT GRAPH: Guest user, API skipped');

      return;
    }

    final searchFromDate = _formatDate(_fromDate);

    final searchToDate = _formatDate(_toDate);

    context.read<HomeBloc>().add(
      VisitGraphCountEvent(userId, searchFromDate, searchToDate),
    );
  }

  static String _appName = appName;
  static const String _appSubtitle = 'Agro Company';
  @override
  void initState() {
    super.initState();

    // ============================================================
    // AUTH LISTENER
    // ============================================================

    _authProvider = sl<AuthProvider>();

    _authProvider.addListener(_onAuthChanged);

    TabRefresh.home.addListener(_onTabRefresh);

    _loadUserData();

    // ------------------------------------------------------------
    // DEVELOPER OPTIONS CHECK
    // ------------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final isEnabled =
          await DeveloperOptionsChecker.isDeveloperOptionsEnabled();

      if (!mounted) return;

      if (isEnabled) {
        await showDeveloperOptionWarning();
      }
    });

    // ------------------------------------------------------------
    // APP BAR USER/APP NAME SWITCH
    // ------------------------------------------------------------

    _appBarTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;

      setState(() {
        _showUserInfo = !_showUserInfo;
      });
    });

    // ------------------------------------------------------------
    // LOCATION PERMISSION
    // ------------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _checkLocationAndGps();
    });
  }

  void _onTabRefresh() {
    _loadUserData();
  }

  Future<void> _onAuthChanged() async {
    await _loadUserData();
  }

  Future<void> printCurrentLocationTable() async {
    try {
      final LocationRepository repository = sl<LocationRepository>();

      const int userId = 4;

      final locations = await repository.getAllLocations(userId);

      if (locations.isEmpty) {
        debugPrint('NO LOCATION RECORDS FOUND');
      }

      for (final location in locations) {
        debugPrint(
          'ID: ${location.id} | '
          'UserId: ${location.userId} | '
          'Lat: ${location.latitude} | '
          'Lng: ${location.longitude} | '
          'Time: ${location.capturedAt} | '
          'Accuracy: ${location.accuracy} | '
          'Provider: ${location.provider} | '
          'Address: ${location.geoAddress} | '
          'Distance: ${location.distance}',
        );
      }

      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('PRINT LOCATION TABLE ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  @override
  void dispose() {
    TabRefresh.home.removeListener(_onTabRefresh);
    _authProvider.removeListener(_onAuthChanged);

    _appBarTimer?.cancel();

    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      await printCurrentLocationTable();

      final userData = await SecureStorage.instance.getUserData();

      if (!mounted) return;

      // ==========================================================
      // NO USER DATA = GUEST
      // ==========================================================

      if (userData == null) {
        setState(() {
          _userId = '0';
          _username = 'user';
        });

        return;
      }

      // ==========================================================
      // READ USER
      // ==========================================================

      final userId = userData['user_id']?.toString().trim() ?? '';

      final userName = userData['user_name']?.toString().trim() ?? '';

      if (userId.isEmpty || userId == '0') {
        setState(() {
          _userId = '0';
          _username = 'user';
        });

        return;
      }

      // ==========================================================
      // LOGGED-IN USER
      // ==========================================================

      setState(() {
        _userId = userId;

        _username = userName.isNotEmpty ? userName : 'user';
      });

      context.read<HomeBloc>().add(GetMonthlyPerformanceEvent());
      await getEmployeeStatus(userId);

      if (!mounted) return;
    } catch (e, stackTrace) {
      if (!mounted) return;

      // If reading storage fails, treat as guest.
      setState(() {
        _userId = '0';
        _username = 'user';
      });
    }
  }

  Future<void> getUserName() async {
    final userData = await SecureStorage.instance.getUserData();

    if (userData != null) {
      final userName = userData['user_name']?.toString();
      print('user name $userName');

      if (userName != null && userName.isNotEmpty) {
        if (mounted) {
          setState(() {
            _username = userName;
          });
        }
      }
    }
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Exit', style: context.appTextStyles.dialogTitle),
          content: Text(
            'Do you want to exit the app?',
            style: context.appTextStyles.dialogBody,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'CANCEL',
                style: AppTextStyles.button.copyWith(color: context.appText),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                foregroundColor: context.appOnPrimary,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('OK', style: AppTextStyles.button),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _checkLocationAndGps() async {
    if (!mounted) return;

    final PermissionStatus status = await _locationPermissionStatus();

    debugPrint('LOCATION STATUS = $status');

    // ============================================================
    // PERMISSION GRANTED
    // ============================================================
    if (status.isGranted || status.isLimited) {
      await _checkGpsService();
      return;
    }

    // ============================================================
    // FIRST TIME / CAN STILL ASK
    // ============================================================
    if (status.isDenied) {
      if (!mounted) return;

      await _showLocationPermissionDialog();
      return;
    }

    // ============================================================
    // USER HAS DENIED PERMISSION PERMANENTLY
    // iOS will NOT show the native popup again.
    // User has to open Settings.
    // ============================================================
    if (status.isPermanentlyDenied || status.isRestricted) {
      if (!mounted) return;

      await _showLocationSettingsDialog();
      return;
    }
  }

  Future<PermissionStatus> _locationPermissionStatus({
    bool request = false,
  }) async {
    if (!Platform.isIOS) {
      return request
          ? await Permission.location.request()
          : await Permission.location.status;
    }

    final locationPermission = request
        ? await Geolocator.requestPermission()
        : await Geolocator.checkPermission();
    debugPrint('IOS LOCATION AUTHORIZATION = $locationPermission');

    switch (locationPermission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return PermissionStatus.granted;
      case LocationPermission.deniedForever:
        return PermissionStatus.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return PermissionStatus.denied;
    }
  }

  Future<void> _showLocationPermissionDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return LocationPermissionDialog(
          onUseLocation: () async {
            Navigator.of(dialogContext).pop();

            final PermissionStatus result = await _locationPermissionStatus(
              request: true,
            );

            debugPrint('LOCATION PERMISSION RESULT = $result');

            if (!mounted) return;

            if (result.isGranted || result.isLimited) {
              await _checkGpsService();
            } else if (result.isPermanentlyDenied || result.isRestricted) {
              await _showLocationSettingsDialog();
            }
          },
        );
      },
    );
  }

  Future<void> _checkGpsService() async {
    if (!mounted) return;

    final bool gpsEnabled = await Geolocator.isLocationServiceEnabled();

    debugPrint('LOCATION SERVICE = $gpsEnabled');

    if (!gpsEnabled) {
      if (!mounted) return;

      await _showGpsOffDialog();
    }
  }

  Future<void> _showLocationSettingsDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(
                Icons.location_off_rounded,
                color: context.appWarning,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Location Permission Required',
                  style: AppTextStyles.dialogTitle,
                ),
              ),
            ],
          ),
          content: Text(
            'Location permission is disabled for this app. '
            'Please enable location permission from Settings.',
            style: AppTextStyles.dialogBody,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('CANCEL', style: AppTextStyles.button),
            ),

            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await openAppSettings();
              },
              icon: const Icon(Icons.settings, size: 18),
              label: Text('OPEN SETTINGS', style: AppTextStyles.button),
            ),
          ],
        );
      },
    );
  }
  // Future<void> checkLocationPermission(BuildContext context) async {
  //   final status = await Permission.location.status;

  //   if (status.isGranted) {
  //     return;
  //   }

  //   if (!context.mounted) return;

  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) {
  //       return LocationPermissionDialog(onPermissionResult: () {});
  //     },
  //   );
  // }

  Future<void> _showGpsOffDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          // ========================================================
          // TITLE
          // ========================================================
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appWarning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  color: context.appWarning,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text('GPS is Off', style: AppTextStyles.dialogTitle),
              ),
            ],
          ),

          // ========================================================
          // MESSAGE
          // ========================================================
          content: Text(
            'Your GPS / Location service is turned off. '
            'Please turn on GPS to continue using location services.',
            style: AppTextStyles.dialogBody,
          ),

          // ========================================================
          // BUTTON
          // ========================================================
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                foregroundColor: context.appOnPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await Geolocator.openLocationSettings();
              },
              icon: const Icon(Icons.settings, size: 18),
              label: Text('TURN ON GPS', style: AppTextStyles.button),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Logout', style: context.appTextStyles.dialogTitle),
          content: Text(
            'Are you sure you want to logout?',
            style: context.appTextStyles.dialogBody,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'CANCEL',
                style: AppTextStyles.button.copyWith(color: context.appText),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                foregroundColor: context.appOnPrimary,
              ),
              onPressed: () {
                // Return TRUE to _logout()
                Navigator.of(dialogContext).pop(true);
              },
              child: Text('LOGOUT', style: AppTextStyles.button),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      // Clear logged-in user data
      await SecureStorage.instance.clearAll();

      final authProvider = sl<AuthProvider>();

      await authProvider.checkLoginStatus();
      if (!mounted) return;
      // Update local state
      setState(() {
        _userId = '0';
        _username = 'user';
      });

      context.go(AppRouter.home);
    } catch (e, stackTrace) {
      debugPrint('Logout error: $e');
      debugPrint('$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final shouldExit = await _showExitDialog();

        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: CustomAppBar(
          leading: Builder(
            builder: (scaffoldContext) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appBorder),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,

                  // icon: const Icon(
                  //   Icons.person_2_outlined,
                  //   color: context.appText,
                  // ),
                  icon: Image.asset(
                    'assets/icons/logo.png',
                    width: 35,
                    height: 35,
                  ),

                  onPressed: () {
                    context.push('/profile');
                  },
                ),
              );
            },
          ),

          showLogin: _userId != null && _userId == '0',

          showLogout: _userId != null && _userId != '0',

          onLoginTap: () {
            context.push(AppRouter.login);
          },

          onLogOutTap: _logout,

          // ============================================================
          // USER NAME
          // ============================================================
          userName: _userId != null && _userId != '0' && _showUserInfo
              ? '$_username '
              : null,

          title: !_showUserInfo || _userId == null || _userId == '0'
              ? _appName
              : null,

          subtitle: !_showUserInfo || _userId == null || _userId == '0'
              ? _appSubtitle
              : null,

          showBackButton: false,
        ),

        body: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 12.h),
                if (_userId == null)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_userId == '0') ...[
                  SizedBox(height: 10),
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, homeState) {
                      if (homeState.status == HomeStatus.loading &&
                          homeState.menus.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (homeState.menus.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return BlocBuilder<QuickAcessBloc, QuickAccessState>(
                        builder: (context, quickAccessState) {
                          return QuickAccessSection(
                            menus: homeState.menus,
                            punchStat: quickAccessState.punchStat,
                          );
                        },
                      );
                    },
                  ),

                  SizedBox(height: 12.h),
                ] else ...[
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      int pendingCount = 0;
                      int pendingTotalCount = 0;

                      String punchTiming = '';
                      String city = '';
                      String countryState = '';

                      final data = state.data;

                      if (state.status == HomeStatus.success && data != null) {
                        pendingCount = data.pendingInpunchCount;

                        pendingTotalCount = data.totalRecursiveEmployee;

                        punchTiming = data.inpunchTime ?? '';

                        city = data.city ?? '';

                        countryState = data.state ?? '';
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 100.h,
                                  child: buildPunchCard(
                                    "Today's Punch",
                                    punchTiming.isEmpty ? '--' : punchTiming,
                                    [
                                      city,
                                      countryState,
                                    ].where((e) => e.isNotEmpty).join(', '),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: SizedBox(
                                  height: 100.h,
                                  child: RotatingHomeCard(
                                    weather: const HomeForecastCard(
                                      compact: true,
                                    ),
                                    showPending: pendingTotalCount != 1,
                                    pending: buildInfoCard(
                                      'In Punch Pending',
                                      '$pendingCount/$pendingTotalCount',
                                      onTap: () {
                                        _showPendingListDialog(
                                          data?.result ?? [],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 8.h),

                  BlocListener<HomeBloc, HomeState>(
                    listenWhen: (previous, current) =>
                        previous.monthlyPerformanceDetailData !=
                            current.monthlyPerformanceDetailData ||
                        previous.status != current.status,

                    listener: (context, state) {
                      if (!_monthlyDetailLoading) return;

                      if (state.status ==
                              HomeStatus.mothlyPerformanceDetailSuccess &&
                          state.monthlyPerformanceDetailData != null) {
                        _monthlyDetailLoading = false;

                        _showMonthlyRankingDialog(
                          state.monthlyPerformanceDetailData!,
                        );
                      } else if (state.status ==
                          HomeStatus.monthlyPerformanceDetailFailure) {
                        _monthlyDetailLoading = false;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.errorMessage ??
                                  'Unable to load employee rankings',
                            ),
                          ),
                        );
                      }
                    },

                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _onMarqueeTap,
                      child: BlocBuilder<HomeBloc, HomeState>(
                        buildWhen: (previous, current) =>
                            previous.monthlyPerformanceData !=
                            current.monthlyPerformanceData,

                        builder: (context, state) {
                          return EmployeeMonthMarquee(
                            entries:
                                state.monthlyPerformanceData?.result ??
                                const [],
                          );
                        },
                      ),
                    ),
                  ),
                  // ======================================================
                  // VISIT STATISTICS
                  // ======================================================
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      if (state.status == HomeStatus.loading) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 8.h,
                          ),
                          height: 140.h,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final homeData =
                          state.homedata ??
                          HomeVisitEntity(
                            status: false,
                            message: '',
                            todayTotalVisit: '0',
                            todayDealerCnt: '0',
                            todayFarmerCnt: '0',
                            monthlyTotalVisit: '0',
                            monthlyDealerCnt: '0',
                            monthlyFarmerCnt: '0',
                            monthlyUniqueDealerCnt: '0',
                            monthlyUniqueFarmerCnt: '0',
                            lastThirNotVisitDealer: '0',
                            lastThirNotVisitFarmer: '0',
                            // NEW FIELDS
                            totalDealerCount: '0',
                            totalFarmerCount: '0',
                            dayWise: const [],
                          );

                      return VisitStatisticsTable(homeData);
                    },
                  ),

                  SizedBox(height: 4.h),
                  // ======================================================
                  // NOT VISITED
                  // ======================================================
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      if (state.status == HomeStatus.loading) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 8.w),
                          height: 140.h,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final homeData =
                          state.homedata ??
                          HomeVisitEntity(
                            status: false,
                            message: '',
                            todayTotalVisit: '0',
                            todayDealerCnt: '0',
                            todayFarmerCnt: '0',
                            monthlyTotalVisit: '0',
                            monthlyDealerCnt: '0',
                            monthlyFarmerCnt: '0',
                            monthlyUniqueDealerCnt: '0',
                            monthlyUniqueFarmerCnt: '0',
                            lastThirNotVisitDealer: '0',
                            lastThirNotVisitFarmer: '0',
                            // NEW FIELDS
                            totalDealerCount: '0',
                            totalFarmerCount: '0',
                            dayWise: const [],
                          );

                      return NotVisitedCard(homeData);
                    },
                  ),

                  SizedBox(height: 8.h),

                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      final homeData = state.homedata;

                      return VisitOverviewCard(
                        dealerCount: homeData?.totalDealerCount ?? '0',

                        farmerCount: homeData?.totalFarmerCount ?? '0',

                        dayWise: homeData?.dayWise ?? const [],
                      );
                    },
                  ),

                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, homeState) {
                      if (homeState.status == HomeStatus.loading &&
                          homeState.menus.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (homeState.menus.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return BlocBuilder<QuickAcessBloc, QuickAccessState>(
                        builder: (context, quickAccessState) {
                          return QuickAccessSection(
                            menus: homeState.menus,
                            punchStat: quickAccessState.punchStat,
                          );
                        },
                      );
                    },
                  ),

                  SizedBox(height: 12.h),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPunchCard(String label, String value, String location) {
    return CustomCard(
      color: context.appPrimary,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Icon(Icons.fingerprint, color: context.appOnPrimary, size: 30.h),

          SizedBox(width: 8.w),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.helperText.copyWith(
                    color: context.appOnPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: context.appOnPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: context.appOnPrimary,
                      size: 12.h,
                    ),
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.helperText.copyWith(
                        color: context.appOnPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                Container(
                  margin: EdgeInsets.only(left: 6.w),
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: context.appOnPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Punch In',
                    style: AppTextStyles.badge.copyWith(
                      color: context.appOnPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callPhoneNumber(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to open the phone dialer',
          style: AppTextStyles.body,
        ),
      ),
    );
  }

  Future<void> _showPendingListDialog(
    List<InpunchPendingEntity> pendingList,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.pending_actions, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'In Punch Pending',
                  style: dialogContext.appTextStyles.dialogTitle,
                ),
              ),
              Text(
                pendingList.length.toString(),
                style: AppTextStyles.headingSmall.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          content: pendingList.isEmpty
              ? SizedBox(
                  width: 280,
                  child: Text(
                    'No pending requests',
                    style: dialogContext.appTextStyles.dialogBody,
                  ),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 620,
                    maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 28,
                        headingRowHeight: 44,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 68,
                        dividerThickness: 0.6,
                        headingRowColor: WidgetStatePropertyAll(
                          colorScheme.primary.withOpacity(0.1),
                        ),
                        headingTextStyle: AppTextStyles.tableHeader.copyWith(
                          color: colorScheme.primary,
                        ),
                        dataTextStyle: dialogContext.appTextStyles.tableCell,
                        columns: const [DataColumn(label: Text('Employee'))],
                        rows: List<DataRow>.generate(pendingList.length, (
                          index,
                        ) {
                          final pending = pendingList[index];
                          final mobileNumber =
                              pending.fldMobileNo?.trim() ?? '';

                          return DataRow(
                            color: WidgetStateProperty.resolveWith(
                              (states) => index.isEven
                                  ? colorScheme.surface
                                  : colorScheme.primary.withOpacity(0.035),
                            ),
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pending.fldAdmName ?? 'Unknown'),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: mobileNumber.isEmpty
                                          ? null
                                          : () =>
                                                _callPhoneNumber(mobileNumber),
                                      child: Text(
                                        mobileNumber.isEmpty
                                            ? '-'
                                            : mobileNumber,
                                        style: mobileNumber.isEmpty
                                            ? null
                                            : AppTextStyles.tableCell.copyWith(
                                                color: colorScheme.primary,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('CLOSE', style: AppTextStyles.button),
            ),
          ],
        );
      },
    );
  }

  Widget buildInfoCard(String label, String value, {VoidCallback? onTap}) {
    return CustomCard(
      color: context.appCard,
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: context.appWarning,
            size: 28.h,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge,
                ),
                SizedBox(height: 2.h),
                Text(value, style: AppTextStyles.displaySmall),
                // Text('Pending Punch', style: TextStyle(fontSize: 10.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 20.sp,
              color: context.appPrimary,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appSubText,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/'
                    '${date.year}',
                    style: AppTextStyles.label.copyWith(color: context.appText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getEmployeeStatus(String userId) async {
    try {
      final dioClient = GetIt.instance<DioClient>();
      final formData = FormData.fromMap({'userId': userId});

      final response = await dioClient.client.post(
        ApiClient.getEmployeeStatus,
        data: formData,
      );

      dynamic data = response.data;

      if (data is String) {
        data = jsonDecode(data.trim());
      }

      if (data is! Map) {
        return;
      }
      if (data['status'] != true) {
        return;
      }

      final result = data['result'];

      if (result is! List || result.isEmpty) {
        return;
      }

      final firstResult = result.first;

      if (firstResult is! Map) {
        return;
      }

      final empStatus = firstResult['fld_status']?.toString().trim() ?? '';
      if (empStatus.isEmpty) {
        return;
      }

      if (empStatus == 'Active') {
        return;
      }
      await SecureStorage.instance.clearAll();

      if (!mounted) {
        return;
      }
      context.go(AppRouter.login);
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> showDeveloperOptionWarning() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),

          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 10),

          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

          // ----------------------------------------------------
          // TITLE
          // ----------------------------------------------------
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appWarning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: context.appWarning,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text('Warning', style: AppTextStyles.dialogTitle),
              ),
            ],
          ),

          // ----------------------------------------------------
          // CONTENT
          // ----------------------------------------------------
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'It looks like Developer Options are enabled on your device.',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 10),

              Text(
                'For security purposes, please disable Developer Options before continuing.',
                style: AppTextStyles.body.copyWith(color: context.appSubText),
              ),

              const SizedBox(height: 18),

              Text(
                'Please follow these steps:',
                style: AppTextStyles.labelLarge,
              ),

              const SizedBox(height: 12),

              _buildStep(number: '1', text: 'Go to Settings'),

              _buildStep(number: '2', text: "Search for 'Developer Options'"),

              _buildStep(number: '3', text: 'Disable Developer Options'),
            ],
          ),

          // ----------------------------------------------------
          // BUTTONS
          // ----------------------------------------------------
          actions: [
            OutlinedButton(
              onPressed: () async {
                try {
                  // Open Developer Options directly
                  const intent = AndroidIntent(
                    action: 'android.settings.DEVELOPMENT_SETTINGS',
                  );

                  await intent.launch();
                } catch (e) {
                  debugPrint('Could not open Developer Options: $e');

                  // Fallback: open general Settings
                  try {
                    const intent = AndroidIntent(
                      action: 'android.settings.SETTINGS',
                    );

                    await intent.launch();
                  } catch (e) {
                    debugPrint('Could not open Settings: $e');
                  }
                }
              },

              style: OutlinedButton.styleFrom(
                foregroundColor: context.appPrimary,
                side: BorderSide(color: context.appPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),

              child: Text('SETTINGS', style: AppTextStyles.button),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                foregroundColor: context.appOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
              ),

              child: Text('CONTINUE', style: AppTextStyles.button),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // WARNING STEP
  // ------------------------------------------------------------

  Widget _buildStep({required String number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appPrimary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: AppTextStyles.label.copyWith(color: context.appOnPrimary),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: AppTextStyles.body),
            ),
          ),
        ],
      ),
    );
  }
}
