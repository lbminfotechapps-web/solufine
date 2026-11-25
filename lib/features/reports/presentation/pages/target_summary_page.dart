import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/di/employee_activity_report_di.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/features/reports/presentation/widgets/employee_output_filter.dart';
import '../../domain/entities/invoice_entity.dart';
import '../bloc/employee_activity_bloc.dart';
import '../bloc/employee_activity_event.dart';
import '../bloc/employee_activity_state.dart';

class TargetSummaryPage extends StatelessWidget {
  const TargetSummaryPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<EmployeeActivityBloc>(),
    child: const _TargetSummaryView(),
  );
}

class _TargetSummaryView extends StatefulWidget {
  const _TargetSummaryView();

  @override
  State<_TargetSummaryView> createState() => _TargetSummaryViewState();
}

class _TargetSummaryViewState extends State<_TargetSummaryView> {
  final _employee = TextEditingController();
  DateTime? _date = DateTime.now();
  String _amount = 'Rupees';
  String _appliedEmployee = '';
  bool showFilter = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadTargetSummary();
    });
  }

  @override
  void dispose() {
    _employee.dispose();
    super.dispose();
  }

  void _search() {
    if (_date == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date.')));
      return;
    }
    setState(() => _appliedEmployee = _employee.text.trim().toLowerCase());
    _loadTargetSummary();
  }

  Future<void> _loadTargetSummary() async {
    try {
      final userData = await SecureStorage.instance.getUserData();
      if (!mounted) return;
      final userId = userData?['user_id']?.toString().trim() ?? '';
      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User information is not available.')),
        );
        return;
      }
      context.read<EmployeeActivityBloc>().add(
        GetTargetSummaryEvent(
          date: DateFormat('yyyy-MM-dd').format(_date!),
          userId: userId,
          amountType: 'Rupees',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      debugPrint('Unable to read user information: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load user information.')),
      );
    }
  }

  Future<void> _refreshTargetSummary() async {
    await _loadTargetSummary();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _resetFilter() {
    final String today = DateFormat('dd-MM-yyyy').format(DateTime.now());

    setState(() {
      _employee.clear();
      _amount = 'Rupees';
      _date = DateTime.now();
    });

    context.read<EmployeeActivityBloc>().add(ClearTargetSummary());
    _loadTargetSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: CustomAppBar(
        title: 'Target Summary',
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
        showBackButton: true,
        onBackTap: () => context.go(AppRouter.home),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RefreshIndicator(
          onRefresh: _refreshTargetSummary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFilter(),

              SizedBox(height: 10),

              EmployeeOutputFilter(
                employeeController: _employee,
                toDate: _date == null
                    ? 'Select date'
                    : DateFormat('dd/MM/yyyy').format(_date!),
                expanded: showFilter,
                onToDateTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selected != null) setState(() => _date = selected);
                },
                showAmountType: true,
                amountType: 'Rupees',
                onAmountTypeChanged: (value) {
                  setState(() {
                    _amount = value;
                  });
                },
                onExpandChanged: () {
                  setState(() {
                    showFilter = !showFilter;
                  });
                },
                onReset: _resetFilter,
                onSearch: _search,
              ),
              SizedBox(height: 10),
              BlocBuilder<EmployeeActivityBloc, EmployeeActivityState>(
                builder: (context, state) {
                  if (state.status == EmployeeActivityStatus.loading)
                    return const Center(child: CircularProgressIndicator());
                  if (state.status == EmployeeActivityStatus.failure)
                    return Text(state.errorMessage ?? 'Unable to load summary');
                  final result = state.invoiceEntity?.result;
                  if (result == null)
                    return const Text(
                      'Select filters and search to view the summary.',
                    );
                  final rows = result.invoiceData
                      .where(
                        (row) =>
                            row.rowType.toLowerCase() != 'total' &&
                            row.empName.toLowerCase().contains(
                              _appliedEmployee,
                            ),
                      )
                      .toList();
                  final totals = result.invoiceData
                      .where((row) => row.rowType.toLowerCase() == 'total')
                      .toList();
                  if (rows.isEmpty && totals.isEmpty)
                    return const Text('No summary data found.');
                  return SingleChildScrollView(
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
                      columns: [
                        const DataColumn(label: Text('Sr No.')),
                        const DataColumn(label: Text('EMPLOYEE')),
                        DataColumn(label: Text(result.previousYearDate)),
                        DataColumn(label: Text(result.currentYearDate)),
                        const DataColumn(label: Text('YOY DIFF')),
                        const DataColumn(label: Text('YOY Growth%')),
                        DataColumn(label: Text(result.currentPreMonthDate)),
                        const DataColumn(label: Text('MOM DIFF')),
                        const DataColumn(label: Text('MOM Growth%')),
                        DataColumn(label: Text(result.allPreviousYearDate)),
                      ],
                      rows: [
                        for (var i = 0; i < rows.length; i++)
                          _row(rows[i], '${i + 1}'),
                        if (_appliedEmployee.isEmpty)
                          for (final total in totals) _row(total, ''),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFilter() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: context.onPrimaryColor.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(
              Icons.bar_chart_rounded,
              color: context.onPrimaryColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,

              children: [
                Text(
                  'EMPLOYEE SALES SUMMARY',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: context.onPrimaryColor,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'Track Report',
                  style: AppTextStyles.helperText.copyWith(
                    color: context.onPrimaryColor.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    /*
     Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 180,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date *',
              border: OutlineInputBorder(),
            ),
            child: InkWell(
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _date ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selected != null) setState(() => _date = selected);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _date == null
                        ? 'Select date'
                        : DateFormat('dd/MM/yyyy').format(_date!),
                  ),
                  const Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ),
        // SizedBox(
        //   width: 220,
        //   child: TextField(
        //     controller: _employee,
        //     decoration: const InputDecoration(
        //       labelText: 'Employee Name',
        //       border: OutlineInputBorder(),
        //     ),
        //   ),
        // ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            value: _amount,
            decoration: const InputDecoration(
              labelText: 'Amount Type',
              border: OutlineInputBorder(),
            ),
            items: const ['Rupees', 'Lakh', 'Crore']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _amount = value ?? 'Rupees'),
          ),
        ),
        ElevatedButton(onPressed: _search, child: const Text('Search')),
        OutlinedButton(onPressed: _resetFilter, child: const Text('Reset')),
      ],
    );

    */
  }

  DataRow _row(InvoiceDataEntity row, String number) {
    final divisor = switch (_amount) {
      'Lakh' => 100000.0,
      'Crore' => 10000000.0,
      _ => 1.0,
    };
    final formatter = NumberFormat('#,##0.00');
    String amount(double value) => formatter.format(value / divisor);
    return DataRow(
      cells: [
        DataCell(Text(number)),
        DataCell(Text(row.empName)),
        DataCell(Text(amount(row.previousYearMtd))),
        DataCell(Text(amount(row.currentMtd))),
        DataCell(Text(amount(row.yoyDiff))),
        DataCell(Text('${formatter.format(row.yoyGrowth)}%')),
        DataCell(Text(amount(row.previousMonthMtd))),
        DataCell(Text(amount(row.momDiff))),
        DataCell(Text('${formatter.format(row.momGrowth)}%')),
        DataCell(Text(amount(row.previousYearFull))),
      ],
    );
  }
}
