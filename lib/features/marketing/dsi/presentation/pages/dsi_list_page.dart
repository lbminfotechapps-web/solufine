import 'package:flutter/material.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/router/app_router.dart';

import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';

import '../../domain/entities/dsi_entity.dart';
import '../bloc/dsi_bloc.dart';

class DsiListPage extends StatefulWidget {
  const DsiListPage({super.key});

  @override
  State<DsiListPage> createState() => _DsiListPageState();
}

class _DsiListPageState extends State<DsiListPage> {
  String _userId = '';
  final _scrollController = ScrollController();

  String _effectiveness = 'Time';

  DateTime? _fromDate;
  DateTime? _toDate;

  // Java list dates use day-month-year.
  final DateFormat _dateFormat = DateFormat('d-M-yyyy');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) _loadMore();
  }

  void _loadMore() {
    final bloc = context.read<DsiBloc>();
    if (_userId.isEmpty ||
        bloc.state.loading ||
        bloc.state.loadingMore ||
        !bloc.state.hasMore) {
      return;
    }
    bloc.add(LoadDsiList(DsiFilter(userId: _userId), loadMore: true));
  }

  Future<void> _initialize() async {
    try {
      final user = await SecureStorage.instance.getUserData();

      if (!mounted) return;

      _userId = user?['user_id']?.toString() ?? '';

      if (_userId.isNotEmpty) {
        _fetchList();
      } else {
        _message('Please log in again.');
      }
    } catch (e) {
      _message('Unable to load user details.');
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  String get _filterEffectiveness =>
      _effectiveness == 'Select Effectiveness' ? '' : _effectiveness;

  void _fetchList() {
    if (_userId.isEmpty) return;

    context.read<DsiBloc>().add(
      LoadDsiList(
        DsiFilter(
          userId: _userId,
          searchText: _filterEffectiveness,
          fromDate: _fromDate == null ? '' : _dateFormat.format(_fromDate!),
          toDate: _toDate == null ? '' : _dateFormat.format(_toDate!),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final bloc = context.read<DsiBloc>();

    _fetchList();

    // Wait for the current list loading state
    // to finish so the refresh indicator behaves properly.
    await bloc.stream.firstWhere((state) => !state.loading);
  }

  // ======================================================
  // DATE FILTER
  // ======================================================

  Future<void> _chooseDate({required bool from}) async {
    final now = DateTime.now();

    final initial = from ? (_fromDate ?? now) : (_toDate ?? _fromDate ?? now);

    final earliest = from ? DateTime(2020) : (_fromDate ?? DateTime(2020));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: earliest,
      lastDate: now,
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (from) {
        _fromDate = picked;

        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = null;
        }
      } else {
        _toDate = picked;
      }
    });

    // Refresh after both dates are selected.
    if (_fromDate != null && _toDate != null) {
      _fetchList();
    }
  }

  void _clearDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });

    _fetchList();
  }

  Future<void> _openAddDsi() async {
    final created = await context.push<bool>('/dsi/add');

    if (!mounted) return;

    if (created == true) {
      _fetchList();
    }
  }

  // ======================================================
  // DATE FIELD
  // ======================================================

  Widget _dateFilter({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: context.primaryColor,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  date == null ? label : DateFormat('dd MMM yyyy').format(date),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: date == null
                        ? context.secondaryTextColor
                        : context.primaryTextColor,
                    fontSize: 11,
                    fontWeight: date == null
                        ? FontWeight.w400
                        : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // FILTER PANEL
  // ======================================================

  Widget _filterPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _dateFilter(
                label: 'From Date',
                date: _fromDate,
                onTap: () => _chooseDate(from: true),
              ),

              const SizedBox(width: 8),

              _dateFilter(
                label: 'To Date',
                date: _toDate,
                onTap: () => _chooseDate(from: false),
              ),

              if (_fromDate != null || _toDate != null)
                IconButton(
                  tooltip: 'Clear date filters',
                  onPressed: _clearDates,
                  icon: Icon(Icons.close, color: context.appColors.error),
                ),
            ],
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            dropdownColor: context.cardBackgroundColor,
            style: TextStyle(color: context.cardTextColor),
            iconEnabledColor: context.primaryColor,
            value: _effectiveness,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Effectiveness',
              prefixIcon: Icon(
                Icons.filter_alt_outlined,
                color: context.primaryColor,
              ),
              isDense: true,
            ),
            items: DsiEffectiveness.listOptions
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() => _effectiveness = value);
              _fetchList();
            },
          ),
        ],
      ),
    );
  }

  // ======================================================
  // DSI CARD
  // ======================================================

  void _viewImage(String imageUrl) {
    showDialog<void>(
      context: context,
      useSafeArea: true,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: dialogContext.cardBackgroundColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          height: MediaQuery.sizeOf(dialogContext).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 4, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'DSI photo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: dialogContext.cardTextColor,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close image',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      semanticLabel: 'DSI activity photo',
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : Center(
                              child: CircularProgressIndicator(
                                color: context.primaryColor,
                              ),
                            ),
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 36,
                            color: context.secondaryTextColor,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Photo unavailable',
                            style: TextStyle(color: context.secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Pinch to zoom',
                  style: TextStyle(
                    fontSize: 11,
                    color: dialogContext.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _savingTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.cardTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dsiCard(DsiRecord record) {
    final time = record.saveTime.trim();
    final money = record.saveMoney.trim();
    final timeLabel = time.isEmpty
        ? '—'
        : RegExp(r'[a-zA-Z]').hasMatch(time)
        ? time
        : '$time min';
    final moneyLabel = money.isEmpty
        ? '—'
        : RegExp(r'₹|INR|Rs\.?', caseSensitive: false).hasMatch(money)
        ? money
        : '₹$money';
    final imagePath = record.imageUrl.trim();
    final imageUrl = imagePath.isEmpty
        ? ''
        : Uri.parse(ApiClient.dsiImageBaseUrl).resolve(imagePath).toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor.withValues(alpha: .12),
                  context.primaryColor.withValues(alpha: .03),
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: context.onPrimaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'DSI Date: ${record.date.isEmpty ? '—' : record.date}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: context.cardTextColor,
                              ),
                            ),
                          ),
                          if (imageUrl.isNotEmpty)
                            TextButton(
                              onPressed: () => _viewImage(imageUrl),
                              style: TextButton.styleFrom(
                                foregroundColor: context.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('View image'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (record.effectiveness.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 17,
                        color: context.secondaryTextColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Effectiveness: ${record.effectiveness}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _savingTile(
                        Icons.timer_outlined,
                        'Save Time',
                        timeLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _savingTile(
                        Icons.savings_outlined,
                        'Save Money',
                        moneyLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Description: ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: record.description.isEmpty
                            ? 'No description provided.'
                            : record.description,
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: context.cardTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ======================================================
  // MAIN BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DsiBloc, DsiState>(
      listenWhen: (previous, current) => previous.error != current.error,

      listener: (context, state) {
        if (state.error != null) {
          _message(state.error!);
          context.read<DsiBloc>().add(const ClearDsiMessage());
        }
      },

      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.backgroundColor,

          appBar: CustomAppBar(
            backgroundColor: context.primaryColor,
            titleStyle: AppTextStyles.appBarTitle.copyWith(
              color: context.onPrimaryColor,
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: context.onPrimaryColor,
              ),
              onPressed: () => context.go(AppRouter.home),
            ),
            title: 'DSI Activities',

            showBackButton: true,

            actionIcon: Icons.refresh_rounded,

            onBackTap: () => context.go(AppRouter.home),

            onActionIconTap: _fetchList,
          ),

          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: _filterPanel(),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    Text(
                      'DSI Records',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.records.length} records',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  color: context.primaryColor,
                  onRefresh: _refresh,
                  child: state.loading && state.records.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : state.records.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * .14,
                            ),
                            Icon(
                              Icons.inbox_outlined,
                              size: 55,
                              color: context.secondaryTextColor,
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No DSI Records Found',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: context.primaryTextColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                'Try changing your filters or add a DSI.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 95),
                          controller: _scrollController,
                          itemCount:
                              state.records.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.records.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: state.loadingMore
                                      ? CircularProgressIndicator(
                                          color: context.primaryColor,
                                        )
                                      : TextButton(
                                          onPressed: _loadMore,
                                          child: const Text('Load more'),
                                        ),
                                ),
                              );
                            }
                            return _dsiCard(state.records[index]);
                          },
                        ),
                ),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddDsi,
            backgroundColor: context.primaryColor,
            foregroundColor: context.onPrimaryColor,
            icon: const Icon(Icons.add),
            label: const Text(
              'Add DSI',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    );
  }
}
