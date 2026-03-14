class StockChartPoint {
  final DateTime timestamp;
  final double   price;
  const StockChartPoint({required this.timestamp, required this.price});
}

class StockChartData {
  final String               symbol;
  final List<StockChartPoint> points;
  final double               currentPrice;
  final double               previousClose;
  final String               currency;

  const StockChartData({
    required this.symbol,
    required this.points,
    required this.currentPrice,
    required this.previousClose,
    this.currency = 'USD',
  });

  double get change        => currentPrice - previousClose;
  double get changePercent =>
      previousClose != 0 ? (change / previousClose) * 100 : 0.0;
  bool   get isPositive    => change >= 0;
}

class CompanyInfo {
  final String  symbol;
  final String  shortName;
  final String  longName;
  final String  description;
  final String  sector;
  final String  industry;
  final String  website;
  final double? marketCap;
  final double? peRatio;
  final double? week52High;
  final double? week52Low;
  final double? dividendYield;
  final double? beta;
  final int?    employees;

  const CompanyInfo({
    required this.symbol,
    required this.shortName,
    required this.longName,
    required this.description,
    required this.sector,
    required this.industry,
    required this.website,
    this.marketCap,
    this.peRatio,
    this.week52High,
    this.week52Low,
    this.dividendYield,
    this.beta,
    this.employees,
  });

  factory CompanyInfo.placeholder(String symbol) => CompanyInfo(
        symbol:      symbol,
        shortName:   symbol,
        longName:    symbol,
        description: 'No description available.',
        sector:      '—',
        industry:    '—',
        website:     '—',
      );
}
