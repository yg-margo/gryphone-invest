import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../models/stock_offer.dart';

class SwipeOfferStack extends StatelessWidget {
  final List<StockOffer> offers;
  final bool isDark;
  final bool isRu;
  final ValueChanged<StockOffer> onSwipeLeft;
  final ValueChanged<StockOffer> onSwipeRight;

  const SwipeOfferStack({
    super.key,
    required this.offers,
    required this.isDark,
    required this.isRu,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return _NoOffersCard(isRu: isRu, isDark: isDark);
    }

    final top = offers.first;
    final second = offers.length > 1 ? offers[1] : null;

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (second != null)
                Transform.scale(
                  scale: 0.95,
                  child: Opacity(
                    opacity: 0.55,
                    child: _OfferCard(
                      offer: second,
                      isDark: isDark,
                      isRu: isRu,
                      isPreview: true,
                    ),
                  ),
                ),
              Dismissible(
                key: ValueKey(top.id),
                direction: DismissDirection.horizontal,
                background: _SwipeBackground(isDark: isDark, isRu: isRu),
                secondaryBackground:
                    _SwipeBackground(isDark: isDark, isRu: isRu, isBuy: false),
                onDismissed: (direction) {
                  if (direction == DismissDirection.startToEnd) {
                    onSwipeRight(top);
                  } else {
                    onSwipeLeft(top);
                  }
                },
                child: _OfferCard(
                  offer: top,
                  isDark: isDark,
                  isRu: isRu,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isRu
              ? 'Свайп вправо — купить, влево — пропустить'
              : 'Swipe right to buy, left to skip',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final StockOffer offer;
  final bool isDark;
  final bool isRu;
  final bool isPreview;

  const _OfferCard({
    required this.offer,
    required this.isDark,
    required this.isRu,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    offer.symbol.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
                      offer.symbol,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      offer.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${offer.returnPct.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _OfferMetricRow(
            leftLabel: isRu ? 'Текущая цена' : 'Current price',
            leftValue: Formatters.currency(offer.price),
            rightLabel: isRu ? 'Цель' : 'Target',
            rightValue: Formatters.currency(offer.targetPrice),
          ),
          const SizedBox(height: 12),
          _OfferMetricRow(
            leftLabel: isRu ? 'Кол-во к покупке' : 'Suggested qty',
            leftValue: '${offer.suggestedShares}',
            rightLabel: isRu ? 'Уверенность' : 'Confidence',
            rightValue: '${offer.confidence.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 14),
          Text(
            isRu ? 'Почему это интересно:' : 'Why this idea:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              offer.reasoning,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
              maxLines: isPreview ? 3 : 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferMetricRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _OfferMetricRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OfferMetric(label: leftLabel, value: leftValue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _OfferMetric(label: rightLabel, value: rightValue),
        ),
      ],
    );
  }
}

class _OfferMetric extends StatelessWidget {
  final String label;
  final String value;

  const _OfferMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final bool isDark;
  final bool isRu;
  final bool isBuy;

  const _SwipeBackground({
    required this.isDark,
    required this.isRu,
    this.isBuy = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBuy ? AppColors.success : AppColors.danger;
    final icon = isBuy ? Icons.shopping_bag_rounded : Icons.skip_next_rounded;
    final label =
        isBuy ? (isRu ? 'Купить' : 'Buy') : (isRu ? 'Пропустить' : 'Skip');
    final alignment = isBuy ? Alignment.centerLeft : Alignment.centerRight;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.28 : 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isBuy) ...[
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(icon, color: color),
          if (isBuy) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoOffersCard extends StatelessWidget {
  final bool isRu;
  final bool isDark;

  const _NoOffersCard({required this.isRu, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sentiment_neutral_rounded,
            size: 42,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 12),
          Text(
            isRu
                ? 'Сейчас нет позитивных идей для выбранного горизонта'
                : 'No positive-return ideas for this horizon right now',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            isRu
                ? 'Измените горизонт, чтобы увидеть другие предложения.'
                : 'Switch horizon to see other offers.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
