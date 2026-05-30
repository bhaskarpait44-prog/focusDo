import 'package:flutter/material.dart';
import '../models/topic.dart';
import '../services/mongodb_service.dart';

class TopicProvider extends ChangeNotifier {
  final _dbService = MongodbService.instance;
  List<Topic> _topics = [];
  bool _isLoading = false;

  List<Topic> get topics => _topics;
  bool get isLoading => _isLoading;

  Future<void> fetchTopics() async {
    _isLoading = true;
    notifyListeners();
    _topics = await _dbService.getTopics();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTopic(Topic topic) async {
    await _dbService.addTopic(topic);
    fetchTopics(); // Refresh the list
  }

  Future<void> updateTopic(Topic topic) async {
    await _dbService.updateTopic(topic);
    fetchTopics(); // Refresh the list
  }

  Future<void> deleteTopic(String id) async {
    await _dbService.deleteTopic(id);
    fetchTopics(); // Refresh the list
  }
}
