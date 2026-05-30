import 'package:mongo_dart/mongo_dart.dart';
import '../models/topic.dart';
import '../models/task.dart';

class MongodbService {
  static final MongodbService instance = MongodbService._init();
  static Db? _db;
  
  // MongoDB Atlas Connection String
  // Note: Password '@' character is percent-encoded to '%40'
  static const String _connectionString = "mongodb+srv://erpuser:Macos%40787059@clustertodo.isrzoji.mongodb.net/focusdo?retryWrites=true&w=majority&appName=ClusterTodo";

  MongodbService._init();

  Future<Db> get database async {
    if (_db != null && _db!.isConnected) return _db!;
    _db = await Db.create(_connectionString);
    await _db!.open();
    return _db!;
  }

  // ─── Topic Methods ─────────────────────────────────

  Future<void> addTopic(Topic topic) async {
    final db = await database;
    final collection = db.collection('topics');
    await collection.insert(topic.toMap());
  }

  Future<List<Topic>> getTopics() async {
    final db = await database;
    final collection = db.collection('topics');
    final List<Map<String, dynamic>> maps = await collection.find(where.sortBy('createdAt', descending: false)).toList();
    return maps.map((map) => Topic.fromMap(map)).toList();
  }

  Future<void> updateTopic(Topic topic) async {
    final db = await database;
    final collection = db.collection('topics');
    await collection.update(where.eq('id', topic.id), topic.toMap());
  }

  Future<void> deleteTopic(String id) async {
    final db = await database;
    // Delete topic
    await db.collection('topics').remove(where.eq('id', id));
    // Delete associated tasks
    await db.collection('tasks').remove(where.eq('topicId', id));
  }

  // ─── Task Methods ──────────────────────────────────

  Future<void> addTask(Task task) async {
    final db = await database;
    final collection = db.collection('tasks');
    await collection.insert(task.toMap());
  }

  Future<List<Task>> getTasks(String topicId) async {
    final db = await database;
    final collection = db.collection('tasks');
    final List<Map<String, dynamic>> maps = await collection.find(where.eq('topicId', topicId).sortBy('createdAt', descending: false)).toList();
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final collection = db.collection('tasks');
    final List<Map<String, dynamic>> maps = await collection.find().toList();
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    final collection = db.collection('tasks');
    await collection.update(where.eq('id', task.id), task.toMap());
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.collection('tasks').remove(where.eq('id', id));
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
    }
  }
}
