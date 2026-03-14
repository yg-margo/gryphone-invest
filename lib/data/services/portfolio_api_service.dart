import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api/api_config.dart';

class PortfolioApiService {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<PortfolioApiResponse> loadPortfolio({
    required String token,
  }) async {
    return _request(
      method: 'GET',
      path: '/portfolio',
      token: token,
    );
  }

  static Future<PortfolioApiResponse> savePortfolio({
    required String token,
    required double cash,
    required List<Map<String, dynamic>> positions,
  }) async {
    return _request(
      method: 'PUT',
      path: '/portfolio',
      token: token,
      body: {
        'cash': cash,
        'positions': positions,
      },
    );
  }

  static Future<PortfolioApiResponse> resetPortfolio({
    required String token,
  }) async {
    return _request(
      method: 'POST',
      path: '/portfolio/reset',
      token: token,
    );
  }

  static Future<PortfolioApiResponse> _request({
    required String method,
    required String path,
    required String token,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = ApiConfig.uri(path);
      http.Response response;

      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: _headers(token: token))
              .timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: _headers(token: token),
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await http
              .put(
                uri,
                headers: _headers(token: token),
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
          break;
        default:
          return const PortfolioApiResponse.error('Unsupported method');
      }

      return _handle(response);
    } catch (_) {
      return const PortfolioApiResponse.error('network');
    }
  }

  static Map<String, String> _headers({required String token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static PortfolioApiResponse _handle(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PortfolioApiResponse.success(data);
      }

      final message = data['message'] as String? ??
          data['error'] as String? ??
          'Server error ${response.statusCode}';
      return PortfolioApiResponse.error(message);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const PortfolioApiResponse.success(<String, dynamic>{});
      }
      return PortfolioApiResponse.error('Server error ${response.statusCode}');
    }
  }
}

class PortfolioApiResponse {
  final bool ok;
  final Map<String, dynamic>? data;
  final String? error;

  const PortfolioApiResponse._({required this.ok, this.data, this.error});

  const PortfolioApiResponse.success(Map<String, dynamic> data)
      : this._(ok: true, data: data);

  const PortfolioApiResponse.error(String error)
      : this._(ok: false, error: error);
}
