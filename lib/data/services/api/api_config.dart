class ApiConfig {
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _normalize(_envApiBaseUrl);
    }
    return _normalize('http://localhost:3000/api/v1');
  }

  static Uri uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(apiBaseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
    return base.replace(
      path: '$basePath$normalizedPath',
      queryParameters:
          query?.map((key, value) => MapEntry(key, value?.toString())),
    );
  }

  static String _normalize(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
