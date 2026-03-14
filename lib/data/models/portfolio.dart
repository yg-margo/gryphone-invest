import 'position.dart';

class Portfolio {
  final List<Position> positions;
  final double cash;
  final List<double> valueHistory;
  const Portfolio({
    required this.positions,
    required this.cash,
    required this.valueHistory,
  });

  double get totalValue =>
      positions.fold(0.0, (sum, p) => sum + p.currentValue) + cash;

  double get investedValue =>
      positions.fold(0.0, (sum, p) => sum + p.currentValue);

  double get totalCost =>
      positions.fold(0.0, (sum, p) => sum + p.totalCost);

  double get totalGain => investedValue - totalCost;

  double get totalGainPercent =>
      totalCost > 0 ? (totalGain / totalCost) * 100 : 0;

  double get dayChange =>
      positions.fold(0.0, (sum, p) => sum + (p.gain * 0.1));

  bool get isPositive => totalGain >= 0;

  Portfolio copyWith({
    List<Position>? positions,
    double? cash,
    List<double>? valueHistory,
  }) {
    return Portfolio(
      positions: positions ?? this.positions,
      cash: cash ?? this.cash,
      valueHistory: valueHistory ?? this.valueHistory,
    );
  }
}
