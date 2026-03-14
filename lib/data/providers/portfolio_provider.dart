import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/portfolio.dart';
import '../models/position.dart';
import '../services/market_data_service.dart';
import '../services/portfolio_api_service.dart';

class PortfolioProvider extends ChangeNotifier {
  static const String _guestStorageKey = 'portfolio_guest';

  Portfolio _portfolio = Portfolio(
    positions: [],
    cash: 100000.0,
    valueHistory: MarketDataService.generatePortfolioHistory(90),
  );

  String _authToken = '';
  int? _authUserId;
  bool _isAuthenticated = false;
  bool _isSyncing = false;
  int _sessionVersion = 0;

  Portfolio get portfolio => _portfolio;
  bool get isSyncing => _isSyncing;

  PortfolioProvider() {
    _loadPortfolioFromLocal();
  }

  void setAuthSession({
    required bool isAuthenticated,
    required String token,
    required int? userId,
  }) {
    final changed = _isAuthenticated != isAuthenticated ||
        _authToken != token ||
        _authUserId != userId;

    if (!changed) return;

    _isAuthenticated = isAuthenticated;
    _authToken = token;
    _authUserId = userId;

    _sessionVersion += 1;
    _handleSessionChange(_sessionVersion);
  }

  Future<void> _handleSessionChange(int version) async {
    if (!_isAuthenticated || _authToken.isEmpty) {
      await _loadPortfolioFromLocal(version: version);
      return;
    }

    await _loadPortfolioFromLocal(version: version);
    if (version != _sessionVersion) return;

    await syncFromBackend(version: version);
  }

  Future<void> syncFromBackend({int? version}) async {
    if (!_isAuthenticated || _authToken.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final response =
          await PortfolioApiService.loadPortfolio(token: _authToken);
      if (version != null && version != _sessionVersion) return;
      if (!response.ok || response.data == null) return;

      final parsed = _portfolioFromApi(response.data!);
      _portfolio = parsed.copyWith(
        valueHistory: _portfolio.valueHistory,
      );

      await _savePortfolioToLocal();
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _loadPortfolioFromLocal({int? version}) async {
    final prefs = await SharedPreferences.getInstance();
    if (version != null && version != _sessionVersion) return;

    final json = prefs.getString(_storageKey);

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final positionsRaw = data['positions'] as List<dynamic>? ?? <dynamic>[];

        final positions = positionsRaw
            .whereType<Map<String, dynamic>>()
            .map(Position.fromJson)
            .toList();

        _portfolio = Portfolio(
          positions: positions,
          cash: (data['cash'] as num?)?.toDouble() ?? 100000.0,
          valueHistory: MarketDataService.generatePortfolioHistory(90),
        );
      } catch (_) {
        _portfolio = Portfolio(
          positions: [],
          cash: 100000.0,
          valueHistory: MarketDataService.generatePortfolioHistory(90),
        );
      }
    } else {
      _portfolio = Portfolio(
        positions: [],
        cash: 100000.0,
        valueHistory: MarketDataService.generatePortfolioHistory(90),
      );
    }

    notifyListeners();
  }

  Future<void> _savePortfolioToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'positions': _portfolio.positions.map((p) => p.toJson()).toList(),
      'cash': _portfolio.cash,
    };

    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> _syncPortfolioToBackend() async {
    if (!_isAuthenticated || _authToken.isEmpty) return;

    await PortfolioApiService.savePortfolio(
      token: _authToken,
      cash: _portfolio.cash,
      positions: _portfolio.positions.map((p) => p.toJson()).toList(),
    );
  }

  void addPosition(String symbol, String name, double shares, double price) {
    final existing =
        _portfolio.positions.where((p) => p.symbol == symbol).firstOrNull;
    final cost = shares * price;
    if (cost > _portfolio.cash) return;

    List<Position> newPositions;
    if (existing != null) {
      final totalShares = existing.shares + shares;
      final newAvg = (existing.totalCost + cost) / totalShares;
      newPositions = _portfolio.positions.map((p) {
        if (p.symbol == symbol) {
          return p.copyWith(
            shares: totalShares,
            avgCost: newAvg,
            currentPrice: price,
          );
        }
        return p;
      }).toList();
    } else {
      newPositions = [
        ..._portfolio.positions,
        Position(
          symbol: symbol,
          name: name,
          shares: shares,
          avgCost: price,
          currentPrice: price,
        ),
      ];
    }

    _portfolio = _portfolio.copyWith(
      positions: newPositions,
      cash: _portfolio.cash - cost,
    );

    _persistPortfolio();
    notifyListeners();
  }

  void removePosition(String id) {
    final position = _portfolio.positions.firstWhere((p) => p.id == id);

    _portfolio = _portfolio.copyWith(
      positions: _portfolio.positions.where((p) => p.id != id).toList(),
      cash: _portfolio.cash + position.currentValue,
    );

    _persistPortfolio();
    notifyListeners();
  }

  void updatePrices(Map<String, double> prices) {
    final updated = _portfolio.positions.map((p) {
      final newPrice = prices[p.symbol];
      if (newPrice != null) {
        return p.copyWith(currentPrice: newPrice);
      }
      return p;
    }).toList();

    _portfolio = _portfolio.copyWith(positions: updated);
    _savePortfolioToLocal();
    notifyListeners();
  }

  void resetPortfolio() {
    _portfolio = Portfolio(
      positions: [],
      cash: 100000.0,
      valueHistory: MarketDataService.generatePortfolioHistory(90),
    );

    _persistPortfolio();
    notifyListeners();
  }

  Future<void> _persistPortfolio() async {
    await _savePortfolioToLocal();
    await _syncPortfolioToBackend();
  }

  String get _storageKey {
    if (_authUserId != null) {
      return 'portfolio_user_$_authUserId';
    }
    return _guestStorageKey;
  }

  Portfolio _portfolioFromApi(Map<String, dynamic> data) {
    final positionsRaw = data['positions'] as List<dynamic>? ?? <dynamic>[];

    final positions =
        positionsRaw.whereType<Map<String, dynamic>>().map((item) {
      final normalized = <String, dynamic>{
        'id': item['id']?.toString() ?? '',
        'symbol': item['symbol']?.toString() ?? '',
        'name': item['name']?.toString() ?? '',
        'shares': (item['shares'] as num?)?.toDouble() ?? 0.0,
        'avgCost': (item['avgCost'] as num?)?.toDouble() ?? 0.0,
        'currentPrice': (item['currentPrice'] as num?)?.toDouble() ?? 0.0,
        'purchaseDate': item['purchaseDate']?.toString() ??
            DateTime.now().toIso8601String(),
      };
      return Position.fromJson(normalized);
    }).toList();

    return Portfolio(
      positions: positions,
      cash: (data['cash'] as num?)?.toDouble() ?? 100000.0,
      valueHistory: MarketDataService.generatePortfolioHistory(90),
    );
  }
}
