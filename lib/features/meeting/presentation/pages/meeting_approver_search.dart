import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/meeting_option.dart';
import '../../domain/usecases/get_meeting_options.dart';

class MeetingApproverSearch extends StatefulWidget {
  const MeetingApproverSearch({
    super.key,
    required this.controller,
    required this.options,
    required this.onSelected,
    required this.onEdited,
  });
  final TextEditingController controller;
  final GetMeetingOptions options;
  final ValueChanged<MeetingOption> onSelected;
  final VoidCallback onEdited;
  @override
  State<MeetingApproverSearch> createState() => _MeetingApproverSearchState();
}

class _MeetingApproverSearchState extends State<MeetingApproverSearch> {
  Timer? _timer;
  int _version = 0;
  String? _selectedName;
  String? _error;
  bool _loading = false;
  bool _show = false;
  List<MeetingOption> _matches = [];

  void _search(String query) {
    _timer?.cancel();
    final version = ++_version;
    widget.onEdited();
    setState(() {
      _selectedName = null;
      _error = null;
      _loading = false;
      _show = false;
      _matches = [];
    });
    if (query.trim().isEmpty) return;
    _timer = Timer(const Duration(seconds: 1), () async {
      if (!mounted || version != _version) return;
      setState(() => _loading = true);
      try {
        final matches = await widget.options.budgetApprovers(query.trim());
        if (!mounted || version != _version) return;
        setState(() {
          _matches = matches;
          _loading = false;
          _show = true;
        });
      } catch (_) {
        if (!mounted || version != _version) return;
        setState(() {
          _loading = false;
          _error = 'Unable to load approvers. Please try again.';
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _version++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Meeting Budget Approval Received(Name) *',
            border: const OutlineInputBorder(),
            helperText: _error ?? 'Search and select a budget approver',
            helperMaxLines: 2,
          ),
          onChanged: _search,
          validator: (value) => _selectedName == null || value != _selectedName
              ? 'Please select a budget approver from the results'
              : null,
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_show && _matches.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No matches found'),
          ),
        if (_show && _matches.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final option = _matches[index];
                return ListTile(
                  title: Text(option.name),
                  onTap: () {
                    _timer?.cancel();
                    _version++;
                    setState(() {
                      _selectedName = option.name;
                      widget.controller.text = option.name;
                      _show = false;
                      _loading = false;
                      _error = null;
                    });
                    widget.onSelected(option);
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
      ],
    ),
  );
}
