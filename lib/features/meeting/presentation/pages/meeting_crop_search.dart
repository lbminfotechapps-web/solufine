import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/complaint_form/data/datasource/complain_form_dsource.dart';

class MeetingCropSelection {
  const MeetingCropSelection({
    this.cropId = '',
    this.productIds = const [],
    this.classIds = const [],
  });
  final String cropId;
  final List<String> productIds;
  final List<String> classIds;
}

class MeetingCropSearch extends StatefulWidget {
  const MeetingCropSearch({
    super.key,
    required this.crop,
    required this.subcategory,
    required this.onChanged,
  });
  final TextEditingController crop;
  final TextEditingController subcategory;
  final ValueChanged<MeetingCropSelection> onChanged;

  @override
  State<MeetingCropSearch> createState() => _MeetingCropSearchState();
}

class _CropOption {
  const _CropOption(this.id, this.name, {this.classId = ''});
  final String id;
  final String name;
  final String classId;
}

class _MeetingCropSearchState extends State<MeetingCropSearch> {
  final _source = ComplainFormDSource(DioClient());
  final _timers = <int, Timer>{};
  final _versions = [0, 0];
  final _loading = [false, false];
  final _show = [false, false];
  final List<String?> _errors = [null, null];
  final List<List<_CropOption>> _options = [[], []];
  final _ids = ['', ''];
  final _names = ['', ''];
  final _productQuery = TextEditingController();
  final _selectedProducts = <String, _CropOption>{};
  static const _labels = ['Crop', 'Product'];

  TextEditingController _controller(int index) =>
      index == 0 ? widget.crop : _productQuery;

  void _notify() => widget.onChanged(
    MeetingCropSelection(
      cropId: _ids[0],
      productIds: List.unmodifiable(_selectedProducts.keys),
      classIds: List.unmodifiable(
        _selectedProducts.values.map((item) => item.classId).toSet(),
      ),
    ),
  );

  void _invalidate(int index, {bool clear = false}) {
    _timers.remove(index)?.cancel();
    _versions[index]++;
    _ids[index] = '';
    _names[index] = '';
    _loading[index] = false;
    _show[index] = false;
    _errors[index] = null;
    _options[index] = [];
    if (clear) {
      _controller(index).clear();
      if (index == 1) {
        _selectedProducts.clear();
        widget.subcategory.clear();
      }
    }
  }

  void _search(int index, String value) {
    setState(() {
      _invalidate(index);
      if (index == 0) {
        _invalidate(1, clear: true);
      }
    });
    _notify();
    if (value.trim().isEmpty) return;
    if (index > 0 && _ids[0].isEmpty) {
      setState(
        () => _errors[index] = 'Please select a crop from the results first',
      );
      return;
    }
    final version = _versions[index];
    final cropId = _ids[0];
    _timers[index] = Timer(
      const Duration(seconds: 1),
      () => _load(index, version, cropId),
    );
  }

  Future<void> _load(int index, int version, String cropId) async {
    if (!mounted || version != _versions[index]) return;
    setState(() {
      _loading[index] = true;
      _show[index] = true;
    });
    try {
      List<_CropOption> options;
      if (index == 0) {
        final result = await _source.getCategoryList();
        if (!result.status) throw StateError(result.message);
        options = result.result
            .map((item) => _CropOption(item.categoryId, item.categoryName))
            .toList();
      } else {
        final result = await _source.getSubCategoryList(cropId);
        if (!result.status) throw StateError(result.message);
        options = result.result
            .map(
              (item) => _CropOption(
                item.productId,
                item.productName,
                classId: item.subcategoryId,
              ),
            )
            .toList();
      }
      if (!mounted ||
          version != _versions[index] ||
          (index > 0 && cropId != _ids[0])) {
        return;
      }
      final query = _controller(index).text.trim().toLowerCase();
      setState(() {
        _loading[index] = false;
        _options[index] = options
            .where((option) => option.name.toLowerCase().contains(query))
            .toList();
      });
    } catch (error) {
      if (!mounted || version != _versions[index]) return;
      setState(() {
        _loading[index] = false;
        _errors[index] = error is StateError && error.message.isNotEmpty
            ? error.message
            : 'Unable to load ${_labels[index].toLowerCase()}. Please try again.';
      });
    }
  }

  void _toggleProduct(_CropOption option) {
    setState(() {
      if (_selectedProducts.containsKey(option.id)) {
        _selectedProducts.remove(option.id);
      } else {
        _selectedProducts[option.id] = option;
      }
      widget.subcategory.text = _selectedProducts.values
          .map((item) => item.name)
          .join(', ');
    });
    _notify();
  }

  void _select(int index, _CropOption option) {
    setState(() {
      _timers.remove(index)?.cancel();
      _versions[index]++;
      _ids[index] = option.id;
      _names[index] = option.name;
      _controller(index).text = option.name;
      _show[index] = false;
      _errors[index] = null;
      if (index == 0) {
        _invalidate(1, clear: true);
      }
    });
    _notify();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _productQuery.dispose();
    super.dispose();
  }

  Widget _field(int index) {
    final controller = _controller(index);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (index == 1 && _selectedProducts.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final option in _selectedProducts.values)
                  InputChip(
                    label: Text(option.name),
                    onDeleted: () => _toggleProduct(option),
                  ),
              ],
            ),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: '${_labels[index]} *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              suffixIcon: IconButton(
                tooltip: controller.text.isEmpty ? 'Search' : 'Clear',
                icon: Icon(
                  controller.text.isEmpty ? Icons.search : Icons.close,
                ),
                onPressed: controller.text.isEmpty
                    ? null
                    : () {
                        controller.clear();
                        _search(index, '');
                      },
              ),
              helperText:
                  _errors[index] ??
                  '(After searching characters, wait for 1 sec..!)',
              helperStyle: const TextStyle(color: Colors.red, fontSize: 12),
              helperMaxLines: 2,
            ),
            onTap: index == 1
                ? () {
                    if (!_show[1] && !_loading[1]) {
                      if (_ids[0].isEmpty) {
                        setState(
                          () => _errors[1] =
                              'Please select a crop from the results first',
                        );
                      } else {
                        _load(1, _versions[1], _ids[0]);
                      }
                    }
                  }
                : null,
            onChanged: (value) => _search(index, value),
            validator: (value) =>
                (index == 1
                    ? _selectedProducts.isEmpty
                    : _ids[index].isEmpty || value != _names[index])
                ? 'Please select ${_labels[index].toLowerCase()} from the results'
                : null,
          ),
          if (_loading[index]) const LinearProgressIndicator(),
          if (_show[index] && !_loading[index] && _errors[index] == null)
            if (_options[index].isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No matches found'),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: _options[index].length,
                  itemBuilder: (context, itemIndex) {
                    final option = _options[index][itemIndex];
                    if (index == 1) {
                      return CheckboxListTile(
                        title: Text(option.name),
                        value: _selectedProducts.containsKey(option.id),
                        onChanged: (_) => _toggleProduct(option),
                      );
                    }
                    return ListTile(
                      title: Text(option.name),
                      onTap: () => _select(index, option),
                    );
                  },
                ),
              ),
          if (index == 1 && _show[1])
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  _timers.remove(1)?.cancel();
                  setState(() {
                    _versions[1]++;
                    _show[1] = false;
                    _loading[1] = false;
                    _errors[1] = null;
                    _productQuery.clear();
                  });
                  FocusScope.of(context).unfocus();
                  _notify();
                },
                child: const Text('OK'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [for (var index = 0; index < 2; index++) _field(index)],
  );
}
