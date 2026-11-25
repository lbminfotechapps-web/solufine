import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/features/dealer/data/models/DealerListModel.dart';
import '../bloc/dealerlist_bloc.dart';
import '../bloc/dealerlist_event.dart';
import '../bloc/dealerlist_state.dart';

class DealerDashboardPage extends StatelessWidget {
  final DealerListModel dealer;

  const DealerDashboardPage({super.key, required this.dealer});

  double? parseNumber(String? value) {
    final number = double.tryParse(
      (value ?? '')
          .replaceAll(',', '')
          .replaceAll('%', '')
          .replaceAll('₹', '')
          .trim(),
    );

    return number != null && number.isFinite ? number : null;
  }

  String money(String? value) {
    final number = parseNumber(value);

    return number == null
        ? '-'
        : '₹${NumberFormat('#,##0.00', 'en_IN').format(number)}';
  }

  void reloadDashboard(BuildContext context) {
    context.read<DealerListBloc>().add(
      DealerDashboardListEvent(dealerId: dealer.outletId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,

      appBar: CustomAppBar(
        title: 'Dealer Potential',
        showBackButton: true,
        onBackTap: () =>context.pop(),
      ),

      // appBar: AppBar(
      //   elevation: 0,
      //   title: const Text('Dealer Dashboard'),
      //   backgroundColor: context.primaryColor,
      //   foregroundColor: context.onPrimaryColor,
      //   actions: [
      //     IconButton(
      //       tooltip: 'Refresh',
      //       onPressed: () => reloadDashboard(context),
      //       icon: const Icon(Icons.refresh_rounded),
      //     ),
      //   ],
      // ),
      body: BlocBuilder<DealerListBloc, DealerListState>(
        builder: (context, state) {
          if (state.status == DealerListStatus.loading ||
              state.status == DealerListStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == DealerListStatus.failure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? 'Unable to load dashboard'),

                  TextButton(
                    onPressed: () => reloadDashboard(context),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = state.dashboard?.result;

          if (data == null) {
            return const Center(child: Text('No dashboard data available.'));
          }

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // ========================================
              // DEALER INFORMATION
              // ========================================
              _dealerHeader(context),

              const SizedBox(height: 14),

              // ========================================
              // SALES PERFORMANCE CARD
              // ========================================
              _salesPerformanceCard(
                context,
                thisYear: data.thisYear,
                lastYear: data.lastYear,
                thisYearSales: data.thisYearSales,
                lastYearSales: data.lastYearSales,
                potential: data.dealerPotential,
                growth: data.growthPercent,
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: _cardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: context.primaryColor,
                            size: 21,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Product-wise Opportunity',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.cardTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (data.products.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No product data available.'),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          horizontalMargin: 12,
                          columnSpacing: 20,
                          headingRowHeight: 45,
                          dataRowMinHeight: 44,
                          dataRowMaxHeight: 56,

                          border: TableBorder.all(
                            color: context.cardTextColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),

                          headingRowColor: WidgetStateProperty.all(
                            context.primaryColor.withOpacity(0.08),
                          ),

                          headingTextStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.cardTextColor,
                          ),

                          dataTextStyle: TextStyle(
                            fontSize: 12,
                            color: context.cardTextColor,
                          ),

                          columns: const [
                            DataColumn(label: Text('Product')),
                            DataColumn(
                              label: Text('Last Year Sales'),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text('This Year Sales'),
                              numeric: true,
                            ),
                            DataColumn(label: Text('Growth'), numeric: true),
                            DataColumn(label: Text('Potential'), numeric: true),
                          ],

                        rows: [
  for (final product in data.products)
    DataRow(
      cells: [
        DataCell(Text(product.productName)),
        DataCell(Text(money(product.lastYearSales))),
        DataCell(Text(money(product.thisYearSales))),
        DataCell(_tableGrowth(product.growthPercent)),
        DataCell(Text(money(product.potential))),
      ],
    ),

  // ==========================================
  // GRAND TOTAL ROW
  // ==========================================
  DataRow(
    color: WidgetStateProperty.all(
      context.primaryColor.withOpacity(0.12),
    ),
    cells: [
      const DataCell(
        Text(
          'Total',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      DataCell(
        Text(
          money(data.total.lastYearSales),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      DataCell(
        Text(
          money(data.total.thisYearSales),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      DataCell(
        _tableGrowth(data.total.growthPercent),
      ),

      DataCell(
        Text(
          money(data.total.dealerPotential),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.primaryColor,
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
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

Widget _dealerHeader(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    ),
    decoration: _cardDecoration(context),
    child: Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: context.primaryColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: context.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dealer.outletName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.cardTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Dealer Sales Dashboard',
                style: TextStyle(
                  fontSize: 10,
                  color: context.cardTextColor.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  // ==================================================
  // SALES PERFORMANCE CARD
  // ==================================================

Widget _salesPerformanceCard(
  BuildContext context, {
  required String thisYear,
  required String lastYear,
  required String thisYearSales,
  required String lastYearSales,
  required String potential,
  required String growth,
}) {
  final growthValue = parseNumber(growth);
  final foreground = context.onPrimaryColor;

  final growthColor = growthValue == null
      ? foreground.withOpacity(0.7)
      : growthValue < 0
          ? const Color(0xffFDA4AF)
          : growthValue > 0
              ? const Color(0xff86EFAC)
              : foreground.withOpacity(0.7);

  final growthIcon = growthValue == null
      ? Icons.remove_rounded
      : growthValue < 0
          ? Icons.trending_down_rounded
          : growthValue > 0
              ? Icons.trending_up_rounded
              : Icons.trending_flat_rounded;

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.primaryColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          children: [
            Icon(
              Icons.insights_rounded,
              color: foreground,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Sales Performance',
              style: TextStyle(
                fontSize: 13,
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // CURRENT & PREVIOUS YEAR SALES
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _salesValue(
                context,
                title: 'This Year Sales',
                year: thisYear,
                value: money(thisYearSales),
              ),
            ),

            Container(
              width: 1,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: foreground.withOpacity(0.15),
            ),

            Expanded(
              child: _salesValue(
                context,
                title: 'Last Year Sales',
                year: lastYear,
                value: money(lastYearSales),
              ),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(
            height: 1,
            color: foreground.withOpacity(0.18),
          ),
        ),

        // DEALER POTENTIAL & GROWTH
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _salesValue(
                context,
                title: 'Dealer Potential',
                year: '',
                value: money(potential),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Growth',
                    style: TextStyle(
                      fontSize: 11,
                      color: foreground.withOpacity(0.75),
                    ),
                  ),

                  const SizedBox(height: 4),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          growthIcon,
                          color: growthColor,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          growthValue == null
                              ? '-'
                              : '${growthValue > 0 ? '+' : ''}'
                                  '${growthValue.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: growthColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ==================================================
  // SALES VALUE
  // ==================================================

Widget _salesValue(
  BuildContext context, {
  required String title,
  required String year,
  required String value,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        year.isEmpty ? title : '$title ($year)',
        style: TextStyle(
          color: context.onPrimaryColor.withOpacity(0.75),
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      const SizedBox(height: 4),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.onPrimaryColor,
          ),
        ),
      ),
    ],
  );
}

  // ==================================================
  // OUTSTANDING & OVERDUE CARD
  // ==================================================

  // ==================================================
  // TABLE GROWTH INDICATOR
  // ==================================================

  Widget _tableGrowth(String value) {
    final growth = parseNumber(value);

    final color = growth == null
        ? Colors.grey
        : growth < 0
        ? const Color(0xffDC2626)
        : growth > 0
        ? const Color(0xff16875B)
        : Colors.grey;

    return Text(
      growth == null
          ? '-'
          : '${growth > 0 ? '+' : ''}'
                '${growth.toStringAsFixed(2)}%',
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
    );
  }

  // ==================================================
  // COMMON CARD DECORATION
  // ==================================================

BoxDecoration _cardDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: context.cardTextColor.withOpacity(0.08),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.025),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
}
