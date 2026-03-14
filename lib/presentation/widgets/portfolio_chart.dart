import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class PortfolioMiniChart extends StatefulWidget {
  final List<double> history;
  final bool isRu;
  const PortfolioMiniChart({super.key, required this.history,this.isRu = true});

  @override
  State<PortfolioMiniChart> createState() => _PortfolioMiniChartState();
}

class _PortfolioMiniChartState extends State<PortfolioMiniChart> {
  int _selectedRange = 2;
  final ranges = [7, 30, 90];
  final rangeLabels = ['1W', '1M', '3M'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = ranges[_selectedRange];
    final data = widget.history.length >= days
        ? widget.history.sublist(widget.history.length - days)
        : widget.history;

    final isPositive = data.last >= data.first;
    final lineColor = isPositive ? AppColors.success : AppColors.danger;

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final minY = data.reduce((a, b) => a < b ? a : b) * 0.995;
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.005;

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
              Text('Performance', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: List.generate(rangeLabels.length, (i) {
                  final isSelected = i == _selectedRange;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRange = i),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkElevated : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rangeLabels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withOpacity(0.2),
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
                        .map((s) => LineTooltipItem(
                              Formatters.currency(s.y),
                              TextStyle(
                                color: lineColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ))
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
