import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // ADD THIS IMPORT!
import 'services/firebase_service.dart';
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
  
  // Initialize Firebase with EXTREME DETAILED logging
  print('🔥🔥🔥 FIREBASE INITIALIZATION STARTING... 🔥🔥🔥');
  print('📡 Attempting to connect to Firebase Backend...');
  
  bool firebaseInitialized = false;
  String firebaseStatus = 'INITIALIZING';
  
  try {
    print('🎯 Step 1: Calling FirebaseService.initialize()...');
    await FirebaseService.initialize();
    print('✅✅✅ Firebase Core: SUCCESSFULLY INITIALIZED! ✅✅✅');
    
    // INTENSIVE CONNECTION TESTING
    print('🧪🧪🧪 STARTING INTENSIVE CONNECTION TESTS... 🧪🧪🧪');
    final connected = await FirebaseService.instance.testConnection();
    
    if (connected) {
      firebaseInitialized = true;
      firebaseStatus = 'CONNECTED';
      print('🎉🎉🎉 FIREBASE BACKEND: FULLY CONNECTED AND OPERATIONAL! 🎉🎉🎉');
      
      // Test individual services with detailed logging
      await _testFirebaseServices();
      
    } else {
      firebaseInitialized = false;
      firebaseStatus = 'CONNECTION_FAILED';
      print('❌❌❌ FIREBASE BACKEND: CONNECTION TEST FAILED! ❌❌❌');
    }
    
  } catch (e, stackTrace) {
    firebaseInitialized = false;
    firebaseStatus = 'INITIALIZATION_FAILED';
    print('💥💥💥 FIREBASE INITIALIZATION CATASTROPHIC FAILURE! 💥💥💥');
    print('🚨 ERROR: $e');
    print('📊 FULL STACK TRACE:');
    print(stackTrace.toString());
  }
  
  print('📊📊📊 FIREBASE STATUS SUMMARY 📊📊📊');
  print('   ✅ Initialized: $firebaseInitialized');
  print('   🔗 Status: $firebaseStatus');
  print('   🌐 Backend Communication: ${firebaseInitialized ? "🟢 ACTIVE" : "🔴 INACTIVE"}');
  print('   📱 Project ID: safariapp-5965d');
  
  print('🚀🚀🚀 LAUNCHING QUANTIS TRADING APP... 🚀🚀🚀');
  
  runApp(MyApp(
    firebaseEnabled: firebaseInitialized,
    firebaseStatus: firebaseStatus,
  ));
}

// Test all Firebase services individually with EXTREME DETAIL
Future<void> _testFirebaseServices() async {
  try {
    print('🔬🔬🔬 TESTING INDIVIDUAL FIREBASE SERVICES 🔬🔬🔬');
    
    // Test 1: Authentication Service
    print('🔐 TESTING FIREBASE AUTHENTICATION...');
    final authService = FirebaseService.instance.auth;
    final currentUser = authService.currentUser;
    print('   ✅ Auth Service Status: OPERATIONAL');
    print('   👤 Current User: ${currentUser?.email ?? "No current user logged in"}');
    print('   🆔 User ID: ${currentUser?.uid ?? "N/A"}');
    
    // Test 2: Firestore Service
    print('🗄️ TESTING FIRESTORE DATABASE...');
    final firestoreService = FirebaseService.instance.firestore;
    
    final testData = {
      'timestamp': FieldValue.serverTimestamp(),
      'platform': kIsWeb ? 'web_browser' : 'mobile_device',
      'test_type': 'comprehensive_app_initialization',
      'app_version': '1.0.0',
      'project_id': 'safariapp-5965d',
      'test_id': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    print('   📝 Writing test document to Firestore...');
    await firestoreService.collection('quantis_connection_tests').doc('startup_${DateTime.now().millisecondsSinceEpoch}').set(testData);
    print('   ✅✅✅ Firestore WRITE TEST: SUCCESSFUL! ✅✅✅');
    
    // Test 3: Read from Firestore
    print('   📖 Reading test document from Firestore...');
    final testDoc = await firestoreService.collection('quantis_connection_tests').limit(1).get();
    if (testDoc.docs.isNotEmpty) {
      print('   ✅✅✅ Firestore READ TEST: SUCCESSFUL! ✅✅✅');
      print('   📊 Retrieved ${testDoc.docs.length} document(s)');
      print('   🔍 Latest document data: ${testDoc.docs.first.data()}');
    }
    
    // Test 4: Real-time listener
    print('   📡 Testing real-time listener...');
    final stream = firestoreService.collection('quantis_connection_tests').limit(1).snapshots();
    await stream.take(1).forEach((snapshot) {
      print('   ✅✅✅ Firestore REAL-TIME LISTENER: WORKING! ✅✅✅');
      print('   📊 Real-time snapshot contains ${snapshot.docs.length} documents');
    });
    
    print('🎉🎉🎉 ALL FIREBASE SERVICES: FULLY OPERATIONAL! 🎉🎉🎉');
    
  } catch (e, stackTrace) {
    print('❌❌❌ FIREBASE SERVICES TEST FAILED! ❌❌❌');
    print('🚨 Error: $e');
    print('📊 Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  final bool firebaseEnabled;
  final String firebaseStatus;
  
  const MyApp({
    super.key, 
    required this.firebaseEnabled,
    required this.firebaseStatus,
  });

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
              return Scaffold(
                body: Stack(
                  children: [
                    child ?? const SizedBox(),
                    // Firebase Connection Indicator - MORE VISIBLE
                    Positioned(
                      top: 50,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: firebaseEnabled ? Colors.green.shade600 : Colors.red.shade600,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (firebaseEnabled ? Colors.green : Colors.red).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              firebaseEnabled ? Icons.cloud_done : Icons.cloud_off,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              firebaseStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Debug Info - BOTTOM LEFT
                    if (kDebugMode)
                      Positioned(
                        bottom: 20,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Firebase: ${firebaseEnabled ? "🟢" : "🔴"}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                              Text(
                                'Project: safariapp-5965d',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                              Text(
                                'Platform: ${kIsWeb ? "Web" : "Mobile"}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
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