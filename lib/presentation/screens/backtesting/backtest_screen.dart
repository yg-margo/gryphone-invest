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
import '../../../responsive.dart';

class BacktestScreen extends StatefulWidget {
  const BacktestScreen({super.key});
  @override
  State<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  String _strategy = AppConstants.strategies.first, _symbol = 'AAPL';
  int _days = 90;
  double _capital = 10000;
  BacktestResult? _result;
  bool _running = false;
  final _capitalCtrl = TextEditingController(text: '10000');

  String _rangeFor(int days) => days <= 30 ? '3mo' : days <= 90 ? '6mo' : days <= 180 ? '1y' : '2y';

  Future<void> _run() async {
    final isRu = context.read<LocaleProvider>().isRussian;
    final stock = context.read<MarketProvider>().getStock(_symbol);
    if (stock == null) return;
    setState(() => _running = true);
    try {
      final history = await YahooFinanceService.getHistoricalCloses(symbol: _symbol, range: _rangeFor(_days), interval: '1d');
      final sliced = history.length > _days ? history.sublist(history.length - _days) : history;
      final result = BacktestService.runBacktest(strategy: _strategy, symbol: _symbol, initialCapital: _capital, days: sliced.length, priceHistory: sliced);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isRu ? 'Не удалось загрузить данные для бэктеста' : 'Failed to load backtest data'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  void dispose() { _capitalCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRu = context.watch<LocaleProvider>().isRussian;
    final symbols = context.watch<MarketProvider>().stocks.map((s) => s.symbol).toList();
    final desktop = AppBreakpoints.isDesktop(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('backtesting', isRussian: isRu))),
      body: SingleChildScrollView(
        padding: AppBreakpoints.pagePadding(context),
        child: ResponsiveContent(
          child: desktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 4, child: _configCard(isDark, isRu, symbols)), const SizedBox(width: 20), Expanded(flex: 6, child: _resultPanel(isDark, isRu))])
              : Column(children: [_configCard(isDark, isRu, symbols), const SizedBox(height: 16), _resultPanel(isDark, isRu)]),
        ),
      ),
    );
  }

  Widget _configCard(bool isDark, bool isRu, List<String> symbols) {
    final strategyNames = AppStrings.strategyNames(isRu);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.get('configuration', isRussian: isRu), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text(AppStrings.get('strategy', isRussian: isRu)), const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: _strategy, items: AppConstants.strategies.map((e) => DropdownMenuItem(value: e, child: Text(strategyNames[e] ?? e, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() => _strategy = v!)),
        const SizedBox(height: 12),
        Text(AppStrings.get('symbol', isRussian: isRu)), const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: _symbol, items: symbols.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _symbol = v!)),
        const SizedBox(height: 12),
        Text(AppStrings.get('period', isRussian: isRu)), const SizedBox(height: 8),
        Wrap(spacing: 8, children: [30, 60, 90].map((d) => ChoiceChip(label: Text('$d ${isRu ? 'дн.' : 'd'}'), selected: _days == d, onSelected: (_) => setState(() => _days = d))).toList()),
        const SizedBox(height: 12),
        Text(AppStrings.get('initialCapital', isRussian: isRu)), const SizedBox(height: 8),
        TextField(controller: _capitalCtrl, keyboardType: TextInputType.number, onChanged: (v) => _capital = double.tryParse(v) ?? 10000, decoration: const InputDecoration(prefixIcon: Icon(Icons.attach_money), hintText: '10000')),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _running ? null : _run, icon: _running ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow), label: Text(_running ? AppStrings.get('runningBacktest', isRussian: isRu) : AppStrings.get('runBacktest', isRussian: isRu))))
      ]),
    );
  }

  Widget _resultPanel(bool isDark, bool isRu) {
    if (_result == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppStrings.get('results', isRussian: isRu), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 12), Text(isRu ? 'Выберите параметры слева и запустите бэктест.' : 'Choose parameters and run a backtest to see results.')]),
      );
    }
    final r = _result!;
    final spots = r.equityCurve.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final minY = r.equityCurve.reduce((a, b) => a < b ? a : b) * .98;
    final maxY = r.equityCurve.reduce((a, b) => a > b ? a : b) * 1.02;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(AppStrings.get('results', isRussian: isRu), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const Spacer(), Chip(label: Text(r.isProfitable ? AppStrings.get('profitable', isRussian: isRu) : AppStrings.get('loss', isRussian: isRu), style: TextStyle(color: r.isProfitable ? AppColors.success : AppColors.danger)), backgroundColor: (r.isProfitable ? AppColors.success : AppColors.danger).withOpacity(.12))]),
          const SizedBox(height: 14),
          GridView.count(crossAxisCount: AppBreakpoints.columns(context, mobile: 2, tablet: 3, desktop: 3), shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2, children: [
            _metric(AppStrings.get('totalReturn', isRussian: isRu), Formatters.percentRaw(r.totalReturn), r.totalReturn >= 0),
            _metric(AppStrings.get('annualReturn', isRussian: isRu), Formatters.percentRaw(r.annualizedReturn), r.annualizedReturn >= 0),
            _metric(AppStrings.get('maxDrawdown', isRussian: isRu), '-${r.maxDrawdown.toStringAsFixed(2)}%', false),
            _metric(AppStrings.get('sharpeRatio', isRussian: isRu), r.sharpeRatio.toStringAsFixed(2), r.sharpeRatio >= 1),
            _metric(AppStrings.get('winRate', isRussian: isRu), '${r.winRate.toStringAsFixed(1)}%', r.winRate >= 50),
            _metric(AppStrings.get('finalCapital', isRussian: isRu), Formatters.currency(r.finalCapital), r.isProfitable),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppStrings.get('equityCurve', isRussian: isRu), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 16), SizedBox(height: 220, child: LineChart(LineChartData(minY: minY, maxY: maxY, borderData: FlBorderData(show: false), gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)), titlesData: const FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))), lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: r.isProfitable ? AppColors.success : AppColors.danger, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [(r.isProfitable ? AppColors.success : AppColors.danger).withOpacity(.2), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)))]))) ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppStrings.get('tradeSignals', isRussian: isRu), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 12), ...r.signals.take(10).map((s) => ListTile(contentPadding: EdgeInsets.zero, title: Text('${s.type} • ${Formatters.shortDate(s.date)}'), subtitle: Text(Formatters.currency(s.price)), trailing: s.type == 'SELL' ? Text(Formatters.change(s.profit), style: TextStyle(color: s.profit >= 0 ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w700)) : null))]),
      ),
    ]);
  }

  Widget _metric(String label, String value, bool positive) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: (positive ? AppColors.success : AppColors.danger).withOpacity(.08), borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(fontSize: 11)), const SizedBox(height: 4), Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: positive ? AppColors.success : AppColors.danger))]),
  );
}
