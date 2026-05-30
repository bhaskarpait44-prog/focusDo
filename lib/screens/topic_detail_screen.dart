import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/topic.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'add_edit_task_screen.dart';

class TopicDetailScreen extends StatefulWidget {
  final Topic topic;

  const TopicDetailScreen({super.key, required this.topic});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks(widget.topic.id);
    });
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final topicColor = _hexToColor(widget.topic.color);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.topic.icon} ${widget.topic.name}'),
        backgroundColor: topicColor.withAlpha((0.1 * 255).toInt()),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.tasks.isEmpty) {
            return const Center(child: Text('No tasks for this topic. Add one!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.tasks.length,
            itemBuilder: (context, index) {
              final task = provider.tasks[index];
              return TaskTile(task: task, topic: widget.topic);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditTaskScreen(topic: widget.topic),
          ),
        ),
        backgroundColor: topicColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final Topic topic;

  const TaskTile({super.key, required this.task, required this.topic});

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.scheduledAt != null &&
        task.scheduledAt!.isBefore(DateTime.now()) &&
        !task.isDone;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => Provider.of<TaskProvider>(context, listen: false)
              .toggleTaskDone(task, topic.name),
          activeColor: _hexToColor(topic.color),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
            color: isOverdue ? Colors.red : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (task.scheduledAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isOverdue ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(task.scheduledAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: _PriorityIndicator(priority: task.priority),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditTaskScreen(topic: topic, task: task),
          ),
        ),
        onLongPress: () => _confirmDelete(context),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false).deleteTask(task);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PriorityIndicator extends StatelessWidget {
  final String priority;

  const _PriorityIndicator({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (priority) {
      case 'high':
        color = Colors.red;
        label = '🔴';
        break;
      case 'medium':
        color = Colors.orange;
        label = '🟠';
        break;
      default:
        color = Colors.green;
        label = '🟢';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label),
    );
  }
}
