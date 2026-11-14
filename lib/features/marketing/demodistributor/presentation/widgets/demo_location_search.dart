import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/demo_distributor_entry.dart';

class DemoLocationSearch extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final DemoOption? selected;
  final String parentId;
  final bool enabled;
  final String? disabledHint;
  final Future<List<DemoOption>> Function(String query) load;
  final VoidCallback onEdited;
  final ValueChanged<DemoOption> onSelected;

  const DemoLocationSearch({
    super.key,
    required this.label,
    required this.controller,
    required this.selected,
    required this.load,
    required this.onEdited,
    required this.onSelected,
    this.parentId = '',
    this.enabled = true,
    this.disabledHint,
  });

  @override
  State<DemoLocationSearch> createState() => _DemoLocationSearchState();
}

class _DemoLocationSearchState extends State<DemoLocationSearch> {
  final _focus = FocusNode();
  Timer? _timer;
  int _version = 0;
  bool _loading = false;
  bool _searched = false;
  String? _error;
  String _query = '';
  List<DemoOption> _options = [];

  @override
  void initState() {
    super.initState();
    _query = widget.controller.text;
    widget.controller.addListener(_controllerChanged);
    _focus.addListener(_focusChanged);
  }

  void _reset() {
    _timer?.cancel();
    ++_version;
    _loading = false;
    _searched = false;
    _error = null;
    _options = [];
  }

  void _controllerChanged() {
    if (widget.controller.text == _query) return;
    setState(() {
      _query = widget.controller.text;
      _reset();
    });
  }

  void _focusChanged() {
    if (!_focus.hasFocus) setState(_reset);
  }

  @override
  void didUpdateWidget(covariant DemoLocationSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentId != widget.parentId ||
        oldWidget.enabled != widget.enabled) {
      _reset();
    }
  }

  void _changed(String value) {
    widget.onEdited();
    _timer?.cancel();
    final version = ++_version;
    setState(() {
      _query = value;
      _options = [];
      _error = null;
      _searched = false;
      _loading = value.trim().isNotEmpty;
    });
    if (value.trim().isEmpty) return;
    _timer = Timer(const Duration(seconds: 1), () => _load(value, version));
  }

  Future<void> _load(String query, int version) async {
    try {
      final options = await widget.load(query.trim());
      if (!mounted || version != _version || !_focus.hasFocus) return;
      setState(() {
        _loading = false;
        _searched = true;
        _options = options;
      });
    } catch (_) {
      if (!mounted || version != _version || !_focus.hasFocus) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load results. Tap to retry.';
      });
    }
  }

  void _select(DemoOption option) {
    setState(() {
      _reset();
      _query = option.name;
      widget.controller.value = TextEditingValue(
        text: option.name,
        selection: TextSelection.collapsed(offset: option.name.length),
      );
    });
    widget.onSelected(option);
    _focus.unfocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_controllerChanged);
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFieldTapRegion(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            onChanged: _changed,
            validator: (_) =>
                widget.selected != null &&
                    widget.controller.text == widget.selected!.name
                ? null
                : 'Please select ${widget.label} from the results',
            decoration: InputDecoration(
              labelText: '${widget.label} *',
              helperText: widget.enabled
                  ? 'Type to search; wait for 1 second.'
                  : widget.disabledHint,
              border: const OutlineInputBorder(),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
            ),
          ),
          if (_focus.hasFocus && _error != null)
            TextButton(
              onPressed: () => _changed(widget.controller.text),
              child: Text(_error!),
            ),
          if (_focus.hasFocus && _searched && _options.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No results found'),
            ),
          if (_focus.hasFocus && _options.isNotEmpty)
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _options.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(_options[index].name),
                    onTap: () => _select(_options[index]),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
