import 'package:url_launcher/url_launcher.dart';
import 'package:solufine/core/utility/tab_refresh.dart';

import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/followup_entity.dart';
import '../bloc/followup_bloc.dart';
import '../bloc/followup_event.dart';
import '../bloc/followup_state.dart';
import 'package:solufine/features/followup/presentation/widgets/followup_home_widget_service.dart';

class FollowupPage extends StatefulWidget {
  const FollowupPage({super.key});

  @override
  State<FollowupPage> createState() => _FollowupPageState();
}

class _FollowupPageState extends State<FollowupPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _calendarAttentionController;
  // ===========================================================================
  // VARIABLES
  // ===========================================================================
  // From and To dates always start as the current local day.
  late DateTime fromDate;
  late DateTime toDate;

  String selectedType = 'Dealer';

  String userId = '';

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    fromDate = today;
    toDate = today;

    _calendarAttentionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    TabRefresh.followup.addListener(_onTabRefresh);
    _initializePage();
  }

  // ===========================================================================
  // INITIALIZE
  // ===========================================================================

  void _onTabRefresh() {
    _calendarAttentionController.repeat(reverse: true);
    _initializePage();
  }

  @override
  void dispose() {
    TabRefresh.followup.removeListener(_onTabRefresh);
    _calendarAttentionController.dispose();
    super.dispose();
  }


  Future<void> _initializePage() async {
    try {
      final userData = await SecureStorage.instance.getUserData();
      if (!mounted) return;

      final String id = userData?['user_id']?.toString() ?? '';
      if (id.isEmpty) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      setState(() {
        userId = id;
        fromDate = today;
        toDate = today;
      });

      debugPrint('Followup default From: ${_formatDate(fromDate)}');
      debugPrint('Followup default To: ${_formatDate(toDate)}');

      _loadFollowup();
    } catch (e, stackTrace) {
      debugPrint('Followup initialize error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ===========================================================================
  // UPDATE HOME WIDGET FROM API RESULT
  // ===========================================================================

  Future<void> _updateHomeWidget(
  List<FollowupEntity> followups,
) async {
  try {
    await FollowupHomeWidgetService.updateFollowups(
      followups: followups,
      fromDate: fromDate,
      toDate: toDate,
      selectedType: selectedType,
    );
  } catch (e) {
    debugPrint('Followup Widget Error: $e');
  }
}
  // ===========================================================================
  // DATE FORMAT
  // ===========================================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  String _formatShortDate(DateTime date) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ===========================================================================
  // API
  // ===========================================================================

  void _loadFollowup() {
    if (userId.isEmpty) return;

    context.read<FollowupBloc>().add(
      GetUpcomingFollowupEvent(
        fromDate: _formatDate(fromDate),
        toDate: _formatDate(toDate),
        type: selectedType,
        userId: userId,
      ),
    );
  }

  // ===========================================================================
  // TYPE CHANGE
  // ===========================================================================

  void _changeType(String type) {
    if (selectedType == type) return;

    setState(() {
      selectedType = type;
    });

    // Automatically load new list.
    _loadFollowup();
  }

  // ===========================================================================
  // DATE PICKER THEME
  // ===========================================================================

  ThemeData _datePickerTheme(BuildContext context) {
    return Theme.of(context);
  }

  // ===========================================================================
  // FROM DATE
  // ===========================================================================

  Future<void> _selectFromDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(data: _datePickerTheme(context), child: child!);
      },
    );

    if (result == null) return;

    setState(() {
      fromDate = result;

      if (fromDate.isAfter(toDate)) {
        toDate = fromDate;
      }
    });

    _loadFollowup();
  }

  // ===========================================================================
  // TO DATE
  // ===========================================================================

  Future<void> _selectToDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: fromDate,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(data: _datePickerTheme(context), child: child!);
      },
    );

    if (result == null) return;

    setState(() {
      toDate = result;
    });

    _loadFollowup();
  }

  Widget _buildCalendarAction() {
    final theme = Theme.of(context);
    final background =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final foreground =
        theme.appBarTheme.foregroundColor ??
        (ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        tooltip: 'View follow-ups in calendar',
        style: IconButton.styleFrom(
          backgroundColor: foreground.withValues(alpha: 0.12),
          foregroundColor: foreground,
          shape: const CircleBorder(),
        ),
        onPressed: () {
          _calendarAttentionController.stop();
          _calendarAttentionController.value = 0.5;
          context.push(AppRouter.calendarReport);
        },
        icon: AnimatedBuilder(
          animation: _calendarAttentionController,
          child: const Icon(Icons.calendar_month_rounded, size: 20),
          builder: (context, child) {
            final progress = Curves.easeInOut.transform(
              _calendarAttentionController.value,
            );
            return Transform.rotate(
              angle: (progress - 0.5) * 0.3,
              child: Transform.scale(
                scale: 1 + (0.5 - (progress - 0.5).abs()) * 0.2,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: context.appBackground,

 appBar: CustomAppBar(
  title: 'Upcoming Followup List',

  action: Row(
    mainAxisSize: MainAxisSize.min,
    children: [

      // ADD HOME SCREEN WIDGET
      IconButton(
        tooltip: 'Add Followup Widget',
        icon: const Icon(
          Icons.widgets_rounded,
          size: 22,
        ),
        onPressed: () async {
          await FollowupHomeWidgetService.requestWidget();
        },
      ),

      // EXISTING CALENDAR BUTTON
      _buildCalendarAction(),
    ],
  ),

  showBackButton: true,
  onBackTap: () => context.go(AppRouter.home),
),
    body: BlocListener<FollowupBloc, FollowupState>(
      listener: (context, state) async {

        // API SUCCESS
        if (state is FollowupSuccess) {
          await _updateHomeWidget(state.followups);
        }

        // API EMPTY
        if (state is FollowupEmpty) {
          await _updateHomeWidget(
            <FollowupEntity>[],
          );
        }

        // For FollowupError, preserve the last cached data.
      },

      child: Column(
        children: [
          _buildTopHeader(),

          _buildFilterSection(),

          Expanded(
            child: BlocBuilder<FollowupBloc, FollowupState>(
              builder: (context, state) {

                if (state is FollowupLoading) {
                  return _buildLoading();
                }

                if (state is FollowupError) {
                  return _buildErrorState(state.message);
                }

                if (state is FollowupEmpty) {
                  return _buildEmptyState();
                }

                if (state is FollowupSuccess) {
                  return _buildFollowupList(
                    state.followups,
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    ),
  );
}


  // ===========================================================================
  // TOP HEADER
  // ===========================================================================

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: context.appPrimary,
        // gradient: context.appBackgroundGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.appOnPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: context.appOnPrimary.withValues(alpha: 0.10),
              ),
            ),
            child: Icon(
              Icons.event_note_rounded,
              color: context.appOnPrimary,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          // -------------------------------------------------------------------
          // TITLE
          // -------------------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Followups',
                  style: TextStyle(
                    color: context.appOnPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${_formatShortDate(fromDate)}  •  '
                  '${_formatShortDate(toDate)}',
                  style: TextStyle(
                    color: context.appOnPrimary.withValues(alpha: 0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // COUNT
          // -------------------------------------------------------------------
          BlocBuilder<FollowupBloc, FollowupState>(
            builder: (context, state) {
              if (state is FollowupSuccess) {
                return _buildCountBadge(state.followups.length);
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COUNT BADGE
  // ===========================================================================

  Widget _buildCountBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: context.appPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            'TOTAL',
            style: TextStyle(
              color: context.appSubText,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FILTER SECTION
  // ===========================================================================

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.shadow.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // =================================================================
          // FROM + TO + SEARCH
          // =================================================================
          Row(
            children: [
              Expanded(
                child: _buildDateBox(
                  title: 'FROM',
                  date: fromDate,
                  icon: Icons.calendar_month_rounded,
                  onTap: _selectFromDate,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _buildDateBox(
                  title: 'TO',
                  date: toDate,
                  icon: Icons.event_rounded,
                  onTap: _selectToDate,
                ),
              ),

              const SizedBox(width: 7),

              _buildSearchButton(),
            ],
          ),

          const SizedBox(height: 10),

          // =================================================================
          // DEALER / FARMER
          // =================================================================
          _buildTypeSelector(),
        ],
      ),
    );
  }

  // ===========================================================================
  // DATE BOX
  // ===========================================================================

  Widget _buildDateBox({
    required String title,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.appInputBackground,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: context.appCard,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: context.appPrimary),
              ),

              const SizedBox(width: 6),

              // Date
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 7.5,
                        color: context.appSubText,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      _formatShortDate(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.appOnCard,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TYPE SELECTOR
  // ===========================================================================

  Widget _buildTypeSelector() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appInputBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              title: 'Dealer',
              icon: Icons.storefront_rounded,
            ),
          ),

          Expanded(
            child: _buildTypeOption(
              title: 'Farmer',
              icon: Icons.agriculture_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TYPE OPTION
  // ===========================================================================

  Widget _buildTypeOption({required String title, required IconData icon}) {
    final bool selected = selectedType == title;

    return GestureDetector(
      onTap: () {
        _changeType(title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? context.appPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.appPrimary.withValues(alpha: 0.20),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected
                    ? context.appOnPrimary.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 15,
                color: selected ? context.appOnPrimary : context.appSubText,
              ),
            ),

            const SizedBox(width: 5),

            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? context.appOnPrimary : context.appSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SEARCH BUTTON
  // ===========================================================================

  Widget _buildSearchButton() {
    final bool enabled = userId.isNotEmpty;

    return Material(
      color: enabled ? context.appPrimary : context.appCard,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: enabled ? _loadFollowup : null,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 48,
          height: 52,
          child: Icon(
            Icons.search_rounded,
            color: enabled ? context.appOnPrimary : context.appSubText,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LIST
  // ===========================================================================

  Widget _buildFollowupList(List<FollowupEntity> followups) {
    return RefreshIndicator(
      color: context.appPrimary,
      onRefresh: () async {
        _loadFollowup();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 25),
        itemCount: followups.length,
        itemBuilder: (context, index) {
          return _buildFollowupCard(followups[index], index);
        },
      ),
    );
  }

  // ===========================================================================
  // FOLLOWUP CARD
  // ===========================================================================

  Widget _buildFollowupCard(FollowupEntity item, int index) {
    final bool isPhone = item.followupType.toLowerCase() == 'phone';

    final bool hasFollowupDate =
        item.followupDate.isNotEmpty && item.followupDate != item.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.shadow.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // LEFT TYPE INDICATOR
              // ---------------------------------------------------------------
              Container(
                width: 4,
                color: isPhone ? context.appPrimary : context.appPrimary,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(item),

                      const SizedBox(height: 11),

                      _buildDateTimeRow(item, hasFollowupDate),

                      // if (item.remark.isNotEmpty) ...[
                      //   const SizedBox(height: 9),
                      //   _buildRemark(
                      //     item.remark,
                      //   ),
                      // ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CARD HEADER
  // ===========================================================================

  Widget _buildCardHeader(FollowupEntity item) {
    final bool isPhone = item.followupType.toLowerCase() == 'phone';

    return Row(
      children: [
        // ---------------------------------------------------------------------
        // ICON
        // ---------------------------------------------------------------------
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPhone
                  ? [context.appCard, context.appCard]
                  : [context.appCard, context.appCard],
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isPhone ? Icons.phone_in_talk_rounded : Icons.storefront_rounded,
            color: isPhone ? context.appPrimary : context.appPrimary,
            size: 20,
          ),
        ),

        const SizedBox(width: 10),

        // ---------------------------------------------------------------------
        // NAME
        // ---------------------------------------------------------------------
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name.isEmpty ? 'Unknown' : item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: context.appOnCard,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    Icons.business_center_outlined,
                    size: 12,
                    color: context.appSubText,
                  ),

                  const SizedBox(width: 4),

                  Flexible(
                    child: Text(
                      item.type.isEmpty ? 'Followup' : item.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.appSubText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // ---------------------------------------------------------------------
        // TYPE CHIP
        // ---------------------------------------------------------------------
        if (item.time.isNotEmpty) _buildStatusChip(item.time, isPhone),
      ],
    );
  }

  // ===========================================================================
  // STATUS CHIP
  // ===========================================================================

  Widget _buildStatusChip(String type, bool isPhone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isPhone ? context.appCard : context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPhone ? context.appCard : context.appBorder,
        ),
      ),
    );
  }

  // ===========================================================================
  // DATE + TIME
  // ===========================================================================

  Widget _buildDateTimeRow(FollowupEntity item, bool hasFollowupDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: context.appInputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          // -------------------------------------------------------------------
          // DATE
          // -------------------------------------------------------------------
          _buildInfoItem(
            icon: Icons.calendar_today_rounded,
            label: 'DATE',
            value: item.date,
          ),

          Container(
            width: 1,
            height: 29,
            margin: const EdgeInsets.symmetric(horizontal: 9),
            color: context.appBorder,
          ),

          // -------------------------------------------------------------------
          // TIME
          // -------------------------------------------------------------------
          _buildInfoItem(
            icon: Icons.mobile_friendly,
            label: 'Mobile',
            value: item.mobileNo,
            onTap: item.mobileNo.trim().isEmpty
                ? null
                : () => _callMobile(item.mobileNo),
          ),

          // -------------------------------------------------------------------
          // FOLLOWUP DATE
          // -------------------------------------------------------------------
          if (hasFollowupDate) ...[
            const SizedBox(width: 8),

            Container(width: 1, height: 29, color: context.appBorder),

            const SizedBox(width: 8),

            Expanded(child: _buildNextDate(item.followupDate)),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // INFO ITEM
  // ===========================================================================

  Future<void> _callMobile(String mobileNo) async {
    final number = mobileNo.trim().replaceAll(RegExp(r'[\s().-]'), '');
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(number)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid mobile number.')));
      return;
    }
    try {
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: number),
        mode: LaunchMode.externalApplication,
      );
      if (opened || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open the phone dialer.')),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 14, color: context.appPrimary),

            const SizedBox(width: 6),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 7.5,
                      color: context.appSubText,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    value.isEmpty ? '--' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: context.appOnCard,
                      fontWeight: FontWeight.w700,
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

  // ===========================================================================
  // NEXT FOLLOWUP DATE
  // ===========================================================================

  Widget _buildNextDate(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          context.appPrimary.withValues(alpha: 0.1),
          context.appCard,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(Icons.event_repeat_rounded, size: 13, color: context.appPrimary),

          const SizedBox(width: 4),

          Expanded(
            child: Text(
              date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: context.appPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOADING
  // ===========================================================================

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 20),
      itemCount: 5,
      itemBuilder: (_, index) {
        return Container(
          height: 145,
          margin: const EdgeInsets.only(bottom: 9),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appBorder),
          ),
          child: Center(
            child: SizedBox(
              width: 23,
              height: 23,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: context.appPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  Widget _buildErrorState(String message) {
    return _buildStateContent(
      icon: Icons.cloud_off_rounded,
      iconColor: context.appError,
      title: 'Unable to load followups',
      subtitle: message,
      buttonText: 'Try Again',
    );
  }

  // ===========================================================================
  // EMPTY
  // ===========================================================================

  Widget _buildEmptyState() {
    return _buildStateContent(
      icon: Icons.event_available_rounded,
      iconColor: context.appPrimary,
      title: 'No followups found',
      subtitle:
          'No $selectedType followups are available for the selected date range.',
      buttonText: 'Refresh',
    );
  }

  // ===========================================================================
  // EMPTY / ERROR CONTENT
  // ===========================================================================

  Widget _buildStateContent({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // -----------------------------------------------------------------
            // ICON
            // -----------------------------------------------------------------
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 37, color: iconColor),
            ),

            const SizedBox(height: 17),

            // -----------------------------------------------------------------
            // TITLE
            // -----------------------------------------------------------------
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.appText,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 7),

            // -----------------------------------------------------------------
            // SUBTITLE
            // -----------------------------------------------------------------
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: context.appSubText,
              ),
            ),

            const SizedBox(height: 19),

            // -----------------------------------------------------------------
            // BUTTON
            // -----------------------------------------------------------------
            Material(
              color: context.appPrimary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _loadFollowup,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: context.appOnPrimary,
                        size: 17,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        buttonText,
                        style: TextStyle(
                          color: context.appOnPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
