class StockOffer {
  final String id;
  final String symbol;
  final String name;
  final double price;
  final double targetPrice;
  final double returnPct;
  final double confidence;
  final String reasoning;
  final int suggestedShares;

  const StockOffer({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.targetPrice,
    required this.returnPct,
    required this.confidence,
    required this.reasoning,
    required this.suggestedShares,
  });
}
