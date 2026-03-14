class BacktestResult {
  final String strategyName;
  final DateTime startDate;
  final DateTime endDate;
  final double initialCapital;
  final double finalCapital;
  final double totalReturn;
  final double annualizedReturn;
  final double maxDrawdown;
  final double sharpeRatio;
  final double winRate;
  final int totalTrades;
  final List<double> equityCurve;
  final List<TradeSignal> signals;

  const BacktestResult({
    required this.strategyName,
    required this.startDate,
    required this.endDate,
    required this.initialCapital,
    required this.finalCapital,
    required this.totalReturn,
    required this.annualizedReturn,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.winRate,
    required this.totalTrades,
    required this.equityCurve,
    required this.signals,
  });

  bool get isProfitable => totalReturn > 0;
}

class TradeSignal {
  final DateTime date;
  final String type;
  final double price;
  final double profit;

  const TradeSignal({
    required this.date,
    required this.type,
    required this.price,
    required this.profit,
  });
}
