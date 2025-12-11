import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/chat_bot/chat_bot_screen.dart';
import 'screens/daily_signals/daily_signals_screen.dart';
import 'screens/market_sessions/market_sessions_screen.dart';
import 'screens/quick_analysis/quick_analysis_screen.dart';
import 'screens/trading_calendar/trading_calendar_screen.dart';
import 'screens/pricing/pricing_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'theme/app_colors.dart';
import 'screens/forex/forex_markets_screen.dart';
import 'screens/affiliate/affiliate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀🚀🚀 FOREX AI TRADING APP - STARTING 🚀🚀🚀');
  print('📱 Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
  print('🔧 Debug Mode: ${kDebugMode ? "ENABLED" : "DISABLED"}');
  print('⏰ Timestamp: ${DateTime.now()}');
  print('🌐 Backend: FastAPI @ http://localhost:8000');
  
  // Set preferred orientations for mobile only
  if (!kIsWeb) {
    print('📱 Setting mobile orientations...');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    print('✅ Mobile orientations set');
  }
  
  print('🚀 Launching FOREX AI App...');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final router = _createRouter(context);
          
          return MaterialApp.router(
            title: 'FOREX AI Trading',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryPurple,
                brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
              ),
              scaffoldBackgroundColor: themeProvider.isDarkMode 
                  ? AppColors.backgroundDark 
                  : AppColors.backgroundLight,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/onboarding',
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isAuthenticated = authProvider.isAuthenticated;
        
        final isOnOnboarding = state.matchedLocation == '/onboarding';
        final isOnLogin = state.matchedLocation == '/login';
        final isOnSignup = state.matchedLocation == '/signup';
        
        // If not authenticated and trying to access protected routes
        if (!isAuthenticated && !isOnOnboarding && !isOnLogin && !isOnSignup) {
          return '/login';
        }
        
        // If authenticated and on auth pages, go to dashboard
        if (isAuthenticated && (isOnLogin || isOnSignup)) {
          return '/dashboard';
        }
        
        return null; // No redirect
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/chat-bot',
          builder: (context, state) => const ChatBotScreen(),
        ),
        GoRoute(
          path: '/daily-signals',
          builder: (context, state) => const DailySignalsScreen(),
        ),
        GoRoute(
          path: '/market-sessions',
          builder: (context, state) => const MarketSessionsScreen(),
        ),
        GoRoute(
          path: '/quick-analysis',
          builder: (context, state) => const QuickAnalysisScreen(),
        ),
        GoRoute(
          path: '/trading-calendar',
          builder: (context, state) => const TradingCalendarScreen(),
        ),
        GoRoute(
          path: '/pricing',
          builder: (context, state) => const PricingScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/forex-markets',
          builder: (context, state) => const ForexMarketsScreen(),
        ),
        GoRoute(
          path: '/affiliate',
          builder: (context, state) => const AffiliateScreen(),
        ),
      ],
    );
  }
}
