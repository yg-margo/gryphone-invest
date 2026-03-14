import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/news_article.dart';
import 'api/api_config.dart';

class NewsService {
  static const Duration _timeout = Duration(seconds: 20);

  static const List<String> _endpointCandidates = [
    '/news',
    '/yahoo/news',
  ];

  static final Map<String, Future<List<NewsArticle>>> _inFlightByLang = {};

  static Future<List<NewsArticle>> fetchNews({
    required bool isRussian,
  }) {
    final langKey = isRussian ? 'ru' : 'en';
    final inFlight = _inFlightByLang[langKey];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _fetchNewsInternal(isRussian: isRussian);
    _inFlightByLang[langKey] = future;

    return future.whenComplete(() {
      final current = _inFlightByLang[langKey];
      if (identical(current, future)) {
        _inFlightByLang.remove(langKey);
      }
    });
  }

  static Future<List<NewsArticle>> _fetchNewsInternal({
    required bool isRussian,
  }) async {
    Exception? lastError;

    for (var i = 0; i < _endpointCandidates.length; i++) {
      final endpoint = _endpointCandidates[i];
      final isLastCandidate = i == _endpointCandidates.length - 1;

      final uri = ApiConfig.uri(endpoint, {'lang': isRussian ? 'ru' : 'en'});

      final http.Response res;
      try {
        res = await http.get(uri,
            headers: {'Accept': 'application/json'}).timeout(_timeout);
      } catch (e) {
        throw Exception('Network error: $e');
      }

      if (res.statusCode == 404 && !isLastCandidate) {
        lastError = Exception('News API HTTP 404');
        continue;
      }

      if (res.statusCode != 200) {
        throw Exception('News API HTTP ${res.statusCode}');
      }

      final Map<String, dynamic> body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Invalid JSON from news API');
      }

      if (body['ok'] != true) {
        throw Exception(body['error']?.toString() ?? 'News API returned error');
      }

      final articlesRaw = body['articles'] as List<dynamic>? ?? [];

      return articlesRaw
          .whereType<Map<String, dynamic>>()
          .map((json) {
            return NewsArticle(
              id: json['id'] as String? ?? '',
              title: json['title'] as String? ?? '',
              description: json['description'] as String? ?? '',
              url: json['url'] as String? ?? '',
              imageUrl: json['imageUrl'] as String?,
              source: json['source'] as String? ?? 'Yahoo Finance',
              publishedAt: _parseDate(json['publishedAt'] as String?),
            );
          })
          .where((a) => a.title.isNotEmpty && a.url.isNotEmpty)
          .toList();
    }

    throw lastError ?? Exception('News endpoint is unavailable');
  }

  static DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.now();
    }
  }
}
