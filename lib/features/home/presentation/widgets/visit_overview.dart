import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl/intl.dart';

import 'package:solufine/features/home/doman/home_entity/homevisit_entity.dart';

class VisitOverviewCard extends StatefulWidget {
  final VoidCallback? onViewReport;
  final String dealerCount;
  final String farmerCount;
  final List<DayWiseVisitEntity> dayWise;
  final bool isOpen;

  const VisitOverviewCard({
    super.key,
    this.onViewReport,
    required this.dealerCount,
    required this.farmerCount,
    required this.dayWise,
    this.isOpen = false,
  });

  @override
  State<VisitOverviewCard> createState() => _VisitOverviewCardState();
}

class _VisitOverviewCardState extends State<VisitOverviewCard> {
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.isOpen;
  }

  @override
  void didUpdateWidget(covariant VisitOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) _isOpen = widget.isOpen;
  }

  static const Color _dealerColor = Color(0xFF2563EB);
  static const Color _farmerColor = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // HEADER
          // ==========================================================
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  gradient: context.appBackgroundGradient,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: context.appOnPrimary,
                  size: 21.sp,
                ),
              ),

              SizedBox(width: 10.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visit Overview',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: context.appOnCard,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Last 8 days overview ',
                      style: AppTextStyles.helperText.copyWith(
                        color: context.appSubText,
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.onViewReport != null)
                InkWell(
                  onTap: widget.onViewReport,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: AppTextStyles.badge.copyWith(
                            color: _dealerColor,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10.sp,
                          color: _dealerColor,
                        ),
                      ],
                    ),
                  ),
                ),
              InkWell(
                onTap: () {
                  setState(() => _isOpen = !_isOpen);
                },
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                   decoration: BoxDecoration(
                  gradient: context.appBackgroundGradient,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                  child: Text('View Report',
                    style: AppTextStyles.badge.copyWith(
                      color: context.appOnPrimary,
                    ),
                  ),
                ),
              ),

              // IconButton(
              //   onPressed: () {
              //     setState(() => _isOpen = !_isOpen);
              //   },
              //   tooltip: _isOpen
              //       ? 'Collapse visit chart'
              //       : 'Expand visit chart',
              //   icon: Icon(
              //     _isOpen
              //         ? Icons.keyboard_arrow_up_rounded
              //         : Icons.keyboard_arrow_down_rounded,
              //     size: 20.sp,
              //     color: context.appSubText,
              //   ),
              // ),
            ],
          ),

          SizedBox(height: 8.h),

          // ==========================================================
          // TOTAL CARDS
          // ==========================================================
          Row(
            children: [
              Expanded(
                child: _CompactStatCard(
                  title: 'Dealer Visits',
                  value: widget.dealerCount,
                  icon: Icons.storefront_rounded,
                  color: _dealerColor,
                  background: Color.alphaBlend(
                    _dealerColor.withValues(alpha: 0.1),
                    context.appCard,
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              Expanded(
                child: _CompactStatCard(
                  title: 'Farmer Visits',
                  value: widget.farmerCount,
                  icon: Icons.agriculture_rounded,
                  color: _farmerColor,
                  background: Color.alphaBlend(
                    _farmerColor.withValues(alpha: 0.1),
                    context.appCard,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          if (_isOpen) ...[
            Row(
              children: [
                Text(
                  'Visit Trend',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: context.appOnCard,
                  ),
                ),

                const Spacer(),

                const _LegendItem(color: _dealerColor, label: 'Dealer'),

                SizedBox(width: 12.w),

                const _LegendItem(color: _farmerColor, label: 'Farmer'),
              ],
            ),

            SizedBox(height: 8.h),

            // ==========================================================
            // CHART
            // ==========================================================
            Container(
              height: 190.h,
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(4.w, 6.h, 6.w, 0),
              decoration: BoxDecoration(
                color: context.appInputBackground,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: context.appBorder),
              ),
              child: _VisitLineChart(dayWise: widget.dayWise),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// COMPACT STAT CARD
// ============================================================================

class _CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),

          SizedBox(width: 9.w),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.appSubText,
                  ),
                ),

                SizedBox(height: 2.h),

                Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.cardValue.copyWith(
                    color: color,
                    height: 1,
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

// ============================================================================
// LEGEND
// ============================================================================

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7.w,
          height: 7.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: context.appSubText),
        ),
      ],
    );
  }
}

// ============================================================================
// VISIT LINE CHART
// ============================================================================

class _VisitLineChart extends StatelessWidget {
  final List<DayWiseVisitEntity> dayWise;

  const _VisitLineChart({required this.dayWise});

  static const Color dealerColor = Color(0xFF2563EB);

  static const Color farmerColor = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    if (dayWise.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: context.appInputBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insert_chart_outlined_rounded,
                color: context.appSubText,
                size: 21.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'No visit data available',
              style: AppTextStyles.helperText.copyWith(
                color: context.appSubText,
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // SPOTS
    // ============================================================

    final List<FlSpot> dealerSpots = List.generate(
      dayWise.length,
      (index) => FlSpot(
        index.toDouble(),
        double.tryParse(dayWise[index].dealerCount) ?? 0,
      ),
    );

    final List<FlSpot> farmerSpots = List.generate(
      dayWise.length,
      (index) => FlSpot(
        index.toDouble(),
        double.tryParse(dayWise[index].farmerCount) ?? 0,
      ),
    );

    // ============================================================
    // MAX VALUE
    // ============================================================

    double maxCount = 0;

    for (final item in dayWise) {
      final dealer = double.tryParse(item.dealerCount) ?? 0;

      final farmer = double.tryParse(item.farmerCount) ?? 0;

      maxCount = math.max(maxCount, math.max(dealer, farmer));
    }

    final yInterval = _calculateYInterval(maxCount);

    final maxY = _calculateMaxY(maxCount, yInterval);

    final maxX = dayWise.length > 1 ? (dayWise.length - 1).toDouble() : 1.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,

        // ========================================================
        // GRID
        // ========================================================
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: context.appBorder, strokeWidth: 1);
          },
        ),

        // ========================================================
        // BORDER
        // ========================================================
        borderData: FlBorderData(show: false),

        // ========================================================
        // TITLES
        // ========================================================
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25.w,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxY) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _formatYAxis(value),
                    style: AppTextStyles.helperText.copyWith(
                      color: context.appSubText,
                    ),
                  ),
                );
              },
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28.h,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();

                if (index < 0 || index >= dayWise.length) {
                  return const SizedBox.shrink();
                }

                if ((value - index).abs() > 0.01) {
                  return const SizedBox.shrink();
                }

                final date = DateTime.tryParse(dayWise[index].date);

                if (date == null) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  space: 7.h,
                  child: Text(
                    DateFormat('dd MMM').format(date),
                    style: AppTextStyles.helperText.copyWith(
                      color: context.appSubText,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ========================================================
        // TOOLTIP
        // ========================================================
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final bool isDealer = spot.barIndex == 0;

                return LineTooltipItem(
                  '${isDealer ? 'Dealer' : 'Farmer'}  ${spot.y.toInt()}',
                  AppTextStyles.badge.copyWith(
                    color: isDealer ? dealerColor : farmerColor,
                  ),
                );
              }).toList();
            },
          ),
        ),

        // ========================================================
        // LINES
        // ========================================================
        lineBarsData: [
          // Dealer
          LineChartBarData(
            spots: dealerSpots,

            isCurved: true,
            curveSmoothness: 0.22,

            color: dealerColor,

            barWidth: 2.8,

            isStrokeCapRound: true,

            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.8,
                  color: context.appCard,
                  strokeWidth: 2.2,
                  strokeColor: dealerColor,
                );
              },
            ),

            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  dealerColor.withOpacity(0.15),
                  dealerColor.withOpacity(0.00),
                ],
              ),
            ),
          ),

          // Farmer
          LineChartBarData(
            spots: farmerSpots,

            isCurved: true,
            curveSmoothness: 0.22,

            color: farmerColor,

            barWidth: 2.8,

            isStrokeCapRound: true,

            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.8,
                  color: context.appCard,
                  strokeWidth: 2.2,
                  strokeColor: farmerColor,
                );
              },
            ),

            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  farmerColor.withOpacity(0.10),
                  farmerColor.withOpacity(0.00),
                ],
              ),
            ),
          ),
        ],
      ),

      duration: const Duration(milliseconds: 450),

      curve: Curves.easeOutCubic,
    );
  }

  // ==========================================================================
  // DYNAMIC Y INTERVAL
  // ==========================================================================

  double _calculateYInterval(double maxCount) {
    if (maxCount <= 5) {
      return 1;
    }

    if (maxCount <= 10) {
      return 2;
    }

    if (maxCount <= 25) {
      return 5;
    }

    if (maxCount <= 50) {
      return 10;
    }

    if (maxCount <= 100) {
      return 20;
    }

    if (maxCount <= 250) {
      return 50;
    }

    if (maxCount <= 500) {
      return 100;
    }

    if (maxCount <= 1000) {
      return 200;
    }

    return _niceNumber(maxCount / 5);
  }

  // ==========================================================================
  // DYNAMIC MAX Y
  // ==========================================================================

  double _calculateMaxY(double maxCount, double interval) {
    if (maxCount <= 0) {
      return 5;
    }

    final rounded = (maxCount / interval).ceil() * interval;

    return rounded + interval;
  }

  // ==========================================================================
  // NICE NUMBER
  // ==========================================================================

  double _niceNumber(double value) {
    if (value <= 0) {
      return 1;
    }

    final exponent = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();

    final fraction = value / exponent;

    double niceFraction;

    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }

    return niceFraction * exponent;
  }

  // ==========================================================================
  // FORMAT Y AXIS
  // ==========================================================================

  String _formatYAxis(double value) {
    if (value >= 1000000) {
      final result = value / 1000000;

      if (result == result.roundToDouble()) {
        return '${result.toInt()}M';
      }

      return '${result.toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      final result = value / 1000;

      if (result == result.roundToDouble()) {
        return '${result.toInt()}K';
      }

      return '${result.toStringAsFixed(1)}K';
    }

    return value.toInt().toString();
  }
}
