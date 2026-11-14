import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../doman/home_entity/monthly_performance_entity.dart';

class EmployeeMonthMarquee extends StatefulWidget {
  final List<MonthlyPerformanceItemEntity> entries;
  const EmployeeMonthMarquee({super.key, required this.entries});

  @override
  State<EmployeeMonthMarquee> createState() => _EmployeeMonthMarqueeState();
}

class _EmployeeMonthMarqueeState extends State<EmployeeMonthMarquee>
    with SingleTickerProviderStateMixin {
  String _rankAward(int rank) => switch (rank) {
    1 => '\u{1F3C6}',
    2 => '\u{1F948}',
    3 => '\u{1F949}',
    _ => '\u{1F3C5}',
  };
  Widget _bouncingNames(List<String> names, TextStyle style) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final indexed in names.indexed) ...[
              if (indexed.$1 > 0) Text('   \u2022   ', style: style),
              Transform.translate(
                offset: Offset(
                  0,
                  reduceMotion
                      ? 0
                      : -2.5 *
                            math
                                .sin(
                                  _animation.value * math.pi * 24 +
                                      indexed.$1 * 0.6,
                                )
                                .abs(),
                ),
                child: Text(indexed.$2.split(' ').first, style: style),
              ),
              Text(indexed.$2.substring(indexed.$2.indexOf(' ')), style: style),
            ],
          ],
        ),
      ),
    );
  }

  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = [
      for (final entry in widget.entries)
        for (final indexed
            in entry.employeeNames
                .where((name) => name.trim().isNotEmpty)
                .indexed)
          '${_rankAward(indexed.$1 + 1)} ${indexed.$2.trim()}',
    ];
    if (names.isEmpty) return const SizedBox.shrink();
    final text = names.join('   \u2022   ');
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final textWidth = painter.width;
    final height = painter.height;
    painter.dispose();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Semantics(
            label: 'Employee of the Month: ${names.join(', ')}',
            excludeSemantics: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (textWidth <= constraints.maxWidth ||
                    MediaQuery.disableAnimationsOf(context)) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _bouncingNames(names, style),
                  );
                }
                final loopWidth = textWidth + 48;
                return SizedBox(
                  height: height + 6,
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        final offset = -_animation.value * loopWidth;
                        return Stack(
                          children: [
                            for (final left in [offset, offset + loopWidth])
                              Positioned(
                                left: left,
                                top: 0,
                                child: _bouncingNames(names, style),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
