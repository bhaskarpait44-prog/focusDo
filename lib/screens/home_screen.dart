import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/topic.dart';
import '../providers/topic_provider.dart';
import 'topic_detail_screen.dart';
import 'add_edit_topic_screen.dart';

import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to fetch data after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TopicProvider>(context, listen: false).fetchTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusDo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<TopicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.topics.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.topics.isEmpty) {
            return const Center(child: Text('No topics yet. Add one!'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: provider.topics.length,
            itemBuilder: (context, index) {
              final topic = provider.topics[index];
              return TopicCard(topic: topic);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTopicScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TopicCard extends StatelessWidget {
  final Topic topic;

  const TopicCard({super.key, required this.topic});

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(topic.color);
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TopicDetailScreen(topic: topic)),
      ),
      onLongPress: () => _showOptions(context),
      child: Card(
        color: color.withAlpha((0.1 * 255).toInt()),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              topic.icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              topic.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Topic'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditTopicScreen(topic: topic),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Topic', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Topic?'),
        content: Text('This will delete "${topic.name}" and all its tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<TopicProvider>(context, listen: false).deleteTopic(topic.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
