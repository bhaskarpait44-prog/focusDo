import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/mongodb_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final _dbService = MongodbService.instance;
  final _notificationService = NotificationService();
  List<Task> _tasks = [];
  List<Task> _allTasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  List<Task> get allTasks => _allTasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks(String topicId) async {
    _isLoading = true;
    notifyListeners();
    _tasks = await _dbService.getTasks(topicId);
    await _ensureDailyTasksExist(_tasks);
    // Re-fetch after ensuring daily tasks
    _tasks = await _dbService.getTasks(topicId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllTasks() async {
    _isLoading = true;
    notifyListeners();
    _allTasks = await _dbService.getAllTasks();
    await _ensureDailyTasksExist(_allTasks);
    // Re-fetch after ensuring daily tasks
    _allTasks = await _dbService.getAllTasks();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _ensureDailyTasksExist(List<Task> currentTasks) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Identify unique daily task "templates" (by title and topicId)
    final dailyTaskTemplates = currentTasks.where((t) => t.isDaily).fold<Map<String, Task>>({}, (map, task) {
      final key = '${task.topicId}_${task.title}';
      if (!map.containsKey(key)) {
        map[key] = task;
      }
      return map;
    });

    bool createdAny = false;

    for (var template in dailyTaskTemplates.values) {
      // Check if there is an instance for today
      final hasToday = currentTasks.any((t) {
        if (t.topicId != template.topicId || t.title != template.title) return false;
        if (t.scheduledAt == null) return false;
        final taskDate = DateTime(t.scheduledAt!.year, t.scheduledAt!.month, t.scheduledAt!.day);
        return taskDate.isAtSameMomentAs(today);
      });

      if (!hasToday) {
        // Create it for today
        final scheduledTime = template.scheduledAt ?? now;
        final todayScheduledAt = DateTime(
          today.year,
          today.month,
          today.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );

        final newTask = Task(
          id: const Uuid().v4(),
          topicId: template.topicId,
          title: template.title,
          description: template.description,
          scheduledAt: todayScheduledAt,
          priority: template.priority,
          isDone: false,
          isDaily: true,
          createdAt: now,
        );
        
        await _dbService.addTask(newTask);
        createdAny = true;
      }
    }

    if (createdAny) {
      // We don't call fetchTasks here to avoid recursion, 
      // the caller will re-fetch if needed or we update locally.
    }
  }

  Future<void> addTask(Task task, String topicName) async {
    await _dbService.addTask(task);
    if (task.scheduledAt != null) {
      await _notificationService.schedule(task, topicName);
    }
    fetchTasks(task.topicId); // Refresh the list
    fetchAllTasks(); // Refresh for calendar
  }

  Future<void> updateTask(Task task, String topicName) async {
    await _dbService.updateTask(task);
    if (task.isDone) {
      await _notificationService.cancel(task.id);
    } else if (task.scheduledAt != null) {
      await _notificationService.schedule(task, topicName);
    }
    fetchTasks(task.topicId); // Refresh the list
    fetchAllTasks(); // Refresh for calendar
  }

  Future<void> deleteTask(Task task) async {
    await _dbService.deleteTask(task.id);
    await _notificationService.cancel(task.id);
    fetchTasks(task.topicId); // Refresh the list
    fetchAllTasks(); // Refresh for calendar
  }

  Future<void> toggleTaskDone(Task task, String topicName) async {
    final updatedTask = task.copyWith(isDone: !task.isDone);
    await updateTask(updatedTask, topicName);

    // If it was marked as done and is a daily task, create it for the next day
    if (updatedTask.isDone && updatedTask.isDaily) {
      final nextDay = (updatedTask.scheduledAt ?? DateTime.now()).add(const Duration(days: 1));
      
      final newTask = Task(
        id: const Uuid().v4(),
        topicId: updatedTask.topicId,
        title: updatedTask.title,
        description: updatedTask.description,
        scheduledAt: nextDay,
        priority: updatedTask.priority,
        isDone: false,
        isDaily: true,
        createdAt: DateTime.now(),
      );
      
      await addTask(newTask, topicName);
    }
  }
}
