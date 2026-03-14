import 'dart:math';
import '../models/stock.dart';

class AIPrediction {
  final String symbol;
  final String name;
  final double currentPrice;
  final double target7d;
  final double target30d;
  final double target90d;
  final double confidence;
  final String sentiment;
  final String reasoning;
  final List<String> signals;

  const AIPrediction({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.target7d,
    required this.target30d,
    required this.target90d,
    required this.confidence,
    required this.sentiment,
    required this.reasoning,
    required this.signals,
  });

  double get change7d => ((target7d - currentPrice) / currentPrice) * 100;
  double get change30d => ((target30d - currentPrice) / currentPrice) * 100;
  double get change90d => ((target90d - currentPrice) / currentPrice) * 100;
}

class AIPredictionService {
  static final Random _random = Random(12);

  static AIPrediction generatePrediction(Stock stock) {
    final isBullish = _random.nextBool();
    final neutralChance = _random.nextDouble() < 0.2;
    final sentiment = neutralChance
        ? 'Neutral'
        : (isBullish ? 'Bullish' : 'Bearish');

    final multiplier = isBullish ? 1.0 : -1.0;
    final base = stock.currentPrice;

    final t7 = base * (1 + multiplier * (_random.nextDouble() * 0.03 + 0.005));
    final t30 = base * (1 + multiplier * (_random.nextDouble() * 0.08 + 0.02));
    final t90 = base * (1 + multiplier * (_random.nextDouble() * 0.18 + 0.05));

    final confidence = 55 + _random.nextDouble() * 35;

    final reasonings = {
      'Bullish': [
        'Strong earnings growth with expanding profit margins signals continued upward momentum.',
        'Technical indicators show golden cross formation; volume confirms bullish breakout.',
        'Institutional accumulation detected with above-average buy pressure over past 30 days.',
      ],
      'Bearish': [
        'Overbought RSI conditions combined with weakening revenue guidance suggest a correction.',
        'Death cross formation on weekly chart; deteriorating market breadth a key concern.',
        'Rising competition and margin compression may weigh on forward earnings estimates.',
      ],
      'Neutral': [
        'Mixed signals — strong fundamentals offset by macro headwinds; consolidation likely.',
        'Price trading within established range; awaiting catalyst for directional move.',
      ],
    };

    final bullishSignals = [
      'RSI: 58 (Healthy)',
      'MACD: Bullish crossover',
      'Volume: +24% avg',
      'MA50 > MA200',
      'Insider buying detected',
      'Earnings beat 3Q in a row',
    ];

    final bearishSignals = [
      'RSI: 74 (Overbought)',
      'MACD: Bearish divergence',
      'Volume: -18% avg',
      'MA50 < MA200',
      'Institutional selling',
      'Guidance lowered',
    ];

    final neutralSignals = [
      'RSI: 51 (Neutral)',
      'MACD: Flat',
      'Volume: Average',
      'Price at MA50',
    ];

    final signals = sentiment == 'Bullish'
        ? bullishSignals
        : sentiment == 'Bearish'
            ? bearishSignals
            : neutralSignals;

    final reasoningList = reasonings[sentiment]!;
    final reasoning = reasoningList[_random.nextInt(reasoningList.length)];

    return AIPrediction(
      symbol: stock.symbol,
      name: stock.name,
      currentPrice: base,
      target7d: double.parse(t7.toStringAsFixed(2)),
      target30d: double.parse(t30.toStringAsFixed(2)),
      target90d: double.parse(t90.toStringAsFixed(2)),
      confidence: double.parse(confidence.toStringAsFixed(1)),
      sentiment: sentiment,
      reasoning: reasoning,
      signals: signals,
    );
  }

  static List<AIPrediction> generateAllPredictions(List<Stock> stocks) {
    return stocks.map((s) => generatePrediction(s)).toList();
  }
}
