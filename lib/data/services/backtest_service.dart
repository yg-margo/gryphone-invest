import 'dart:math';

import '../models/backtest_result.dart';

class BacktestService {
  static final Random _random = Random(99);

  static BacktestResult runBacktest({
    required String strategy,
    required String symbol,
    required double initialCapital,
    required int days,
    required List<double> priceHistory,
  }) {
    if (priceHistory.length < 2) {
      throw ArgumentError('Not enough price history for backtesting');
    }

    final startDate = DateTime.now().subtract(Duration(days: days));
    final endDate = DateTime.now();

    switch (strategy) {
      case 'Moving Average Crossover':
        return _maStrategy(
          symbol,
          strategy,
          initialCapital,
          priceHistory,
          startDate,
          endDate,
        );
      case 'RSI Momentum':
        return _rsiStrategy(
          symbol,
          strategy,
          initialCapital,
          priceHistory,
          startDate,
          endDate,
        );
      case 'Bollinger Bands':
        return _bollingerStrategy(
          symbol,
          strategy,
          initialCapital,
          priceHistory,
          startDate,
          endDate,
        );
      case 'Buy & Hold':
        return _buyHoldStrategy(
          symbol,
          strategy,
          initialCapital,
          priceHistory,
          startDate,
          endDate,
        );
      default:
        return _meanReversionStrategy(
          symbol,
          strategy,
          initialCapital,
          priceHistory,
          startDate,
          endDate,
        );
    }
  }

  static BacktestResult _buyHoldStrategy(
    String symbol,
    String strategyName,
    double capital,
    List<double> prices,
    DateTime start,
    DateTime end,
  ) {
    final shares = capital / prices.first;
    final finalCapital = shares * prices.last;
    final totalReturn = ((finalCapital - capital) / capital) * 100;
    final days = prices.length;
    final annualized = (pow((finalCapital / capital), 365 / days) - 1) * 100;

    double maxVal = capital;
    double maxDrawdown = 0;
    final equity = prices.map((p) => shares * p).toList();
    for (final val in equity) {
      if (val > maxVal) maxVal = val;
      final drawdown = ((maxVal - val) / maxVal) * 100;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    }

    return BacktestResult(
      strategyName: strategyName,
      startDate: start,
      endDate: end,
      initialCapital: capital,
      finalCapital: double.parse(finalCapital.toStringAsFixed(2)),
      totalReturn: double.parse(totalReturn.toStringAsFixed(2)),
      annualizedReturn: double.parse(annualized.toStringAsFixed(2)),
      maxDrawdown: double.parse(maxDrawdown.toStringAsFixed(2)),
      sharpeRatio: double.parse(
        (totalReturn / 15 + _random.nextDouble() * 0.5).toStringAsFixed(2),
      ),
      winRate: 100.0,
      totalTrades: 1,
      equityCurve: equity,
      signals: [
        TradeSignal(date: start, type: 'BUY', price: prices.first, profit: 0),
        TradeSignal(
          date: end,
          type: 'SELL',
          price: prices.last,
          profit: finalCapital - capital,
        ),
      ],
    );
  }

  static BacktestResult _maStrategy(
    String symbol,
    String strategyName,
    double capital,
    List<double> prices,
    DateTime start,
    DateTime end,
  ) {
    final equity = <double>[];
    final signals = <TradeSignal>[];
    double cash = capital;
    double shares = 0;
    const shortPeriod = 5;
    const longPeriod = 20;

    if (prices.length <= longPeriod + 1) {
      return _buildResult(
        strategyName,
        start,
        end,
        capital,
        capital,
        [capital],
        const [],
      );
    }

    for (int i = longPeriod + 1; i < prices.length; i++) {
      final shortMA =
          prices.sublist(i - shortPeriod, i).reduce((a, b) => a + b) /
              shortPeriod;
      final longMA = prices.sublist(i - longPeriod, i).reduce((a, b) => a + b) /
          longPeriod;
      final prevShortMA =
          prices.sublist(i - shortPeriod - 1, i - 1).reduce((a, b) => a + b) /
              shortPeriod;
      final prevLongMA =
          prices.sublist(i - longPeriod - 1, i - 1).reduce((a, b) => a + b) /
              longPeriod;

      if (prevShortMA <= prevLongMA && shortMA > longMA && shares == 0) {
        shares = cash / prices[i];
        final date = start.add(Duration(days: i));
        signals.add(
          TradeSignal(date: date, type: 'BUY', price: prices[i], profit: 0),
        );
        cash = 0;
      } else if (prevShortMA >= prevLongMA && shortMA < longMA && shares > 0) {
        final sellValue = shares * prices[i];
        final profit = sellValue -
            (shares * (signals.lastWhere((s) => s.type == 'BUY').price));
        signals.add(
          TradeSignal(
            date: start.add(Duration(days: i)),
            type: 'SELL',
            price: prices[i],
            profit: profit,
          ),
        );
        cash = sellValue;
        shares = 0;
      }

      equity.add(cash + shares * prices[i]);
    }

    final finalCapital = equity.isEmpty ? capital : equity.last;
    return _buildResult(
      strategyName,
      start,
      end,
      capital,
      finalCapital,
      equity,
      signals,
    );
  }

  static BacktestResult _rsiStrategy(
    String symbol,
    String strategyName,
    double capital,
    List<double> prices,
    DateTime start,
    DateTime end,
  ) {
    final equity = <double>[];
    final signals = <TradeSignal>[];
    double cash = capital;
    double shares = 0;
    const period = 14;

    List<double> calculateRSI(List<double> p) {
      final rsiValues = <double>[];
      for (int i = period; i < p.length; i++) {
        double gains = 0;
        double losses = 0;
        for (int j = i - period; j < i; j++) {
          final diff = p[j + 1] - p[j];
          if (diff > 0) {
            gains += diff;
          } else {
            losses -= diff;
          }
        }
        final rs = losses == 0 ? 100.0 : gains / losses;
        rsiValues.add(100 - (100 / (1 + rs)));
      }
      return rsiValues;
    }

    final rsi = calculateRSI(prices);

    for (int i = 0; i < rsi.length; i++) {
      final date = start.add(Duration(days: i + period));
      if (rsi[i] < 30 && shares == 0) {
        shares = cash / prices[i + period];
        signals.add(
          TradeSignal(
            date: date,
            type: 'BUY',
            price: prices[i + period],
            profit: 0,
          ),
        );
        cash = 0;
      } else if (rsi[i] > 70 && shares > 0) {
        final sellValue = shares * prices[i + period];
        final buyPrice = signals.lastWhere((s) => s.type == 'BUY').price;
        signals.add(
          TradeSignal(
            date: date,
            type: 'SELL',
            price: prices[i + period],
            profit: sellValue - (shares * buyPrice),
          ),
        );
        cash = sellValue;
        shares = 0;
      }
      equity.add(cash + shares * prices[i + period]);
    }

    final finalCapital = equity.isEmpty ? capital : equity.last;
    return _buildResult(
      strategyName,
      start,
      end,
      capital,
      finalCapital,
      equity,
      signals,
    );
  }

  static BacktestResult _bollingerStrategy(
    String symbol,
    String strategyName,
    double capital,
    List<double> prices,
    DateTime start,
    DateTime end,
  ) {
    final equity = <double>[];
    final signals = <TradeSignal>[];
    double cash = capital;
    double shares = 0;
    const period = 20;

    for (int i = period; i < prices.length; i++) {
      final window = prices.sublist(i - period, i);
      final mean = window.reduce((a, b) => a + b) / period;
      final variance =
          window.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) / period;
      final std = sqrt(variance);
      final upper = mean + 2 * std;
      final lower = mean - 2 * std;
      final date = start.add(Duration(days: i));

      if (prices[i] < lower && shares == 0) {
        shares = cash / prices[i];
        signals.add(
          TradeSignal(date: date, type: 'BUY', price: prices[i], profit: 0),
        );
        cash = 0;
      } else if (prices[i] > upper && shares > 0) {
        final sellValue = shares * prices[i];
        final buyPrice = signals.lastWhere((s) => s.type == 'BUY').price;
        signals.add(
          TradeSignal(
            date: date,
            type: 'SELL',
            price: prices[i],
            profit: sellValue - (shares * buyPrice),
          ),
        );
        cash = sellValue;
        shares = 0;
      }
      equity.add(cash + shares * prices[i]);
    }

    final finalCapital = equity.isEmpty ? capital : equity.last;
    return _buildResult(
      strategyName,
      start,
      end,
      capital,
      finalCapital,
      equity,
      signals,
    );
  }

  static BacktestResult _meanReversionStrategy(
    String symbol,
    String strategyName,
    double capital,
    List<double> prices,
    DateTime start,
    DateTime end,
  ) {
    final equity = <double>[];
    final signals = <TradeSignal>[];
    double cash = capital;
    double shares = 0;
    const period = 10;

    for (int i = period; i < prices.length; i++) {
      final mean =
          prices.sublist(i - period, i).reduce((a, b) => a + b) / period;
      final deviation = ((prices[i] - mean) / mean) * 100;
      final date = start.add(Duration(days: i));

      if (deviation < -3 && shares == 0) {
        shares = cash / prices[i];
        signals.add(
          TradeSignal(date: date, type: 'BUY', price: prices[i], profit: 0),
        );
        cash = 0;
      } else if (deviation > 3 && shares > 0) {
        final sellValue = shares * prices[i];
        final buyPrice = signals.lastWhere((s) => s.type == 'BUY').price;
        signals.add(
          TradeSignal(
            date: date,
            type: 'SELL',
            price: prices[i],
            profit: sellValue - (shares * buyPrice),
          ),
        );
        cash = sellValue;
        shares = 0;
      }
      equity.add(cash + shares * prices[i]);
    }

    final finalCapital = equity.isEmpty ? capital : equity.last;
    return _buildResult(
      strategyName,
      start,
      end,
      capital,
      finalCapital,
      equity,
      signals,
    );
  }

  static BacktestResult _buildResult(
    String strategyName,
    DateTime start,
    DateTime end,
    double initial,
    double finalCap,
    List<double> equity,
    List<TradeSignal> signals,
  ) {
    final totalReturn = ((finalCap - initial) / initial) * 100;
    final days = end.difference(start).inDays;
    final annualized = days > 0
        ? (pow((finalCap / initial), 365 / days) - 1) * 100
        : totalReturn;

    double maxVal = initial;
    double maxDrawdown = 0;
    for (final val in equity) {
      if (val > maxVal) maxVal = val;
      final dd = ((maxVal - val) / maxVal) * 100;
      if (dd > maxDrawdown) maxDrawdown = dd;
    }

    final sellSignals = signals.where((s) => s.type == 'SELL').toList();
    final wins = sellSignals.where((s) => s.profit > 0).length;
    final winRate =
        sellSignals.isEmpty ? 0.0 : (wins / sellSignals.length) * 100;
    final sharpe = totalReturn > 0
        ? (totalReturn / max(maxDrawdown, 1)) *
            (_random.nextDouble() * 0.4 + 0.8)
        : -(_random.nextDouble() * 0.5);

    return BacktestResult(
      strategyName: strategyName,
      startDate: start,
      endDate: end,
      initialCapital: initial,
      finalCapital: double.parse(finalCap.toStringAsFixed(2)),
      totalReturn: double.parse(totalReturn.toStringAsFixed(2)),
      annualizedReturn: double.parse(annualized.toStringAsFixed(2)),
      maxDrawdown: double.parse(maxDrawdown.toStringAsFixed(2)),
      sharpeRatio: double.parse(sharpe.toStringAsFixed(2)),
      winRate: double.parse(winRate.toStringAsFixed(1)),
      totalTrades: signals.where((s) => s.type == 'BUY').length,
      equityCurve: equity,
      signals: signals,
    );
  }
}
