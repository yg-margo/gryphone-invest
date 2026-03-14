import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/stock.dart';
import '../../../data/models/stock_detail.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/providers/market_provider.dart';
import '../../../data/services/yahoo_finance_service.dart';
import '../../../data/services/company_descriptions.dart';
import '../portfolio/add_position_screen.dart';

class StockDetailScreen extends StatefulWidget {
  final Stock stock;
  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  int             _rangeIndex  = 2;
  StockChartData? _chartData;
  CompanyInfo?    _companyInfo;
  bool            _chartLoading  = true;
  bool            _infoLoading   = true;
  String?         _chartError;

  @override
  void initState() {
    super.initState();
    _loadChart();
    _loadCompanyInfo();
  }

  ChartRange get _currentRange => ChartRange.all[_rangeIndex];

  Future<void> _loadChart() async {
    setState(() { _chartLoading = true; _chartError = null; });
    try {
      final data = await YahooFinanceService.getChartData(
        symbol:   widget.stock.symbol,
        range:    _currentRange.range,
        interval: _currentRange.interval,
      );
      if (mounted) {
        setState(() { _chartData = data; _chartLoading = false; });
        if (data.currentPrice > 0) {
          context.read<MarketProvider>().updateStockPrice(
            widget.stock.symbol,
            data.currentPrice,
            change: data.change,
            changePercent: data.changePercent,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _chartError   = e.toString();
        _chartLoading = false;
      });
      }
    }
  }

  Future<void> _loadCompanyInfo() async {
    try {
      final info = await YahooFinanceService.getCompanyInfo(widget.stock.symbol);
      if (mounted) setState(() { _companyInfo = info; _infoLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _infoLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRu   = context.watch<LocaleProvider>().isRussian;
    final stock  = widget.stock;

    final marketStock   = context.watch<MarketProvider>().getStock(stock.symbol);
    final livePrice     = marketStock?.currentPrice ?? stock.currentPrice;
    final price         = _chartData?.currentPrice  ?? livePrice;
    final prevClose     = _chartData?.previousClose ?? (livePrice - (marketStock?.change ?? stock.change));
    final change        = price - prevClose;
    final changePct     = prevClose != 0 ? (change / prevClose) * 100 : stock.changePercent;
    final isPositive    = change >= 0;
    final lineColor     = isPositive ? AppColors.success : AppColors.danger;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(stock.symbol),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: _BuyBar(
        stock:    stock,
        isRu:     isRu,
        isDark:   isDark,
        price:    price,
        isPositive: isPositive,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [

          _PriceHeader(
            stock:      stock,
            price:      price,
            change:     change,
            changePct:  changePct,
            isPositive: isPositive,
            isDark:     isDark,
          ),

          _ChartSection(
            chartData:    _chartData,
            isLoading:    _chartLoading,
            error:        _chartError,
            rangeIndex:   _rangeIndex,
            isRu:         isRu,
            isDark:       isDark,
            lineColor:    lineColor,
            isPositive:   isPositive,
            onRangeChanged: (i) {
              setState(() => _rangeIndex = i);
              _loadChart();
            },
          ),

          const SizedBox(height: 16),

          if (_chartData != null)
            _MetricsRow(
              chartData: _chartData!,
              companyInfo: _companyInfo,
              isDark: isDark,
              isRu:   isRu,
            ),

          const SizedBox(height: 16),

          _AboutSection(
            info:      _companyInfo,
            isLoading: _infoLoading,
            isDark:    isDark,
            isRu:      isRu,
          ),
        ],
      ),
    );
  }
}

class _PriceHeader extends StatelessWidget {
  final Stock  stock;
  final double price;
  final double change;
  final double changePct;
  final bool   isPositive;
  final bool   isDark;

  const _PriceHeader({
    required this.stock,
    required this.price,
    required this.change,
    required this.changePct,
    required this.isPositive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stock.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(price),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize:   36,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: color, size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}  '
                '(${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color:      color,
                  fontSize:   14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final StockChartData? chartData;
  final bool            isLoading;
  final String?         error;
  final int             rangeIndex;
  final bool            isRu;
  final bool            isDark;
  final Color           lineColor;
  final bool            isPositive;
  final Function(int)   onRangeChanged;

  const _ChartSection({
    required this.chartData,
    required this.isLoading,
    required this.error,
    required this.rangeIndex,
    required this.isRu,
    required this.isDark,
    required this.lineColor,
    required this.isPositive,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          _RangeSelector(
            selectedIndex: rangeIndex,
            isDark:        isDark,
            isRu:          isRu,
            onSelect:      onRangeChanged,
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? _ChartError(isRu: isRu)
                    : chartData != null && chartData!.points.isNotEmpty
                        ? _LineChart(
                            chartData:  chartData!,
                            lineColor:  lineColor,
                            isDark:     isDark,
                            isPositive: isPositive,
                          )
                        : _ChartError(isRu: isRu),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final int          selectedIndex;
  final bool         isDark;
  final bool         isRu;
  final Function(int) onSelect;

  const _RangeSelector({
    required this.selectedIndex,
    required this.isDark,
    required this.isRu,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(ChartRange.all.length, (i) {
        final range      = ChartRange.all[i];
        final label      = isRu ? range.labelRu : range.label;
        final isSelected = i == selectedIndex;

        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize:   13,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _LineChart extends StatelessWidget {
  final StockChartData chartData;
  final Color          lineColor;
  final bool           isDark;
  final bool           isPositive;

  const _LineChart({
    required this.chartData,
    required this.lineColor,
    required this.isDark,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final points = chartData.points;
    final spots  = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.price))
        .toList();

    final prices = points.map((p) => p.price).toList();
    final minY   = prices.reduce((a, b) => a < b ? a : b) * 0.997;
    final maxY   = prices.reduce((a, b) => a > b ? a : b) * 1.003;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show:               true,
          drawVerticalLine:   false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color:       isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles:   true,
              reservedSize: 62,
              getTitlesWidget: (val, _) => Text(
                '\$${val.toStringAsFixed(val >= 100 ? 0 : 2)}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkSubtext : AppColors.lightSubtext,
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
            spots:    spots,
            isCurved: true,
            color:    lineColor,
            barWidth: 2.5,
            dotData:  const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withOpacity(0.22),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.darkElevated : AppColors.lightCard,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '\$${s.y.toStringAsFixed(2)}',
                      TextStyle(
                        color:      lineColor,
                        fontWeight: FontWeight.w700,
                        fontSize:   12,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ChartError extends StatelessWidget {
  final bool isRu;
  const _ChartError({required this.isRu});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off_outlined,
              color: AppColors.primaryLight, size: 36),
          const SizedBox(height: 8),
          Text(
            isRu ? 'Не удалось загрузить график' : 'Failed to load chart',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final StockChartData chartData;
  final CompanyInfo?   companyInfo;
  final bool           isDark;
  final bool           isRu;

  const _MetricsRow({
    required this.chartData,
    required this.companyInfo,
    required this.isDark,
    required this.isRu,
  });

  String _formatCap(double? cap) {
    if (cap == null) return '—';
    if (cap >= 1e12) return '\$${(cap / 1e12).toStringAsFixed(2)}T';
    if (cap >= 1e9)  return '\$${(cap / 1e9).toStringAsFixed(2)}B';
    if (cap >= 1e6)  return '\$${(cap / 1e6).toStringAsFixed(2)}M';
    return '\$$cap';
  }

  @override
  Widget build(BuildContext context) {
    final info = companyInfo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _MetricCell(
                  label: isRu ? 'Пред. закрытие' : 'Prev Close',
                  value: '\$${chartData.previousClose.toStringAsFixed(2)}',
                  isDark: isDark,
                ),
                _MetricCell(
                  label: isRu ? 'Тек. цена' : 'Current',
                  value: '\$${chartData.currentPrice.toStringAsFixed(2)}',
                  isDark: isDark,
                ),
                _MetricCell(
                  label: isRu ? 'Кап-я' : 'Mkt Cap',
                  value: _formatCap(info?.marketCap),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MetricCell(
                  label: isRu ? '52н. макс' : '52W High',
                  value: info?.week52High != null
                      ? '\$${info!.week52High!.toStringAsFixed(2)}' : '—',
                  isDark: isDark,
                  valueColor: AppColors.success,
                ),
                _MetricCell(
                  label: isRu ? '52н. мин' : '52W Low',
                  value: info?.week52Low != null
                      ? '\$${info!.week52Low!.toStringAsFixed(2)}' : '—',
                  isDark: isDark,
                  valueColor: AppColors.danger,
                ),
                _MetricCell(
                  label: 'P/E',
                  value: info?.peRatio != null
                      ? info!.peRatio!.toStringAsFixed(2) : '—',
                  isDark: isDark,
                ),
              ],
            ),
            if (info?.beta != null || info?.dividendYield != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _MetricCell(
                    label: 'Beta',
                    value: info?.beta != null
                        ? info!.beta!.toStringAsFixed(2) : '—',
                    isDark: isDark,
                  ),
                  _MetricCell(
                    label: isRu ? 'Дивиденды' : 'Dividend',
                    value: info?.dividendYield != null
                        ? '${(info!.dividendYield! * 100).toStringAsFixed(2)}%'
                        : '—',
                    isDark: isDark,
                  ),
                  _MetricCell(
                    label: isRu ? 'Сотрудники' : 'Employees',
                    value: info?.employees != null
                        ? _formatEmployees(info!.employees!) : '—',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatEmployees(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

class _MetricCell extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    isDark;
  final Color?  valueColor;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatefulWidget {
  final CompanyInfo? info;
  final bool         isLoading;
  final bool         isDark;
  final bool         isRu;

  const _AboutSection({
    required this.info,
    required this.isLoading,
    required this.isDark,
    required this.isRu,
  });

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final info   = widget.info;
    final isRu   = widget.isRu;
    final isDark = widget.isDark;

    final desc = info == null
        ? ''
        : (info.description == '—' ||
                info.description == 'No description available.' ||
                info.description.isEmpty)
            ? CompanyDescriptions.get(info.symbol, isRussian: isRu)
            : info.description;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRu ? 'О компании' : 'About',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            if (widget.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (info != null) ...[
              if (info.sector != '—') ...[
                _InfoRow(
                  icon:  Icons.business_outlined,
                  label: isRu ? 'Сектор' : 'Sector',
                  value: info.sector,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
              ],
              if (info.industry != '—') ...[
                _InfoRow(
                  icon:  Icons.category_outlined,
                  label: isRu ? 'Отрасль' : 'Industry',
                  value: info.industry,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
              ],
              if (info.website != '—') ...[
                _InfoRow(
                  icon:  Icons.link_rounded,
                  label: isRu ? 'Сайт' : 'Website',
                  value: info.website,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
              ],

              if (desc.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: _expanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Text(
                          desc,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.55),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        secondChild: Text(
                          desc,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.55),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _expanded
                            ? (isRu ? 'Скрыть' : 'Show less')
                            : (isRu ? 'Читать далее' : 'Read more'),
                        style: const TextStyle(
                          color:      AppColors.primaryLight,
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else
              Text(
                isRu
                    ? 'Информация недоступна'
                    : 'Information not available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final bool     isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BuyBar extends StatelessWidget {
  final Stock  stock;
  final bool   isRu;
  final bool   isDark;
  final double price;
  final bool   isPositive;

  const _BuyBar({
    required this.stock,
    required this.isRu,
    required this.isDark,
    required this.price,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left:   16,
        right:  16,
        top:    12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRu ? 'Цена' : 'Price',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12),
              ),
              Text(
                Formatters.currency(price),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isPositive ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddPositionScreen(
                    preselectedSymbol: stock.symbol,
                  ),
                ),
              ),
              icon:  const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: Text(isRu ? 'Купить' : 'Buy'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
