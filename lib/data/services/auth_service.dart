import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api/api_config.dart';

class AuthService {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<AuthResponse> login({
    required String login,
    required String password,
  }) async {
    return _post(
      path: '/auth/login',
      body: {
        'login': login,
        'password': password,
      },
    );
  }

  static Future<AuthResponse> register({
    required String name,
    required String surname,
    required String login,
    required String email,
    required String password,
  }) async {
    return _post(
      path: '/auth/register',
      body: {
        'name': name,
        'surname': surname,
        'login': login,
        'email': email,
        'password': password,
      },
    );
  }

  static Future<AuthResponse> forgotPassword({
    required String email,
  }) async {
    return _post(
      path: '/auth/forgot-password',
      body: {'email': email},
    );
  }

  static Future<AuthResponse> resetPassword({
    required String token,
    required String password,
  }) async {
    return _post(
      path: '/auth/reset-password',
      body: {
        'token': token,
        'password': password,
      },
    );
  }

  static Future<AuthResponse> _post({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    try {
      final res = await http
          .post(
            ApiConfig.uri(path),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _handle(res);
    } catch (_) {
      return const AuthResponse.error('network');
    }
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static AuthResponse _handle(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return AuthResponse.success(body);
      }

      final message = body['message'] as String? ??
          body['error'] as String? ??
          'Server error ${res.statusCode}';
      return AuthResponse.error(message);
    } catch (_) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return const AuthResponse.success(<String, dynamic>{});
      }
      return AuthResponse.error('Server error ${res.statusCode}');
    }
  }
}

class AuthResponse {
  final bool ok;
  final Map<String, dynamic>? data;
  final String? error;

  const AuthResponse._({required this.ok, this.data, this.error});

  const AuthResponse.success(Map<String, dynamic> data)
      : this._(ok: true, data: data);

  const AuthResponse.error(String message) : this._(ok: false, error: message);

  String? get token => data?['token'] as String?;
}
