import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:solufine/core/theme/app_theme_context.dart';

import '../../domain/entities/assign_employee.dart';

class EmployeeOutputFilter extends StatelessWidget {
  final TextEditingController employeeController;

  final String employeeId;

  final String fromDate;

  final String toDate;

  final bool expanded;

  final List<AssignEmployee> employees;

  final bool employeeLoading;

  final VoidCallback? onExpandChanged;

  final ValueChanged<String>? onEmployeeChanged;

  final ValueChanged<AssignEmployee>? onEmployeeSelected;

  final VoidCallback? onFromDateTap;

  final VoidCallback onToDateTap;

  final VoidCallback onReset;

  final VoidCallback onSearch;
  final bool showAmountType;
  final String amountType;
  final ValueChanged<String>? onAmountTypeChanged;

  const EmployeeOutputFilter({
    super.key,
    required this.employeeController,

    // Optional parameters
    this.employeeId = '',
    this.fromDate = '',
    this.employees = const [],
    this.employeeLoading = false,
    this.onExpandChanged,
    this.onEmployeeChanged,
    this.onEmployeeSelected,
    this.onFromDateTap,

    // Mandatory parameters
    required this.toDate,
    required this.expanded,
    required this.onToDateTap,
    required this.onReset,
    required this.onSearch,
    this.showAmountType = false,
    this.amountType = 'Rupees',
    this.onAmountTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: .035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // FILTER HEADER
          // ======================================================
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onExpandChanged,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.filter_alt_outlined,
                      color: context.primaryColor,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search & Filter',
                          style: AppTextStyles.listTitle.copyWith(
                            color: context.cardTextColor,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          showAmountType
                              ? 'Employee name, date and amount type'
                              : 'Employee name and date range',
                          style: AppTextStyles.caption.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // FILTER BODY
          // ======================================================
          if (expanded) ...[
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  // ==================================================
                  // EMPLOYEE LABEL
                  // ==================================================
                  const _FieldLabel(
                    icon: Icons.person_outline_rounded,
                    title: 'Employee',
                  ),

                  const SizedBox(height: 7),

                  // ==================================================
                  // EMPLOYEE TEXT FIELD
                  // ==================================================
                  TextField(
                    style: AppTextStyles.input,
                    controller: employeeController,

                    onChanged: onEmployeeChanged,

                    decoration: InputDecoration(
                      hintText: 'Search employee name',

                      hintStyle: AppTextStyles.inputHint.copyWith(
                        color: context.secondaryTextColor,
                      ),

                      prefixIcon: Icon(Icons.search_rounded, size: 20),

                      suffixIcon: employeeController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                employeeController.clear();

                                onEmployeeChanged?.call('');
                              },
                              icon: Icon(Icons.close_rounded, size: 18),
                            )
                          : null,

                      filled: true,

                      fillColor: context.appColors.surfaceContainerHighest,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  // ==================================================
                  // LOADING
                  // ==================================================
                  if (employeeLoading)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),

                  // ==================================================
                  // EMPLOYEE SUGGESTIONS
                  // ==================================================
                  if (employees.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),

                      constraints: const BoxConstraints(maxHeight: 190),

                      decoration: BoxDecoration(
                        color: context.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.borderColor),
                      ),

                      child: ListView.separated(
                        shrinkWrap: true,

                        itemCount: employees.length,

                        separatorBuilder: (_, __) => const Divider(height: 1),

                        itemBuilder: (context, index) {
                          final employee = employees[index];

                          return InkWell(
                            onTap: () {
                              onEmployeeSelected?.call(employee);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: context.primaryColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_outline,
                                      size: 17,
                                      color: context.primaryColor,
                                    ),
                                  ),

                                  const SizedBox(width: 9),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee.fldAdmName.toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.labelLarge,
                                        ),

                                        const SizedBox(height: 2),

                                        Text(
                                          'ID: ${employee.fldId}',
                                          style: AppTextStyles.helperText
                                              .copyWith(
                                                color:
                                                    context.secondaryTextColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // DATES
                  // ==================================================
                  Row(
                    children: [
                      if (onFromDateTap != null) ...[
                        const SizedBox(height: 14),

                        const _FieldLabel(
                          icon: Icons.calendar_today,
                          title: 'Date',
                        ),

                        const SizedBox(height: 7),

                        Expanded(
                          child: _DateField(
                            title: 'From Date',
                            value: fromDate,
                            onTap: onFromDateTap,
                          ),
                        ),

                        const SizedBox(width: 10),
                      ],

                      Expanded(
                        child: _DateField(
                          title: onFromDateTap != null ? 'To Date' : 'Date',
                          value: toDate,
                          onTap: onToDateTap,
                        ),
                      ),
                    ],
                  ),

                  if (showAmountType) ...[
                    const SizedBox(height: 14),

                    const _FieldLabel(
                      icon: Icons.currency_rupee_rounded,
                      title: 'Amount Type',
                    ),

                    const SizedBox(height: 7),

                    DropdownButtonFormField<String>(
                      value: amountType,
                      isExpanded: true,
                      style: AppTextStyles.input.copyWith(
                        color: context.cardTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Select Amount Type',
                        filled: true,
                        fillColor: context.appColors.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const ['Rupees', 'Lakh', 'Crore']
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: onAmountTypeChanged == null
                          ? null
                          : (value) {
                              onAmountTypeChanged?.call(value ?? 'Rupees');
                            },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ==================================================
                  // BUTTONS
                  // ==================================================
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReset,

                          icon: Icon(Icons.restart_alt_rounded, size: 18),

                          label: Text('Reset', style: AppTextStyles.button),

                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.secondaryTextColor,

                            side: BorderSide(color: context.borderColor),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),

                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onSearch,

                          icon: Icon(Icons.search_rounded, size: 18),

                          label: Text('Search', style: AppTextStyles.button),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,

                            foregroundColor: context.onPrimaryColor,

                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),

                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// FIELD LABEL
// ================================================================

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FieldLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: context.primaryColor),

        const SizedBox(width: 6),

        Text(
          title,
          style: AppTextStyles.buttonSmall.copyWith(
            color: context.cardTextColor,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// DATE FIELD
// ================================================================

class _DateField extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _DateField({required this.title, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),

      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),

        decoration: BoxDecoration(
          color: context.appColors.surfaceContainerHighest,

          borderRadius: BorderRadius.circular(11),
        ),

        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 17,
              color: context.primaryColor,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    value,
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: context.cardTextColor,
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
}
