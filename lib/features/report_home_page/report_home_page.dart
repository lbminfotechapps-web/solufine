
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dynamic_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/secure_storage/secure_storage.dart';
import '../../core/utility/widgets/custom_appbar.dart';

import '../home/doman/home_entity/menu_entity.dart';
import '../home/presentation/home_bloc/home_bloc.dart';
import '../home/presentation/home_bloc/home_event.dart';
import '../home/presentation/home_bloc/home_state.dart';

class ReportsHomePage extends StatelessWidget {
  const ReportsHomePage({super.key});

  // =====================================================
  // ALLOWED REPORT MENU IDs
  // =====================================================

  static const List<String> _menuIds = [
    '32',
    '63',
    '65',
    '57',
    '64',
    '86',
    '87',
    '89',
  ];

  // =====================================================
  // ROUTES
  // =====================================================

  static const Map<String, String> _routes = {
    '32': AppRouter.empActivityReport,
    '63': AppRouter.empOutputReport,
    '65': AppRouter.noVisitDealer,
    '57': AppRouter.visitSummaryReport,
    '64': AppRouter.topTenDealer,
    '87': AppRouter.monthlyVisitPerformanceReport,
    '89': AppRouter.growthReport,
  };

  // =====================================================
  // RELOAD REPORT MENUS
  // =====================================================

  Future<void> _reloadMenus(BuildContext context) async {
    final data = await SecureStorage.instance.getUserData();

    if (!context.mounted) return;

    final userId = int.tryParse(
          data?['user_id']?.toString() ?? '',
        ) ??
        0;

    context.read<HomeBloc>().add(
          GetMenuEvent(
            userId,
            userId == 0 ? '0' : '1',
          ),
        );
  }

  // =====================================================
  // RESOLVE ROUTE
  // =====================================================

  String? _routeForMenu(MenuEntity menu) {
    final id = menu.menuId.trim();

    final name = menu.menuName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (id == '89' ||
        name.contains('degrowth') ||
        name.contains('growth')) {
      return AppRouter.growthReport;
    }

    if (name.contains('salespersonstat') ||
        name.contains('salesmanstat') ||
        name.contains('monthlyperformance') ||
        name.contains('performanceanalysis')) {
      return AppRouter.monthlyPerformanceReport;
    }

    if (name.contains('employeeactivity') ||
        name.contains('empactivity')) {
      return AppRouter.empActivityReport;
    }

    if (name.contains('employeeoutput') ||
        name.contains('empoutput')) {
      return AppRouter.empOutputReport;
    }

    if (name.contains('visitsummary')) {
      return AppRouter.visitSummaryReport;
    }

    if (name.contains('notvisitdealer') ||
        name.contains('nonvisiteddealer') ||
        name.contains('notvisiteddealer')) {
      return AppRouter.noVisitDealer;
    }

    if (name.contains('toptendealer') ||
        name.contains('top10dealer')) {
      return AppRouter.topTenDealer;
    }

    return _routes[id];
  }

  // =====================================================
  // OPEN REPORT
  // =====================================================

  Future<void> _openMenu(
    BuildContext context,
    MenuEntity menu,
  ) async {
    final route = _routeForMenu(menu);

    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            '${menu.menuName} is not available yet',
          ),
        ),
      );
      return;
    }

    debugPrint('REPORT: ${menu.menuName}');
    debugPrint('ROUTE: $route');

    if ([
      AppRouter.empActivityReport,
      AppRouter.empOutputReport,
      AppRouter.visitSummaryReport,
    ].contains(route)) {
      final data =
          await SecureStorage.instance.getUserData();

      if (!context.mounted) return;

      context.push(
        route,
        extra: data?['user_id']?.toString() ?? '',
      );
    } else {
      if (!context.mounted) return;

      context.push(route);
    }
  }

  // =====================================================
  // REPORT ICON
  // =====================================================

  IconData _iconForMenu(MenuEntity menu) {
    final name = menu.menuName.toLowerCase();

    if (name.contains('growth')) {
      return Icons.trending_up_rounded;
    }

    if (name.contains('performance') ||
        name.contains('salesman')) {
      return Icons.insights_rounded;
    }

    if (name.contains('activity')) {
      return Icons.groups_outlined;
    }

    if (name.contains('output')) {
      return Icons.bar_chart_rounded;
    }

    if (name.contains('summary')) {
      return Icons.route_outlined;
    }

    if (name.contains('not visit')) {
      return Icons.location_off_outlined;
    }

    if (name.contains('top')) {
      return Icons.emoji_events_outlined;
    }

    if (name.contains('visit')) {
      return Icons.location_on_outlined;
    }

    return Icons.analytics_outlined;
  }

  // =====================================================
  // REPORT DESCRIPTION
  // =====================================================

  String _descriptionForMenu(MenuEntity menu) {
    final name = menu.menuName.toLowerCase();

    if (name.contains('growth')) {
      return 'Dealer growth insights';
    }

    if (name.contains('performance') ||
        name.contains('salesman')) {
      return 'Performance analytics';
    }

    if (name.contains('activity')) {
      return 'Field activity tracking';
    }

    if (name.contains('output')) {
      return 'Employee productivity';
    }

    if (name.contains('summary')) {
      return 'Dealer & farmer coverage';
    }

    if (name.contains('not visit')) {
      return 'Pending dealer coverage';
    }

    if (name.contains('top')) {
      return 'Top dealer ranking';
    }

    if (name.contains('visit')) {
      return 'Visit analysis';
    }

    return 'Business insights';
  }

  // =====================================================
  // REPORT TAG
  // =====================================================

  String _tagForMenu(MenuEntity menu) {
    final name = menu.menuName.toLowerCase();

    if (name.contains('growth')) {
      return 'GROWTH';
    }

    if (name.contains('performance') ||
        name.contains('salesman')) {
      return 'ANALYTICS';
    }

    if (name.contains('activity')) {
      return 'ACTIVITY';
    }

    if (name.contains('output')) {
      return 'OUTPUT';
    }

    if (name.contains('visit')) {
      return 'VISITS';
    }

    if (name.contains('top')) {
      return 'RANKING';
    }

    return 'REPORT';
  }

  // =====================================================
  // PAGE
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,

      appBar: CustomAppBar(
        title: 'Reports',
        showBackButton: true,
        onBackTap: () => context.go(AppRouter.home),
      ),

      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // Only display menus returned by the API
            // and permitted in _menuIds.

            final menusById = <String, MenuEntity>{
              for (final menu in state.menus)
                if (_menuIds.contains(menu.menuId.trim()))
                  menu.menuId.trim(): menu,
            };

            final menus = <MenuEntity>[
              for (final id in _menuIds)
                if (menusById[id] != null)
                  menusById[id]!,
            ];

            if (state.status == HomeStatus.loading &&
                state.menus.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  color: context.appPrimary,
                ),
              );
            }

            if (state.status == HomeStatus.failure &&
                state.menus.isEmpty) {
              return _errorState(context);
            }

            return RefreshIndicator(
              color: context.appPrimary,
              onRefresh: () => _reloadMenus(context),
              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // HERO
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      12, 12, 12, 0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _heroCard(
                        context,
                        menus.length,
                      ),
                    ),
                  ),

                  // HEADER
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      13, 16, 13, 10,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _sectionHeader(
                        context,
                        menus.length,
                      ),
                    ),
                  ),

                  // EMPTY
                  if (menus.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyReports(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        12, 0, 12, 20,
                      ),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width =
                              constraints.crossAxisExtent;

                          int columns = 2;

                          if (width >= 1050) {
                            columns = 5;
                          } else if (width >= 780) {
                            columns = 4;
                          } else if (width >= 560) {
                            columns = 3;
                          }

                          return SliverGrid(
                            delegate:
                                SliverChildBuilderDelegate(
                              (context, index) {
                                final menu = menus[index];

                                return 
                                _reportTile(
                                  context,
                                  menu,
                                );
                              },
                              childCount: menus.length,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,

                              // Stable height, avoids
                              // card text overflow.
                              mainAxisExtent: 154,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // =====================================================
  // COMPACT HERO CARD
  // =====================================================

  Widget _heroCard(
    BuildContext context,
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.appPrimary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: context.appPrimary.withValues(
              alpha: 0.16,
            ),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.appOnPrimary.withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.analytics_rounded,
              size: 24,
              color: context.appOnPrimary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.appOnPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Track performance and field insights',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appOnPrimary
                        .withValues(alpha: 0.83),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: context.appOnPrimary,
                ),
              ),

              Text(
                'Reports',
                style: TextStyle(
                  color: context.appOnPrimary
                      .withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SECTION HEADER
  // =====================================================

  Widget _sectionHeader(
    BuildContext context,
    int count,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Explore Reports',
            style: TextStyle(
              color: context.appText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: context.appPrimary.withValues(
              alpha: 0.09,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count available',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.appPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // MODERN REPORT TILE
  // =====================================================

  Widget _reportTile(
    BuildContext context,
    MenuEntity menu,
  ) {
    final icon = _iconForMenu(menu);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _openMenu(context, menu),
        child: Ink(
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: context.appBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withValues(alpha: 0.025),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ICON + NAVIGATION HINT
                Row(
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: context.appPrimary.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                            BorderRadius.circular(11),
                      ),
                      child: menu.iconImage.trim().isEmpty
                          ? Icon(
                              icon,
                              color: context.appPrimary,
                              size: 21,
                            )
                          : Image.network(
                              menu.iconImage,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return Icon(
                                  icon,
                                  color: context.appPrimary,
                                  size: 21,
                                );
                              },
                            ),
                    ),

                    const Spacer(),

                    Icon(
                      Icons.north_east_rounded,
                      color: context.appSubText,
                      size: 17,
                    ),
                  ],
                ),

                const Spacer(),

                // REPORT NAME
                Text(
                  menu.menuName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appOnCard,
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                // REPORT DESCRIPTION
                Text(
                  _descriptionForMenu(menu),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appSubText,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 8),

                // SMALL CATEGORY LABEL
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.appPrimary.withValues(
                        alpha: 0.07,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      _tagForMenu(menu),
                      style: TextStyle(
                        color: context.appPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // ERROR STATE
  // =====================================================

  Widget _errorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 45,
              color: context.appError,
            ),

            const SizedBox(height: 10),

            Text(
              'Unable to load reports',
              style: TextStyle(
                color: context.appText,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Please check your internet connection',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appSubText,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: () => _reloadMenus(context),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// EMPTY STATE
// =====================================================

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 48,
              color: context.appPrimary,
            ),

            const SizedBox(height: 10),

            Text(
              'No Reports Available',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: context.appText,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'No report menus are assigned to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: context.appSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
