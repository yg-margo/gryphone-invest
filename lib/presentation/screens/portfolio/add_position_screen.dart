import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/market_provider.dart';
import '../../../data/providers/portfolio_provider.dart';
import '../../../data/providers/locale_provider.dart';

class AddPositionScreen extends StatefulWidget {
  final String? preselectedSymbol;

  const AddPositionScreen({super.key, this.preselectedSymbol});

  @override
  State<AddPositionScreen> createState() => _AddPositionScreenState();
}

class _AddPositionScreenState extends State<AddPositionScreen> {
  String? _selectedSymbol;
  final _sharesController = TextEditingController();
  final _formKey          = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedSymbol != null) {
      _selectedSymbol = widget.preselectedSymbol;
    }
  }

  @override
  void dispose() {
    _sharesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final isRu      = context.watch<LocaleProvider>().isRussian;
    final market    = context.watch<MarketProvider>();
    final portfolio = context.read<PortfolioProvider>();
    final stocks    = market.stocks;

    final selectedStock = _selectedSymbol != null
        ? stocks.firstWhere(
            (s) => s.symbol == _selectedSymbol,
            orElse: () => stocks.first,
          )
        : null;

    final shares    = double.tryParse(_sharesController.text) ?? 0;
    final totalCost = selectedStock != null
        ? shares * selectedStock.currentPrice
        : 0.0;
    final canAfford = totalCost <= portfolio.portfolio.cash && totalCost > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('addPosition', isRussian: isRu)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            Text(
              AppStrings.get('selectStock', isRussian: isRu),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color:        isDark ? AppColors.darkElevated : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:        _selectedSymbol,
                  hint: Text(
                    AppStrings.get('chooseStock', isRussian: isRu),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  isExpanded:    true,
                  dropdownColor: isDark
                      ? AppColors.darkElevated : AppColors.lightCard,
                  items: stocks.map((stock) {
                    return DropdownMenuItem(
                      value: stock.symbol,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width:  32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:        AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                stock.symbol.substring(0, 1),
                                style: const TextStyle(
                                  color:      AppColors.primaryLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize:   13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${stock.symbol} — ${stock.name}',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment:  MainAxisAlignment.center,
                            children: [
                              Text(
                                Formatters.currency(stock.currentPrice),
                                style: const TextStyle(
                                  color:      AppColors.primaryLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize:   13,
                                ),
                              ),
                              Text(
                                Formatters.percentRaw(stock.changePercent),
                                style: TextStyle(
                                  color: stock.isPositive
                                      ? AppColors.success : AppColors.danger,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() {
                    _selectedSymbol = val;
                    _sharesController.clear();
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              AppStrings.get('numberOfShares', isRussian: isRu),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller:  _sharesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText:   AppStrings.get('sharesHint', isRussian: isRu),
                prefixIcon: const Icon(
                  Icons.numbers_rounded,
                  color: AppColors.primaryLight,
                ),
              ),
              onChanged: (_) => setState(() {}),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return AppStrings.get('sharesError', isRussian: isRu);
                }
                if ((double.tryParse(val) ?? 0) <= 0) {
                  return AppStrings.get('sharesErrorZero', isRussian: isRu);
                }
                return null;
              },
            ),

            if (selectedStock != null) ...[
              const SizedBox(height: 12),
              _QuickAmounts(
                cashAvailable: portfolio.portfolio.cash,
                price:         selectedStock.currentPrice,
                isDark:        isDark,
                onSelect: (qty) {
                  setState(() {
                    _sharesController.text = qty.toStringAsFixed(
                      qty == qty.toInt() ? 0 : 4,
                    );
                  });
                },
              ),
            ],

            const SizedBox(height: 24),

            if (selectedStock != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _OrderRow(
                      label: AppStrings.get('pricePerShare', isRussian: isRu),
                      value: Formatters.currency(selectedStock.currentPrice),
                    ),
                    const SizedBox(height: 8),
                    _OrderRow(
                      label: AppStrings.get('shares', isRussian: isRu),
                      value: shares > 0
                          ? shares.toStringAsFixed(4) : '—',
                    ),
                    const Divider(height: 24),
                    _OrderRow(
                      label: AppStrings.get('totalCost', isRussian: isRu),
                      value: shares > 0
                          ? Formatters.currency(totalCost) : '—',
                      isBold: true,
                    ),
                    const SizedBox(height: 6),
                    _OrderRow(
                      label: AppStrings.get('availableCash', isRussian: isRu),
                      value: Formatters.currency(portfolio.portfolio.cash),
                      valueColor: shares > 0
                          ? (canAfford ? AppColors.success : AppColors.danger)
                          : null,
                    ),
                    if (shares > 0 && !canAfford) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:        AppColors.danger.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.danger.withOpacity(0.30),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isRu
                                    ? 'Недостаточно средств'
                                    : 'Insufficient funds',
                                style: const TextStyle(
                                  color:    AppColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedSymbol == null ||
                        !canAfford ||
                        shares <= 0)
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          portfolio.addPosition(
                            selectedStock!.symbol,
                            selectedStock.name,
                            shares,
                            selectedStock.currentPrice,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isRu
                                    ? 'Куплено ${shares.toStringAsFixed(2)} акций ${selectedStock.symbol}'
                                    : 'Bought ${shares.toStringAsFixed(2)} shares of ${selectedStock.symbol}',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                icon:  const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: Text(AppStrings.get('buyPosition', isRussian: isRu)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _QuickAmounts extends StatelessWidget {
  final double        cashAvailable;
  final double        price;
  final bool          isDark;
  final Function(double) onSelect;

  const _QuickAmounts({
    required this.cashAvailable,
    required this.price,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final maxShares  = cashAvailable / price;
    final percents   = [0.25, 0.50, 0.75, 1.0];
    final labels     = ['25%', '50%', '75%', 'Max'];

    return Row(
      children: List.generate(percents.length, (i) {
        final qty = maxShares * percents[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < percents.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: qty > 0 ? () => onSelect(qty) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:        isDark
                      ? AppColors.darkElevated : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color:      AppColors.primaryLight,
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   isBold;
  final Color? valueColor;

  const _OrderRow({
    required this.label,
    required this.value,
    this.isBold     = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color:      valueColor,
            fontSize:   isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
