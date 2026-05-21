import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String topicId;
  final String title;
  final String description;
  final DateTime? scheduledAt; // null = no alarm
  final String priority; // 'low' | 'medium' | 'high'
  final bool isDone;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.topicId,
    required this.title,
    required this.description,
    this.scheduledAt,
    required this.priority,
    required this.isDone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topicId': topicId,
      'title': title,
      'description': description,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'priority': priority,
      'isDone': isDone ? 1 : 0, // Convert boolean to integer
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      topicId: map['topicId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.parse(map['scheduledAt'])
          : null,
      priority: map['priority'] ?? 'medium',
      isDone: map['isDone'] == 1, // Convert integer to boolean
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? scheduledAt,
    String? priority,
    bool? isDone,
  }) {
    return Task(
      id: id,
      topicId: topicId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
    );
  }
}
