import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/demo_distributor_entry.dart';

/// Debounces searches and ignores stale responses after a newer query.
class DemoOptionPicker extends StatefulWidget {
  final String title;
  final Future<List<DemoOption>> Function(String query) load;
  const DemoOptionPicker({super.key, required this.title, required this.load});
  @override
  State<DemoOptionPicker> createState() => _DemoOptionPickerState();
}

class _DemoOptionPickerState extends State<DemoOptionPicker> {
  Timer? _timer;
  int _version = 0;
  bool _loading = true;
  String? _error;
  List<DemoOption> _options = [];
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load('', ++_version);
  }

  void _changed(String query) {
    _timer?.cancel();
    final version = ++_version;
    setState(() {
      _loading = true;
      _error = null;
    });
    _timer = Timer(const Duration(seconds: 1), () => _load(query, version));
  }

  Future<void> _load(String query, int version) async {
    try {
      final options = await widget.load(query);
      if (!mounted || version != _version) return;
      setState(() {
        _options = options;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || version != _version) return;
      setState(() {
        _error = 'Unable to load options. Please retry.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: double.maxFinite,
      height: 360,
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: _changed,
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(
                          onPressed: () {
                            setState(() => _loading = true);
                            _load(_search.text, ++_version);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _options.isEmpty
                ? const Center(child: Text('No results found'))
                : ListView.builder(
                    itemCount: _options.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_options[index].name),
                      onTap: () => Navigator.pop(context, _options[index]),
                    ),
                  ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );
}
