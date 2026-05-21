import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/topic.dart';
import '../providers/topic_provider.dart';

class AddEditTopicScreen extends StatefulWidget {
  final Topic? topic;

  const AddEditTopicScreen({super.key, this.topic});

  @override
  State<AddEditTopicScreen> createState() => _AddEditTopicScreenState();
}

class _AddEditTopicScreenState extends State<AddEditTopicScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIcon;

  final List<String> _colors = [
    '#FF5733', '#33FF57', '#3357FF', '#F333FF', '#FF33A8',
    '#33FFF3', '#FFD433', '#8D33FF', '#FF8D33', '#33FF8D'
  ];

  final List<String> _icons = ['📚', '💼', '💪', '🧘', '🏠', '🛒', '🎨', '🚀', '🛠️', '🌱'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topic?.name ?? '');
    _selectedColor = widget.topic?.color ?? _colors[0];
    _selectedIcon = widget.topic?.icon ?? _icons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final topic = Topic(
        id: widget.topic?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
        createdAt: widget.topic?.createdAt ?? DateTime.now(),
      );

      final provider = Provider.of<TopicProvider>(context, listen: false);
      if (widget.topic == null) {
        provider.addTopic(topic);
      } else {
        provider.updateTopic(topic);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic == null ? 'Add Topic' : 'Edit Topic'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Topic Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 24),
              const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey[300] : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                        ),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((colorHex) {
                  final isSelected = _selectedColor == colorHex;
                  final color = _hexToColor(colorHex);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorHex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _hexToColor(_selectedColor),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.topic == null ? 'Create Topic' : 'Save Changes'),
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
