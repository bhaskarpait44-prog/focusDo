import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/topic_provider.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Fetch all tasks for calendar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchAllTasks();
    });
  }

  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.scheduledAt == null) return false;
      return isSameDay(task.scheduledAt, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final topicProvider = Provider.of<TopicProvider>(context);
    final selectedTasks = _getTasksForDay(_selectedDay!, taskProvider.allTasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              return _getTasksForDay(day, taskProvider.allTasks);
            },
            calendarStyle: const CalendarStyle(
              // The markers will be handled by the builder below
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox();
                
                final tasks = events.cast<Task>();
                final allDone = tasks.every((t) => t.isDone);
                
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: allDone ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: selectedTasks.isEmpty
                ? const Center(child: Text('No tasks for this day'))
                : ListView.builder(
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      final topic = topicProvider.topics.firstWhere(
                        (t) => t.id == task.topicId,
                        orElse: () => topicProvider.topics.first,
                      );
                      
                      final statusColor = task.isDone ? Colors.green : Colors.red;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: statusColor.withAlpha(80), width: 1),
                        ),
                        child: ListTile(
                          leading: Text(topic.icon, style: const TextStyle(fontSize: 24)),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            task.scheduledAt != null
                                ? DateFormat('hh:mm a').format(task.scheduledAt!)
                                : '',
                            style: TextStyle(color: statusColor.withAlpha(180)),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              task.isDone ? Icons.check_circle : Icons.circle_outlined,
                              color: statusColor,
                            ),
                            onPressed: () => taskProvider.toggleTaskDone(task, topic.name),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
