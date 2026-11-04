import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/products/data/product_datasource.dart';
import 'package:solufine/features/products/domain/entity/product_name.dart';

class DealerSalesPotential {
  const DealerSalesPotential({
    required this.productId,
    required this.productName,
    required this.amount,
  });
  final String productId;
  final String productName;
  final String amount;
}

class DealerAdditionalInformation {
  DealerAdditionalInformation({
    required this.classification,
    required List<DealerSalesPotential> salesPotential,
  }) : salesPotential = List.unmodifiable(salesPotential);
  final String classification;
  final List<DealerSalesPotential> salesPotential;
}

class DealerAdditionalInformationDialog extends StatefulWidget {
  const DealerAdditionalInformationDialog({
    super.key,
    this.initialValue,
    this.loadProducts,
  });
  final DealerAdditionalInformation? initialValue;
  final Future<ProductResponseEntity> Function(String query)? loadProducts;

  @override
  State<DealerAdditionalInformationDialog> createState() =>
      _DealerAdditionalInformationDialogState();
}

class _DealerAdditionalInformationDialogState
    extends State<DealerAdditionalInformationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amounts = <String, TextEditingController>{};
  final _names = <String, String>{};
  String? _classification;
  String _query = '';
  bool _loading = false;
  Timer? _debounce;
  int _request = 0;
  List<String> _resultIds = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _classification = widget.initialValue?.classification;
    for (final item
        in widget.initialValue?.salesPotential ?? <DealerSalesPotential>[]) {
      _names[item.productId] = item.productName;
      _amounts[item.productId] = TextEditingController(text: item.amount);
    }
  }

  void _search(String value) {
    _debounce?.cancel();
    final request = ++_request;
    setState(() {
      _query = value.trim();
      _resultIds = [];
      _loading = false;
      _error = null;
    });
    if (_query.isEmpty) return;
    final query = _query;
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _load(query, request),
    );
  }

  Future<void> _load(String query, int request) async {
    if (!mounted || request != _request) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await (widget.loadProducts?.call(query) ??
              ProductDatasource(DioClient()).getProductNameList(query));
      if (!mounted || request != _request) return;
      if (!response.status) throw StateError(response.message);
      setState(() {
        _resultIds = [];
        for (final product in response.products) {
          if (product.productId.trim().isEmpty ||
              product.productName.trim().isEmpty) {
            continue;
          }
          if (!_resultIds.contains(product.productId)) {
            _resultIds.add(product.productId);
          }
          _names[product.productId] = product.productName;
          _amounts.putIfAbsent(
            product.productId,
            () => TextEditingController(),
          );
        }
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('DEALER SALES POTENTIAL PRODUCTS ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load products. Please try again.';
      });
    }
  }

  String get _grandTotal {
    var cents = 0;
    for (final controller in _amounts.values) {
      final parts = controller.text.trim().split('.');
      final whole = int.tryParse(parts.first) ?? 0;
      final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
      cents += whole * 100 + (int.tryParse(fraction) ?? 0);
    }
    return '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final entries = <DealerSalesPotential>[];
    for (final item in _amounts.entries) {
      final text = item.value.text.trim();
      if (text.isEmpty) continue;
      final amount = double.tryParse(text);
      if (amount == null || !amount.isFinite || amount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enter a valid amount for ${_names[item.key]}'),
          ),
        );
        return;
      }
      entries.add(
        DealerSalesPotential(
          productId: item.key,
          productName: _names[item.key]!,
          amount: text,
        ),
      );
    }
    Navigator.pop(
      context,
      DealerAdditionalInformation(
        classification: _classification!,
        salesPotential: entries,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _request++;
    for (final controller in _amounts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleIds = _query.isEmpty
        ? _amounts.entries
              .where((entry) => entry.value.text.trim().isNotEmpty)
              .map((entry) => entry.key)
        : _resultIds;
    final products = visibleIds.map((id) => MapEntry(id, _names[id]!)).toList();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    InputDecoration decoration(String label) => InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 480,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 4, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Additional information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _classification,
                          isDense: true,
                          decoration: decoration('Classification *'),
                          items: ['A', 'B', 'C']
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _classification = value),
                          validator: (value) => value == null
                              ? 'Please select classification'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Sales potential',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: decoration('Search products').copyWith(
                            prefixIcon: const Icon(Icons.search, size: 20),
                          ),
                          onChanged: _search,
                        ),
                        const SizedBox(height: 8),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (_error != null)
                          Column(
                            children: [
                              Text(
                                _error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.error,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _search(_query),
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        else if (products.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _query.isEmpty
                                  ? 'Search to add products and amounts'
                                  : 'No matching products',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            separatorBuilder: (_, index) => Divider(
                              height: 12,
                              color: colors.outlineVariant,
                            ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.value,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        key: ValueKey(product.key),
                                        controller: _amounts[product.key],
                                        onChanged: (_) => setState(() {}),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: [
                                          TextInputFormatter.withFunction(
                                            (oldValue, newValue) =>
                                                RegExp(
                                                  r'^\d{0,12}(\.\d{0,2})?$',
                                                ).hasMatch(newValue.text)
                                                ? newValue
                                                : oldValue,
                                          ),
                                        ],
                                        decoration: decoration('Amount'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Grand Total', style: theme.textTheme.titleSmall),
                    Text(
                      _grandTotal,
                      key: const ValueKey('sales-potential-grand-total'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _loading || _error != null ? null : _save,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
