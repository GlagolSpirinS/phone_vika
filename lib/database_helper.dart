import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'main.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    print("Database path: $path"); // Логирование пути к базе данных
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      readOnly: false, // Явно указываем, что база данных не только для чтения
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Создание таблицы Users
    await db.execute('''
      CREATE TABLE Users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Создание таблицы Courses
    await db.execute('''
      CREATE TABLE Courses (
        course_id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        creator_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_archived BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (creator_id) REFERENCES Users(user_id)
      )
    ''');

    // Создание таблицы CourseMaterials
    await db.execute('''
      CREATE TABLE CourseMaterials (
        material_id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        content_type TEXT NOT NULL,
        content BLOB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (course_id) REFERENCES Courses(course_id)
      )
    ''');

    // Создание таблицы Tests
    await db.execute('''
      CREATE TABLE Tests (
        test_id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        question TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        options TEXT,
        FOREIGN KEY (course_id) REFERENCES Courses(course_id)
      )
    ''');

    // Создание таблицы TestResults
    await db.execute('''
      CREATE TABLE TestResults (
        result_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        test_id INTEGER,
        score INTEGER,
        completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users(user_id),
        FOREIGN KEY (test_id) REFERENCES Tests(test_id)
      )
    ''');

    // Создание таблицы Achievements
    await db.execute('''
      CREATE TABLE Achievements (
        achievement_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        course_id INTEGER,
        points INTEGER,
        achieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users(user_id),
        FOREIGN KEY (course_id) REFERENCES Courses(course_id)
      )
    ''');

    // Создание таблицы Comments
    await db.execute('''
      CREATE TABLE Comments (
        comment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        course_id INTEGER,
        comment_text TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users(user_id),
        FOREIGN KEY (course_id) REFERENCES Courses(course_id)
      )
    ''');

    // Создание таблицы Reviews
    await db.execute('''
      CREATE TABLE Reviews (
        review_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        course_id INTEGER,
        rating INTEGER,
        review_text TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users(user_id),
        FOREIGN KEY (course_id) REFERENCES Courses(course_id)
      )
    ''');

    // Создание таблицы Favorites
    await db.execute('''
      CREATE TABLE Favorites (
        favorite_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        course_id INTEGER,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users(user_id),
        FOREIGN KEY (course_id) REFERENCES Courses(course_id)
      )
    ''');

    // Создание таблицы Wishlist
    await db.execute('''
      CREATE TABLE Wishlist (
        wishlist_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        course_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES Users(user_id),
        FOREIGN KEY (course_id) REFERENCES Courses(course_id)
      )
    ''');

    // Создание таблицы Posts
    await db.execute('''
      CREATE TABLE Posts (
        post_id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        user_id INTEGER,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (course_id) REFERENCES Courses(course_id),
        FOREIGN KEY (user_id) REFERENCES Users(user_id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Создаем таблицу Posts, если её нет
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Posts (
          post_id INTEGER PRIMARY KEY AUTOINCREMENT,
          course_id INTEGER,
          user_id INTEGER,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (course_id) REFERENCES Courses(course_id),
          FOREIGN KEY (user_id) REFERENCES Users(user_id)
        )
      ''');
    }
  }

  // Методы для работы с таблицей Users
  Future<int> insertUser(
    String email,
    String password,
    String role, {
    String? firstName,
    String? lastName,
  }) async {
    Database db = await database;
    String passwordHash = hashPassword(password);
    return await db.insert('Users', {
      'email': email,
      'password_hash': passwordHash,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
    });
  }

  Future<int> updateUser(
    int userId,
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final db = await database;
    return await db.update(
      'Users',
      {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password_hash': password,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getCommentsWithUserNameByCourseId(
    int courseId,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
    SELECT Comments.*, Users.first_name 
    FROM Comments 
    INNER JOIN Users ON Comments.user_id = Users.user_id 
    WHERE Comments.course_id = ?
    ORDER BY Comments.created_at DESC
  ''',
      [courseId],
    );
    return result;
  }

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'Users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'Users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Методы для работы с таблицей Courses
  Future<int> insertCourse(
    String title,
    String description,
    int creatorId, {
    bool isArchived = false,
  }) async {
    Database db = await database;
    return await db.insert('Courses', {
      'title': title,
      'description': description,
      'creator_id': creatorId,
      'is_archived': isArchived ? 1 : 0,
    });
  }

  Future<List<Map<String, dynamic>>> getAllCourses() async {
    Database db = await database;
    return await db.query('Courses');
  }

  Future<Map<String, dynamic>?> getCourseById(int courseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Courses', // Исправлено на 'Courses'
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<int> updateCourse(
    int courseId,
    String title,
    String description, {
    bool? isArchived,
  }) async {
    Database db = await database;
    return await db.update(
      'Courses',
      {
        'title': title,
        'description': description,
        if (isArchived != null) 'is_archived': isArchived ? 1 : 0,
      },
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  Future<int> deleteCourse(int courseId) async {
    Database db = await database;
    try {
      await db.transaction((txn) async {
        // Сначала удаляем связанные записи
        await txn.delete(
          'TestResults',
          where: 'test_id IN (SELECT test_id FROM Tests WHERE course_id = ?)',
          whereArgs: [courseId],
        );

        await txn.delete(
          'Tests',
          where: 'course_id = ?',
          whereArgs: [courseId],
        );

        await txn.delete(
          'CourseMaterials',
          where: 'course_id = ?',
          whereArgs: [courseId],
        );

        await txn.delete(
          'Posts',
          where: 'course_id = ?',
          whereArgs: [courseId],
        );

        await txn.delete(
          'Favorites',
          where: 'course_id = ?',
          whereArgs: [courseId],
        );

        await txn.delete(
          'Wishlist',
          where: 'course_id = ?',
          whereArgs: [courseId],
        );

        // Теперь удаляем сам курс
        await txn.delete(
          'Courses',
          where: 'course_id = ?',
          whereArgs: [courseId],
        );
      });
      return 1;
    } catch (e) {
      print('Error deleting course: $e');
      rethrow;
    }
  }

  // Методы для работы с таблицей CourseMaterials
  Future<int> insertCourseMaterial(
    int courseId,
    String contentType,
    List<int> content,
  ) async {
    Database db = await database;
    return await db.insert('CourseMaterials', {
      'course_id': courseId,
      'content_type': contentType,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> getMaterialsByCourseId(
    int courseId,
  ) async {
    Database db = await database;
    return await db.query(
      'CourseMaterials',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  Future<int> deleteCourseMaterial(int materialId) async {
    Database db = await database;
    return await db.delete(
      'CourseMaterials',
      where: 'material_id = ?',
      whereArgs: [materialId],
    );
  }

  // Методы для работы с таблицей Tests
  Future<int> insertTest(
    int courseId,
    String question,
    String correctAnswer, {
    String? options,
  }) async {
    Database db = await database;
    return await db.insert('Tests', {
      'course_id': courseId,
      'question': question,
      'correct_answer': correctAnswer,
      'options': options,
    });
  }

  Future<List<Map<String, dynamic>>> getTestsByCourseId(int courseId) async {
    Database db = await database;
    return await db.query(
      'Tests',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  Future<int> deleteTest(int testId) async {
    Database db = await database;
    try {
      await db.transaction((txn) async {
        // Сначала удаляем связанные записи результатов теста
        await txn.delete(
          'TestResults',
          where: 'test_id = ?',
          whereArgs: [testId],
        );

        // Теперь удаляем сам тест
        await txn.delete('Tests', where: 'test_id = ?', whereArgs: [testId]);
      });
      return 1;
    } catch (e) {
      print('Error deleting test: $e');
      rethrow;
    }
  }

  // Методы для работы с таблицей TestResults
  Future<int> insertTestResult(int userId, int testId, int score) async {
    Database db = await database;
    return await db.insert('TestResults', {
      'user_id': userId,
      'test_id': testId,
      'score': score,
    });
  }

  Future<List<Map<String, dynamic>>> getTestResultsByUserId(int userId) async {
    Database db = await database;
    return await db.query(
      'TestResults',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Методы для работы с таблицей Achievements
  Future<int> insertAchievement(int userId, int courseId, int points) async {
    Database db = await database;
    return await db.insert('Achievements', {
      'user_id': userId,
      'course_id': courseId,
      'points': points,
    });
  }

  Future<List<Map<String, dynamic>>> getAchievementsByUserId(int userId) async {
    Database db = await database;
    return await db.query(
      'Achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Методы для работы с таблицей Comments
  Future<int> insertComment(
    int userId,
    int courseId,
    String commentText,
  ) async {
    Database db = await database;
    return await db.insert('Comments', {
      'user_id': userId,
      'course_id': courseId,
      'comment_text': commentText,
    });
  }

  Future<List<Map<String, dynamic>>> getCommentsByCourseId(int courseId) async {
    Database db = await database;
    return await db.query(
      'Comments',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  // Метод для обновления комментария
  Future<int> updateComment(int commentId, String commentText) async {
    Database db = await database;
    return await db.update(
      'Comments',
      {'comment_text': commentText},
      where: 'comment_id = ?',
      whereArgs: [commentId],
    );
  }

  // Метод для удаления комментария
  Future<int> deleteComment(int commentId) async {
    Database db = await database;
    return await db.delete(
      'Comments',
      where: 'comment_id = ?',
      whereArgs: [commentId],
    );
  }

  // Методы для работы с таблицей Reviews
  Future<int> insertReview(
    int userId,
    int courseId,
    int rating, {
    String? reviewText,
  }) async {
    Database db = await database;
    return await db.insert('Reviews', {
      'user_id': userId,
      'course_id': courseId,
      'rating': rating,
      'review_text': reviewText,
    });
  }

  Future<List<Map<String, dynamic>>> getReviewsByCourseId(int courseId) async {
    Database db = await database;
    return await db.query(
      'Reviews',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  // Методы для работы с таблицей Favorites
  Future<int> insertFavorite(int userId, int courseId) async {
    Database db = await database;
    return await db.insert('Favorites', {
      'user_id': userId,
      'course_id': courseId,
    });
  }

  Future<List<Map<String, dynamic>>> getFavoritesByUserId(int userId) async {
    Database db = await database;
    return await db.query(
      'Favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteFavorite(int favoriteId) async {
    Database db = await database;
    return await db.delete(
      'Favorites',
      where: 'favorite_id = ?',
      whereArgs: [favoriteId],
    );
  }

  // Методы для работы с таблицей Wishlist
  Future<int> insertWishlist(int userId, int courseId) async {
    Database db = await database;
    return await db.insert('Wishlist', {
      'user_id': userId,
      'course_id': courseId,
    });
  }

  Future<List<Map<String, dynamic>>> getWishlistByUserId(int userId) async {
    Database db = await database;
    return await db.query(
      'Wishlist',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteWishlist(int wishlistId) async {
    Database db = await database;
    return await db.delete(
      'Wishlist',
      where: 'wishlist_id = ?',
      whereArgs: [wishlistId],
    );
  }

  Future<String?> getUserRole(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return maps.first['role'] as String?;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    final db = await database;
    List<Map<String, dynamic>> courses = await db.query('Courses');
    print("Courses fetched: $courses");
    return courses;
  }

  // Методы для работы с таблицей Posts
  Future<int> insertPost(
    int courseId,
    int userId,
    String title,
    String content,
  ) async {
    Database db = await database;
    return await db.insert('Posts', {
      'course_id': courseId,
      'user_id': userId,
      'title': title,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> getPostsByCourseId(int courseId) async {
    Database db = await database;
    return await db.rawQuery(
      '''
      SELECT Posts.*, Users.first_name, Users.last_name 
      FROM Posts 
      INNER JOIN Users ON Posts.user_id = Users.user_id 
      WHERE Posts.course_id = ? 
      ORDER BY Posts.created_at DESC
    ''',
      [courseId],
    );
  }

  Future<int> deletePost(int postId) async {
    Database db = await database;
    return await db.delete('Posts', where: 'post_id = ?', whereArgs: [postId]);
  }

  // Метод для обновления поста
  Future<int> updatePost(int postId, String title, String content) async {
    Database db = await database;
    return await db.update(
      'Posts',
      {'title': title, 'content': content},
      where: 'post_id = ?',
      whereArgs: [postId],
    );
  }

  // Метод для подсчета прогресса курса
  Future<double> getCourseProgress(int courseId, int userId) async {
    final db = await database;

    // Получаем общее количество тестов в курсе
    final List<Map<String, dynamic>> tests = await db.query(
      'Tests',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );

    if (tests.isEmpty) return 0.0;

    // Получаем количество пройденных тестов
    final List<Map<String, dynamic>> completedTests = await db.rawQuery(
      '''
      SELECT COUNT(*) as completed
      FROM TestResults tr
      INNER JOIN Tests t ON tr.test_id = t.test_id
      WHERE t.course_id = ? AND tr.user_id = ?
    ''',
      [courseId, userId],
    );

    final int totalTests = tests.length;
    final int completedCount = completedTests.first['completed'] as int;

    return totalTests > 0 ? completedCount / totalTests : 0.0;
  }
  
}
