import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';

class MeetingLocation {
  const MeetingLocation(this.id, this.name);
  final String id;
  final String name;
}

class MeetingLocationSearch extends StatefulWidget {
  const MeetingLocationSearch({
    super.key,
    required this.kind,
    required this.controller,
    required this.onSelected,
    required this.onEdited,
    this.parentId = '',
  });
  final String kind;
  final TextEditingController controller;
  final String parentId;
  final ValueChanged<MeetingLocation> onSelected;
  final VoidCallback onEdited;

  @override
  State<MeetingLocationSearch> createState() => _MeetingLocationSearchState();
}

class _MeetingLocationSearchState extends State<MeetingLocationSearch> {
  final _focus = FocusNode();
  bool _loading = false;
  String? _error;
  String? _selectedName;
  int _request = 0;
  CancelToken? _cancel;
  bool get _enabled => widget.kind == 'State' || widget.parentId.isNotEmpty;

  @override
  void dispose() {
    _request++;
    _cancel?.cancel();
    _focus.dispose();
    super.dispose();
  }

  String _read(Map row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return '';
  }

  Future<Iterable<MeetingLocation>> _search(TextEditingValue value) async {
    final request = ++_request;
    _cancel?.cancel();
    final query = value.text.trim();
    if (!_enabled || query.isEmpty || query == _selectedName) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
      return const [];
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted || request != _request) return const [];
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await SecureStorage.instance.getUserData();
      if (!mounted || request != _request) return const [];
      final userId = user?['user_id']?.toString() ?? '';
      if (userId.isEmpty) {
        throw StateError('Please sign in again to search locations.');
      }
      final endpoint = switch (widget.kind) {
        'State' => 'get_state',
        'District' => 'get_district',
        _ => 'get_taluka',
      };
      final cancel = CancelToken();
      _cancel = cancel;
      final response = await DioClient().client.post(
        '${ApiClient.baseUrl}/$endpoint',
        data: {
          'user_id': userId,
          'searchText': query,
          if (widget.kind == 'District') 'state_id': widget.parentId,
          if (widget.kind == 'Block') 'district_id': widget.parentId,
        },
        cancelToken: cancel,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
        ),
      );
      dynamic data = response.data;
      if (data is String) {
        var text = data.trim();
        if (text.startsWith('<') &&
            text.contains('A PHP Error was encountered')) {
          final start = RegExp(r'\{\s*"status"\s*:').firstMatch(text)?.start;
          if (start != null) text = text.substring(start);
        }
        data = jsonDecode(text);
      }
      if (data is Map) {
        final status = data['status'];
        if (!(status == true ||
            status == 1 ||
            status == '1' ||
            status.toString().toLowerCase() == 'true')) {
          throw StateError(
            data['message']?.toString() ?? 'Location search failed.',
          );
        }
        data = data['result'];
      }
      if (data is! List) throw const FormatException('Invalid location list');
      final locations = data
          .whereType<Map>()
          .map((row) {
            final idKeys = switch (widget.kind) {
              'State' => ['fld_state_id', 'state_id', 'fld_id', 'id'],
              'District' => [
                'fld_dist_id',
                'fld_district_id',
                'district_id',
                'fld_id',
                'id',
              ],
              _ => ['fld_taluka_id', 'taluka_id', 'fld_id', 'id'],
            };
            final nameKeys = switch (widget.kind) {
              'State' => ['fld_name', 'fld_state_name', 'state_name', 'name'],
              'District' => [
                'fld_dist_name',
                'fld_district_name',
                'fld_name',
                'district_name',
                'name',
              ],
              _ => ['fld_name', 'fld_taluka_name', 'taluka_name', 'name'],
            };
            return MeetingLocation(_read(row, idKeys), _read(row, nameKeys));
          })
          .where((entry) => entry.id.isNotEmpty && entry.name.isNotEmpty)
          .toList();
      if (!mounted || request != _request) return const [];
      setState(() {
        _loading = false;
        _error = locations.isEmpty ? 'No matches found.' : null;
      });
      return locations;
    } catch (error) {
      if (!mounted || request != _request) return const [];
      setState(() {
        _loading = false;
        _error = error is StateError
            ? error.message
            : error is DioException && error.response?.statusCode == 404
            ? '${widget.kind} endpoint not found (404).'
            : 'Unable to search ${widget.kind.toLowerCase()}. Please try again.';
      });
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: RawAutocomplete<MeetingLocation>(
        textEditingController: widget.controller,
        focusNode: _focus,
        displayStringForOption: (entry) => entry.name,
        optionsBuilder: _search,
        onSelected: (entry) {
          _selectedName = entry.name;
          widget.onSelected(entry);
        },
        fieldViewBuilder: (context, controller, focus, onSubmitted) => TextFormField(
          controller: controller,
          focusNode: focus,
          enabled: _enabled,
          decoration: InputDecoration(
            labelText:
                'Select ${widget.kind}${widget.kind == 'Block' ? '' : ' *'}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            helperText: !_enabled
                ? 'Select ${widget.kind == 'District' ? 'State' : 'District'} first'
                : _error ?? '(After searching characters, wait for 1 sec..!)',
            helperStyle: const TextStyle(color: Colors.red, fontSize: 12),
            helperMaxLines: 2,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: (_) {
            _selectedName = null;
            widget.onEdited();
          },
          validator: (value) {
            if (widget.kind == 'Block' &&
                (value == null || value.trim().isEmpty)) {
              return null;
            }
            if (_selectedName == null || value != _selectedName) {
              return 'Please select ${widget.kind.toLowerCase()} from the results';
            }
            return null;
          },
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: (MediaQuery.sizeOf(context).width - 24).clamp(
                180.0,
                736.0,
              ),
              height: 200,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final entry = options.elementAt(index);
                  return ListTile(
                    title: Text(entry.name),
                    onTap: () => onSelected(entry),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
