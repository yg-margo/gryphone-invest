import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/stock_detail.dart';
import 'api/api_config.dart';

class YahooFinanceService {
  static const Duration _timeout = Duration(seconds: 20);
  static const String _chartBase = 'query1.finance.yahoo.com';
  static const String _summaryBase = 'query2.finance.yahoo.com';

  static String _normalizeSymbol(String symbol) {
    return symbol.replaceAll('.', '-');
  }

  static Future<http.Response> _getChart({
    required String symbol,
    required String range,
    required String interval,
  }) {
    final yahooSymbol = _normalizeSymbol(symbol);

    if (kIsWeb) {
      final uri = ApiConfig.uri(
        '/yahoo/chart/$yahooSymbol',
        {
          'range': range,
          'interval': interval,
        },
      );
      return http.get(uri, headers: _webHeaders).timeout(_timeout);
    }

    final uri = Uri.https(
      _chartBase,
      '/v8/finance/chart/$yahooSymbol',
      {
        'range': range,
        'interval': interval,
        'includePrePost': 'false',
        'events': 'div,splits',
        'corsDomain': 'finance.yahoo.com',
      },
    );
    return http.get(uri, headers: _nativeHeaders).timeout(_timeout);
  }

  static Future<StockChartData> getChartData({
    required String symbol,
    required String range,
    required String interval,
  }) async {
    final res = await _getChart(
      symbol: symbol,
      range: range,
      interval: interval,
    );

    if (res.statusCode != 200) {
      throw Exception('Yahoo chart HTTP ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final chart = json['chart'] as Map<String, dynamic>?;
    if (chart == null) {
      throw Exception('Invalid Yahoo chart response');
    }

    final chartError = chart['error'];
    if (chartError != null) {
      if (chartError is Map<String, dynamic>) {
        throw Exception(chartError['description'] ?? 'Yahoo chart error');
      }
      throw Exception('Yahoo chart error');
    }

    final results = chart['result'] as List?;
    if (results == null || results.isEmpty) {
      throw Exception('No chart data for $symbol');
    }

    final result = results.first as Map<String, dynamic>;
    final meta = result['meta'] as Map<String, dynamic>? ?? {};

    final timestamps = (result['timestamp'] as List?)
            ?.map((e) => DateTime.fromMillisecondsSinceEpoch((e as int) * 1000))
            .toList() ??
        [];

    final indicators = result['indicators'] as Map<String, dynamic>? ?? {};
    final quoteList = indicators['quote'] as List?;
    if (quoteList == null || quoteList.isEmpty) {
      throw Exception('No indicator data for $symbol');
    }

    final closes = (quoteList.first as Map<String, dynamic>)['close'] as List?;
    if (closes == null || timestamps.isEmpty) {
      throw Exception('Empty price data for $symbol');
    }

    final points = <StockChartPoint>[];
    for (int i = 0; i < timestamps.length && i < closes.length; i++) {
      final price = closes[i];
      if (price != null) {
        points.add(
          StockChartPoint(
            timestamp: timestamps[i],
            price: (price as num).toDouble(),
          ),
        );
      }
    }

    if (points.isEmpty) {
      throw Exception('No valid chart points for $symbol');
    }

    final currentPrice =
        (meta['regularMarketPrice'] as num?)?.toDouble() ?? points.last.price;
    final previousClose = (meta['chartPreviousClose'] as num?)?.toDouble() ??
        (meta['previousClose'] as num?)?.toDouble() ??
        points.first.price;
    final currency = meta['currency'] as String? ?? 'USD';

    return StockChartData(
      symbol: symbol,
      points: points,
      currentPrice: currentPrice,
      previousClose: previousClose,
      currency: currency,
    );
  }

  static Future<List<double>> getHistoricalCloses({
    required String symbol,
    required String range,
    required String interval,
  }) async {
    final data = await getChartData(
      symbol: symbol,
      range: range,
      interval: interval,
    );
    return data.points.map((p) => p.price).toList();
  }

  static Future<CompanyInfo> getCompanyInfo(String symbol) async {
    final summaryInfo = await _getCompanyInfoFromSummary(symbol);
    if (!_isPlaceholderCompanyInfo(summaryInfo, symbol)) {
      return summaryInfo;
    }

    return _getCompanyInfoFromQuote(symbol);
  }

  static Future<CompanyInfo> _getCompanyInfoFromQuote(String symbol) async {
    final yahooSymbol = _normalizeSymbol(symbol);

    http.Response res;
    if (kIsWeb) {
      res = await http
          .get(
            ApiConfig.uri(
              '/yahoo/quote',
              {'symbols': yahooSymbol},
            ),
            headers: _webHeaders,
          )
          .timeout(_timeout);
    } else {
      final uri = Uri.https(
        _chartBase,
        '/v7/finance/quote',
        {
          'symbols': yahooSymbol,
          'corsDomain': 'finance.yahoo.com',
        },
      );
      res = await http.get(uri, headers: _nativeHeaders).timeout(_timeout);
    }

    if (res.statusCode != 200) {
      return CompanyInfo.placeholder(symbol);
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final quoteResponse =
          json['quoteResponse'] as Map<String, dynamic>? ?? {};
      final results = (quoteResponse['result'] as List?) ?? [];

      if (results.isEmpty) {
        return CompanyInfo.placeholder(symbol);
      }

      final q = results.first as Map<String, dynamic>;

      double? numValue(String key) {
        final v = q[key];
        if (v is num) return v.toDouble();
        return null;
      }

      return CompanyInfo(
        symbol: symbol,
        shortName: q['shortName'] as String? ?? symbol,
        longName:
            q['longName'] as String? ?? q['shortName'] as String? ?? symbol,
        description: '—',
        sector: '—',
        industry: '—',
        website: '—',
        marketCap: numValue('marketCap'),
        peRatio: numValue('trailingPE'),
        week52High: numValue('fiftyTwoWeekHigh'),
        week52Low: numValue('fiftyTwoWeekLow'),
        dividendYield: numValue('dividendYield'),
        beta: numValue('beta'),
        employees: null,
      );
    } catch (_) {
      return CompanyInfo.placeholder(symbol);
    }
  }

  static Future<CompanyInfo> _getCompanyInfoFromSummary(String symbol) async {
    final yahooSymbol = _normalizeSymbol(symbol);

    http.Response res;
    if (kIsWeb) {
      res = await http
          .get(
            ApiConfig.uri('/yahoo/company/$yahooSymbol'),
            headers: _webHeaders,
          )
          .timeout(_timeout);
    } else {
      final uri = Uri.https(
        _summaryBase,
        '/v10/finance/quoteSummary/$yahooSymbol',
        {
          'modules': 'assetProfile,summaryDetail,defaultKeyStatistics',
          'corsDomain': 'finance.yahoo.com',
        },
      );
      res = await http.get(uri, headers: _nativeHeaders).timeout(_timeout);
    }

    if (res.statusCode != 200) {
      return CompanyInfo.placeholder(symbol);
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final quoteSummary = json['quoteSummary'] as Map<String, dynamic>?;

      if (quoteSummary == null || quoteSummary['error'] != null) {
        return CompanyInfo.placeholder(symbol);
      }

      final result =
          (quoteSummary['result'] as List?)?.first as Map<String, dynamic>?;
      if (result == null) return CompanyInfo.placeholder(symbol);

      final profile = result['assetProfile'] as Map<String, dynamic>? ?? {};
      final detail = result['summaryDetail'] as Map<String, dynamic>? ?? {};
      final stats =
          result['defaultKeyStatistics'] as Map<String, dynamic>? ?? {};

      double? rawValue(Map map, String key) {
        final v = map[key];
        if (v == null) return null;
        if (v is num) return v.toDouble();
        if (v is Map) return (v['raw'] as num?)?.toDouble();
        return null;
      }

      final longName = profile['longName'] as String? ??
          profile['companyOfficers']?[0]?['title'] as String? ??
          symbol;

      return CompanyInfo(
        symbol: symbol,
        shortName: symbol,
        longName: longName,
        description: profile['longBusinessSummary'] as String? ?? '—',
        sector: profile['sector'] as String? ?? '—',
        industry: profile['industry'] as String? ?? '—',
        website: profile['website'] as String? ?? '—',
        marketCap: rawValue(detail, 'marketCap'),
        peRatio: rawValue(detail, 'trailingPE'),
        week52High: rawValue(detail, 'fiftyTwoWeekHigh'),
        week52Low: rawValue(detail, 'fiftyTwoWeekLow'),
        dividendYield: rawValue(detail, 'dividendYield'),
        beta: rawValue(stats, 'beta'),
        employees: (profile['fullTimeEmployees'] as num?)?.toInt(),
      );
    } catch (_) {
      return CompanyInfo.placeholder(symbol);
    }
  }

  static bool _isPlaceholderCompanyInfo(CompanyInfo info, String symbol) {
    return info.longName == symbol &&
        info.description == '—' &&
        info.sector == '—' &&
        info.industry == '—' &&
        info.website == '—' &&
        info.marketCap == null &&
        info.peRatio == null &&
        info.week52High == null &&
        info.week52Low == null &&
        info.dividendYield == null &&
        info.beta == null &&
        info.employees == null;
  }

  static Future<Map<String, QuoteData>> getBatchQuotes(
      List<String> symbols) async {
    final result = <String, QuoteData>{};

    try {
      final yahooToApp = <String, String>{
        for (final s in symbols) _normalizeSymbol(s): s,
      };

      http.Response res;
      if (kIsWeb) {
        res = await http
            .get(
              ApiConfig.uri(
                '/yahoo/quote',
                {'symbols': yahooToApp.keys.join(',')},
              ),
              headers: _webHeaders,
            )
            .timeout(_timeout);
      } else {
        final uri = Uri.https(
          _chartBase,
          '/v7/finance/quote',
          {
            'symbols': yahooToApp.keys.join(','),
            'corsDomain': 'finance.yahoo.com',
          },
        );
        res = await http.get(uri, headers: _nativeHeaders).timeout(_timeout);
      }

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final quoteResponse =
            json['quoteResponse'] as Map<String, dynamic>? ?? {};
        final results = (quoteResponse['result'] as List?) ?? [];

        for (final item in results) {
          final q = item as Map<String, dynamic>;
          final yahooSymbol = q['symbol'] as String?;
          final price = (q['regularMarketPrice'] as num?)?.toDouble();

          if (yahooSymbol == null || price == null || price <= 0) continue;

          final appSymbol = yahooToApp[yahooSymbol] ?? yahooSymbol;
          result[appSymbol] = QuoteData(
            price: price,
            change: (q['regularMarketChange'] as num?)?.toDouble() ?? 0,
            changePercent:
                (q['regularMarketChangePercent'] as num?)?.toDouble() ?? 0,
          );
        }
      }
    } catch (_) {
    }

    final missingSymbols =
        symbols.where((s) => !result.containsKey(s)).toList();
    for (final symbol in missingSymbols) {
      try {
        final chart = await getChartData(
          symbol: symbol,
          range: '1d',
          interval: '5m',
        );

        result[symbol] = QuoteData(
          price: chart.currentPrice,
          change: chart.change,
          changePercent: chart.changePercent,
        );
      } catch (_) {
      }
    }

    return result;
  }

  static Future<Map<String, dynamic>> getQuote(String symbol) async {
    final batch = await getBatchQuotes([symbol]);
    final q = batch[symbol];
    if (q == null) return {};

    return {
      'regularMarketPrice': q.price,
      'regularMarketChange': q.change,
      'regularMarketChangePercent': q.changePercent,
    };
  }

  static Map<String, String> get _nativeHeaders => {
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp/1.0)',
        'Accept': 'application/json',
      };

  static Map<String, String> get _webHeaders => {
        'Accept': 'application/json',
      };
}

class ChartRange {
  final String label;
  final String labelRu;
  final String range;
  final String interval;

  const ChartRange({
    required this.label,
    required this.labelRu,
    required this.range,
    required this.interval,
  });

  static const List<ChartRange> all = [
    ChartRange(label: 'D', labelRu: 'Д', range: '1d', interval: '5m'),
    ChartRange(label: 'W', labelRu: 'Н', range: '5d', interval: '15m'),
    ChartRange(label: 'M', labelRu: 'М', range: '1mo', interval: '1d'),
    ChartRange(label: '6M', labelRu: '6М', range: '6mo', interval: '1wk'),
    ChartRange(label: 'Y', labelRu: 'Г', range: '1y', interval: '1wk'),
    ChartRange(label: 'All', labelRu: 'Все', range: 'max', interval: '1mo'),
  ];
}

class QuoteData {
  final double price;
  final double change;
  final double changePercent;

  const QuoteData({
    required this.price,
    required this.change,
    required this.changePercent,
  });
}
