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
  
  print('🚀🚀🚀 QUANTIS TRADING APP - STARTING INITIALIZATION 🚀🚀🚀');
  print('📱 Platform: ${kIsWeb ? "WEB BROWSER" : "MOBILE DEVICE"}');
  print('🔧 Debug Mode: ${kDebugMode ? "ENABLED" : "DISABLED"}');
  print('⏰ Timestamp: ${DateTime.now()}');
  
  // Set preferred orientations for mobile only
  if (!kIsWeb) {
    print('📱 Setting mobile orientations...');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    print('✅ Mobile orientations set');
  }
  
  print('🚀🚀🚀 LAUNCHING QUANTIS TRADING APP... 🚀🚀🚀');
  
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
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp.router(
            title: 'Quantis Trading App',
            debugShowCheckedModeBanner: false,
            theme: _buildAppTheme(),
            themeMode: ThemeMode.light,
            routerConfig: _router,
            builder: (context, child) {
              return child ?? const SizedBox();
            },
          );
        },
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.primaryPurple,
        onPrimary: Colors.white,
        secondary: AppColors.primaryNavy,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.primaryNavy,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.primaryNavy,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.primaryPurple),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: AppColors.primaryPurple.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: AppColors.primaryPurple.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        labelLarge: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w600),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}

// ROUTER CONFIGURATION
final GoRouter _router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/signup',
      builder: (context, state) => const SignupScreen(),
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
      path: '/chat',
      builder: (context, state) => const ChatBotScreen(),
    ),
    GoRoute(
      path: '/affiliate',
      builder: (context, state) => const AffiliateScreen(),
    ),
    GoRoute(
      path: '/forex-markets',
      builder: (context, state) => const ForexMarketsScreen(),
    ),
    GoRoute(
      path: '/daily-signals',
      builder: (context, state) => const DailySignalsScreen(),
    ),
    GoRoute(
      path: '/signals',
      builder: (context, state) => const DailySignalsScreen(),
    ),
    GoRoute(
      path: '/market-sessions',
      builder: (context, state) => const MarketSessionsScreen(),
    ),
    GoRoute(
      path: '/sessions',
      builder: (context, state) => const MarketSessionsScreen(),
    ),
    GoRoute(
      path: '/quick-analysis',
      builder: (context, state) => const QuickAnalysisScreen(),
    ),
    GoRoute(
      path: '/analysis',
      builder: (context, state) => const QuickAnalysisScreen(),
    ),
    GoRoute(
      path: '/trading-calendar',
      builder: (context, state) => const TradingCalendarScreen(),
    ),
    GoRoute(
      path: '/calendar',
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
  ],
);