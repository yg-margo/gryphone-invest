import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/providers/market_provider.dart';
import '../../../data/providers/portfolio_provider.dart';
import '../../../data/services/ai_prediction_service.dart';
import 'models/stock_offer.dart';
import 'widgets/horizon_selector.dart';
import 'widgets/swipe_offer_stack.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  static const double _defaultOfferBudget = 5000;

  String _selectedHorizon = '30d';
  final Set<String> _consumedOfferIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRu = context.watch<LocaleProvider>().isRussian;
    final market = context.watch<MarketProvider>();

    final horizonLabels = [
      AppStrings.get('days7', isRussian: isRu),
      AppStrings.get('days30', isRussian: isRu),
      AppStrings.get('days90', isRussian: isRu),
    ];
    final horizonKeys = ['7d', '30d', '90d'];

    final allOffers = _buildPositiveOffers(
      predictions: market.predictions,
      market: market,
      horizonKey: _selectedHorizon,
    );

    final offers = allOffers
        .where((offer) => !_consumedOfferIds.contains(offer.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('aiPredictions', isRussian: isRu)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: market.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: HorizonSelector(
                    selectedKey: _selectedHorizon,
                    keys: horizonKeys,
                    labels: horizonLabels,
                    isDark: isDark,
                    onSelect: (key) {
                      if (key == _selectedHorizon) return;
                      setState(() {
                        _selectedHorizon = key;
                        _consumedOfferIds.clear();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SwipeOfferStack(
                      offers: offers,
                      isDark: isDark,
                      isRu: isRu,
                      onSwipeLeft: _handleSkip,
                      onSwipeRight: _handleBuy,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<StockOffer> _buildPositiveOffers({
    required List<AIPrediction> predictions,
    required MarketProvider market,
    required String horizonKey,
  }) {
    final offers = <StockOffer>[];

    for (final prediction in predictions) {
      final marketStock = market.getStock(prediction.symbol);
      if (marketStock == null) continue;

      final returnPct = _returnForHorizon(prediction, horizonKey);
      if (returnPct <= 0) continue;

      final suggestedShares = _suggestShares(
        price: marketStock.currentPrice,
        confidence: prediction.confidence,
      );

      offers.add(
        StockOffer(
          id: '${prediction.symbol}_$horizonKey',
          symbol: prediction.symbol,
          name: prediction.name,
          price: marketStock.currentPrice,
          targetPrice: _targetPriceForHorizon(prediction, horizonKey),
          returnPct: returnPct,
          confidence: prediction.confidence,
          reasoning: prediction.reasoning,
          suggestedShares: suggestedShares,
        ),
      );
    }

    offers.sort((a, b) => b.returnPct.compareTo(a.returnPct));
    return offers;
  }

  int _suggestShares({
    required double price,
    required double confidence,
  }) {
    if (price <= 0) return 1;

    final confidenceFactor = (confidence / 100).clamp(0.4, 0.95);
    final plannedBudget = _defaultOfferBudget * confidenceFactor;
    return max(1, (plannedBudget / price).floor());
  }

  double _returnForHorizon(AIPrediction prediction, String horizonKey) {
    switch (horizonKey) {
      case '7d':
        return prediction.change7d;
      case '90d':
        return prediction.change90d;
      case '30d':
      default:
        return prediction.change30d;
    }
  }

  double _targetPriceForHorizon(AIPrediction prediction, String horizonKey) {
    switch (horizonKey) {
      case '7d':
        return prediction.target7d;
      case '90d':
        return prediction.target90d;
      case '30d':
      default:
        return prediction.target30d;
    }
  }

  void _handleSkip(StockOffer offer) {
    setState(() {
      _consumedOfferIds.add(offer.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<LocaleProvider>().isRussian
              ? 'Пропущено: ${offer.symbol}'
              : 'Skipped: ${offer.symbol}',
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _handleBuy(StockOffer offer) {
    final portfolioProvider = context.read<PortfolioProvider>();
    final localeProvider = context.read<LocaleProvider>();
    final oldCash = portfolioProvider.portfolio.cash;

    portfolioProvider.addPosition(
      offer.symbol,
      offer.name,
      offer.suggestedShares.toDouble(),
      offer.price,
    );

    final didBuy = portfolioProvider.portfolio.cash < oldCash;

    if (didBuy) {
      setState(() {
        _consumedOfferIds.add(offer.id);
      });

      final cost = offer.price * offer.suggestedShares;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localeProvider.isRussian
                ? 'Куплено ${offer.suggestedShares} ${offer.symbol} за ${Formatters.currency(cost)}'
                : 'Bought ${offer.suggestedShares} ${offer.symbol} for ${Formatters.currency(cost)}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localeProvider.isRussian
              ? 'Недостаточно средств для покупки ${offer.symbol}'
              : 'Not enough cash to buy ${offer.symbol}',
        ),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}
