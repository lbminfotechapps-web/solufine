import 'package:flutter/material.dart';
import 'package:solufine/core/utility/widgets/adaptive_search_dropdown.dart';
import '../../domain/entities/demo_distributor_entry.dart';

class DemoIrrigationSearch extends StatefulWidget {
  const DemoIrrigationSearch({
    super.key,
    required this.load,
    required this.onChanged,
  });
  final Future<List<DemoOption>> Function() load;
  final ValueChanged<String?> onChanged;

  @override
  State<DemoIrrigationSearch> createState() => _DemoIrrigationSearchState();
}

class _DemoIrrigationSearchState extends State<DemoIrrigationSearch> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<DemoOption>? _options;
  bool _visible = false;
  bool _loading = false;
  String? _error;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (!_focus.hasFocus && mounted) setState(() => _visible = false);
  }

  Future<void> _open() async {
    setState(() => _visible = true);
    if (_options != null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await widget.load();
      if (!mounted) return;
      setState(
        () => _options = options
            .where(
              (item) =>
                  item.id.trim().isNotEmpty &&
                  item.id != '0' &&
                  item.name.trim().isNotEmpty &&
                  !item.name.trim().toLowerCase().startsWith(
                    'select irrigation',
                  ),
            )
            .toList(),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to load irrigation. Tap the field to retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = _options ?? const <DemoOption>[];
    return AdaptiveSearchDropdown(
      visible: _visible,
      field: TextFormField(
        controller: _controller,
        focusNode: _focus,
        readOnly: true,
        onTap: _open,
        decoration: InputDecoration(
          labelText: 'Select Irrigation',
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedId != null)
                IconButton(
                  tooltip: 'Clear irrigation',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _controller.clear();
                      _selectedId = null;
                      _visible = false;
                    });
                    widget.onChanged(null);
                    _focus.unfocus();
                  },
                ),
              IconButton(
                tooltip: 'Select irrigation',
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: () {
                  _focus.requestFocus();
                  _open();
                },
              ),
            ],
          ),
        ),
        validator: (value) =>
            (value?.trim().isNotEmpty ?? false) && _selectedId == null
            ? 'Please select irrigation from the results'
            : null,
      ),
      options: _loading
          ? const LinearProgressIndicator()
          : _error != null
          ? Padding(padding: const EdgeInsets.all(12), child: Text(_error!))
          : options.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No matches found'),
            )
          : ListView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                return ListTile(
                  title: Text(option.name),
                  onTap: () {
                    setState(() {
                      _controller.text = option.name;
                      _visible = false;
                    });
                    _selectedId = option.id;
                    widget.onChanged(option.id);
                    _focus.unfocus();
                  },
                );
              },
            ),
    );
  }
}
