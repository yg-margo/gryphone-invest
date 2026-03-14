import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/position.dart';

class PositionTile extends StatelessWidget {
  final Position position;
  final bool isDark;
  final bool isRu;
  final VoidCallback onSell;

  const PositionTile({
    super.key,
    required this.position,
    required this.isDark,
    required this.isRu,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    position.symbol.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.symbol,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 15),
                    ),
                    Text(
                      '${position.shares.toStringAsFixed(4)} '
                      '${AppStrings.get('shares', isRussian: isRu)} @ '
                      '${Formatters.currency(position.avgCost)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(position.currentValue),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (position.isPositive
                              ? AppColors.success
                              : AppColors.danger)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      Formatters.percentRaw(position.gainPercent),
                      style: TextStyle(
                        color: position.isPositive
                            ? AppColors.success
                            : AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: AppStrings.get('avgCost', isRussian: isRu),
                  value: Formatters.currency(position.avgCost),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniInfo(
                  label: AppStrings.get('currentPrice', isRussian: isRu),
                  value: Formatters.currency(position.currentPrice),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniInfo(
                  label: AppStrings.get('pnl', isRussian: isRu),
                  value: Formatters.change(position.gain),
                  isDark: isDark,
                  valueColor: position.isPositive
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showSellDialog(context),
              icon: const Icon(Icons.sell, size: 16),
              label: Text(AppStrings.get('sellPosition', isRussian: isRu)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSellDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${AppStrings.get('sell', isRussian: isRu)} ${position.symbol}?',
        ),
        content: Text(
          '${position.shares.toStringAsFixed(4)} '
          '${AppStrings.get('shares', isRussian: isRu)} '
          '@ ${Formatters.currency(position.currentPrice)}.\n\n'
          '${isRu ? 'Вы получите' : 'You will receive'}: '
          '${Formatters.currency(position.currentValue)}.\n\n'
          '${AppStrings.get('pnl', isRussian: isRu)}: '
          '${Formatters.change(position.gain)} '
          '(${Formatters.percentRaw(position.gainPercent)})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('cancel', isRussian: isRu)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSell();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppStrings.get('sell', isRussian: isRu)} '
                    '${position.symbol} — '
                    '${Formatters.currency(position.currentValue)}',
                  ),
                  backgroundColor: position.isPositive
                      ? AppColors.success
                      : AppColors.danger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: Text(AppStrings.get('sell', isRussian: isRu)),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _MiniInfo({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
