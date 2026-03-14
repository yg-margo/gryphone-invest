class Stock {
  final String symbol;
  final String name;
  final String sector;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double marketCap;
  final double volume;
  final List<double> priceHistory;

  const Stock({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.marketCap,
    required this.volume,
    required this.priceHistory,
  });

  bool get isPositive => change >= 0;

  Stock copyWith({double? currentPrice, double? change, double? changePercent}) {
    return Stock(
      symbol: symbol,
      name: name,
      sector: sector,
      currentPrice: currentPrice ?? this.currentPrice,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      marketCap: marketCap,
      volume: volume,
      priceHistory: priceHistory,
    );
  }
}
