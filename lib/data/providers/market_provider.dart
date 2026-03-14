import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/stock.dart';
import '../services/ai_prediction_service.dart';
import '../services/market_data_service.dart';
import '../services/yahoo_finance_service.dart';

class MarketProvider extends ChangeNotifier {
  static const Duration _lifecycleRefreshCooldown = Duration(seconds: 8);

  List<Stock> _stocks = [];
  List<AIPrediction> _predictions = [];
  bool _isLoading = true;
  Timer? _yahooTimer;
  bool _isBatchFetching = false;
  DateTime? _lastCorrectionRefreshAt;

  List<Stock> get stocks => _stocks;
  List<AIPrediction> get predictions => _predictions;
  bool get isLoading => _isLoading;

  MarketProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _stocks = MarketDataService.getMockStocks();
    notifyListeners();

    await refreshMarketCorrections(force: true);

    _predictions = AIPredictionService.generateAllPredictions(_stocks);
    _isLoading = false;
    notifyListeners();

    _yahooTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => refreshMarketCorrections(force: true),
    );
  }

  Future<void> refreshMarketCorrections({
    List<String>? symbols,
    bool force = false,
  }) async {
    final now = DateTime.now();
    final last = _lastCorrectionRefreshAt;
    final isWithinCooldown =
        last != null && now.difference(last) < _lifecycleRefreshCooldown;

    if (!force && isWithinCooldown) return;

    final ok = await _fetchBatch(symbols: symbols);
    if (ok) {
      _lastCorrectionRefreshAt = DateTime.now();
    }
  }

  Future<bool> _fetchBatch({List<String>? symbols}) async {
    if (_stocks.isEmpty || _isBatchFetching) return false;

    _isBatchFetching = true;
    try {
      final symbolsToUpdate = (symbols == null || symbols.isEmpty)
          ? _stocks.map((s) => s.symbol).toList()
          : _stocks
              .where((stock) => symbols.contains(stock.symbol))
              .map((stock) => stock.symbol)
              .toList();

      if (symbolsToUpdate.isEmpty) return false;

      final results = await Future.wait(
        symbolsToUpdate.map((symbol) async {
          try {
            final chart = await YahooFinanceService.getChartData(
              symbol: symbol,
              range: '1d',
              interval: '5m',
            );

            return MapEntry(
              symbol,
              QuoteData(
                price: chart.currentPrice,
                change: chart.change,
                changePercent: chart.changePercent,
              ),
            );
          } catch (_) {
            return null;
          }
        }),
      );

      final quotes = <String, QuoteData>{
        for (final item in results)
          if (item != null) item.key: item.value,
      };

      if (quotes.isEmpty) return false;

      bool changed = false;
      final updated = List<Stock>.from(_stocks);

      for (int i = 0; i < updated.length; i++) {
        final q = quotes[updated[i].symbol];
        if (q == null) continue;

        updated[i] = updated[i].copyWith(
          currentPrice: q.price,
          change: q.change,
          changePercent: q.changePercent,
        );
        changed = true;
      }

      if (changed) {
        _stocks = updated;
        _predictions = AIPredictionService.generateAllPredictions(_stocks);
        notifyListeners();
      }

      return changed;
    } catch (_) {
      return false;
    } finally {
      _isBatchFetching = false;
    }
  }

  void updateStockPrice(
    String symbol,
    double price, {
    double? change,
    double? changePercent,
  }) {
    final idx = _stocks.indexWhere((s) => s.symbol == symbol);
    if (idx == -1) return;

    final old = _stocks[idx];
    final base = old.currentPrice - old.change;
    final updated = List<Stock>.from(_stocks);

    updated[idx] = old.copyWith(
      currentPrice: price,
      change: change ?? double.parse((price - base).toStringAsFixed(2)),
      changePercent: changePercent ??
          (base != 0
              ? double.parse(((price - base) / base * 100).toStringAsFixed(2))
              : old.changePercent),
    );

    _stocks = updated;
    _predictions = AIPredictionService.generateAllPredictions(_stocks);
    notifyListeners();
  }

  Stock? getStock(String symbol) {
    try {
      return _stocks.firstWhere((s) => s.symbol == symbol);
    } catch (_) {
      return null;
    }
  }

  AIPrediction? getPrediction(String symbol) {
    try {
      return _predictions.firstWhere((p) => p.symbol == symbol);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _yahooTimer?.cancel();
    super.dispose();
  }
}
