import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_strings.dart';
import '../../data/services/ai_prediction_service.dart';

class PredictionCard extends StatelessWidget {
  final AIPrediction prediction;
  final String horizonKey;
  final bool isDark;
  final bool isRu;

  const PredictionCard({
    super.key,
    required this.prediction,
    required this.horizonKey,
    required this.isDark,
    required this.isRu,
  });

  Color get _sentimentColor {
    switch (prediction.sentiment) {
      case 'Bullish':
        return AppColors.success;
      case 'Bearish':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String get _sentimentLabel {
    switch (prediction.sentiment) {
      case 'Bullish':
        return AppStrings.get('bullish', isRussian: isRu);
      case 'Bearish':
        return AppStrings.get('bearish', isRussian: isRu);
      default:
        return AppStrings.get('neutral', isRussian: isRu);
    }
  }

  double get _targetChange {
    switch (horizonKey) {
      case '7d':
        return prediction.change7d;
      case '90d':
        return prediction.change90d;
      default:
        return prediction.change30d;
    }
  }

  double get _targetPrice {
    switch (horizonKey) {
      case '7d':
        return prediction.target7d;
      case '90d':
        return prediction.target90d;
      default:
        return prediction.target30d;
    }
  }

  String get _horizonLabel {
    switch (horizonKey) {
      case '7d':
        return AppStrings.get('days7', isRussian: isRu);
      case '90d':
        return AppStrings.get('days90', isRussian: isRu);
      default:
        return AppStrings.get('days30', isRussian: isRu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _targetChange >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    prediction.symbol.substring(0, 1),
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
                      prediction.symbol,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      prediction.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _sentimentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _sentimentLabel,
                  style: TextStyle(
                    color: _sentimentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              _PriceBox(
                label: AppStrings.get('current', isRussian: isRu),
                price: prediction.currentPrice,
                isDark: isDark,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.primaryLight),
              ),
              _PriceBox(
                label: '${AppStrings.get('current', isRussian: isRu) == 'Текущая' ? 'Цель' : 'Target'} ($_horizonLabel)',
                price: _targetPrice,
                change: _targetChange,
                isDark: isDark,
                isTarget: true,
                isPositive: isPositive,
              ),
            ],
          ),
          const SizedBox(height: 14),

          _ConfidenceBar(
            confidence: prediction.confidence,
            isDark: isDark,
            isRu: isRu,
          ),
          const SizedBox(height: 12),

          Text(
            prediction.reasoning,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: prediction.signals.map((signal) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  signal,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryLight,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final double price;
  final double? change;
  final bool isDark;
  final bool isTarget;
  final bool isPositive;

  const _PriceBox({
    required this.label,
    required this.price,
    this.change,
    required this.isDark,
    this.isTarget = false,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isTarget
              ? (isPositive ? AppColors.success : AppColors.danger)
                  .withOpacity(0.1)
              : (isDark ? AppColors.darkElevated : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: isTarget
              ? Border.all(
                  color: (isPositive ? AppColors.success : AppColors.danger)
                      .withOpacity(0.3),
                )
              : null,
        ),
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
            const SizedBox(height: 4),
            Text(
              Formatters.currency(price),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isTarget
                    ? (isPositive ? AppColors.success : AppColors.danger)
                    : null,
              ),
            ),
            if (change != null)
              Text(
                Formatters.percentRaw(change!),
                style: TextStyle(
                  fontSize: 11,
                  color: isPositive ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  final bool isDark;
  final bool isRu;

  const _ConfidenceBar({
    required this.confidence,
    required this.isDark,
    required this.isRu,
  });

  Color get _barColor {
    if (confidence >= 75) return AppColors.success;
    if (confidence >= 55) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.get('aiConfidence', isRussian: isRu),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12),
            ),
            Text(
              '${confidence.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence / 100,
            minHeight: 6,
            backgroundColor:
                isDark ? AppColors.darkElevated : AppColors.lightCard,
            valueColor: AlwaysStoppedAnimation<Color>(_barColor),
          ),
        ),
      ],
    );
  }
}
