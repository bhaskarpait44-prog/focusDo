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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.topic.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                color: topicColor.withAlpha(20),
                child: Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Text(widget.topic.icon, style: const TextStyle(fontSize: 100)),
                  ),
                ),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Consumer<TaskProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.tasks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (provider.tasks.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist_outlined, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        const Text('No tasks here yet.', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = provider.tasks[index];
                      return TaskTile(task: task, topic: widget.topic);
                    },
                    childCount: provider.tasks.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditTaskScreen(topic: widget.topic),
          ),
        ),
        backgroundColor: topicColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('Add Task'),
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final Topic topic;

  const TaskTile({super.key, required this.task, required this.topic});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.scheduledAt != null &&
        task.scheduledAt!.isBefore(DateTime.now()) &&
        !task.isDone;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.isDone ? Colors.green.withAlpha(40) : Colors.grey.withAlpha(40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditTaskScreen(topic: topic, task: task),
            ),
          ),
          onLongPress: () => _confirmDelete(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Provider.of<TaskProvider>(context, listen: false)
                      .toggleTaskDone(task, topic.name),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: task.isDone ? Colors.green : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isDone ? Colors.green : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: task.isDone
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                          color: task.isDone
                              ? Colors.grey
                              : isOverdue
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (task.scheduledAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.alarm,
                              size: 14,
                              color: isOverdue ? Colors.red : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, h:mm a').format(task.scheduledAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverdue ? Colors.red : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PriorityIndicator(priority: task.priority),
              ],
            ),
          ),
        ),
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
        label = 'High';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Medium';
        break;
      default:
        color = Colors.green;
        label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}
