import 'dart:convert';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddCoursePage extends StatefulWidget {
  final int userId;

  const AddCoursePage({super.key, required this.userId});

  @override
  _AddCoursePageState createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _postTitleController = TextEditingController();
  final _postContentController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  final List<Map<String, dynamic>> _posts = [];
  late TabController _tabController;
  String _materialType = 'текст';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить новый курс')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Основная информация о курсе
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название курса',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите название';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание курса',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите описание';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            // Табы для тестов и постов
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Тесты'), Tab(text: 'Посты')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Вкладка с тестами
                  _buildTestsTab(),
                  // Вкладка с постами
                  _buildPostsTab(),
                ],
              ),
            ),
            // Кнопка добавления курса
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _addCourse,
                child: const Text('Добавить курс'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionCard(_questions[index], index);
              },
            ),
          ),
          ElevatedButton(
            onPressed: _showAddQuestionDialog,
            child: const Text('Добавить вопрос'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(_posts[index], index);
              },
            ),
          ),
          ElevatedButton(
            onPressed: _showAddPostDialog,
            child: const Text('Добавить пост'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Вопрос ${index + 1}'),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeQuestion(index),
                ),
              ],
            ),
            Text('Вопрос: ${question['question']}'),
            Text('Правильный ответ: ${question['correctAnswer']}'),
            Text('Варианты ответов: ${question['options'].join(', ')}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Пост ${index + 1}'),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removePost(index),
                ),
              ],
            ),
            Text('Заголовок: ${post['title']}'),
            Text('Содержание: ${post['content']}'),
          ],
        ),
      ),
    );
  }

  void _showAddQuestionDialog() {
    final questionController = TextEditingController();
    final correctAnswerController = TextEditingController();
    final List<String> options = [];
    final optionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Добавить вопрос'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: questionController,
                          decoration: const InputDecoration(
                            labelText: 'Вопрос',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: correctAnswerController,
                          decoration: const InputDecoration(
                            labelText: 'Правильный ответ',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionController,
                                decoration: const InputDecoration(
                                  labelText: 'Дополнительный вариант ответа',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (optionController.text.isNotEmpty) {
                                  setState(() {
                                    options.add(optionController.text);
                                    optionController.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (options.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Добавленные варианты:'),
                              const SizedBox(height: 5),
                              ...options.asMap().entries.map((entry) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${entry.key + 1}. ${entry.value}',
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          options.removeAt(entry.key);
                                        });
                                      },
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (questionController.text.isNotEmpty &&
                            correctAnswerController.text.isNotEmpty) {
                          setState(() {
                            _questions.add({
                              'question': questionController.text,
                              'correctAnswer': correctAnswerController.text,
                              'options': options,
                            });
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Добавить'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showAddPostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Добавить пост'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Заголовок'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Содержание'),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      contentController.text.isNotEmpty) {
                    setState(() {
                      _posts.add({
                        'title': titleController.text,
                        'content': contentController.text,
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Добавить'),
              ),
            ],
          ),
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _removePost(int index) {
    setState(() {
      _posts.removeAt(index);
    });
  }

  void _addCourse() async {
    if (_formKey.currentState!.validate()) {
      String title = _titleController.text;
      String description = _descriptionController.text;

      DatabaseHelper dbHelper = DatabaseHelper();

      // Добавляем курс
      int courseId = await dbHelper.insertCourse(
        title,
        description,
        widget.userId,
      );

      if (courseId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось добавить курс')),
        );
        return;
      }

      // Добавляем тесты
      for (var question in _questions) {
        int testResult = await dbHelper.insertTest(
          courseId,
          question['question'],
          question['correctAnswer'],
          options: question['options'].join(','),
        );

        if (testResult == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при добавлении вопроса')),
          );
          return;
        }
      }

      // Добавляем посты
      for (var post in _posts) {
        int postResult = await dbHelper.insertPost(
          courseId,
          widget.userId,
          post['title'],
          post['content'],
        );

        if (postResult == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при добавлении поста')),
          );
          return;
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Курс успешно добавлен')));
      Navigator.pop(context);
    }
  }
}
