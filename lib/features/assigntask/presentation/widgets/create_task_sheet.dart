
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:solufine/core/utility/image_compression.dart';

import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import 'task_photo.dart';

const _green = Color(0xFF16803D);
const _dark = Color(0xFF172B3A);
const _border = Color(0xFFE2EAE5);
const _background = Color(0xFFF5F7F6);

class CreateTaskSheet extends StatefulWidget {
  final List<EmployeeEntity> employees;

  const CreateTaskSheet({
    super.key,
    required this.employees,
  });

  @override
  State<CreateTaskSheet> createState() =>
      _CreateTaskSheetState();
}

class _CreateTaskSheetState
    extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();

  String? _employeeId;
  TaskPriority _priority = TaskPriority.medium;

  late DateTime _assignedAt;
  late DateTime _dueAt;

  File? _photo;
  String? _savedPath;
  bool _preparing = false;
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    _assignedAt = DateTime.now();
    _dueAt = _assignedAt.add(
      const Duration(days: 1),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  InputDecoration _input(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: _green,
        size: 18,
      ),
      filled: true,
      fillColor: _background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  Future<void> _pickDate(bool assign) async {
    final current = assign ? _assignedAt : _dueAt;

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    final next = DateTime(
      picked.year,
      picked.month,
      picked.day,
      current.hour,
      current.minute,
    );

    setState(() {
      if (assign) {
        _assignedAt = next;
      } else {
        _dueAt = next;
      }
    });
  }

  Future<void> _pickTime(bool assign) async {
    final current = assign ? _assignedAt : _dueAt;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: false,
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    final next = DateTime(
      current.year,
      current.month,
      current.day,
      picked.hour,
      picked.minute,
    );

    setState(() {
      if (assign) {
        _assignedAt = next;
      } else {
        _dueAt = next;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_preparing || _waiting) return;

    setState(() => _preparing = true);

    try {
      final selected = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (selected == null) return;

      final result =
          await ImageCompression.compressImage(
        File(selected.path),
        maxWidth: 450,
        maxHeight: 450,
        quality: 45,
      );

      if (result == null || !await result.exists()) {
        throw Exception('Image compression failed');
      }

      if (!mounted) return;

      setState(() {
        _photo = result;
        _savedPath = null;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image error: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _preparing = false);
      }
    }
  }

  Future<void> _chooseImage() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: _green,
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: _green,
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _persistPhoto() async {
    if (_photo == null) return null;

    final root =
        await getApplicationDocumentsDirectory();

    final folder = Directory(
      p.join(root.path, 'task_attachments'),
    );

    await folder.create(recursive: true);

    final path = p.join(
      folder.path,
      'task_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    final file = await _photo!.copy(path);

    return file.path;
  }

  Future<void> _submit() async {
    if (_preparing || _waiting) return;

    if (!_formKey.currentState!.validate()) return;

    if (!_dueAt.isAfter(_assignedAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Due time must be after assigned time',
          ),
        ),
      );
      return;
    }

    final matches = widget.employees
        .where((x) => x.id == _employeeId)
        .toList();

    if (matches.isEmpty) return;

    setState(() => _preparing = true);

    try {
      _savedPath ??= await _persistPhoto();

      if (!mounted) return;

      final employee = matches.first;
      final now = DateTime.now();

      final task = TaskEntity(
        id: now.microsecondsSinceEpoch.toString(),
        employeeId: employee.id,
        employeeName: employee.name,
        title: _title.text.trim(),
        description: _description.text.trim(),
        assignedAt: _assignedAt,
        dueAt: _dueAt,
        createdAt: now,
        priority: _priority,
        status: TaskStatus.pending,
        attachmentPath: _savedPath,
      );

      setState(() => _waiting = true);

      context.read<TaskBloc>().add(
        AddTask(task),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save task: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _preparing = false);
      }
    }
  }

  Widget _tile(
    String label,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Expanded(
      child: TextFormField(
        key: ValueKey('$label:$value'),
        initialValue: value,
        readOnly: true,
        enabled: onTap != null,
        onTap: onTap == null ? null : () {
          FocusManager.instance.primaryFocus?.unfocus();
          onTap();
        },
        style: const TextStyle(
          color: _dark,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        decoration: _input(label, icon).copyWith(
          suffixIcon: onTap == null ? null : const Icon(Icons.arrow_drop_down, size: 20),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listenWhen: (old, next) =>
          old.saveCounter != next.saveCounter ||
          (old.notificationId != next.notificationId &&
              next.error &&
              _waiting &&
              !next.completing),
      listener: (context, state) {
        if (!_waiting) return;

        if (state.error) {
          setState(() => _waiting = false);
          return;
        }

        if (!state.saving) {
          Navigator.pop(context);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.97,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 9,
                  ),
                  height: 4,
                  width: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    15, 0, 8, 7,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Assign New Task',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _dark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _waiting
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(14),
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _employeeId,
                          isExpanded: true,
                          decoration: _input(
                            'Select Employee *',
                            Icons.person_outline,
                          ),
                          items: widget.employees.map(
                            (x) => DropdownMenuItem(
                              value: x.id,
                              child: Text(
                                x.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ).toList(),
                          onChanged: (x) =>
                              setState(() => _employeeId = x),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (x) =>
                              x == null || x.isEmpty
                                  ? 'Select employee'
                                  : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _title,
                          maxLength: 120,
                          decoration: _input(
                            'Task Title *',
                            Icons.title,
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (x) =>
                              x == null || x.trim().isEmpty
                                  ? 'Enter task title'
                                  : null,
                        ),
                        TextFormField(
                          controller: _description,
                          minLines: 2,
                          maxLines: 3,
                          decoration: _input(
                            'Description *',
                            Icons.notes,
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (x) =>
                              x == null || x.trim().isEmpty
                                  ? 'Enter description'
                                  : null,
                        ),
                        const SizedBox(height: 11),
                        const Text(
                          'Assignment Schedule',
                          style: TextStyle(
                            color: _dark,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _tile(
                              'Assign Date',
                              DateFormat('dd MMM yyyy')
                                  .format(_assignedAt),
                              Icons.event,
                              () => _pickDate(true),
                            ),
                            const SizedBox(width: 8),
                            _tile(
                              'Assign Time',
                              DateFormat('hh:mm a')
                                  .format(_assignedAt),
                              Icons.schedule,
                              () => _pickTime(true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _tile(
                              'Due Date',
                              DateFormat('dd MMM yyyy')
                                  .format(_dueAt),
                              Icons.event_outlined,
                              () => _pickDate(false),
                            ),
                            const SizedBox(width: 8),
                            _tile(
                              'Due Time',
                              DateFormat('hh:mm a')
                                  .format(_dueAt),
                              Icons.access_time,
                              () => _pickTime(false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        DropdownButtonFormField<TaskPriority>(
                          initialValue: _priority,
                          decoration: _input(
                            'Priority',
                            Icons.flag_outlined,
                          ),
                          items: TaskPriority.values.map(
                            (x) => DropdownMenuItem(
                              value: x,
                              child: Text(x.label),
                            ),
                          ).toList(),
                          onChanged: (x) {
                            if (x != null) {
                              setState(() => _priority = x);
                            }
                          },
                        ),
                        const SizedBox(height: 11),
                        OutlinedButton.icon(
                          onPressed: _preparing || _waiting
                              ? null
                              : _chooseImage,
                          icon: const Icon(Icons.attach_file),
                          label: Text(
                            _photo == null
                                ? 'Camera / Gallery Attachment'
                                : 'Change Attachment',
                          ),
                        ),
                        if (_photo != null) ...[
                          Stack(
                            children: [
                              TaskPhoto(
                                localPath: _photo!.path,
                                title: 'New Task Attachment',
                                height: 145,
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: IconButton.filledTonal(
                                  onPressed: _waiting
                                      ? null
                                      : () => setState(() {
                                            _photo = null;
                                            _savedPath = null;
                                          }),
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: _border),
                    ),
                  ),
                  child: BlocBuilder<TaskBloc, TaskState>(
                    builder: (context, state) {
                      final busy = _preparing ||
                          _waiting ||
                          state.saving ||
                          state.completing;

                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: busy ? null : _submit,
                          icon: busy
                              ? const SizedBox(
                                  height: 17,
                                  width: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline,
                                ),
                          label: Text(
                            busy ? 'Saving...' : 'Assign Task',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
