import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  static const String _prefsTokenKey = 'auth_token';
  static const String _prefsNameKey = 'auth_name';
  static const String _prefsSurnameKey = 'auth_surname';
  static const String _prefsEmailKey = 'auth_email';
  static const String _prefsLoginKey = 'auth_login';
  static const String _prefsUserIdKey = 'auth_user_id';

  static const String defaultLogin = 'admin';

  bool _isAuthenticated = false;
  bool _isInitializing = true;
  AuthStatus _status = AuthStatus.idle;
  String? _error;
  String _name = '';
  String _surname = '';
  String _email = '';
  String _login = '';
  String _token = '';
  int? _userId;
  Uint8List? _avatarBytes;

  AuthProvider() {
    _restoreSession();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _status == AuthStatus.loading;
  AuthStatus get status => _status;
  String? get error => _error;
  String get name => _name;
  String get surname => _surname;
  String get email => _email;
  String get loginName => _login;
  String get token => _token;
  int? get userId => _userId;
  String get fullName => '$_name $_surname'.trim();
  Uint8List? get avatarBytes => _avatarBytes;

  String get initials {
    final n = _name.isNotEmpty ? _name[0].toUpperCase() : '';
    final s = _surname.isNotEmpty ? _surname[0].toUpperCase() : '';
    return '$n$s';
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_prefsTokenKey) ?? '';
      _name = prefs.getString(_prefsNameKey) ?? '';
      _surname = prefs.getString(_prefsSurnameKey) ?? '';
      _email = prefs.getString(_prefsEmailKey) ?? '';
      _login = prefs.getString(_prefsLoginKey) ?? '';
      _userId = prefs.getInt(_prefsUserIdKey);

      _isAuthenticated = _token.isNotEmpty;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTokenKey, _token);
    await prefs.setString(_prefsNameKey, _name);
    await prefs.setString(_prefsSurnameKey, _surname);
    await prefs.setString(_prefsEmailKey, _email);
    await prefs.setString(_prefsLoginKey, _login);
    if (_userId != null) {
      await prefs.setInt(_prefsUserIdKey, _userId!);
    } else {
      await prefs.remove(_prefsUserIdKey);
    }
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsNameKey);
    await prefs.remove(_prefsSurnameKey);
    await prefs.remove(_prefsEmailKey);
    await prefs.remove(_prefsLoginKey);
    await prefs.remove(_prefsUserIdKey);
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _error = msg;
    notifyListeners();
  }

  void _setSuccess() {
    _status = AuthStatus.success;
    _error = null;
    notifyListeners();
  }

  void _applyUser(Map<String, dynamic> user) {
    _name = user['name'] as String? ?? _name;
    _surname = user['surname'] as String? ?? _surname;
    _email = user['email'] as String? ?? _email;
    _login = user['login'] as String? ?? _login;
    _userId = user['id'] is num ? (user['id'] as num).toInt() : _userId;
  }

  Future<bool> login(String login, String password) async {
    _setLoading();

    final res = await AuthService.login(
      login: login.trim(),
      password: password,
    );

    if (!res.ok) {
      _setError(res.error ?? 'invalid');
      return false;
    }

    _token = res.token ?? '';
    _isAuthenticated = _token.isNotEmpty;

    final user = res.data?['user'] as Map<String, dynamic>? ?? {};
    _applyUser(user);

    await _persistSession();
    _setSuccess();
    return true;
  }

  Future<bool> register({
    required String name,
    required String surname,
    required String login,
    required String email,
    required String password,
  }) async {
    _setLoading();

    final res = await AuthService.register(
      name: name,
      surname: surname,
      login: login,
      email: email,
      password: password,
    );

    if (!res.ok) {
      _setError(res.error ?? 'register_error');
      return false;
    }

    _token = res.token ?? '';
    _isAuthenticated = _token.isNotEmpty;

    final user = res.data?['user'] as Map<String, dynamic>? ?? {};
    _applyUser(user);

    await _persistSession();
    _setSuccess();
    return true;
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading();

    final res = await AuthService.forgotPassword(email: email);
    if (!res.ok) {
      _setError(res.error ?? 'email_not_found');
      return false;
    }

    _setSuccess();
    return true;
  }

  void updateProfile({String? name, String? surname, String? email}) {
    if (name != null) _name = name;
    if (surname != null) _surname = surname;
    if (email != null) _email = email;

    _persistSession();
    notifyListeners();
  }

  void updateAvatar(Uint8List bytes) {
    _avatarBytes = bytes;
    notifyListeners();
  }

  void removeAvatar() {
    _avatarBytes = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = '';
    _name = '';
    _surname = '';
    _email = '';
    _login = '';
    _userId = null;
    _avatarBytes = null;
    _status = AuthStatus.idle;
    _error = null;

    await _clearPersistedSession();
    notifyListeners();
  }
}
