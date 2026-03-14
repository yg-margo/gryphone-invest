import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/backtest_result.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/providers/market_provider.dart';
import '../../../data/services/backtest_service.dart';
import '../../../data/services/yahoo_finance_service.dart';

class BacktestScreen extends StatefulWidget {
  const BacktestScreen({super.key});

  @override
  State<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  String _selectedStrategy = AppConstants.strategies[0];
  String _selectedSymbol = 'AAPL';
  int _selectedDays = 90;
  double _initialCapital = 10000;
  BacktestResult? _result;
  bool _isRunning = false;
  final _capitalController = TextEditingController(text: '10000');

  String _rangeForBacktest(int days) {
    if (days <= 30) return '3mo';
    if (days <= 90) return '6mo';
    if (days <= 180) return '1y';
    return '2y';
  }

  Future<void> _runBacktest() async {
    final market = context.read<MarketProvider>();
    final isRu = context.read<LocaleProvider>().isRussian;
    final stock = market.getStock(_selectedSymbol);

    if (stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRu
                ? 'Тикер $_selectedSymbol не найден'
                : 'Symbol $_selectedSymbol not found',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isRunning = true);

    try {
      final history = await YahooFinanceService.getHistoricalCloses(
        symbol: _selectedSymbol,
        range: _rangeForBacktest(_selectedDays),
        interval: '1d',
      );

      if (history.length < 2) {
        throw Exception('Not enough history');
      }

      final slicedHistory = history.length > _selectedDays
          ? history.sublist(history.length - _selectedDays)
          : history;

      if (slicedHistory.length < 2) {
        throw Exception('Not enough sliced history');
      }

      final result = BacktestService.runBacktest(
        strategy: _selectedStrategy,
        symbol: _selectedSymbol,
        initialCapital: _initialCapital,
        days: slicedHistory.length,
        priceHistory: slicedHistory,
      );

      if (!mounted) return;
      setState(() {
        _result = result;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRu
                ? 'Не удалось загрузить реальные данные для бэктеста. Попробуйте снова.'
                : 'Failed to load real backtest data. Please try again.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  @override
  void dispose() {
    _capitalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRu = context.watch<LocaleProvider>().isRussian;
    final market = context.watch<MarketProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('backtesting', isRussian: isRu)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ConfigCard(
            isDark: isDark,
            isRu: isRu,
            strategies: AppConstants.strategies,
            symbols: market.stocks.map((s) => s.symbol).toList(),
            selectedStrategy: _selectedStrategy,
            selectedSymbol: _selectedSymbol,
            selectedDays: _selectedDays,
            capitalController: _capitalController,
            onStrategyChanged: (v) => setState(() => _selectedStrategy = v!),
            onSymbolChanged: (v) => setState(() => _selectedSymbol = v!),
            onDaysChanged: (v) => setState(() => _selectedDays = v),
            onCapitalChanged: (v) =>
                setState(() => _initialCapital = double.tryParse(v) ?? 10000),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runBacktest,
              icon: _isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isRunning
                    ? AppStrings.get('runningBacktest', isRussian: isRu)
                    : AppStrings.get('runBacktest', isRussian: isRu),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultSummary(result: _result!, isDark: isDark, isRu: isRu),
            const SizedBox(height: 16),
            _EquityCurveChart(result: _result!, isDark: isDark, isRu: isRu),
            const SizedBox(height: 16),
            _TradesList(result: _result!, isDark: isDark, isRu: isRu),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final bool isDark;
  final bool isRu;
  final List<String> strategies;
  final List<String> symbols;
  final String selectedStrategy;
  final String selectedSymbol;
  final int selectedDays;
  final TextEditingController capitalController;
  final Function(String?) onStrategyChanged;
  final Function(String?) onSymbolChanged;
  final Function(int) onDaysChanged;
  final Function(String) onCapitalChanged;

  const _ConfigCard({
    required this.isDark,
    required this.isRu,
    required this.strategies,
    required this.symbols,
    required this.selectedStrategy,
    required this.selectedSymbol,
    required this.selectedDays,
    required this.capitalController,
    required this.onStrategyChanged,
    required this.onSymbolChanged,
    required this.onDaysChanged,
    required this.onCapitalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strategyNames = AppStrings.strategyNames(isRu);
    final dayLabels = [
      '30 ${isRu ? 'дн.' : 'd'}',
      '60 ${isRu ? 'дн.' : 'd'}',
      '90 ${isRu ? 'дн.' : 'd'}',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get('configuration', isRussian: isRu),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.get('strategy', isRussian: isRu),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStrategy,
                  isExpanded: true,
                  dropdownColor:
                      isDark ? AppColors.darkElevated : AppColors.lightCard,
                  items: strategies.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        strategyNames[item] ?? item,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: onStrategyChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.get('symbol', isRussian: isRu),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSymbol,
                isExpanded: true,
                dropdownColor:
                    isDark ? AppColors.darkElevated : AppColors.lightCard,
                items: symbols
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: onSymbolChanged,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.get('period', isRussian: isRu),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [30, 60, 90].asMap().entries.map((entry) {
              final days = entry.value;
              final label = dayLabels[entry.key];
              final isSelected = days == selectedDays;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onDaysChanged(days),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkElevated
                              : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.get('initialCapital', isRussian: isRu),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: capitalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixIcon:
                  Icon(Icons.attach_money, color: AppColors.primaryLight),
              hintText: '10000',
            ),
            onChanged: onCapitalChanged,
          ),
        ],
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final BacktestResult result;
  final bool isDark;
  final bool isRu;

  const _ResultSummary({
    required this.result,
    required this.isDark,
    required this.isRu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get('results', isRussian: isRu),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (result.isProfitable
                          ? AppColors.success
                          : AppColors.danger)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.isProfitable
                      ? AppStrings.get('profitable', isRussian: isRu)
                      : AppStrings.get('loss', isRussian: isRu),
                  style: TextStyle(
                    color: result.isProfitable
                        ? AppColors.success
                        : AppColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
            children: [
              _MetricTile(
                label: AppStrings.get('totalReturn', isRussian: isRu),
                value: Formatters.percentRaw(result.totalReturn),
                isPositive: result.isProfitable,
                isDark: isDark,
              ),
              _MetricTile(
                label: AppStrings.get('annualReturn', isRussian: isRu),
                value: Formatters.percentRaw(result.annualizedReturn),
                isPositive: result.annualizedReturn >= 0,
                isDark: isDark,
              ),
              _MetricTile(
                label: AppStrings.get('maxDrawdown', isRussian: isRu),
                value: '-${result.maxDrawdown.toStringAsFixed(2)}%',
                isPositive: false,
                isDark: isDark,
              ),
              _MetricTile(
                label: AppStrings.get('sharpeRatio', isRussian: isRu),
                value: result.sharpeRatio.toStringAsFixed(2),
                isPositive: result.sharpeRatio >= 1,
                isDark: isDark,
              ),
              _MetricTile(
                label: AppStrings.get('winRate', isRussian: isRu),
                value: '${result.winRate.toStringAsFixed(1)}%',
                isPositive: result.winRate >= 50,
                isDark: isDark,
              ),
              _MetricTile(
                label: AppStrings.get('totalTrades', isRussian: isRu),
                value: '${result.totalTrades}',
                isPositive: true,
                isDark: isDark,
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get('initialCapital', isRussian: isRu),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.currency(result.initialCapital),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, color: AppColors.primaryLight),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.get('finalCapital', isRussian: isRu),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.currency(result.finalCapital),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: result.isProfitable
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;
  final bool isDark;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.isPositive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isPositive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquityCurveChart extends StatelessWidget {
  final BacktestResult result;
  final bool isDark;
  final bool isRu;

  const _EquityCurveChart({
    required this.result,
    required this.isDark,
    required this.isRu,
  });

  @override
  Widget build(BuildContext context) {
    final spots = result.equityCurve
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final minY = result.equityCurve.reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = result.equityCurve.reduce((a, b) => a > b ? a : b) * 1.02;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get('equityCurve', isRussian: isRu),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (val, _) => Text(
                        Formatters.compactCurrency(val),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: result.isProfitable
                        ? AppColors.success
                        : AppColors.danger,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          (result.isProfitable
                                  ? AppColors.success
                                  : AppColors.danger)
                              .withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        isDark ? AppColors.darkElevated : AppColors.lightCard,
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            Formatters.currency(s.y),
                            const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradesList extends StatelessWidget {
  final BacktestResult result;
  final bool isDark;
  final bool isRu;

  const _TradesList({
    required this.result,
    required this.isDark,
    required this.isRu,
  });

  @override
  Widget build(BuildContext context) {
    final trades = result.signals.take(10).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get('tradeSignals', isRussian: isRu),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...trades.map((signal) {
            final isBuy = signal.type == 'BUY';
            final signalLabel =
                isBuy ? (isRu ? 'КУПИТЬ' : 'BUY') : (isRu ? 'ПРОДАТЬ' : 'SELL');
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.lightCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isBuy ? AppColors.success : AppColors.danger)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      signalLabel,
                      style: TextStyle(
                        color: isBuy ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    Formatters.shortDate(signal.date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    Formatters.currency(signal.price),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (!isBuy && signal.profit != 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      Formatters.change(signal.profit),
                      style: TextStyle(
                        color: signal.profit >= 0
                            ? AppColors.success
                            : AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
