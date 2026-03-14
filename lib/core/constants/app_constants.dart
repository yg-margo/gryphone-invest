class AppConstants {
  static const String appName = 'Gryphone Invest';
  static const String appVersion = '1.0.0';
  static const double defaultCash = 100000.0;

  static const List<String> strategies = [
    'Moving Average Crossover',
    'RSI Momentum',
    'Bollinger Bands',
    'Buy & Hold',
    'Mean Reversion',
  ];

  static const List<String> timeframes = ['1W', '1M', '3M', '6M', '1Y', 'All'];

  static const List<String> predictionHorizons = ['7 days', '30 days', '90 days'];
}
