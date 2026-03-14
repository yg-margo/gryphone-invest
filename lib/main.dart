import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/locale_provider.dart';
import 'data/providers/market_provider.dart';
import 'data/providers/portfolio_provider.dart';
import 'data/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PortfolioProvider>(
          create: (_) => PortfolioProvider(),
          update: (_, auth, portfolio) {
            final provider = portfolio ?? PortfolioProvider();
            provider.setAuthSession(
              isAuthenticated: auth.isAuthenticated,
              token: auth.token,
              userId: auth.userId,
            );
            return provider;
          },
        ),
      ],
      child: const GryphoineInvestApp(),
    ),
  );
}
