import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/topic.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('focusdo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE topics (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        topicId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        scheduledAt TEXT,
        priority TEXT NOT NULL,
        isDone INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (topicId) REFERENCES topics (id) ON DELETE CASCADE
      )
    ''');
  }

  // ─── Topic Methods ─────────────────────────────────

  Future<void> addTopic(Topic topic) async {
    final db = await instance.database;
    await db.insert('topics', topic.toMap());
  }

  Future<List<Topic>> getTopics() async {
    final db = await instance.database;
    final maps = await db.query('topics', orderBy: 'createdAt ASC');
    return maps.isNotEmpty ? maps.map((map) => Topic.fromMap(map)).toList() : [];
  }

  Future<void> updateTopic(Topic topic) async {
    final db = await instance.database;
    await db.update('topics', topic.toMap(), where: 'id = ?', whereArgs: [topic.id]);
  }

  Future<void> deleteTopic(String id) async {
    final db = await instance.database;
    await db.delete('topics', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Task Methods ──────────────────────────────────

  Future<void> addTask(Task task) async {
    final db = await instance.database;
    await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks(String topicId) async {
    final db = await instance.database;
    final maps = await db.query('tasks', where: 'topicId = ?', whereArgs: [topicId], orderBy: 'createdAt ASC');
    return maps.isNotEmpty ? maps.map((map) => Task.fromMap(map)).toList() : [];
  }

  Future<void> updateTask(Task task) async {
    final db = await instance.database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(String id) async {
    final db = await instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
