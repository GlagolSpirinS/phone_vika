import 'package:flutter/material.dart';
import 'database_helper.dart';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // Контроллер для имени
  final _surnameController = TextEditingController(); // Контроллер для фамилии
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEditing = false;
  String _maskedPassword = ''; // Переменная для отображения пароля звёздочками
  String _realPassword = ''; // Переменная для хранения реального пароля

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    Map<String, dynamic>? user = await dbHelper.getUserById(widget.userId);

    if (user != null) {
      setState(() {
        _nameController.text = user['first_name'] ?? '';
        _surnameController.text = user['last_name'] ?? '';
        _emailController.text = user['email'] ?? '';
        _realPassword = user['password_hash'] ?? '';
        _maskedPassword = '*' * _realPassword.length;
        _passwordController.text = _maskedPassword;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isEditing)
                TextFormField(
                  controller: TextEditingController(text: '${_nameController.text} ${_surnameController.text}'),
                  decoration: const InputDecoration(
                    labelText: 'Полное имя',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: false,
                ),
              if (_isEditing) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите ваше имя';
                    }
                    if (value.length < 2) {
                      return 'Имя должно содержать минимум 2 символа';
                    }
                    if (value.length > 50) {
                      return 'Имя не должно превышать 50 символов';
                    }
                    if (!RegExp(r'^[А-Яа-яЁё\s]+$').hasMatch(value)) {
                      return 'Имя должно содержать только буквы';
                    }
                    if (!value[0].toUpperCase().contains(value[0])) {
                      return 'Имя должно начинаться с заглавной буквы';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _surnameController,
                  decoration: const InputDecoration(
                    labelText: 'Фамилия',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите вашу фамилию';
                    }
                    if (value.length < 2) {
                      return 'Фамилия должна содержать минимум 2 символа';
                    }
                    if (value.length > 50) {
                      return 'Фамилия не должна превышать 50 символов';
                    }
                    if (!RegExp(r'^[А-Яа-яЁё\s]+$').hasMatch(value)) {
                      return 'Фамилия должна содержать только буквы';
                    }
                    if (!value[0].toUpperCase().contains(value[0])) {
                      return 'Фамилия должна начинаться с заглавной буквы';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите ваш email';
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
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите ваш пароль';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('Сохранить изменения'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    child: const Text('Изменить профиль'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      String surname = _surnameController.text;
      String email = _emailController.text;
      String password = _passwordController.text;

      // Если пароль не изменен, используем старый пароль
      if (password == _maskedPassword) {
        password = _realPassword;
      }

      DatabaseHelper dbHelper = DatabaseHelper();
      int result = await dbHelper.updateUser(
        widget.userId,
        name,
        surname,
        email,
        password,
      );

      if (result != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
        setState(() {
          _isEditing = false;
          _realPassword = password; // Обновляем реальный пароль
          _maskedPassword = '*' * _realPassword.length; // Обновляем маскированный пароль
          _passwordController.text = _maskedPassword; // Отображаем маскированный пароль
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось обновить профиль')),
        );
      }
    }
  }
}