import 'dart:math';
import '../models/stock.dart';

class MarketDataService {
  static final Random _random = Random(42);

  static List<double> _generatePriceHistory(double basePrice, int days) {
    final prices = <double>[];
    double price = basePrice * 0.7;
    for (int i = 0; i < days; i++) {
      final change = ((_random.nextDouble() - 0.48) * price * 0.025);
      price = max(price + change, basePrice * 0.3);
      prices.add(double.parse(price.toStringAsFixed(2)));
    }
    return prices;
  }

  static List<Stock> getMockStocks() {
    return [
      Stock(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        sector: 'Technology',
        currentPrice: 189.45,
        change: 2.34,
        changePercent: 1.25,
        marketCap: 2940000000000,
        volume: 58420000,
        priceHistory: _generatePriceHistory(189.45, 90),
      ),
      Stock(
        symbol: 'MSFT',
        name: 'Microsoft Corp.',
        sector: 'Technology',
        currentPrice: 415.20,
        change: -3.15,
        changePercent: -0.75,
        marketCap: 3090000000000,
        volume: 22100000,
        priceHistory: _generatePriceHistory(415.20, 90),
      ),
      Stock(
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        sector: 'Technology',
        currentPrice: 172.80,
        change: 1.92,
        changePercent: 1.12,
        marketCap: 2160000000000,
        volume: 24500000,
        priceHistory: _generatePriceHistory(172.80, 90),
      ),
      Stock(
        symbol: 'NVDA',
        name: 'NVIDIA Corp.',
        sector: 'Semiconductors',
        currentPrice: 875.40,
        change: 18.60,
        changePercent: 2.17,
        marketCap: 2160000000000,
        volume: 43200000,
        priceHistory: _generatePriceHistory(875.40, 90),
      ),
      Stock(
        symbol: 'AMZN',
        name: 'Amazon.com Inc.',
        sector: 'Consumer',
        currentPrice: 182.15,
        change: -0.85,
        changePercent: -0.46,
        marketCap: 1890000000000,
        volume: 32100000,
        priceHistory: _generatePriceHistory(182.15, 90),
      ),
      Stock(
        symbol: 'TSLA',
        name: 'Tesla Inc.',
        sector: 'Automotive',
        currentPrice: 248.50,
        change: -7.20,
        changePercent: -2.81,
        marketCap: 790000000000,
        volume: 98500000,
        priceHistory: _generatePriceHistory(248.50, 90),
      ),
      Stock(
        symbol: 'META',
        name: 'Meta Platforms',
        sector: 'Technology',
        currentPrice: 512.30,
        change: 8.45,
        changePercent: 1.68,
        marketCap: 1310000000000,
        volume: 15600000,
        priceHistory: _generatePriceHistory(512.30, 90),
      ),
      Stock(
        symbol: 'NFLX',
        name: 'Netflix Inc.',
        sector: 'Entertainment',
        currentPrice: 628.90,
        change: 12.30,
        changePercent: 1.99,
        marketCap: 272000000000,
        volume: 4800000,
        priceHistory: _generatePriceHistory(628.90, 90),
      ),
      Stock(
        symbol: 'JPM',
        name: 'JPMorgan Chase',
        sector: 'Finance',
        currentPrice: 198.75,
        change: 1.05,
        changePercent: 0.53,
        marketCap: 573000000000,
        volume: 9200000,
        priceHistory: _generatePriceHistory(198.75, 90),
      ),
      Stock(
        symbol: 'BRK.B',
        name: 'Berkshire Hathaway',
        sector: 'Finance',
        currentPrice: 365.20,
        change: 2.80,
        changePercent: 0.77,
        marketCap: 795000000000,
        volume: 3400000,
        priceHistory: _generatePriceHistory(365.20, 90),
      ),
    ];
  }

  static List<double> generatePortfolioHistory(int days) {
    double value = 100000;
    final history = <double>[];
    for (int i = 0; i < days; i++) {
      final drift = (_random.nextDouble() - 0.46) * value * 0.008;
      value = max(value + drift, 50000);
      history.add(double.parse(value.toStringAsFixed(2)));
    }
    return history;
  }
}
