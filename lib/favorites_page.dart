import 'dart:async';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'course_datail_page.dart';

class FavoritesPage extends StatefulWidget {
  final int userId;

  const FavoritesPage({super.key, required this.userId});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final StreamController<List<Map<String, dynamic>>> _favoritesController =
      StreamController.broadcast();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    List<Map<String, dynamic>> favorites =
        await _dbHelper.getFavoritesByUserId(widget.userId);

    List<Map<String, dynamic>> courseDetails = [];
    for (var favorite in favorites) {
      Map<String, dynamic>? course =
          await _dbHelper.getCourseById(favorite['course_id']);
      if (course != null) {
        courseDetails.add(course);
      }
    }

    _favoritesController.sink.add(courseDetails);
  }

  @override
  void dispose() {
    _favoritesController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _favoritesController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data;

          if (favorites == null || favorites.isEmpty) {
            return const Center(child: Text('Нет избранных курсов'));
          }

          return RefreshIndicator(
            onRefresh: _loadFavorites,
            child: ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final course = favorites[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(course['title']),
                    subtitle: Text(course['description']),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseDetailPage(
                            courseId: course['course_id'],
                            userId: widget.userId,
                          ),
                        ),
                      );
                      _loadFavorites(); // Обновим поток после возврата
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}