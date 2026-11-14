import 'dealer_report_dialog.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/di/auth_di.dart';
import 'package:solufine/core/location_tracking/location_repository.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/app_tutorial_service.dart';
import 'package:solufine/core/utility/device_info_util.dart';
import 'package:solufine/core/utility/location_util.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_loader.dart';
import 'package:solufine/core/utility/widgets/tutorial_description.dart';
import 'package:solufine/features/dealer/data/models/DealerListModel.dart';
import 'package:solufine/features/dealer/presentation/bloc/dealerlist_bloc.dart';
import 'package:solufine/features/dealer/presentation/bloc/dealerlist_event.dart';
import 'package:solufine/features/dealer/presentation/bloc/dealerlist_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';

class DealerListScreen extends StatefulWidget {
  const DealerListScreen({super.key});

  @override
  State<DealerListScreen> createState() => _DealerListScreenState();
}

class _DealerListScreenState extends State<DealerListScreen> {
  final GlobalKey _dealerPinKey = GlobalKey();

  final GlobalKey _dealerCallKey = GlobalKey();

  final GlobalKey _dealerEditKey = GlobalKey();

  final GlobalKey _dealerMapKey = GlobalKey();

  final GlobalKey _dealerWhatsAppKey = GlobalKey();

  bool _dealerTutorialRequested = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialLoading = true;
  Timer? _searchDebounce;

  String _searchText = '';
  String? _currentLatitude;
  String? _currentLongitude;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isOpeningDirections = false;
  @override
  void initState() {
    super.initState();

    _loadDealers(searchKey: '', startLimit: 0, isLoadMore: false);

    // Listen for search changes
    _searchController.addListener(_onSearchChanged);
  }

  void _showDealerTutorialIfNeeded() {
    // Already requested during this screen lifecycle.
    if (_dealerTutorialRequested) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _dealerTutorialRequested) {
        return;
      }

      // =========================================================
      // IMPORTANT
      // First dealer card must actually be rendered.
      // =========================================================

      final bool hasAnyTarget =
          _dealerCallKey.currentContext != null ||
          _dealerEditKey.currentContext != null ||
          _dealerMapKey.currentContext != null ||
          _dealerWhatsAppKey.currentContext != null ||
          _dealerPinKey.currentContext != null;

      if (!hasAnyTarget) {
        debugPrint('Dealer tutorial: targets are not rendered yet.');

        return;
      }

      _dealerTutorialRequested = true;

      await AppTutorialService.showDealerListTutorial(
        context: context,
        targets: _buildDealerTutorialTargets(),
      );
    });
  }

  List<TargetFocus> _buildDealerTutorialTargets() {
    final List<TargetFocus> targets = [];

    // ============================================================
    // PIN / LOC
    // Only add when button currently exists.
    // ============================================================

    if (_dealerPinKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'dealer_pin',
          keyTarget: _dealerPinKey,
          shape: ShapeLightFocus.RRect,
          radius: 10,
          paddingFocus: 6,
          enableOverlayTab: false,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: const TutorialDescription(
                step: 'Dealer Visit',
                title: 'Dealer Visit',
                description:
                    'Tap Pin to start a dealer visit. If the dealer location is not available, use LOC to save the dealer location first.',
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // CALL
    // ============================================================

    if (_dealerCallKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'dealer_call',
          keyTarget: _dealerCallKey,
          shape: ShapeLightFocus.RRect,
          radius: 10,
          paddingFocus: 6,
          enableOverlayTab: false,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: const TutorialDescription(
                step: 'Call',
                title: 'Call Dealer',
                description:
                    'Tap here to quickly call the selected dealer using their registered mobile number.',
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // EDIT
    // ============================================================

    if (_dealerEditKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'dealer_edit',
          keyTarget: _dealerEditKey,
          shape: ShapeLightFocus.Circle,
          paddingFocus: 6,
          enableOverlayTab: false,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: const TutorialDescription(
                step: 'Edit',
                title: 'Edit Dealer',
                description:
                    'Use this option to view or update the dealer information.',
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // MAP
    // ============================================================

    if (_dealerMapKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'dealer_map',
          keyTarget: _dealerMapKey,
          shape: ShapeLightFocus.Circle,
          paddingFocus: 6,
          enableOverlayTab: false,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: const TutorialDescription(
                step: 'Map',
                title: 'Dealer Location',
                description:
                    'Tap the Map icon to open the dealer location and get directions.',
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // WHATSAPP
    // ============================================================

    if (_dealerWhatsAppKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'dealer_whatsapp',
          keyTarget: _dealerWhatsAppKey,
          shape: ShapeLightFocus.Circle,
          paddingFocus: 6,
          enableOverlayTab: false,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: const TutorialDescription(
                step: 'WhatsApp',
                title: 'WhatsApp Dealer',
                description:
                    'Tap here to quickly start a WhatsApp conversation with the dealer.',
                isLast: true,
              ),
            ),
          ],
        ),
      );
    }

    return targets;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // SEARCH CHANGE
  // =========================================================

  void _onSearchChanged() {
    final searchText = _searchController.text.trim();

    setState(() {
      _searchText = searchText;
    });

    // Cancel previous timer
    _searchDebounce?.cancel();

    if (searchText.isNotEmpty && searchText.length < 3) return;
    _searchDebounce = Timer(const Duration(seconds: 2), () {
      _loadDealers(searchKey: searchText);
    });
  }

  void _loadDealers({
    String searchKey = '',
    int startLimit = 0,
    bool isLoadMore = false,
  }) async {
    // Prevent duplicate load-more calls
    if (isLoadMore && (_isLoadingMore || !_hasMore)) {
      return;
    }

    // Get user ID
    final userData = await SecureStorage.instance.getUserData();
    if (!mounted) return;

    final int? userId = int.tryParse(userData?['user_id']?.toString() ?? '');

    if (userId == null) {
      debugPrint('ERROR: Invalid user_id: ${userData?['user_id']}');
      return;
    }

    // Handle pagination
    if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      // _startLimit = startLimit;
      _hasMore = true;
    }

    // Get current location
    String latitude = '';
    String longitude = '';

    final position = await LocationUtil.instance.getCurrentLocation();

    if (position != null) {
      latitude = position.latitude.toString();
      longitude = position.longitude.toString();
    }

    debugPrint('Latitude: $latitude');
    debugPrint('Longitude: $longitude');

    if (!mounted) return;

    if (searchKey != _searchController.text.trim()) return;
    setState(() {
      _currentLatitude = position != null ? latitude : null;
      _currentLongitude = position != null ? longitude : null;
    });

    // Call dealer API
    context.read<DealerListBloc>().add(
      DealerListEvent(
        user_id: userId.toString(),
        latitude: latitude,
        longitude: longitude,
        searchText: searchKey,
        type: 'Dealer',
        startLimit: 0,
      ),
    );
  }

  Future<void> _openDealerDirections(DealerListModel dealer) async {
    if (_isOpeningDirections) return;

    void showError(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: AppTextStyles.body)),
      );
    }

    final latitude = double.tryParse(dealer.latitude?.trim() ?? '');
    final longitude = double.tryParse(dealer.longitude?.trim() ?? '');
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        (latitude == 0 && longitude == 0)) {
      showError('Dealer location is not available. Please update it first.');
      return;
    }

    setState(() => _isOpeningDirections = true);
    try {
      final position = await LocationUtil.instance.getCurrentLocation().timeout(
        const Duration(seconds: 20),
        onTimeout: () => null,
      );
      if (!mounted) return;
      if (position == null) {
        showError(
          'Unable to get your location. Enable GPS and allow location access.',
        );
        return;
      }

      final uri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'origin': '${position.latitude},${position.longitude}',
        'destination': '$latitude,$longitude',
        'travelmode': 'driving',
      });
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) showError('Unable to open Google Maps. Please try again.');
    } catch (_) {
      showError('Unable to open directions. Please try again.');
    } finally {
      if (mounted) setState(() => _isOpeningDirections = false);
    }
  }

  Future<void> _submitDealerLocation(DealerListModel dealer) async {
    try {
      final String dealerId = dealer.outletId?.toString().trim() ?? '';

      final userData = await SecureStorage.instance.getUserData();

      final String userId = userData?['user_id']?.toString().trim() ?? '';

      final position = await LocationUtil.instance.getCurrentLocation();

      final String latitude = position!.latitude.toString();

      final String longitude = position.longitude.toString();

      final String accuracy = position.accuracy.toString();

      debugPrint('Current Latitude  : $latitude');
      debugPrint('Current Longitude : $longitude');
      debugPrint('Accuracy          : $accuracy');

      // ============================================================

      final String networkLatitude = latitude;
      final String networkLongitude = longitude;

      final String gpsLatitude = latitude;
      final String gpsLongitude = longitude;

      // ============================================================
      // 5. GET ADDRESS
      // ============================================================

      String geoAddress = '';

      try {
        geoAddress = await LocationUtil.instance.getAddress(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        debugPrint('GET ADDRESS ERROR: $e');
      }

      // ============================================================
      // 6. DEVICE INFORMATION
      // ============================================================

      String strNetworkInfo = '';
      String strBatteryInfo = '';

      try {
        strNetworkInfo = await DeviceInfoUtil.instance.getNetworkInfo();
      } catch (e) {
        debugPrint('NETWORK INFO ERROR: $e');
      }

      try {
        strBatteryInfo = await DeviceInfoUtil.instance.getBatteryInfo();
      } catch (e) {
        debugPrint('BATTERY INFO ERROR: $e');
      }

      // ============================================================
      // 7. LOCATION HISTORY
      // ============================================================

      String locationHistoryString = '';

      try {
        final int parsedUserId = int.tryParse(userId) ?? 0;

        if (parsedUserId > 0) {
          final locationRepository = sl<LocationRepository>();

          final locations = await locationRepository.getAllLocations(
            parsedUserId,
          );

          final List<Map<String, dynamic>> history = locations.map((location) {
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

          locationHistoryString = jsonEncode(history);
        }
      } catch (e) {
        debugPrint('LOCATION HISTORY ERROR: $e');
      }

      // ============================================================
      // 8. PRINT FINAL DATA
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('DEALER LOCATION FINAL DATA');
      debugPrint('========================================');

      debugPrint('Dealer ID          : $dealerId');
      debugPrint('User ID            : $userId');

      debugPrint('Latitude           : $latitude');
      debugPrint('Longitude          : $longitude');

      debugPrint('Network Latitude   : $networkLatitude');
      debugPrint('Network Longitude  : $networkLongitude');

      debugPrint('GPS Latitude       : $gpsLatitude');
      debugPrint('GPS Longitude      : $gpsLongitude');

      debugPrint('Geo Address        : $geoAddress');

      debugPrint('Network Info       : $strNetworkInfo');
      debugPrint('Battery Info       : $strBatteryInfo');

      debugPrint('Location History   : $locationHistoryString');

      debugPrint('========================================');

      if (!mounted) return;

      // ============================================================
      // 9. CALL BLOC
      // ============================================================

      context.read<DealerListBloc>().add(
        AddDealerLocation(
          dealerId: dealerId,
          userId: userId,

          locationHistoryString: locationHistoryString,

          latitude: latitude,
          longitude: longitude,

          networkLatitude: networkLatitude,
          networkLongitude: networkLongitude,

          gpsLatitude: gpsLatitude,
          gpsLongitude: gpsLongitude,

          geoAddress: geoAddress,

          mobileInfo: '',
          mobileImei: '',

          networkInfo: strNetworkInfo,
          batteryInfo: strBatteryInfo,
        ),
      );

      debugPrint('ADD DEALER LOCATION EVENT SENT');
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('UPDATE DEALER LOCATION ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      // _showError(
      //   'Unable to update dealer location. Please try again.',
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: CustomAppBar(
          title: 'Dealer List',
          showBackButton: true,
          onBackTap: () => context.go('/home'),
        ),

        body: Column(
          children: [
            _buildSearchBar(),
            _buildLocationRow(),

            Expanded(
              child: BlocConsumer<DealerListBloc, DealerListState>(
                listener: (context, state) {
                  if (state.status == DealerListStatus.success ||
                      state.status == DealerListStatus.failure) {
                    if (mounted) {
                      setState(() {
                        _isInitialLoading = false;
                        _isLoadingMore = false;
                      });
                    }
                  }

                  if (state.status ==
                      DealerListStatus.addDealerLocationSuccess) {
                    debugPrint('DEALER LOCATION UPDATED SUCCESSFULLY');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Dealer location updated successfully',
                          style: AppTextStyles.body,
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    _loadDealers(searchKey: _searchController.text.trim());
                  }

                  //
                },
                builder: (context, state) {
                  if (_isInitialLoading ||
                      state.status == DealerListStatus.loading) {
                    return const CustomLoader();
                  }

                  if (state.status == DealerListStatus.failure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 50,
                              color: context.appColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.errorMessage ?? 'Something went wrong',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _loadDealers(
                                  searchKey: _searchController.text.trim(),
                                );
                                // _loadFarmers(searchKey: _searchController.text.trim());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: context.onPrimaryColor,
                              ),
                              child: Text('Retry', style: AppTextStyles.button),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final dealers = state.dealerList;

                  if (dealers.isNotEmpty) {
                    _showDealerTutorialIfNeeded();
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _searchText.isEmpty
                                    ? 'Your dealers'
                                    : 'Search results',
                                style: AppTextStyles.sectionTitle.copyWith(
                                  letterSpacing: -0.4,
                                  color: context.primaryTextColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${dealers.length}',
                                style: AppTextStyles.buttonSmall.copyWith(
                                  color: context.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: dealers.isEmpty
                            ? _buildEmptyView()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  _loadDealers();
                                },
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    104,
                                  ),
                                  itemCount: dealers.length,
                                  itemBuilder: (context, index) {
                                    final dealer = dealers[index];

                                    return _DealerListItem(
                                      dealer: dealer,

                                      pinKey: index == 0 ? _dealerPinKey : null,

                                      callKey: index == 0
                                          ? _dealerCallKey
                                          : null,

                                      editKey: index == 0
                                          ? _dealerEditKey
                                          : null,

                                      mapKey: index == 0 ? _dealerMapKey : null,

                                      whatsappKey: index == 0
                                          ? _dealerWhatsAppKey
                                          : null,

                                      onMapTap: _isOpeningDirections
                                          ? null
                                          : () {
                                              _openDealerDirections(dealer);
                                            },

                                      onLocationTap: () {
                                        _submitDealerLocation(dealer);
                                      },
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: context.primaryColor,
          foregroundColor: context.onPrimaryColor,
          elevation: 3,
          onPressed: () {
            context.push('/dealrFollowUpAdd');
          },
          tooltip: 'Add dealer follow-up',
          icon: const Icon(Icons.add_rounded),
          label: Text('Add Dealer', style: AppTextStyles.button),
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    final latitude = double.tryParse(_currentLatitude ?? '');
    final longitude = double.tryParse(_currentLongitude ?? '');
    final hasLocation = latitude != null && longitude != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.my_location_rounded,
              size: 13,
              color: context.primaryColor,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                hasLocation
                    ? 'Lat ${latitude.toStringAsFixed(5)}   |   Long ${longitude.toStringAsFixed(5)}'
                    : 'Location unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      decoration: const BoxDecoration(
        // color: Color(0xFF123D32),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),

      child: _AnimatedDealerSearchHint(
        builder: (context, index) => TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          style: AppTextStyles.input.copyWith(color: context.primaryTextColor),
          decoration: InputDecoration(
            hint: AnimatedSwitcher(
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [...previousChildren, ?currentChild],
              ),
              duration: Duration(
                milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 400,
              ),
              child: Text(
                index == 0 ? 'Search dealer name' : 'Search with mobile no',
                key: ValueKey(index),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
            hintStyle: AppTextStyles.inputHint.copyWith(
              color: context.secondaryTextColor,
            ),
            filled: true,
            fillColor: context.appTheme.inputBackground,
            prefixIcon: AnimatedSwitcher(
              duration: Duration(
                milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 400,
              ),
              child: Icon(
                _searchController.text.isNotEmpty || index == 0
                    ? Icons.search_rounded
                    : Icons.phone_android_rounded,
                key: ValueKey(_searchController.text.isNotEmpty ? 0 : index),
                color: context.primaryColor,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _searchController.clear,
                  )
                : null,

            helperText:
                'Search after 3 characters. After searching wait for 2 sec..!',
            helperStyle: AppTextStyles.helperText.copyWith(
              color: context.appColors.error,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchText.isNotEmpty ? Icons.search_off : Icons.store_outlined,
            size: 48,
            color: context.secondaryTextColor,
          ),

          const SizedBox(height: 12),

          Text(
            'No Dealers Found..!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.secondaryTextColor,
            ),
          ),

          if (_searchText.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'Try another search',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedDealerSearchHint extends StatefulWidget {
  final Widget Function(BuildContext context, int index) builder;
  const _AnimatedDealerSearchHint({required this.builder});

  @override
  State<_AnimatedDealerSearchHint> createState() =>
      _AnimatedDealerSearchHintState();
}

class _AnimatedDealerSearchHintState extends State<_AnimatedDealerSearchHint> {
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || !TickerMode.valuesOf(context).enabled) return;
        setState(() => _index = (_index + 1) % 2);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _index);
}

class _DealerListItem extends StatelessWidget {
  final DealerListModel dealer;
  final VoidCallback onLocationTap;
  final VoidCallback? onMapTap;
  final Key? pinKey;
  final Key? callKey;
  final Key? editKey;
  final Key? mapKey;
  final Key? whatsappKey;
  const _DealerListItem({
    required this.dealer,
    required this.onLocationTap,
    required this.onMapTap,
    this.pinKey,
    this.callKey,
    this.editKey,
    this.mapKey,
    this.whatsappKey,
  });

  Future<Map<String, Object>?> _openReport(
    BuildContext context,
    String reportType,
  ) {
    final repository = context.read<DealerListBloc>().repository;
    return showDialog<Map<String, Object>>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) =>
            DealerListBloc(repository: repository)
              ..add(GetTallyCompanyListEvent()),
        child: DealerReportDialog(
          reportType: reportType,
          dealerId: dealer.outletId,
        ),
      ),
    );
  }

  Widget _reportAction(
    BuildContext context,
    String label,
    String type,
    IconData icon,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openReport(context, type),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: context.primaryColor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: context.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: context.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    String normalize(String? value) {
      var number = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      if (number.startsWith('00')) {
        number = number.substring(2);
      }
      if (number.length == 11 && number.startsWith('0')) {
        number = number.substring(1);
      }
      if (number.length == 10) {
        number = '91$number';
      }
      return number;
    }

    bool isValid(String number) =>
        RegExp(r'^[1-9][0-9]{10,14}$').hasMatch(number);
    var number = normalize(dealer.outletPersonMobile);
    if (!isValid(number)) number = normalize(dealer.outletMobile);
    void showError(String message) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: AppTextStyles.body)),
      );
    }

    if (!isValid(number)) {
      showError('A valid dealer mobile number is not available.');
      return;
    }
    try {
      final opened = await launchUrl(
        Uri.https('wa.me', '/$number'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) showError('Unable to open WhatsApp. Please try again.');
    } catch (_) {
      showError('Unable to open WhatsApp. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = dealer.outletName.trim();
    final mobile = dealer.outletPersonMobile?.trim() ?? '';
    final person = dealer.outletPerson.trim();
    final latitude = double.tryParse(dealer.latitude ?? '0') ?? 0;
    final longitude = double.tryParse(dealer.longitude ?? '0') ?? 0;
    final locationNotAvailable = latitude == 0 && longitude == 0;
    final outletDistance = double.tryParse(dealer.outletDistance ?? '');
    final definedRadius = double.tryParse(dealer.definedRadius ?? '');
    final showPin =
        outletDistance != null &&
        definedRadius != null &&
        outletDistance < definedRadius;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: context.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor, width: 3),
                ),
                child: Center(
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: AppTextStyles.pageTitle.copyWith(
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Unknown dealer' : name,
                      style: AppTextStyles.listTitle.copyWith(
                        color: context.cardTextColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 13,
                          color: context.secondaryTextColor,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            // 'Lat: ${dealer.latitude}  Long: ${dealer.longitude}',
                            'Lat: ${dealer.latitude}  Long: ${dealer.longitude}  (${dealer.outletDistance})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.helperText.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Divider(height: 1, color: context.borderColor),
          ),

          Row(
            children: [
              Expanded(
                child: _DealerDetail(
                  icon: Icons.phone_outlined,
                  label: 'Mobile Number',
                  text: mobile.isEmpty ? 'Not available' : mobile,
                  onTap: mobile.isEmpty
                      ? null
                      : () {
                          callFarmer(mobile);
                        },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                key: mapKey,
                tooltip: 'Directions to dealer',
                onPressed: onMapTap,
                icon: Image.asset(
                  'assets/images/map.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: context.primaryColor.withValues(alpha: 0.08),
                  side: BorderSide(color: context.borderColor),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                key: whatsappKey,
                tooltip: 'Chat with dealer on WhatsApp',
                onPressed: () => _openWhatsApp(context),
                icon: SizedBox(
                  width: 22,
                  height: 22,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 22,
                        color: context.primaryColor,
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Icon(
                          Icons.phone,
                          size: 13,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: context.primaryColor.withValues(alpha: 0.08),
                  side: BorderSide(color: context.borderColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          _DealerDetail(
            icon: Icons.location_on_outlined,
            label: 'Address',
            text: dealer.outletAddress.trim().isEmpty
                ? 'Address not available'
                : dealer.outletAddress.trim(),
          ),
          const SizedBox(height: 5),
          LayoutBuilder(
            builder: (context, constraints) {
              final call = _ActivityInfo(
                icon: Icons.phone_callback_outlined,
                title: 'Last Call',
                dateTime: dealer.lastDateTime,
              );
              final visit = _ActivityInfo(
                icon: Icons.calendar_today_outlined,
                title: 'Last Visit',
                dateTime: dealer.lastVisitDateTime,
              );
              if (constraints.maxWidth < 240 ||
                  MediaQuery.textScalerOf(context).scale(11) > 18) {
                return Column(
                  children: [call, const SizedBox(height: 6), visit],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: call),
                  const SizedBox(width: 8),
                  Expanded(child: visit),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (locationNotAvailable || showPin)
                Expanded(
                  child: OutlinedButton.icon(
                    key: pinKey,
                    onPressed: locationNotAvailable
                        ? onLocationTap
                        : () {
                            // context.push('/dealerpin', extra: dealer.outletId);
                            context.push(
                              '/dealrFollowUpAddNew',
                              extra: dealer.outletId,
                            );
                          },
                    icon: Icon(
                      locationNotAvailable
                          ? Icons.add_location_alt_outlined
                          : Icons.push_pin_outlined,
                      size: 15,
                    ),
                    label: Text(
                      locationNotAvailable ? 'LOC' : 'Pin',
                      style: AppTextStyles.buttonSmall,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      side: BorderSide(color: context.primaryColor),
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      textStyle: AppTextStyles.buttonSmall,
                      shape: shape,
                    ),
                  ),
                ),
              if (locationNotAvailable || showPin) const SizedBox(width: 6),
              Expanded(
                child: FilledButton.icon(
                  key: callKey,
                  onPressed: mobile.isEmpty
                      ? null
                      : () {
                          if (mobile.isNotEmpty) {
                            callFarmer(mobile);
                            DealerCallEvent(dealer.outletId, mobile);
                          } else {
                            debugPrint('Phone number is missing');
                          }
                        },
                  icon: const Icon(Icons.call_outlined, size: 15),
                  label: Text('Call', style: AppTextStyles.buttonSmall),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.onPrimaryColor,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    textStyle: AppTextStyles.buttonSmall,
                    shape: shape,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                key: editKey,
                tooltip: 'Edit dealer',
                onPressed: () {
                  context.push('/dealerUpdate', extra: dealer);
                },
                icon: const Icon(Icons.edit_outlined, size: 17),
                style: IconButton.styleFrom(
                  foregroundColor: context.primaryColor,
                  side: BorderSide(color: context.primaryColor),
                  minimumSize: const Size(38, 36),
                  shape: shape,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _reportAction(
                      context,
                      'Ledger',
                      'leader',
                      Icons.menu_book_outlined,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: context.borderColor,
                    ),
                  ),
                  Expanded(
                    child: _reportAction(
                      context,
                      'Outstanding',
                      'outstanding',
                      Icons.account_balance_wallet_outlined,
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
}

// class _DealerDetail extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String text;
//   const _DealerDetail({
//     required this.icon,
//     required this.label,
//     required this.text,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 28,
//           height: 28,
//           decoration: BoxDecoration(
//             color: const Color(0xFFEDF5EF),
//             borderRadius: BorderRadius.circular(7),
//           ),
//           child: Icon(icon, size: 15, color: AppColors.primary),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontSize: 9,
//                   color: AppColors.textSecondary,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 text,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   height: 1.25,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF18231C),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

class _DealerDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final VoidCallback? onTap;

  const _DealerDetail({
    required this.icon,
    required this.label,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15, color: context.primaryColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: AppTextStyles.buttonSmall.copyWith(
                    height: 1.25,
                    color: onTap != null
                        ? context.primaryColor
                        : context.cardTextColor,
                    decoration: onTap != null
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? dateTime;
  const _ActivityInfo({
    required this.icon,
    required this.title,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    final raw = dateTime?.trim() ?? '';
    final missing = raw.isEmpty || raw.startsWith('0000-00-00');
    final parsed = missing ? null : DateTime.tryParse(raw);
    final value = missing
        ? 'Not recorded'
        : parsed == null
        ? raw
        : DateFormat('dd MMM yyyy').format(parsed);
    final time = parsed != null && raw.contains(RegExp(r'[T ]\d{2}:\d{2}'))
        ? DateFormat('h:mm a').format(parsed)
        : null;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.appTheme.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: context.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTextStyles.helperText.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                if (time != null)
                  Text(
                    time,
                    style: AppTextStyles.helperText.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> DealerCallEvent(String fldFarmerId, String fldMobileNo) async {
  final url = ApiClient.baseUrl + ApiClient.famerCallApi;
  final userData = await SecureStorage.instance.getUserData();

  final id = userData?['user_id']?.toString();

  try {
    final response = await http.post(
      Uri.parse(url),

      body: {
        "strUserId": id.toString(),

        "strCallToId": fldFarmerId,

        "strMobNo": fldMobileNo,

        "strType": "Dealer",

        "strTime": getCurrentTime(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == true) {
        debugPrint("Call Event Success");
      }
    }
  } catch (e) {
    debugPrint("Call Event Error: $e");
  }
}

String getCurrentTime() {
  final now = DateTime.now();

  int hour = now.hour;

  final minute = now.minute;

  String period = "AM";

  if (hour >= 12) {
    period = "PM";

    if (hour > 12) {
      hour -= 12;
    }
  }

  if (hour == 0) {
    hour = 12;
  }

  final formattedHour = hour.toString().padLeft(2, '0');

  final formattedMinute = minute.toString().padLeft(2, '0');

  return "$formattedHour:"
      "$formattedMinute "
      "$period";
}

Future<void> callFarmer(String phone) async {
  final phoneUri = Uri(scheme: 'tel', path: phone);

  if (!await canLaunchUrl(phoneUri)) {
    debugPrint('Unable to open dialer for phone number: $phone');
    return;
  }

  final launched = await launchUrl(
    phoneUri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched) {
    debugPrint('Failed to open dialer for phone number: $phone');
  }
}
