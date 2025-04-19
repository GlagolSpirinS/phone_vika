import 'package:flutter/material.dart';
import 'add_new_course.dart';
import 'course_datail_page.dart';
// import 'profile_page.dart';
import 'database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await createAdminUser();
  bool isLoggedIn = await AuthService.isLoggedIn();
  int userId = await AuthService.getUserId();
  runApp(MyApp(isLoggedIn: isLoggedIn, userId: userId));
}

Future<void> createAdminUser() async {
  DatabaseHelper dbHelper = DatabaseHelper();
  Map<String, dynamic>? adminUser = await dbHelper.getUserByEmail(
    'admin@example.com',
  );

  if (adminUser == null) {
    await dbHelper.insertUser(
      'admin@example.com',
      'admin123',
      'admin',
      firstName: 'Admin',
      lastName: 'User',
    );
  }
}

String hashPassword(String password) {
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

class AuthService {
  static const String _keyLoggedIn = 'loggedIn';
  static const String _keyUserId = 'userId';

  static Future<void> setLoggedIn(bool value, int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, value);
    await prefs.setInt(_keyUserId, userId);
  }

  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<int> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId) ??
        -1; // Возвращаем -1, если userId не найден
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int userId;

  const MyApp({super.key, required this.isLoggedIn, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Курсы',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: isLoggedIn ? MainScreen(userId: userId) : const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите пароль';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    child: const Text('Войти'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text('Нет аккаунта? Зарегистрироваться'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;

      DatabaseHelper dbHelper = DatabaseHelper();
      Map<String, dynamic>? user = await dbHelper.getUserByEmail(email);

      if (user != null && user['password_hash'] == hashPassword(password)) {
        await AuthService.setLoggedIn(true, user['user_id']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(userId: user['user_id']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный email или пароль')),
        );
      }
    }
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен содержать минимум 6 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Подтвердите пароль',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, подтвердите пароль';
                    }
                    if (value != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _register,
                    child: const Text('Зарегистрироваться'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;

      DatabaseHelper dbHelper = DatabaseHelper();
      int result = await dbHelper.insertUser(
        email,
        password,
        'user', // Роль по умолчанию
      );

      if (result != 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Регистрация успешна')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка регистрации')));
      }
    }
  }
}

class HomePage extends StatefulWidget {
  final int userId;

  const HomePage({super.key, required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userRole;
  List<Map<String, dynamic>> courses = [];
  final Map<int, bool> _favoriteStatus = {};
  final Map<int, double> _courseProgress = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchUserRole();
    await _fetchCourses();
    await _loadFavorites();
    await _loadCourseProgress();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchUserRole() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    String? role = await dbHelper.getUserRole(widget.userId);
    setState(() {
      userRole = role;
    });
  }

  Future<void> _fetchCourses() async {
    try {
      DatabaseHelper dbHelper = DatabaseHelper();
      List<Map<String, dynamic>> courseList = await dbHelper.getCourses();
      setState(() {
        courses = courseList;
      });
    } catch (e) {
      print("Error fetching courses: $e");
    }
  }

  Future<void> _loadFavorites() async {
    if (widget.userId == -1) return;

    final dbHelper = DatabaseHelper();
    final favorites = await dbHelper.getFavoritesByUserId(widget.userId);

    setState(() {
      for (final course in courses) {
        _favoriteStatus[course['course_id']] = favorites.any(
          (fav) => fav['course_id'] == course['course_id'],
        );
      }
    });
  }

  Future<void> _loadCourseProgress() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    for (var course in courses) {
      double progress = await dbHelper.getCourseProgress(
        course['course_id'],
        widget.userId,
      );
      setState(() {
        _courseProgress[course['course_id']] = progress;
      });
    }
  }

  Future<void> _toggleFavorite(int courseId) async {
    final dbHelper = DatabaseHelper();
    final isFavorite = _favoriteStatus[courseId] ?? false;

    try {
      if (isFavorite) {
        final favorites = await dbHelper.getFavoritesByUserId(widget.userId);
        final favorite = favorites.firstWhere(
          (fav) => fav['course_id'] == courseId,
          orElse: () => {},
        );
        if (favorite.isNotEmpty) {
          await dbHelper.deleteFavorite(favorite['favorite_id']);
        }
      } else {
        await dbHelper.insertFavorite(widget.userId, courseId);
      }

      setState(() {
        _favoriteStatus[courseId] = !isFavorite;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _logout() async {
    await AuthService.setLoggedIn(false, -1);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _deleteCourse(int courseId) async {
    final dbHelper = DatabaseHelper();
    try {
      await dbHelper.deleteCourse(courseId);
      await _fetchCourses();
      await _loadFavorites();
      await _loadCourseProgress();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Курс успешно удален')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении курса: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter courses based on the search query
    final filteredCourses =
        courses.where((course) {
          return course['title'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Курсы'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (userRole == 'admin' || userRole == 'manager')
            IconButton(
              icon: const Icon(Icons.add_card),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCoursePage(userId: widget.userId),
                  ),
                );
                await _fetchCourses();
                await _loadCourseProgress();
              },
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Поиск курсов',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredCourses.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет доступных курсов',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                        final isFavorite =
                            _favoriteStatus[course['course_id']] ?? false;
                        final progress =
                            _courseProgress[course['course_id']] ?? 0.0;

                        return Dismissible(
                          key: Key(course['course_id'].toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Подтверждение удаления'),
                                    content: const Text(
                                      'Вы уверены, что хотите удалить этот курс?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Отмена'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text(
                                          'Удалить',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          onDismissed: (direction) {
                            _deleteCourse(course['course_id']);
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () async {
                                final updatedProgress = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CourseDetailPage(
                                          courseId: course['course_id'],
                                          userId: widget.userId,
                                        ),
                                  ),
                                );

                                if (updatedProgress != null) {
                                  setState(() {
                                    _courseProgress[course['course_id']] =
                                        updatedProgress;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            course['title'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isFavorite
                                                ? Icons.star
                                                : Icons.star_outline,
                                            color:
                                                isFavorite
                                                    ? Colors.amber
                                                    : Colors.grey,
                                          ),
                                          onPressed:
                                              () => _toggleFavorite(
                                                course['course_id'],
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      course['description'],
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.grey[200],
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    progress >= 1.0
                                                        ? Colors.green
                                                        : Colors.blue,
                                                  ),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${(progress * 100).toInt()}%',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
