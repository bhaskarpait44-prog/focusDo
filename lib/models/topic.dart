import 'package:cloud_firestore/cloud_firestore.dart';

class Topic {
  final String id;
  final String name;
  final String color; // hex e.g. '#FF5733'
  final String icon; // emoji e.g. '📚'
  final DateTime createdAt;

  Topic({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] ?? '#000000',
      icon: map['icon'] ?? '📁',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Topic copyWith({
    String? name,
    String? color,
    String? icon,
  }) {
    return Topic(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
    );
  }
}
