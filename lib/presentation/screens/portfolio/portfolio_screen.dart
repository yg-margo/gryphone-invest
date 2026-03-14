import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/portfolio_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../responsive.dart';
import '../../widgets/position_tile.dart';
import 'add_position_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRu = context.watch<LocaleProvider>().isRussian;
    final provider = context.watch<PortfolioProvider>();
    final portfolio = provider.portfolio;
    final isDesktop = AppBreakpoints.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('portfolio', isRussian: isRu)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(context, provider, isRu),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPositionScreen())),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.get('addPosition', isRussian: isRu)),
      ),
      body: portfolio.positions.isEmpty
          ? _EmptyPortfolio(isDark: isDark, isRu: isRu)
          : ListView(
              padding: AppBreakpoints.pagePadding(context),
              children: [
                ResponsiveContent(
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  _AllocationChart(portfolio: portfolio, isDark: isDark, isRu: isRu),
                                  const SizedBox(height: 16),
                                  _PortfolioStats(portfolio: portfolio, isRu: isRu),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 6,
                              child: _PositionsCard(portfolio: portfolio, isDark: isDark, isRu: isRu, provider: provider),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _AllocationChart(portfolio: portfolio, isDark: isDark, isRu: isRu),
                            const SizedBox(height: 20),
                            _PortfolioStats(portfolio: portfolio, isRu: isRu),
                            const SizedBox(height: 20),
                            _PositionsCard(portfolio: portfolio, isDark: isDark, isRu: isRu, provider: provider),
                          ],
                        ),
                ),
                const SizedBox(height: 96),
              ],
            ),
    );
  }

  void _showResetDialog(BuildContext context, PortfolioProvider provider, bool isRu) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('resetPortfolioTitle', isRussian: isRu)),
        content: Text(AppStrings.get('resetPortfolioSubtitle', isRussian: isRu)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get('cancel', isRussian: isRu))),
          ElevatedButton(
            onPressed: () {
              provider.resetPortfolio();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.get('resetSuccess', isRussian: isRu)),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(AppStrings.get('reset', isRussian: isRu)),
          ),
        ],
      ),
    );
  }
}

class _PositionsCard extends StatelessWidget {
  final dynamic portfolio;
  final bool isDark;
  final bool isRu;
  final PortfolioProvider provider;

  const _PositionsCard({required this.portfolio, required this.isDark, required this.isRu, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.get('positions', isRussian: isRu), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...portfolio.positions.map<Widget>((pos) => PositionTile(
                position: pos,
                isDark: isDark,
                isRu: isRu,
                onSell: () => provider.removePosition(pos.id),
              )),
        ],
      ),
    );
  }
}

class _EmptyPortfolio extends StatelessWidget {
  final bool isDark;
  final bool isRu;

  const _EmptyPortfolio({required this.isDark, required this.isRu});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 20),
          Text(AppStrings.get('noPositions', isRussian: isRu), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(AppStrings.get('noPositionsSubtitle', isRussian: isRu), style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AllocationChart extends StatelessWidget {
  final dynamic portfolio;
  final bool isDark;
  final bool isRu;

  const _AllocationChart({required this.portfolio, required this.isDark, required this.isRu});

  @override
  Widget build(BuildContext context) {
    final positions = portfolio.positions;
    final total = portfolio.investedValue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.get('allocation', isRussian: isRu), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  ...List.generate(positions.length, (i) {
                    final pct = total > 0 ? positions[i].currentValue / total : 0.0;
                    return Expanded(
                      flex: ((pct * 100).round()).clamp(1, 100),
                      child: Container(color: AppColors.chartColors[i % AppColors.chartColors.length]),
                    );
                  }),
                  if (portfolio.cash > 0)
                    Expanded(
                      flex: (((portfolio.cash / portfolio.totalValue) * 100).round()).clamp(1, 100),
                      child: Container(color: isDark ? AppColors.darkElevated : AppColors.lightBorder),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ...List.generate(positions.length, (i) {
                final pct = total > 0 ? (positions[i].currentValue / total * 100) : 0.0;
                return _LegendItem(color: AppColors.chartColors[i % AppColors.chartColors.length], label: positions[i].symbol, value: '${pct.toStringAsFixed(1)}%');
              }),
              _LegendItem(
                color: isDark ? AppColors.darkElevated : AppColors.lightBorder,
                label: AppStrings.get('cash', isRussian: isRu),
                value: '${((portfolio.cash / portfolio.totalValue) * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$label $value', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
    ]);
  }
}

class _PortfolioStats extends StatelessWidget {
  final dynamic portfolio;
  final bool isRu;

  const _PortfolioStats({required this.portfolio, required this.isRu});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900 ? 3 : width >= 560 ? 2 : 1;
        final childAspectRatio = crossAxisCount == 3
            ? 2.4
            : crossAxisCount == 2
                ? 2.7
                : 4.2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
          children: [
            _MiniStat(
              label: AppStrings.get('invested', isRussian: isRu),
              value: Formatters.compactCurrency(portfolio.totalCost),
            ),
            _MiniStat(
              label: AppStrings.get('marketValue', isRussian: isRu),
              value: Formatters.compactCurrency(portfolio.investedValue),
            ),
            _MiniStat(
              label: AppStrings.get('pnl', isRussian: isRu),
              value: Formatters.currency(portfolio.totalGain),
              isColored: true,
              isPositive: portfolio.isPositive,
            ),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isColored;
  final bool isPositive;

  const _MiniStat({required this.label, required this.value, this.isColored = false, this.isPositive = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isColored ? (isPositive ? AppColors.success : AppColors.danger) : null,
            ),
          ),
        ],
      ),
    );
  }
}
