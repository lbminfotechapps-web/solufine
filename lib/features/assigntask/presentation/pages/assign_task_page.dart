import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';

import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../widgets/task_completion_dialog.dart';
import '../widgets/task_image_row.dart';
import '../widgets/create_task_sheet.dart';

const kOverdue = Color(0xFFDC2626);
const kOverdueBackground = Color(0xFFFFF7F7);
const kOverdueBorder = Color(0xFFF4BBBB);

final taskDateFormat = DateFormat('dd MMM yyyy');
final taskTimeFormat = DateFormat('hh:mm a');

class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({super.key});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final _searchController = TextEditingController();

  String _selectedSummary = 'Total';
  bool _showFilters = false;
  String _query = '';
  String? _employeeId;
  TaskPriority? _priority;
  TaskStatus? _status;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(const LoadTasks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ======================================================
  // STATUS / OVERDUE
  // ======================================================

  bool _isOverdue(TaskEntity task) {
    // Trust fld_overdue_status returned by your backend.
    return task.overdueStatus.trim() == '1';
  }

  bool _isPending(TaskEntity task) {
    return task.status == TaskStatus.pending;
  }

  bool _isCompleted(TaskEntity task) {
    return task.status == TaskStatus.completed;
  }

  Color _priorityColor(TaskPriority value) {
    switch (value) {
      case TaskPriority.low:
        return context.primaryColor;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.deepOrange;
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return const Color(0xFFD97706);
      case TaskStatus.completed:
        return context.primaryColor;
    }
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending_actions_rounded;
      case TaskStatus.completed:
        return Icons.check_circle_rounded;
    }
  }

  // ======================================================
  // FILTER EVENTS
  // ======================================================

  void _applyFilters() {
    context.read<TaskBloc>().add(
      ApplyTaskFilters(
        TaskFilter(
          query: _query,
          employeeId: _employeeId,
          priority: _priority,
          status: _status,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _query = '';
      _employeeId = null;
      _priority = null;
      _status = null;
      _fromDate = null;
      _toDate = null;
    });

    _applyFilters();
  }

  Future<void> _selectDate(bool from) async {
    final current = from ? _fromDate : _toDate;

    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    final other = from ? _toDate : _fromDate;

    if (other != null &&
        ((from && selected.isAfter(other)) ||
            (!from && selected.isBefore(other)))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid date range')));
      return;
    }

    setState(() {
      if (from) {
        _fromDate = selected;
      } else {
        _toDate = selected;
      }
    });

    _applyFilters();
  }

  // ======================================================
  // COMPLETE TASK DIALOG
  // ======================================================

  Future<void> _viewCompletionDetails(TaskEntity task) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: dialogContext.cardBackgroundColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                color: dialogContext.primaryColor.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: dialogContext.primaryColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.task_alt_rounded,
                        color: dialogContext.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completion Details',
                            style: TextStyle(
                              color: dialogContext.primaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (task.completedAt != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              DateFormat(
                                'dd MMM yyyy · hh:mm a',
                              ).format(task.completedAt!),
                              style: TextStyle(
                                fontSize: 11,
                                color: dialogContext.secondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: dialogContext.secondaryTextColor,
                        size: 21,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: dialogContext.primaryTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (task.completionRemark?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: dialogContext.appTheme.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dialogContext.borderColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COMPLETION REMARK',
                                style: TextStyle(
                                  color: dialogContext.secondaryTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                task.completionRemark!.trim(),
                                style: TextStyle(
                                  color: dialogContext.primaryTextColor,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 16,
                            color: dialogContext.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Task Photos',
                            style: TextStyle(
                              color: dialogContext.primaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Tap to enlarge',
                            style: TextStyle(
                              color: dialogContext.secondaryTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      TaskImageRow(
                        taskImageUrl: task.imageUrl,
                        taskLocalPath: task.attachmentPath,
                        completedImageUrl: task.completedImageUrl,
                      ),
                      if ((task.imageUrl?.trim().isEmpty ?? true) &&
                          (task.attachmentPath?.trim().isEmpty ?? true) &&
                          (task.completedImageUrl?.trim().isEmpty ?? true))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'No photos attached.',
                            style: TextStyle(
                              color: dialogContext.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
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

  Future<void> _openCompletion(TaskEntity task) async {
    // Overdue does NOT block task completion.
    if (!_isPending(task)) return;

    final bloc = context.read<TaskBloc>();

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: TaskCompletionDialog(task: task),
      ),
    );
  }

  // ======================================================
  // ASSIGN TASK SHEET
  // ======================================================

  Future<void> _openCreate(List<EmployeeEntity> employees) async {
    if (employees.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Employees not loaded')));
      return;
    }

    final bloc = context.read<TaskBloc>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CreateTaskSheet(employees: employees),
      ),
    );
  }

  // ======================================================
  // MAIN SCREEN
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,

      // appBar: AppBar(
      //   backgroundColor: context.primaryColor,
      //   foregroundColor: context.onPrimaryColor,
      //   title: const Text(
      //     'Assign Task',
      //     style: TextStyle(
      //       fontSize: 18,
      //       fontWeight: FontWeight.w800,
      //     ),
      //   ),
      //   actions: [
      //     IconButton(
      //       tooltip: 'Filters',
      //       onPressed: () {
      //         setState(() {
      //           _showFilters = !_showFilters;
      //         });
      //       },
      //       icon: Icon(Icons.tune_rounded),
      //     ),
      //     IconButton(
      //       tooltip: 'Refresh',
      //       onPressed: () => context.read<TaskBloc>().add(
      //             const LoadTasks(),
      //           ),
      //       icon: Icon(Icons.refresh_rounded),
      //     ),
      //   ],
      // ),
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

        action: Row(
          children: [
            IconButton(
              tooltip: 'Show / Hide Filters',
              icon: Icon(Icons.tune_rounded, color: context.onPrimaryColor),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
            ),

            IconButton(
              tooltip: 'Refresh',
              onPressed: () => context.read<TaskBloc>().add(const LoadTasks()),
              icon: Icon(Icons.refresh_rounded),
            ),
          ],
        ),

        title: 'Assign Task',
        showBackButton: true,
        onBackTap: () => context.go(AppRouter.home),
      ),

      floatingActionButton: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            backgroundColor: context.primaryColor,
            foregroundColor: context.onPrimaryColor,
            onPressed: state.saving || state.completing
                ? null
                : () => _openCreate(state.employees),
            icon: Icon(Icons.add_task_rounded),
            label: const Text('Assign Task'),
          );
        },
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listenWhen: (previous, current) =>
            previous.notificationId != current.notificationId,
        listener: (context, state) {
          if (state.message.isEmpty) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: state.error
                    ? Colors.red
                    : context.primaryColor,
              ),
            );
        },
        builder: (context, state) {
          final summaryTasks = state.filteredTasks;
          final tasks = summaryTasks.where((task) {
            switch (_selectedSummary) {
              case 'Pending':
                return _isPending(task);
              case 'Done':
                return _isCompleted(task);
              case 'Overdue':
                return _isOverdue(task);
              default:
                return true;
            }
          }).toList();

          // Preserve API order when filtering tasks.
          final overdueCount = summaryTasks.where(_isOverdue).length;

          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<TaskBloc>();

              final future = bloc.stream.firstWhere(
                (value) =>
                    value.loadStatus == TaskLoadStatus.success ||
                    value.loadStatus == TaskLoadStatus.failure,
              );

              bloc.add(const LoadTasks());
              await future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 95),
              children: [
                _summary(
                  total: summaryTasks.length,
                  pending: summaryTasks.where((t) => _isPending(t)).length,
                  completed: summaryTasks.where((t) => _isCompleted(t)).length,
                  overdue: overdueCount,
                ),
                const SizedBox(height: 10),

                // Enable this if you want search visible.
                // _searchBox(),
                // const SizedBox(height: 8),
                if (_showFilters) ...[
                  _filters(state.employees),
                  const SizedBox(height: 10),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedSummary == 'Total'
                            ? 'Created Tasks'
                            : _selectedSummary == 'Done'
                            ? 'Completed Tasks'
                            : '$_selectedSummary Tasks',
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${tasks.length} tasks',
                      style: TextStyle(
                        color: context.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),

                if (state.loadStatus == TaskLoadStatus.loading)
                  const Padding(
                    padding: EdgeInsets.all(35),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.loadStatus == TaskLoadStatus.failure)
                  _empty(state.message)
                else if (tasks.isEmpty)
                  _empty('No tasks found')
                else
                  ...tasks.map(_taskCard),
              ],
            ),
          );
        },
      ),
    );
  }

  // ======================================================
  // SUMMARY
  // ======================================================

  Widget _summary({
    required int total,
    required int pending,
    required int completed,
    required int overdue,
  }) {
    Widget item(String title, int count, IconData icon, Color color) {
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _selectedSummary = title),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: _selectedSummary == title ? color : context.borderColor,
                width: _selectedSummary == title ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 19),
                const SizedBox(height: 3),
                Text(
                  '$count',
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item('Total', total, Icons.assignment_outlined, context.primaryColor),
        const SizedBox(width: 6),
        item('Pending', pending, Icons.pending_actions, Colors.orange),
        const SizedBox(width: 6),
        item('Overdue', overdue, Icons.warning_amber_rounded, kOverdue),
        const SizedBox(width: 6),
        item('Done', completed, Icons.task_alt, Colors.teal),
      ],
    );
  }

  // ======================================================
  // SEARCH
  // ======================================================

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _query = value);
        _applyFilters();
      },
      decoration: InputDecoration(
        hintText: 'Search task or employee',
        hintStyle: TextStyle(fontSize: 12),
        prefixIcon: Icon(Icons.search, color: context.primaryColor),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                  _applyFilters();
                },
                icon: Icon(Icons.close, size: 18),
              ),
        filled: true,
        fillColor: context.appTheme.inputBackground,
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: context.borderColor),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  // ======================================================
  // FILTER DATE
  // ======================================================

  Widget _dateFilter(
    String title,
    DateTime? date,
    VoidCallback select,
    VoidCallback clear,
  ) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: select,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    date == null
                        ? 'Any date'
                        : DateFormat('dd-MM-yyyy').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (date != null)
            IconButton(
              onPressed: clear,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }

  // ======================================================
  // FILTER PANEL
  // ======================================================

  Widget _filters(List<EmployeeEntity> employees) {
    InputDecoration decoration(String label) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dateFilter(
                  'From Date',
                  _fromDate,
                  () => _selectDate(true),
                  () {
                    setState(() => _fromDate = null);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dateFilter(
                  'To Date',
                  _toDate,
                  () => _selectDate(false),
                  () {
                    setState(() => _toDate = null);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TaskPriority?>(
                  key: ValueKey('priority_$_priority'),
                  initialValue: _priority,
                  isExpanded: true,
                  decoration: decoration('Priority'),
                  items: [
                    const DropdownMenuItem<TaskPriority?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...TaskPriority.values.map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _priority = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<TaskStatus?>(
                  key: ValueKey('status_$_status'),
                  initialValue: _status,
                  isExpanded: true,
                  decoration: decoration('Status'),
                  items: [
                    const DropdownMenuItem<TaskStatus?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...TaskStatus.values.map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _status = value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<String?>(
            key: ValueKey('employee_$_employeeId'),
            initialValue: _employeeId,
            isExpanded: true,
            decoration: decoration('Employee'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Employees'),
              ),
              ...employees.map(
                (employee) => DropdownMenuItem<String?>(
                  value: employee.id,
                  child: Text(employee.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _employeeId = value);
              _applyFilters();
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: Icon(Icons.restart_alt, size: 17),
              label: const Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // COMPACT DATE BOX
  // ======================================================

  Widget _dateBox(
    String title,
    DateTime date,
    Color color, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFFFEEEE) : context.backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: highlight ? kOverdue : context.secondaryTextColor,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    taskDateFormat.format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: highlight ? kOverdue : context.primaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    taskTimeFormat.format(date),
                    style: TextStyle(
                      color: highlight ? kOverdue : context.secondaryTextColor,
                      fontSize: 10,
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

  // ======================================================
  // STATUS BADGES
  // ======================================================

  Widget _badge({
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // TASK CARD — NO EXPAND ICON
  // ======================================================

  Widget _taskCard(TaskEntity task) {
    final pending = _isPending(task);
    final completed = _isCompleted(task);

    // This is based ONLY on fld_overdue_status.
    final overdue = _isOverdue(task);

    final priorityColor = _priorityColor(task.priority);
    final statusColor = _statusColor(task.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: overdue ? kOverdueBackground : context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: completed
              ? Colors.green
              : (overdue ? kOverdueBorder : context.borderColor),
          width: completed ? 2 : (overdue ? 1.2 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overdue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEAEA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: kOverdue, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'OVERDUE TASK',
                    style: TextStyle(
                      color: kOverdue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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
                // TASK TITLE + EMPLOYEE + PRIORITY
                Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: context.primaryColor,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task : ${task.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.primaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            // '#${task.id} · '
                            'Emp Name : ${task.employeeName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task.priority.label,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                // DESCRIPTION
                if (task.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    'Description : ${task.description}',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ASSIGNED / DUE DATES
                Row(
                  children: [
                    _dateBox('Assigned', task.assignedAt, context.primaryColor),
                    const SizedBox(width: 8),
                    _dateBox(
                      'Due Date',
                      task.dueAt,
                      overdue ? kOverdue : Colors.orange,
                      highlight: overdue,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // TWO SEPARATE BADGES:
                // 1. Task Status
                // 2. Overdue Status
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _badge(
                            text: task.status.label,
                            icon: _statusIcon(task.status),
                            color: statusColor,
                          ),

                          if (overdue)
                            _badge(
                              text: 'Overdue',
                              icon: Icons.warning_amber_rounded,
                              color: kOverdue,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    SizedBox(
                      height: 35,
                      child: OutlinedButton.icon(
                        onPressed: () => _viewCompletionDetails(task),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: BorderSide(color: context.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text(
                          'View',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 35,
                      child: FilledButton.icon(
                        onPressed: pending ? () => _openCompletion(task) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: context.onPrimaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        icon: Icon(Icons.task_alt_rounded, size: 15),
                        label: const Text(
                          'Complete Task',
                          style: TextStyle(fontSize: 11),
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
    );
  }

  // ======================================================
  // EMPTY MESSAGE
  // ======================================================

  Widget _empty(String message) {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            color: context.primaryColor,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.secondaryTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
