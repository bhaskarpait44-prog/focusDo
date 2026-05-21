import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final _dbService = DatabaseService.instance;
  final _notificationService = NotificationService();
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks(String topicId) async {
    _isLoading = true;
    notifyListeners();
    _tasks = await _dbService.getTasks(topicId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(Task task, String topicName) async {
    await _dbService.addTask(task);
    if (task.scheduledAt != null) {
      await _notificationService.schedule(task, topicName);
    }
    fetchTasks(task.topicId); // Refresh the list
  }

  Future<void> updateTask(Task task, String topicName) async {
    await _dbService.updateTask(task);
    if (task.isDone) {
      await _notificationService.cancel(task.id);
    } else if (task.scheduledAt != null) {
      await _notificationService.schedule(task, topicName);
    }
    fetchTasks(task.topicId); // Refresh the list
  }

  Future<void> deleteTask(Task task) async {
    await _dbService.deleteTask(task.id);
    await _notificationService.cancel(task.id);
    fetchTasks(task.topicId); // Refresh the list
  }

  Future<void> toggleTaskDone(Task task, String topicName) async {
    final updatedTask = task.copyWith(isDone: !task.isDone);
    await updateTask(updatedTask, topicName);
  }
}
