import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/topic.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Topic topic;
  final Task? task;

  const AddEditTaskScreen({super.key, required this.topic, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _scheduledAt;
  late String _priority;
  late bool _isDaily;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _scheduledAt = widget.task?.scheduledAt;
    _priority = widget.task?.priority ?? 'medium';
    _isDaily = widget.task?.isDaily ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id ?? const Uuid().v4(),
        topicId: widget.topic.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        scheduledAt: _scheduledAt,
        priority: _priority,
        isDone: widget.task?.isDone ?? false,
        isDaily: _isDaily,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
      );

      final provider = Provider.of<TaskProvider>(context, listen: false);
      if (widget.task == null) {
        provider.addTask(task, widget.topic.name);
      } else {
        provider.updateTask(task, widget.topic.name);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicColor = _hexToColor(widget.topic.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const Text('Schedule Alarm', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(_scheduledAt == null
                    ? 'No time set'
                    : DateFormat('MMM d, yyyy - h:mm a').format(_scheduledAt!)),
                trailing: _scheduledAt != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _scheduledAt = null),
                      )
                    : null,
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Daily Task', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Repeats every day after completion'),
                value: _isDaily,
                onChanged: (value) => setState(() => _isDaily = value),
                activeTrackColor: topicColor.withAlpha(150),
                activeThumbColor: topicColor,
              ),
              const SizedBox(height: 24),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PriorityChip(
                    label: 'Low',
                    value: 'low',
                    isSelected: _priority == 'low',
                    onSelect: (v) => setState(() => _priority = v),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _PriorityChip(
                    label: 'Medium',
                    value: 'medium',
                    isSelected: _priority == 'medium',
                    onSelect: (v) => setState(() => _priority = v),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _PriorityChip(
                    label: 'High',
                    value: 'high',
                    isSelected: _priority == 'high',
                    onSelect: (v) => setState(() => _priority = v),
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: topicColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.task == null ? 'Create Task' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final Function(String) onSelect;
  final Color color;

  const _PriorityChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onSelect,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
