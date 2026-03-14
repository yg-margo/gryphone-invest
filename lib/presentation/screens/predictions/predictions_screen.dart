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
import '../../../responsive.dart';
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
    final allOffers = _buildPositiveOffers(predictions: market.predictions, market: market, horizonKey: _selectedHorizon);
    final offers = allOffers.where((offer) => !_consumedOfferIds.contains(offer.id)).toList();
    final desktop = AppBreakpoints.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('aiPredictions', isRussian: isRu)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [Icon(Icons.auto_awesome, color: Colors.white, size: 14), SizedBox(width: 4), Text('AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]),
            ),
          )
        ],
      ),
      body: market.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: AppBreakpoints.pagePadding(context),
              child: ResponsiveContent(
                child: Column(
                  children: [
                    HorizonSelector(selectedKey: _selectedHorizon, keys: horizonKeys, labels: horizonLabels, isDark: isDark, onSelect: (key) { if (key == _selectedHorizon) return; setState(() { _selectedHorizon = key; _consumedOfferIds.clear(); }); }),
                    const SizedBox(height: 16),
                    Expanded(
                      child: desktop ? _DesktopOffersGrid(offers: offers, isDark: isDark, isRu: isRu, onSkip: _handleSkip, onBuy: _handleBuy) : SwipeOfferStack(offers: offers, isDark: isDark, isRu: isRu, onSwipeLeft: _handleSkip, onSwipeRight: _handleBuy),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<StockOffer> _buildPositiveOffers({required List<AIPrediction> predictions, required MarketProvider market, required String horizonKey}) {
    final offers = <StockOffer>[];
    for (final prediction in predictions) {
      final marketStock = market.getStock(prediction.symbol);
      if (marketStock == null) continue;
      final returnPct = _returnForHorizon(prediction, horizonKey);
      if (returnPct <= 0) continue;
      final suggestedShares = _suggestShares(price: marketStock.currentPrice, confidence: prediction.confidence);
      offers.add(StockOffer(id: '${prediction.symbol}_$horizonKey', symbol: prediction.symbol, name: prediction.name, price: marketStock.currentPrice, targetPrice: _targetPriceForHorizon(prediction, horizonKey), returnPct: returnPct, confidence: prediction.confidence, reasoning: prediction.reasoning, suggestedShares: suggestedShares));
    }
    offers.sort((a, b) => b.returnPct.compareTo(a.returnPct));
    return offers;
  }

  int _suggestShares({required double price, required double confidence}) {
    if (price <= 0) return 1;
    final confidenceFactor = (confidence / 100).clamp(0.4, 0.95);
    return max(1, ((_defaultOfferBudget * confidenceFactor) / price).floor());
  }

  double _returnForHorizon(AIPrediction prediction, String horizonKey) => switch (horizonKey) { '7d' => prediction.change7d, '90d' => prediction.change90d, _ => prediction.change30d };
  double _targetPriceForHorizon(AIPrediction prediction, String horizonKey) => switch (horizonKey) { '7d' => prediction.target7d, '90d' => prediction.target90d, _ => prediction.target30d };

  void _handleSkip(StockOffer offer) {
    setState(() => _consumedOfferIds.add(offer.id));
  }

  void _handleBuy(StockOffer offer) {
    final portfolioProvider = context.read<PortfolioProvider>();
    final localeProvider = context.read<LocaleProvider>();
    final oldCash = portfolioProvider.portfolio.cash;
    portfolioProvider.addPosition(offer.symbol, offer.name, offer.suggestedShares.toDouble(), offer.price);
    final didBuy = portfolioProvider.portfolio.cash < oldCash;
    if (didBuy) {
      setState(() => _consumedOfferIds.add(offer.id));
      final cost = offer.price * offer.suggestedShares;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localeProvider.isRussian ? 'Куплено ${offer.suggestedShares} ${offer.symbol} за ${Formatters.currency(cost)}' : 'Bought ${offer.suggestedShares} ${offer.symbol} for ${Formatters.currency(cost)}'), backgroundColor: AppColors.success));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localeProvider.isRussian ? 'Недостаточно средств для покупки ${offer.symbol}' : 'Not enough cash to buy ${offer.symbol}'), backgroundColor: AppColors.danger));
  }
}

class _DesktopOffersGrid extends StatelessWidget {
  final List<StockOffer> offers;
  final bool isDark;
  final bool isRu;
  final ValueChanged<StockOffer> onSkip;
  final ValueChanged<StockOffer> onBuy;
  const _DesktopOffersGrid({required this.offers, required this.isDark, required this.isRu, required this.onSkip, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return _EmptyOffers(isRu: isRu, isDark: isDark);
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1400 ? 3 : 2;
    final aspectRatio = cols == 3 ? 0.82 : 0.90;
    return GridView.builder(
      itemCount: offers.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, index) => _OfferGridCard(
        offer: offers[index],
        isDark: isDark,
        isRu: isRu,
        onSkip: () => onSkip(offers[index]),
        onBuy: () => onBuy(offers[index]),
      ),
    );
  }
}

class _OfferGridCard extends StatelessWidget {
  final StockOffer offer;
  final bool isDark;
  final bool isRu;
  final VoidCallback onSkip;
  final VoidCallback onBuy;
  const _OfferGridCard({required this.offer, required this.isDark, required this.isRu, required this.onSkip, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightSurface, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primary.withOpacity(.15), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(offer.symbol.substring(0, 1), style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 16)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(offer.symbol, style: Theme.of(context).textTheme.titleLarge), Text(offer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium)])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.success.withOpacity(.15), borderRadius: BorderRadius.circular(10)), child: Text('+${offer.returnPct.toStringAsFixed(2)}%', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 16),
        _MetricBox(label: isRu ? 'Текущая цена' : 'Current price', value: Formatters.currency(offer.price)),
        const SizedBox(height: 8),
        _MetricBox(label: isRu ? 'Цель' : 'Target', value: Formatters.currency(offer.targetPrice)),
        const SizedBox(height: 8),
        _MetricBox(label: isRu ? 'Кол-во к покупке' : 'Suggested qty', value: '${offer.suggestedShares}'),
        const SizedBox(height: 8),
        _MetricBox(label: isRu ? 'Уверенность' : 'Confidence', value: '${offer.confidence.toStringAsFixed(1)}%'),
        const SizedBox(height: 12),
        Text(isRu ? 'Почему это интересно:' : 'Why this idea:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        Expanded(child: Text(offer.reasoning, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45), maxLines: 6, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compactActions = constraints.maxWidth < 320;
            if (compactActions) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: onSkip,
                    child: Text(isRu ? 'Пропустить' : 'Skip'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: onBuy,
                    child: Text(isRu ? 'Купить' : 'Buy'),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSkip,
                    child: Text(isRu ? 'Пропустить' : 'Skip'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBuy,
                    child: Text(isRu ? 'Купить' : 'Buy'),
                  ),
                ),
              ],
            );
          },
        ),
      ]),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  const _MetricBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(.08), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)), const SizedBox(height: 3), Text(value, style: Theme.of(context).textTheme.titleMedium)]),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  final bool isRu;
  final bool isDark;
  const _EmptyOffers({required this.isRu, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightSurface, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.sentiment_neutral_rounded, size: 42, color: AppColors.primaryLight), const SizedBox(height: 12), Text(isRu ? 'Сейчас нет позитивных идей для выбранного горизонта' : 'No positive-return ideas for this horizon right now', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 6), Text(isRu ? 'Измените горизонт, чтобы увидеть другие предложения.' : 'Switch horizon to see other offers.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)]),
    );
  }
}
