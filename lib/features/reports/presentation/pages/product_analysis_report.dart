import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/di/employee_activity_report_di.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_textformfield.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_bloc.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_event.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_state.dart';
import 'package:solufine/features/marketing/demodistributor/presentation/pages/demo_distributor_page.dart';
import 'package:solufine/features/products/presentation/bloc/product_bloc.dart';
import 'package:solufine/features/products/presentation/bloc/product_event.dart';
import 'package:solufine/features/products/presentation/bloc/product_state.dart';
import '../bloc/employee_activity_bloc.dart';
import '../bloc/employee_activity_event.dart';
import '../bloc/employee_activity_state.dart';

class ProductAnalysisReportScreen extends StatelessWidget {
  const ProductAnalysisReportScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<EmployeeActivityBloc>(),
    child: const _ProductAnalysisView(),
  );
}

class _ProductAnalysisView extends StatefulWidget {
  const _ProductAnalysisView();
  @override
  State<_ProductAnalysisView> createState() => _ProductAnalysisViewState();
}

class _ProductAnalysisViewState extends State<_ProductAnalysisView> {
  late DateTime fromDate;
  late DateTime toDate;
  bool _withPacking = false;
  final _distributorController = TextEditingController();
  bool _showOutlets = false;
  Timer? _outletTimer;
  late final ComplaintBloc _complaintBloc;
  late final ProductBloc _productBloc;
  String? _selectedCustomerId;
  int _outletVersion = 0;
  @override
  void initState() {
    super.initState();
    resetDates();
    _complaintBloc = context.read<ComplaintBloc>();
    _productBloc = context.read<ProductBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) loadReport();
    });
  }

  String _selectedChartType = 'Total Value';

  final List<String> _chartTypes = [
    'Total Value',
    'QTY LIT/KG',
    'QTY NOS',
    'Effective Rate',
    'Proportion %',
  ];

  final _productSearchController = TextEditingController();

  bool _showProducts = false;
  String? _selectedProductId;

  Timer? _productTimer;
  int _productVersion = 0;
  void _searchProduct(String value) {
    _productTimer?.cancel();

    final version = ++_productVersion;

    setState(() {
      _selectedProductId = null;
      _showProducts = false;
      _showOutlets = false;
    });

    if (value.trim().isEmpty) return;

    _productTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || version != _productVersion) return;

      _productBloc.add(ProductNameListingEvent(value.trim()));

      setState(() {
        _showProducts = true;
      });
    });
  }

  void _toast(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _searchOutlet(String value) {
    _outletTimer?.cancel();
    final version = ++_outletVersion;
    _selectedCustomerId = null;
    setState(() => _showOutlets = false);
    if (value.trim().isEmpty) return;
    _outletTimer = Timer(const Duration(seconds: 1), () async {
      try {
        final user = await SecureStorage.instance.getUserData();
        if (!mounted || version != _outletVersion) return;
        final userId = (user?['user_id'] ?? user?['userId'] ?? '')
            .toString()
            .trim();
        if (userId.isEmpty) {
          _toast('Unable to load logged-in user');
          return;
        }
        _complaintBloc.add(
          GetOutletListEvent(
            userId: userId,
            dealerType: 'Dealer',
            dealerName: value.trim(),
          ),
        );
        setState(() => _showOutlets = true);
      } catch (e) {
        if (mounted && version == _outletVersion)
          _toast('Unable to search outlets: $e');
      }
    });
  }

  void resetDates() {
    final now = DateTime.now();
    toDate = DateTime(now.year, now.month, now.day);
    final month = DateTime(now.year, now.month - 1);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    fromDate = DateTime(
      month.year,
      month.month,
      now.day > lastDay ? lastDay : now.day,
    );
  }

  Future<void> loadReport() async {
    if (fromDate.isAfter(toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From date cannot be after to date.')),
      );
      return;
    }
    try {
      final data = await SecureStorage.instance.getUserData();
      if (!mounted) return;
      final userId = data?['user_id']?.toString().trim() ?? '';
      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User information is not available.')),
        );
        return;
      }
      final format = DateFormat('yyyy-MM-dd');
      context.read<EmployeeActivityBloc>().add(
        GetProductAnalysisEvent(
          fromDate: format.format(fromDate),
          toDate: format.format(toDate),
          userId: userId,
          outletId: _selectedCustomerId ?? '',
          productId: _selectedProductId ?? '',
          packing: _withPacking ? '1' : '0',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load user information.')),
      );
    }
  }

  void resetFilters() {
    // Cancel pending search timers
    _outletTimer?.cancel();
    _productTimer?.cancel();

    // Invalidate pending searches
    _outletVersion++;
    _productVersion++;

    FocusScope.of(context).unfocus();

    setState(() {
      // Reset dates
      resetDates();

      // Clear search fields
      _distributorController.clear();
      _productSearchController.clear();

      // Reset selected IDs
      _selectedCustomerId = null;
      _selectedProductId = null;

      // Hide search dropdowns
      _showOutlets = false;
      _showProducts = false;

      // Reset packing checkbox
      _withPacking = false;
    });

    // Reload report with default filters
    loadReport();
  }

  Future<void> selectDate(bool from) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: from ? fromDate : toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted)
      setState(() {
        if (from) {
          fromDate = selected;
        } else {
          toDate = selected;
        }
      });
  }

  double _parseChartValue(Object? value) {
    final number = double.tryParse(
      (value ?? '')
          .toString()
          .replaceAll(',', '')
          .replaceAll('%', '')
          .replaceAll('₹', '')
          .trim(),
    );

    return number != null && number.isFinite ? number : 0.0;
  }

  Widget _buildProductBarChart({
    required List<String> productNames,
    required List<double> values,
  }) {
    if (productNames.isEmpty || values.isEmpty) {
      return const SizedBox.shrink();
    }

    final double highestValue = values.reduce(math.max);
    final double lowestValue = values.reduce(math.min);

    final double maxY = highestValue > 0 ? highestValue * 1.20 : 0.0;

    final double minY = lowestValue < 0 ? lowestValue * 1.20 : 0.0;

    final double chartMaxY = maxY == minY ? minY + 10 : maxY;

    final double interval = (chartMaxY - minY) / 5;

    final colors = [
      context.primaryColor,
      Colors.blue,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.indigo,
      Colors.cyan,
    ];

    final formatter = NumberFormat.compact(locale: 'en_IN');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // CHART HEADER
            // ==========================================
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: context.primaryColor,
                  size: 26,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Product Analysis Chart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.cardTextColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==========================================
            // CHART TYPE DROPDOWN
            // ==========================================
            DropdownButtonFormField<String>(
              value: _selectedChartType,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Select Chart Value',
                prefixIcon: Icon(
                  Icons.analytics_outlined,
                  color: context.primaryColor,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _chartTypes.map((type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedChartType = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // ==========================================
            // TOTAL PRODUCTS
            // ==========================================
            Text(
              'Total Products: ${productNames.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.cardTextColor,
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // HORIZONTALLY SCROLLABLE BAR CHART
            // ==========================================
            LayoutBuilder(
              builder: (context, constraints) {
                final double chartWidth = math.max(
                  constraints.maxWidth,
                  (productNames.length * 85.0) + 60,
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        minY: minY,
                        maxY: chartMaxY,

                        alignment: BarChartAlignment.spaceAround,

                        // ==================================
                        // BAR TOUCH TOOLTIP
                        // ==================================
                        barTouchData: BarTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => Colors.black87,

                            fitInsideHorizontally: true,
                            fitInsideVertically: true,

                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final value = values[groupIndex];

                              final formattedValue = NumberFormat(
                                '#,##0.##',
                                'en_IN',
                              ).format(value);

                              final suffix =
                                  _selectedChartType == 'Proportion %'
                                  ? '%'
                                  : '';

                              return BarTooltipItem(
                                '${productNames[groupIndex]}\n'
                                '$_selectedChartType: '
                                '$formattedValue$suffix',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),

                        // ==================================
                        // GRID LINES
                        // ==================================
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: interval,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                              dashArray: [5, 4],
                            );
                          },
                        ),

                        // ==================================
                        // CHART BORDER
                        // ==================================
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.4),
                            ),
                            left: BorderSide(
                              color: Colors.grey.withOpacity(0.4),
                            ),
                          ),
                        ),

                        // ==================================
                        // AXIS TITLES
                        // ==================================
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
                              reservedSize: 58,
                              interval: interval,
                              getTitlesWidget: (value, meta) {
                                final suffix =
                                    _selectedChartType == 'Proportion %'
                                    ? '%'
                                    : '';

                                return Text(
                                  '${formatter.format(value)}$suffix',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.cardTextColor,
                                  ),
                                );
                              },
                            ),
                          ),

                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();

                                if (index < 0 ||
                                    index >= productNames.length ||
                                    value != index.toDouble()) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SizedBox(
                                    width: 75,
                                    child: Text(
                                      productNames[index],
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: context.cardTextColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // ==================================
                        // DYNAMIC BAR DATA
                        // ==================================
                        barGroups: List.generate(values.length, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: values[index],
                                width: 26,
                                color: colors[index % colors.length],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            Center(
              child: Text(
                _selectedChartType,
                style: TextStyle(
                  color: context.cardTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                'Swipe horizontally to view all products.\n'
                'Tap on a bar to view details.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dateField(String title, DateTime date, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: '$title *',
        border: const OutlineInputBorder(),
      ),
      child: Text(DateFormat('dd/MM/yyyy').format(date)),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.backgroundColor,
    appBar: CustomAppBar(
      title: 'Product Analysis',
      backgroundColor: context.primaryColor,
      showBackButton: true,
      onBackTap: () => context.go(AppRouter.home),
    ),
    body: RefreshIndicator(
      onRefresh: loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: context.onPrimaryColor),
                const SizedBox(width: 10),
                Text(
                  'PRODUCT ANALYSIS',
                  style: TextStyle(
                    color: context.onPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ExpansionTile(
              leading: Icon(
                Icons.filter_alt_outlined,
                color: context.primaryColor,
              ),
              title: const Text('Search & Filter'),
              subtitle: const Text('Date range'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: dateField(
                              'From Date',
                              fromDate,
                              () => selectDate(true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: dateField(
                              'To Date',
                              toDate,
                              () => selectDate(false),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      ComplaintSearchDropdown(
                        visible: _showOutlets,
                        field: CustomTextFormField(
                          controller: _distributorController,
                          labelText: 'Dealer Name',
                          hintText: 'Dealer Name *',
                          prefixIcon: Icons.person_outline_rounded,
                          suffixIcon: _distributorController.text.isEmpty
                              ? Icons.search_rounded
                              : Icons.close_rounded,
                          onSuffixIconTap: _distributorController.text.isEmpty
                              ? null
                              : () {
                                  _distributorController.clear();
                                  _searchOutlet('');
                                },
                          onChanged: _searchOutlet,

                          textInputAction: TextInputAction.next,
                        ),

                        options: BlocBuilder<ComplaintBloc, ComplaintFormState>(
                          bloc: _complaintBloc,
                          builder: (context, state) {
                            if (state.status == ComplaintFormStatus.loading)
                              return const LinearProgressIndicator();
                            if (state.status == ComplaintFormStatus.failure)
                              return Text(
                                state.errorMessage ??
                                    'Unable to search outlets',
                              );
                            final outlets =
                                state.outletListEntity?.result ?? [];
                            if (outlets.isEmpty)
                              return const Text('No matching results');
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 240),
                              child: ListView.builder(
                                shrinkWrap: true,
                                primary: false,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.manual,
                                itemCount: outlets.length,
                                itemBuilder: (context, index) {
                                  final outlet = outlets[index];
                                  return ListTile(
                                    title: Text(
                                      "${outlet.outletName} - (${outlet.outletPersonMobile})",
                                    ),
                                    // subtitle: Text(outlet.outletAddress),
                                    onTap: () => setState(() {
                                      _distributorController.text =
                                          "${outlet.outletName} - (${outlet.outletPersonMobile})";
                                      _selectedCustomerId = outlet.outletId;
                                      _showOutlets = false;
                                    }),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      ComplaintSearchDropdown(
                        visible: _showProducts,

                        field: CustomTextFormField(
                          controller: _productSearchController,
                          labelText: 'Product Name',
                          hintText: 'Search Product',
                          prefixIcon: Icons.inventory_2_outlined,

                          suffixIcon: _productSearchController.text.isEmpty
                              ? Icons.search_rounded
                              : Icons.close_rounded,

                          onSuffixIconTap: _productSearchController.text.isEmpty
                              ? null
                              : () {
                                  _productSearchController.clear();
                                  _searchProduct('');
                                },

                          onChanged: _searchProduct,

                          textInputAction: TextInputAction.next,
                        ),

                        options: BlocBuilder<ProductBloc, ProductState>(
                          bloc: _productBloc,

                          builder: (context, state) {
                            final products = state.productNames;

                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 240),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: products.map((product) {
                                    return ListTile(
                                      dense: true,

                                      title: Text(product.productName),

                                      onTap: () {
                                        setState(() {
                                          _productSearchController.text =
                                              product.productName;

                                          _selectedProductId =
                                              product.productId;

                                          _showProducts = false;
                                        });

                                        FocusScope.of(context).unfocus();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      const SizedBox(height: 8),

                      CheckboxListTile(
                        value: _withPacking,
                        onChanged: (bool? value) {
                          setState(() {
                            _withPacking = value ?? false;
                          });
                        },
                        title: Text(
                          'With Packing',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.cardTextColor,
                          ),
                        ),
                        activeColor: context.primaryColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        dense: true,
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(resetDates);
                                loadReport();
                              },
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: loadReport,
                              icon: const Icon(Icons.search),
                              label: const Text('Search'),
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
          const SizedBox(height: 10),
          BlocBuilder<EmployeeActivityBloc, EmployeeActivityState>(
            builder: (context, state) {
              if (state.status == EmployeeActivityStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == EmployeeActivityStatus.failure) {
                return Text(state.errorMessage ?? 'Unable to load report');
              }

              final report = state.productAnalysisReport;

              if (report == null) {
                return const Text(
                  'Select filters and search to view the report.',
                );
              }

              if (report.result.isEmpty) {
                return const Text('No product analysis data found.');
              }

              // ================================================
              // PREPARE CHART DATA FROM TABLE
              // ================================================

              final List<String> productNames = report.result
                  .map((item) => item.productName)
                  .toList();

              final List<double> chartValues = report.result.map((item) {
                switch (_selectedChartType) {
                  case 'QTY LIT/KG':
                    return _parseChartValue(item.qtyLitKg);

                  case 'QTY NOS':
                    return _parseChartValue(item.qtyNos);

                  case 'Effective Rate':
                    return _parseChartValue(item.effRate);

                  case 'Proportion %':
                    return _parseChartValue(item.proportionalPer);

                  case 'Total Value':
                  default:
                    return _parseChartValue(item.totalValue);
                }
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================================================
                  // EXISTING DATA TABLE
                  // ================================================
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      horizontalMargin: 8,
                      columnSpacing: 16,
                      headingRowHeight: 38,
                      dataRowMinHeight: 34,
                      dataRowMaxHeight: 40,

                      headingTextStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.cardTextColor,
                      ),

                      dataTextStyle: TextStyle(
                        fontSize: 11,
                        color: context.cardTextColor,
                      ),

                      border: TableBorder.all(color: Colors.black12),

                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xffe5eef3),
                      ),

                      columns: const [
                        DataColumn(label: Text('Sr No.')),
                        DataColumn(label: Text('PRODUCT')),
                        DataColumn(label: Text('Category Name')),
                        DataColumn(label: Text('QTY LIT/KG')),
                        DataColumn(label: Text('QTY NOS')),
                        DataColumn(label: Text('EFF RATE')),
                        DataColumn(label: Text('TOTAL VALUE')),
                        DataColumn(label: Text('PROPORTION %')),
                      ],

                      rows: [
                        // ==========================================
                        // PRODUCT ROWS
                        // ==========================================
                        for (var i = 0; i < report.result.length; i++)
                          DataRow(
                            cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Text(report.result[i].productName)),
                              DataCell(Text(report.result[i].categoryName)),
                              DataCell(Text(report.result[i].qtyLitKg)),
                              DataCell(Text(report.result[i].qtyNos)),
                              DataCell(Text(report.result[i].effRate)),
                              DataCell(Text(report.result[i].totalValue)),
                              DataCell(Text(report.result[i].proportionalPer)),
                            ],
                          ),

                        // ==========================================
                        // TOTAL ROW
                        // ==========================================
                        DataRow(
                          color: WidgetStateProperty.all(
                            context.primaryColor.withOpacity(0.10),
                          ),
                          cells: [
                            const DataCell(Text('')),

                            const DataCell(
                              Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            DataCell(Text(report.total.qtyLitKg)),

                            DataCell(Text(report.total.qtyNos)),

                            DataCell(Text(report.total.effRate)),

                            DataCell(Text(report.total.totalValue)),

                            DataCell(Text(report.total.proportionalPer)),
                            const DataCell(Text('')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================================================
                  // PRODUCT ANALYSIS BAR CHART
                  // ================================================
                  _buildProductBarChart(
                    productNames: productNames,
                    values: chartValues,
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
