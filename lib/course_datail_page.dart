import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class CourseDetailPage extends StatefulWidget {
  final int courseId;
  final int userId;

  const CourseDetailPage({
    super.key,
    required this.courseId,
    required this.userId,
  });

  @override
  _CourseDetailPageState createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _posts = [];
  Map<int, String?> _userAnswers = {};
  Map<int, List<String>> _shuffledOptions = {};
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _pastResults = [];
  final TextEditingController _commentController = TextEditingController();
  late TabController _tabController;
  String? _userRole;
  Map<String, dynamic>? _courseInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTests();
    _loadPosts();
    _loadComments();
    _loadPastResults();
    _loadUserRole();
    _loadCourseInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    String? role = await dbHelper.getUserRole(widget.userId);
    setState(() {
      _userRole = role;
    });
  }

  // Метод для загрузки тестов
  Future<void> _loadTests() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> tests = await dbHelper.getTestsByCourseId(
      widget.courseId,
    );
    setState(() {
      _tests = tests;
    });
  }

  // Метод для загрузки постов
  Future<void> _loadPosts() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> posts = await dbHelper.getPostsByCourseId(
      widget.courseId,
    );
    setState(() {
      _posts = posts;
    });
  }

  // Метод для загрузки комментариев
  Future<void> _loadComments() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> comments = await dbHelper
        .getCommentsWithUserNameByCourseId(widget.courseId);
    setState(() {
      _comments = comments;
    });
  }

  // Метод для загрузки прошлых результатов
  Future<void> _loadPastResults() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> results = await dbHelper.getTestResultsByUserId(
      widget.userId,
    );
    setState(() {
      _pastResults = results;
    });
  }

  // Метод для загрузки информации о курсе
  Future<void> _loadCourseInfo() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    Map<String, dynamic>? courseInfo = await dbHelper.getCourseById(
      widget.courseId,
    );
    setState(() {
      _courseInfo = courseInfo;
    });
  }

  // Метод для проверки, является ли пользователь создателем курса
  bool _isCourseCreator() {
    return _courseInfo != null && _courseInfo!['creator_id'] == widget.userId;
  }

  // Метод для проверки, был ли тест уже пройден
  bool _isTestAlreadyCompleted(int testId) {
    return _pastResults.any((result) => result['test_id'] == testId);
  }

  // Метод для получения результата теста
  Map<String, dynamic>? _getTestResult(int testId) {
    return _pastResults.firstWhere(
      (result) => result['test_id'] == testId,
      orElse: () => {},
    );
  }

  // Метод для добавления комментария
  Future<void> _addComment() async {
    if (_commentController.text.isNotEmpty) {
      DatabaseHelper dbHelper = DatabaseHelper();
      await dbHelper.insertComment(
        widget.userId,
        widget.courseId,
        _commentController.text,
      );
      _commentController.clear();
      await _loadComments(); // Обновляем список комментариев
    }
  }

  // Метод для подсчета баллов
  int _calculateScore() {
    int score = 0;
    for (var test in _tests) {
      if (_userAnswers[test['test_id']] == test['correct_answer']) {
        score++;
      }
    }
    return score;
  }

  // Метод для удаления теста
  Future<void> _deleteTest(int testId) async {
    try {
      DatabaseHelper dbHelper = DatabaseHelper();
      await dbHelper.deleteTest(testId);
      await _loadTests();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Вопрос успешно удален')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении вопроса: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // Метод для создания карточки теста
  Widget _buildTestCard(Map<String, dynamic> test, int index) {
    bool isCompleted = _isTestAlreadyCompleted(test['test_id']);
    Map<String, dynamic>? pastResult =
        isCompleted ? _getTestResult(test['test_id']) : null;

    // Получаем список всех вариантов ответов
    List<String> options =
        (test['options'] as String).split(',').map((e) => e.trim()).toList();

    // Добавляем правильный ответ в список и перемешиваем только если еще не перемешаны
    if (!_shuffledOptions.containsKey(test['test_id'])) {
      // Проверяем, нет ли уже правильного ответа в списке
      if (!options.contains(test['correct_answer'])) {
        options.add(test['correct_answer']);
      }
      options.shuffle();
      _shuffledOptions[test['test_id']] = options;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Вопрос ${index + 1}: ${test['question']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isCourseCreator())
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirm = await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Подтверждение удаления'),
                              content: const Text(
                                'Вы уверены, что хотите удалить этот вопрос?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Удалить',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await _deleteTest(test['test_id']);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (isCompleted)
              Text(
                'Ваш ответ: ${pastResult?['score'] == 1 ? 'Правильно' : 'Неправильно'}',
                style: TextStyle(
                  color: pastResult?['score'] == 1 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (!isCompleted)
              ..._shuffledOptions[test['test_id']]!.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _userAnswers[test['test_id']],
                  onChanged: (String? value) {
                    setState(() {
                      _userAnswers[test['test_id']] = value;
                    });
                  },
                );
              }).toList(),
            if (!isCompleted && _userAnswers[test['test_id']] != null)
              ElevatedButton(
                onPressed: () => _submitQuestion(test),
                child: const Text('Отправить ответ'),
              ),
          ],
        ),
      ),
    );
  }

  // Метод для создания карточки комментария
Widget _buildCommentCard(
    Map<String, dynamic> comment,
    StateSetter setModalState,
  ) {
    bool isCommentOwner = comment['user_id'] == widget.userId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Пользователь: ${comment['first_name']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCommentOwner || _userRole == 'admin')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCommentOwner)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditCommentDialog(comment, setModalState),
                        ),
                      if (isCommentOwner ||_userRole == 'admin')
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () async {
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Подтверждение'),
                                content: const Text(
                                  'Вы уверены, что хотите удалить этот комментарий?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Удалить',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              DatabaseHelper dbHelper = DatabaseHelper();
                              await dbHelper.deleteComment(comment['comment_id']);
                              // Обновляем список комментариев
                              List<Map<String, dynamic>> updatedComments =
                                  await dbHelper.getCommentsWithUserNameByCourseId(
                                      widget.courseId,
                                  );
                              setModalState(() {
                                _comments = updatedComments;
                              });
                            }
                          },
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(comment['comment_text'], style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 5),
            Text(
              'Дата: ${comment['created_at']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  // Метод для отправки отдельного вопроса
  void _submitQuestion(Map<String, dynamic> test) async {
    if (_userAnswers[test['test_id']] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите ответ')),
      );
      return;
    }

    DatabaseHelper dbHelper = DatabaseHelper();

    try {
      await dbHelper.insertTestResult(
        widget.userId,
        test['test_id'],
        _userAnswers[test['test_id']] == test['correct_answer'] ? 1 : 0,
      );

      await _loadPastResults(); // Обновляем список результатов

      // Получаем обновленный прогресс курса
      double updatedProgress = await dbHelper.getCourseProgress(
        widget.courseId,
        widget.userId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _userAnswers[test['test_id']] == test['correct_answer']
                ? 'Правильно!'
                : 'Неправильно. Правильный ответ: ${test['correct_answer']}',
          ),
        ),
      );

      // Обновляем состояние, чтобы показать результат
      setState(() {
        _loadPastResults();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении результата: $e')),
      );
    }
  }

  // Метод для отображения модального окна с комментариями
  void _showCommentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Комментарии',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentCard(
                          _comments[index],
                          setModalState,
                        );
                      },
                    ),
                  ),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Добавить комментарий',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (_commentController.text.isNotEmpty) {
                        DatabaseHelper dbHelper = DatabaseHelper();
                        await dbHelper.insertComment(
                          widget.userId,
                          widget.courseId,
                          _commentController.text,
                        );
                        _commentController.clear();
                        // Обновляем список комментариев
                        List<Map<String, dynamic>> updatedComments =
                            await dbHelper.getCommentsWithUserNameByCourseId(
                              widget.courseId,
                            );
                        setModalState(() {
                          _comments = updatedComments;
                        });
                      }
                    },
                    child: const Text('Добавить комментарий'),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Метод для создания нового поста
  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать новый пост'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Заголовок'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Содержание'),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  DatabaseHelper dbHelper = DatabaseHelper();
                  await dbHelper.insertPost(
                    widget.courseId,
                    widget.userId,
                    titleController.text,
                    contentController.text,
                  );
                  Navigator.pop(context);
                  await _loadPosts();
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  // Виджет для отображения карточки поста
  Widget _buildPostCard(Map<String, dynamic> post) {
    bool isPostOwner = post['user_id'] == widget.userId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    post['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPostOwner)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditPostDialog(post),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeletePostDialog(post),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post['content'], style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Автор: ${post['first_name']} ${post['last_name']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Дата: ${post['created_at']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Метод для отображения диалога редактирования поста
  void _showEditPostDialog(Map<String, dynamic> post) {
    final titleController = TextEditingController(text: post['title']);
    final contentController = TextEditingController(text: post['content']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать пост'),
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
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  DatabaseHelper dbHelper = DatabaseHelper();
                  await dbHelper.updatePost(
                    post['post_id'],
                    titleController.text,
                    contentController.text,
                  );
                  Navigator.pop(context);
                  await _loadPosts(); // Обновляем список постов
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  // Метод для отображения диалога удаления поста
  void _showDeletePostDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Подтверждение'),
          content: const Text('Вы уверены, что хотите удалить этот пост?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                DatabaseHelper dbHelper = DatabaseHelper();
                await dbHelper.deletePost(post['post_id']);
                Navigator.pop(context);
                await _loadPosts(); // Обновляем список постов
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Метод для показа диалога добавления нового теста
  void _showAddTestDialog() {
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
                  title: const Text('Добавить новый тест'),
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
                      onPressed: () async {
                        if (questionController.text.isNotEmpty &&
                            correctAnswerController.text.isNotEmpty) {
                          DatabaseHelper dbHelper = DatabaseHelper();

                          // Собираем все варианты ответов
                          String allOptions = options.join(',');

                          await dbHelper.insertTest(
                            widget.courseId,
                            questionController.text,
                            correctAnswerController.text,
                            options: allOptions,
                          );
                          Navigator.pop(context);
                          // Обновляем список тестов
                          await _loadTests();
                          setState(() {}); // Обновляем состояние виджета
                        }
                      },
                      child: const Text('Добавить'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Метод для отображения диалога редактирования комментария
  void _showEditCommentDialog(
    Map<String, dynamic> comment,
    StateSetter setModalState,
  ) {
    final editController = TextEditingController(text: comment['comment_text']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать комментарий'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              labelText: 'Текст комментария',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (editController.text.isNotEmpty) {
                  DatabaseHelper dbHelper = DatabaseHelper();
                  await dbHelper.updateComment(
                    comment['comment_id'],
                    editController.text,
                  );
                  Navigator.pop(context);
                  // Обновляем список комментариев
                  List<Map<String, dynamic>> updatedComments = await dbHelper
                      .getCommentsWithUserNameByCourseId(widget.courseId);
                  setModalState(() {
                    _comments = updatedComments;
                  });
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали курса'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Тесты'), Tab(text: 'Посты')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка с тестами
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _tests.length,
                    itemBuilder: (context, index) {
                      return _buildTestCard(_tests[index], index);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (_isCourseCreator())
                  ElevatedButton(
                    onPressed: _showAddTestDialog,
                    child: const Text('Добавить новый тест'),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _showCommentsModal,
                  child: const Text('Показать комментарии'),
                ),
              ],
            ),
          ),
          // Вкладка с постами
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_isCourseCreator())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton(
                      onPressed: _showCreatePostDialog,
                      child: const Text('Создать новый пост'),
                    ),
                  ),
                Expanded(
                  child:
                      _posts.isEmpty
                          ? const Center(
                            child: Text(
                              'Тут пока нет постов',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: _posts.length,
                            itemBuilder: (context, index) {
                              return _buildPostCard(_posts[index]);
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
