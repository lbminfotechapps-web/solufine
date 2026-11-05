import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_detail_entity.dart';

// Import your existing monthly performance detail entity file.

class EmployeeMonthRankingDialog extends StatefulWidget {
  final MonthlyPerformanceDetailEntity data;

  final String imageBaseUrl;

  const EmployeeMonthRankingDialog({
    super.key,
    required this.data,
    this.imageBaseUrl = ApiClient.employeeImageBaseUrl,
  });

  @override
  State<EmployeeMonthRankingDialog> createState() =>
      _EmployeeMonthRankingDialogState();
}

class _EmployeeSlide {
  final String monthYear;
  final MonthlyPerformanceRankEntity employee;

  const _EmployeeSlide({required this.monthYear, required this.employee});
}

class _EmployeeMonthRankingDialogState
    extends State<EmployeeMonthRankingDialog> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;

  int _currentPage = 0;
  late final List<_EmployeeSlide> _slides;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // Flatten monthly data into one employee per slide.
    _slides = [
      for (final month in widget.data.result)
        for (final employee in month.ranks)
          _EmployeeSlide(monthYear: month.monthYear, employee: employee),
    ];

    _startAutoSlide();
  }

  void _startAutoSlide() {
    if (_slides.length <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted ||
          !_pageController.hasClients ||
          MediaQuery.disableAnimationsOf(context)) {
        return;
      }

      final nextPage = (_currentPage + 1) % _slides.length;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  String? _getImageUrl(String image) {
    final fileName = image.trim();

    if (fileName.isEmpty || fileName.toLowerCase() == 'null') return null;

    final uri = Uri.tryParse(fileName);

    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return fileName;
    }

    final configuredBase = widget.imageBaseUrl.trim();
    final imageBase = configuredBase.isEmpty
        ? ApiClient.employeeImageBaseUrl
        : configuredBase;
    final base = imageBase.endsWith('/') ? imageBase : '$imageBase/';

    return '$base${Uri.encodeComponent(fileName)}';
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===============================
            // HEADER
            // ===============================
            Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Employee of the Month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_slides.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('No employee rankings available'),
              )
            else ...[
              // ===============================
              // HORIZONTAL SLIDER
              // ===============================
              SizedBox(
                height: 295,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _employeeCard(_slides[index]);
                  },
                ),
              ),

              const SizedBox(height: 14),

              // ===============================
              // PAGINATION DOTS
              // ===============================
              _buildPaginationDots(),

              const SizedBox(height: 10),

              Text(
                '${_currentPage + 1} / ${_slides.length}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _employeeCard(_EmployeeSlide slide) {
    final colors = Theme.of(context).colorScheme;
    final employee = slide.employee;
    final rank = int.tryParse(employee.rank) ?? 0;
    final imageUrl = _getImageUrl(employee.empImg);

    final String medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '🏅',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          // Month
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              slide.monthYear,
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Rank + photo
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 112,
                width: 112,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 2),
                ),
                child: ClipOval(
                  child: imageUrl == null
                      ? _imagePlaceholder()
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return _imagePlaceholder();
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            );
                          },
                        ),
                ),
              ),

              Positioned(
                bottom: -12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Text(
                    '$medal Rank ${employee.rank}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 27),

          // Employee name
          Text(
            employee.empName.trim().isEmpty ? 'Employee' : employee.empName,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: 55,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPaginationDots() {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 14,
      child: Center(
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: _slides.length,
          separatorBuilder: (_, __) => const SizedBox(width: 5),
          itemBuilder: (context, index) {
            final selected = index == _currentPage;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: selected ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected ? colors.primary : colors.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          },
        ),
      ),
    );
  }
}
