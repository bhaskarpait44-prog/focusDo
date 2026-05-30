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
    _isLoading = false;
    notifyListeners();
    
    // Check for daily tasks in background
    _ensureDailyTasksExist(_tasks).then((created) {
      if (created) fetchTasks(topicId);
    });
  }

  Future<void> fetchAllTasks() async {
    _isLoading = true;
    notifyListeners();
    _allTasks = await _dbService.getAllTasks();
    _isLoading = false;
    notifyListeners();

    // Check for daily tasks in background
    _ensureDailyTasksExist(_allTasks).then((created) {
      if (created) fetchAllTasks();
    });
  }

  Future<bool> _ensureDailyTasksExist(List<Task> currentTasks) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final dailyTaskTemplates = currentTasks.where((t) => t.isDaily).fold<Map<String, Task>>({}, (map, task) {
      final key = '${task.topicId}_${task.title}';
      if (!map.containsKey(key)) {
        map[key] = task;
      }
      return map;
    });

    bool createdAny = false;
    List<Task> newTasks = [];

    for (var template in dailyTaskTemplates.values) {
      final hasToday = currentTasks.any((t) {
        if (t.topicId != template.topicId || t.title != template.title) return false;
        if (t.scheduledAt == null) return false;
        final taskDate = DateTime(t.scheduledAt!.year, t.scheduledAt!.month, t.scheduledAt!.day);
        return taskDate.isAtSameMomentAs(today);
      });

      if (!hasToday) {
        final scheduledTime = template.scheduledAt ?? now;
        final todayScheduledAt = DateTime(
          today.year,
          today.month,
          today.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );

        newTasks.add(Task(
          id: const Uuid().v4(),
          topicId: template.topicId,
          title: template.title,
          description: template.description,
          scheduledAt: todayScheduledAt,
          priority: template.priority,
          isDone: false,
          isDaily: true,
          createdAt: now,
        ));
      }
    }

    if (newTasks.isNotEmpty) {
      for (var task in newTasks) {
        await _dbService.addTask(task);
      }
      createdAny = true;
    }
    return createdAny;
  }

  Future<void> addTask(Task task, String topicName) async {
    // Optimistic Update
    _tasks.add(task);
    _allTasks.add(task);
    notifyListeners();

    try {
      await _dbService.addTask(task);
      if (task.scheduledAt != null) {
        await _notificationService.schedule(task, topicName);
      }
    } catch (e) {
      // Revert on error
      _tasks.removeWhere((t) => t.id == task.id);
      _allTasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task, String topicName) async {
    // Optimistic Update
    final index = _tasks.indexWhere((t) => t.id == task.id);
    final allIndex = _allTasks.indexWhere((t) => t.id == task.id);
    
    Task? oldTask;
    if (index != -1) {
      oldTask = _tasks[index];
      _tasks[index] = task;
    }
    if (allIndex != -1) {
      oldTask ??= _allTasks[allIndex];
      _allTasks[allIndex] = task;
    }
    notifyListeners();

    try {
      await _dbService.updateTask(task);
      if (task.isDone) {
        await _notificationService.cancel(task.id);
      } else if (task.scheduledAt != null) {
        await _notificationService.schedule(task, topicName);
      }
    } catch (e) {
      // Revert on error
      if (oldTask != null) {
        if (index != -1) _tasks[index] = oldTask;
        if (allIndex != -1) _allTasks[allIndex] = oldTask;
        notifyListeners();
      }
    }
  }

  Future<void> deleteTask(Task task) async {
    // Optimistic Update
    final oldTasks = List<Task>.from(_tasks);
    final oldAllTasks = List<Task>.from(_allTasks);
    
    _tasks.removeWhere((t) => t.id == task.id);
    _allTasks.removeWhere((t) => t.id == task.id);
    notifyListeners();

    try {
      await _dbService.deleteTask(task.id);
      await _notificationService.cancel(task.id);
    } catch (e) {
      // Revert on error
      _tasks = oldTasks;
      _allTasks = oldAllTasks;
      notifyListeners();
    }
  }

  Future<void> toggleTaskDone(Task task, String topicName) async {
    final updatedTask = task.copyWith(isDone: !task.isDone);
    await updateTask(updatedTask, topicName);

    // Replication logic (non-blocking)
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
      addTask(newTask, topicName);
    }
  }
}
