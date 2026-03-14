import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../data/providers/market_provider.dart';
import '../../data/providers/portfolio_provider.dart';
import '../../data/providers/locale_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../responsive.dart';
import 'home/home_screen.dart';
import 'portfolio/portfolio_screen.dart';
import 'discover/discover_screen.dart';
import 'backtesting/backtest_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PortfolioScreen(),
    DiscoverScreen(),
    BacktestScreen(),
    ProfileScreen(),
  ];

  MarketProvider? _marketProvider;
  PortfolioProvider? _portfolioProvider;

  void _handleMarketUpdate() {
    final market = _marketProvider;
    final portfolio = _portfolioProvider;
    if (market == null || portfolio == null) return;
    portfolio.updatePrices({
      for (final stock in market.stocks) stock.symbol: stock.currentPrice,
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _marketProvider = context.read<MarketProvider>();
      _portfolioProvider = context.read<PortfolioProvider>();
      _marketProvider!.addListener(_handleMarketUpdate);
      _handleMarketUpdate();
      _marketProvider!.refreshMarketCorrections(force: true);
    });
  }

  @override
  void dispose() {
    _marketProvider?.removeListener(_handleMarketUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRu = context.watch<LocaleProvider>().isRussian;
    final auth = context.watch<AuthProvider>();
    final isDesktop = AppBreakpoints.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                extended: MediaQuery.sizeOf(context).width >= 1440,
                backgroundColor:
                    isDark ? AppColors.darkSurface : AppColors.lightSurface,
                selectedIconTheme: const IconThemeData(color: AppColors.primaryLight),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: Text(AppStrings.get('navHome', isRussian: isRu)),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: const Icon(Icons.account_balance_wallet),
                    label: Text(AppStrings.get('navPortfolio', isRussian: isRu)),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.explore_outlined),
                    selectedIcon: const Icon(Icons.explore),
                    label: Text(isRu ? 'Обзор' : 'Discover'),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.science_outlined),
                    selectedIcon: const Icon(Icons.science),
                    label: Text(AppStrings.get('navBacktest', isRussian: isRu)),
                  ),
                  NavigationRailDestination(
                    icon: _NavAvatar(auth: auth, isSelected: false, isDark: isDark),
                    selectedIcon: _NavAvatar(auth: auth, isSelected: true, isDark: isDark),
                    label: Text(isRu ? 'Профиль' : 'Profile'),
                  ),
                ],
              ),
              VerticalDivider(
                width: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              Expanded(child: _screens[_currentIndex]),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: AppStrings.get('navHome', isRussian: isRu),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              activeIcon: const Icon(Icons.account_balance_wallet),
              label: AppStrings.get('navPortfolio', isRussian: isRu),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: isRu ? 'Обзор' : 'Discover',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.science_outlined),
              activeIcon: const Icon(Icons.science),
              label: AppStrings.get('navBacktest', isRussian: isRu),
            ),
            BottomNavigationBarItem(
              icon: _NavAvatar(auth: auth, isSelected: false, isDark: isDark),
              activeIcon: _NavAvatar(auth: auth, isSelected: true, isDark: isDark),
              label: isRu ? 'Профиль' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavAvatar extends StatelessWidget {
  final AuthProvider auth;
  final bool isSelected;
  final bool isDark;

  const _NavAvatar({
    required this.auth,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primaryLight
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
        gradient: auth.avatarBytes == null
            ? LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(isSelected ? 1.0 : 0.5),
                  AppColors.primaryLight.withOpacity(isSelected ? 1.0 : 0.5),
                ],
              )
            : null,
      ),
      child: ClipOval(
        child: auth.avatarBytes != null
            ? Image.memory(auth.avatarBytes!, fit: BoxFit.cover)
            : Center(
                child: Text(
                  auth.initials,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}
