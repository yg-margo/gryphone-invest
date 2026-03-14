import 'package:uuid/uuid.dart';

class Position {
  final String id;
  final String symbol;
  final String name;
  final double shares;
  final double avgCost;
  final double currentPrice;
  final DateTime purchaseDate;

  Position({
    String? id,
    required this.symbol,
    required this.name,
    required this.shares,
    required this.avgCost,
    required this.currentPrice,
    DateTime? purchaseDate,
  })  : id = id ?? const Uuid().v4(),
        purchaseDate = purchaseDate ?? DateTime.now();

  double get totalCost => shares * avgCost;
  double get currentValue => shares * currentPrice;
  double get gain => currentValue - totalCost;
  double get gainPercent => ((currentPrice - avgCost) / avgCost) * 100;
  bool get isPositive => gain >= 0;

  Position copyWith({double? currentPrice, double? shares, double? avgCost}) {
    return Position(
      id: id,
      symbol: symbol,
      name: name,
      shares: shares ?? this.shares,
      avgCost: avgCost ?? this.avgCost,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDate: purchaseDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'name': name,
        'shares': shares,
        'avgCost': avgCost,
        'currentPrice': currentPrice,
        'purchaseDate': purchaseDate.toIso8601String(),
      };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        id: json['id'],
        symbol: json['symbol'],
        name: json['name'],
        shares: json['shares'],
        avgCost: json['avgCost'],
        currentPrice: json['currentPrice'],
        purchaseDate: DateTime.parse(json['purchaseDate']),
      );
}
