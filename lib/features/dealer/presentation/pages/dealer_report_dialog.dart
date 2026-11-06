import 'package:solufine/core/utility/pdfviewerscreen.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solufine/features/dealer/presentation/bloc/dealerlist_bloc.dart';
import 'package:solufine/features/dealer/presentation/bloc/dealerlist_event.dart';
import 'package:solufine/features/dealer/presentation/bloc/dealerlist_state.dart';

/// Generates and previews a dealer tally report.
class DealerReportDialog extends StatefulWidget {
  final String reportType;
  final String dealerId;

  const DealerReportDialog({
    super.key,
    required this.reportType,
    required this.dealerId,
  });

  @override
  State<DealerReportDialog> createState() => _DealerReportDialogState();
}

class _DealerReportDialogState extends State<DealerReportDialog> {
  bool _submitting = false;
  String? _pdfUrl;
  String? _validationError;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _companyId;

  void _submit() {
    if (_submitting) return;
    final state = context.read<DealerListBloc>().state;
    final validCompany =
        (state.tallyCompanyListModel?.result.any(
          (company) => company.tallyCompanyId == _companyId,
        ) ??
        false);
    if (_fromDate == null || _toDate == null || !validCompany) {
      setState(
        () => _validationError = 'Select both dates and a tally company.',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _validationError = null;
      _pdfUrl = null;
    });
    context.read<DealerListBloc>().add(
      GetTallyPdfEvent(
        widget.reportType,
        widget.dealerId,
        DateFormat('dd-MM-yyyy').format(_fromDate!),
        DateFormat('dd-MM-yyyy').format(_toDate!),
        _companyId!,
      ),
    );
  }

  void _onReportState(BuildContext context, DealerListState state) {
    if (!_submitting) return;
    if (state.status == DealerListStatus.failure) {
      setState(() {
        _submitting = false;
        _validationError =
            state.tallyPdfError ?? 'Unable to generate PDF. Please try again.';
      });
    } else if (state.status == DealerListStatus.success &&
        (state.tallyPdfUrl?.isNotEmpty ?? false)) {
      setState(() {
        _submitting = false;
        _pdfUrl = state.tallyPdfUrl;
      });
      _openPdf();
    }
  }

  void _openPdf() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(pdfUrl: _pdfUrl!),
      ),
    );
  }

  Future<void> _pickDate(bool from) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate:
          (from ? _fromDate : _toDate) ?? (from ? _toDate : _fromDate) ?? today,
      firstDate: from ? DateTime(1900) : (_fromDate ?? DateTime(1900)),
      lastDate: from
          ? (_toDate ?? DateTime(2100, 12, 31))
          : DateTime(2100, 12, 31),
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (from) {
        _fromDate = selected;
      } else {
        _toDate = selected;
      }
    });
  }

  Widget _dateField(String label, DateTime? date, bool from) {
    return InkWell(
      onTap: _submitting ? null : () => _pickDate(from),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 14,
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 30),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          date == null ? 'Select date' : DateFormat('dd/MM/yyyy').format(date),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DealerListBloc, DealerListState>(
      listener: _onReportState,
      child: AlertDialog(
        title: Text(widget.reportType == 'leader' ? 'Ledger' : 'Outstanding'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_validationError != null) ...[
                  Text(
                    _validationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_pdfUrl != null) ...[
                  TextButton.icon(
                    onPressed: _openPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Open generated PDF'),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(child: _dateField('From Date', _fromDate, true)),
                    const SizedBox(width: 12),
                    Expanded(child: _dateField('To Date', _toDate, false)),
                  ],
                ),
                const SizedBox(height: 16),
                BlocBuilder<DealerListBloc, DealerListState>(
                  builder: (context, state) {
                    if (state.tallyCompanyListModel == null &&
                        (state.status == DealerListStatus.loading ||
                            state.status == DealerListStatus.initial)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == DealerListStatus.failure &&
                        state.tallyCompanyListModel == null) {
                      return Column(
                        children: [
                          Text(
                            state.errorMessage ?? 'Unable to load companies.',
                          ),
                          TextButton(
                            onPressed: () => context.read<DealerListBloc>().add(
                              GetTallyCompanyListEvent(),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }
                    final companies = {
                      for (final company
                          in state.tallyCompanyListModel?.result ?? [])
                        if (company.tallyCompanyId.isNotEmpty &&
                            company.tallyCompanyId != '0')
                          company.tallyCompanyId: company.tallyCompanyName,
                    };

                    if (companies.isEmpty) {
                      return const Text('No tally companies available.');
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _companyId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tally Company',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select company'),
                      items: companies.entries
                          .map(
                            (company) => DropdownMenuItem<String>(
                              value: company.key,
                              child: Text(
                                company.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() => _companyId = value),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primaryColor,
                    backgroundColor: context.primaryColor,
                    side: BorderSide(color: context.primaryColor),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: Text(
                    _submitting ? 'Generating' : 'Submit',
                    style: TextStyle(color: context.backgroundColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
