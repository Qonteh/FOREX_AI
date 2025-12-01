import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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

void main() {
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
          return MaterialApp.router(
            title: 'Quantis Trading App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              // FORCE WHITE THEME BRO! NO MORE PURPLE BACKGROUND!
              colorScheme: const ColorScheme.light(
                brightness: Brightness.light,
                primary: AppColors.primaryPurple,
                onPrimary: Colors.white,
                secondary: AppColors.primaryNavy,
                onSecondary: Colors.white,
                error: Colors.red,
                onError: Colors.white,
                background: Colors.white,        // FORCE WHITE BRO!
                onBackground: AppColors.primaryNavy,
                surface: Colors.white,           // FORCE WHITE BRO!
                onSurface: AppColors.primaryNavy,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,  // FORCE WHITE BRO!
              canvasColor: Colors.white,              // FORCE WHITE BRO!
              
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,        // FORCE WHITE BRO!
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
                color: Colors.white,               // FORCE WHITE BRO!
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
            ),
            
            darkTheme: ThemeData(
              // DARK THEME - Beautiful dark with logo colors
              colorScheme: const ColorScheme.dark(
                brightness: Brightness.dark,
                primary: AppColors.primaryPurple,
                onPrimary: Colors.white,
                secondary: AppColors.lightPurple,
                onSecondary: Colors.white,
                error: Colors.red,
                onError: Colors.white,
                background: AppColors.backgroundDark,
                onBackground: Colors.white,
                surface: AppColors.surfaceDark,
                onSurface: Colors.white,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.backgroundDark,
              canvasColor: AppColors.surfaceDark,
              
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surfaceDark,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: IconThemeData(color: AppColors.lightPurple),
                systemOverlayStyle: SystemUiOverlayStyle.light,
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
                color: AppColors.surfaceDark,
                elevation: 4,
                shadowColor: AppColors.primaryPurple.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              
              textTheme: const TextTheme(
                headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                bodyLarge: TextStyle(color: Colors.white70),
                bodyMedium: TextStyle(color: Colors.white60),
                labelLarge: TextStyle(color: AppColors.lightPurple, fontWeight: FontWeight.w600),
              ),
            ),
            
            themeMode: ThemeMode.light,  // FORCE LIGHT MODE BRO!
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // ROOT ROUTE - REDIRECT TO ONBOARDING
    GoRoute(
      path: '/',
      redirect: (context, state) => '/onboarding',
    ),
    
    // ONBOARDING
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    
    // AUTH ROUTES
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
    
    // MAIN APP ROUTES - ALL FIXED!
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
    // 🔥 NEW AFFILIATE ROUTE
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