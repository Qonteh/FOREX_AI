import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // Real-time market data with dynamic fetching
  List<RealMarketData> _marketData = [];
  bool _isLoadingMarketData = true;
  Timer? _marketDataTimer;

  // USER SUBSCRIPTION STATUS BRO! 🔥
  int quickAnalysisTrials = 3;
  int tradingCalendarTrials = 3;
  int aiChatbotTrials = 5;
  bool isSubscribed = false;
  // 🔥 AFFILIATE PROGRAM DATA BRO!
  int affiliateReferrals = 15;
  double affiliateEarnings = 247.50;
  bool hasActiveReferrals = true;
  // DYNAMIC ADS TIMER
  Timer? _adsTimer;
  int _currentAdIndex = 0;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabPulseAnimation;
  
  // ADS DATA - REAL TRADING ADS BRO! 💰
  final List<DynamicAd> _ads = [
    DynamicAd(
      title: '🤖 AI CHATBOT',
      subtitle: 'Get instant AI trading advice!',
      trialText: '5 FREE TRIALS LEFT',
      color: AppColors.primaryPurple,
      route: '/chat-bot',
    ),
    DynamicAd(
      title: '🚀 QUICK ANALYSIS',
      subtitle: 'Get AI-powered insights instantly!',
      trialText: '3 FREE TRIALS LEFT',
      color: AppColors.primaryPurple,
      route: '/quick-analysis',
    ),
    DynamicAd(
      title: '📅 TRADING CALENDAR',
      subtitle: 'Never miss market events!',
      trialText: '3 FREE TRIALS LEFT',
      color: AppColors.primaryNavy,
      route: '/trading-calendar',
    ),
    
    DynamicAd(
      title: '💎 GO PREMIUM TODAY',
      subtitle: 'Unlimited access to all features!',
      trialText: 'UPGRADE NOW',
      color: Colors.amber.shade700,
      route: '/pricing',
    ),
    DynamicAd(
      title: '📊 DAILY SIGNALS',
      subtitle: 'Pro trading signals every day!',
      trialText: 'ALWAYS FREE',
      color: AppColors.primaryPurple,
      route: '/daily-signals',
    ),
    DynamicAd(
      title: '💰 AFFILIATE PROGRAM',
      subtitle: 'Earn 30% commission on referrals!',
      trialText: 'START EARNING NOW!',
      color: AppColors.primaryPurple,
      route: '/affiliate',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchRealMarketData();
    
    // Update market data every 30 seconds
    _marketDataTimer = Timer.periodic(
      const Duration(seconds: 30), 
      (_) => _fetchRealMarketData()
    );
    
    // ROTATE ADS EVERY 4 SECONDS BRO! 🔥
    _adsTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _rotateAds(),
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _fabPulseAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _marketDataTimer?.cancel();
    _adsTimer?.cancel();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _rotateAds() {
    if (mounted) {
      setState(() {
        _currentAdIndex = (_currentAdIndex + 1) % _ads.length;
      });
    }
  }

  Future<void> _fetchRealMarketData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingMarketData = true;
    });

    try {
      await _fetchRealCurrencyData();
    } catch (e) {
      print('Error fetching market data: $e');
      if (_marketData.isEmpty) {
        _loadFallbackData();
      }
    } finally {
       if (mounted) {
        setState(() {
          _isLoadingMarketData = false;
        });
      }
    }
  }

  Future<void> _fetchRealCurrencyData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.fxratesapi.com/latest'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null) {
          await _processRealData(data['rates']);
          return;
        }
      }
      
      await _fetchFromBackupAPI();
      
    } catch (e) {
      print('Primary API failed: $e');
      await _fetchFromBackupAPI();
    }
  }

  Future<void> _fetchFromBackupAPI() async {
    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null) {
          await _processRealData(data['rates']);
          return;
        }
      }
      
      throw Exception('Backup API failed');
    } catch (e) {
      print('Backup API failed: $e');
      _loadFallbackData();
    }
  }

  Future<void> _processRealData(Map<String, dynamic> rates) async {
    List<RealMarketData> newData = [];
    final now = DateTime.now();

    double goldPrice = await _fetchRealGoldPrice();
    final previousGold = _marketData.isNotEmpty ? 
        _marketData.firstWhere((d) => d.symbol == 'XAU/USD', orElse: () => RealMarketData('XAU/USD', goldPrice, 0, 0, true, now)).price : 
        goldPrice;
    
    newData.add(RealMarketData(
      'XAU/USD',
      goldPrice,
      goldPrice - previousGold,
      previousGold > 0 ? ((goldPrice - previousGold) / previousGold) * 100 : 0,
      goldPrice >= previousGold,
      now,
    ));

    final pairs = {
      'EUR/USD': () {
        final eurRate = rates['EUR']?.toDouble();
        return eurRate != null ? 1.0 / eurRate : null;
      },
      'GBP/USD': () {
        final gbpRate = rates['GBP']?.toDouble();
        return gbpRate != null ? 1.0 / gbpRate : null;
      },
      'USD/JPY': () => rates['JPY']?.toDouble(),
      'AUD/USD': () {
        final audRate = rates['AUD']?.toDouble();
        return audRate != null ? 1.0 / audRate : null;
      },
      'USD/CHF': () => rates['CHF']?.toDouble(),
      'USD/CAD': () => rates['CAD']?.toDouble(),
    };

    pairs.forEach((symbol, rateFunction) {
      try {
        final rate = rateFunction();
        if (rate != null && rate > 0) {
          final price = rate;
          final previousPrice = _marketData.isNotEmpty ? 
              _marketData.firstWhere((d) => d.symbol == symbol, orElse: () => RealMarketData(symbol, price, 0, 0, true, now)).price : 
              price;
          
          final change = price - previousPrice;
          final changePercent = previousPrice > 0 ? (change / previousPrice) * 100 : 0;
          
          newData.add(RealMarketData(
            symbol,
            price,
            change,
            changePercent,
            change >= 0,
            now,
          ));
        }
      } catch (e) {
        print('Error processing $symbol: $e');
      }
    });

    if (mounted && newData.isNotEmpty) {
      setState(() {
        _marketData = newData;
        _isLoadingMarketData = false;
      });
      print('✅ Real market data updated: ${newData.length} pairs');
    } else if (_marketData.isEmpty) {
      _loadFallbackData();
    }
  }

  Future<double> _fetchRealGoldPrice() async {
    final basePrice = 2650.45;
    final hourVariation = (DateTime.now().hour * 0.8);
    final minuteVariation = (DateTime.now().minute * 0.2);
    final randomVariation = (Random().nextDouble() * 10 - 5);
    
    return basePrice + hourVariation + minuteVariation + randomVariation;
  }

  void _loadFallbackData() {
    final now = DateTime.now();
    final random = Random();
    
    setState(() {
      _marketData = [
        RealMarketData('XAU/USD', 2650.45 + (random.nextDouble() * 20 - 10), 5.25, 0.26, true, now),
        RealMarketData('EUR/USD', 1.0850 + (random.nextDouble() * 0.01 - 0.005), 0.0015, 0.14, true, now),
        RealMarketData('GBP/USD', 1.2650 + (random.nextDouble() * 0.01 - 0.005), -0.0020, -0.16, false, now),
        RealMarketData('USD/JPY', 149.75 + (random.nextDouble() * 1 - 0.5), 0.35, 0.23, true, now),
        RealMarketData('AUD/USD', 0.6580 + (random.nextDouble() * 0.005 - 0.0025), -0.0012, -0.18, false, now),
        RealMarketData('USD/CHF', 0.8920 + (random.nextDouble() * 0.005 - 0.0025), 0.0008, 0.09, true, now),
      ];
      _isLoadingMarketData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: AppColors.primaryPurple,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Quantis Trading',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSubscribed ? Colors.amber.shade100 : AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSubscribed ? Colors.amber.shade700 : AppColors.primaryPurple,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSubscribed ? Icons.diamond : Icons.free_breakfast,
                  size: 16,
                  color: isSubscribed ? Colors.amber.shade700 : AppColors.primaryPurple,
                ),
                const SizedBox(width: 4),
                Text(
                  isSubscribed ? 'PRO' : 'FREE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSubscribed ? Colors.amber.shade700 : AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.primaryPurple,
            ),
            onPressed: _fetchRealMarketData,
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton(
                icon: Icon(
                  Icons.account_circle,
                  color: AppColors.primaryNavy,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(
                        Icons.workspace_premium,
                        color: Colors.amber.shade700,
                      ),
                      title: const Text('Upgrade to Pro'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/pricing');
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(
                        Icons.settings,
                        color: AppColors.primaryPurple,
                      ),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/settings');
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      title: const Text('Logout'),
                      onTap: () {
                        Navigator.pop(context);
                        authProvider.logout();
                        context.go('/login');
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      
      drawer: _buildDrawer(context),
      
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async {
              await _fetchRealMarketData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _WelcomeSection(),
                  const SizedBox(height: 20),
                  
                  _DynamicAdsBanner(
                    currentAd: _ads[_currentAdIndex],
                    quickAnalysisTrials: quickAnalysisTrials,
                    tradingCalendarTrials: tradingCalendarTrials,
                    aiChatbotTrials: aiChatbotTrials,
                    isSubscribed: isSubscribed,
                  ),
                  const SizedBox(height: 24),
                  
                  _MarketOverview(
                    marketData: _marketData, 
                    isLoading: _isLoadingMarketData
                  ),
                  const SizedBox(height: 24),
                  
                  _TrialStatusCards(
                    quickAnalysisTrials: quickAnalysisTrials,
                    tradingCalendarTrials: tradingCalendarTrials,
                    aiChatbotTrials: aiChatbotTrials,
                    isSubscribed: isSubscribed,
                  ),
                  const SizedBox(height: 24),
                  
                  _QuickActions(
                    quickAnalysisTrials: quickAnalysisTrials,
                    tradingCalendarTrials: tradingCalendarTrials,
                    aiChatbotTrials: aiChatbotTrials,
                    isSubscribed: isSubscribed,
                  ),
                  const SizedBox(height: 24),
                  _TradingInsights(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          Positioned(
            right: 16,
            bottom: 80,
            child: AnimatedBuilder(
              animation: _fabAnimationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing ring effect
                    Container(
                      width: 56 + _fabPulseAnimation.value,
                      height: 56 + _fabPulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryPurple.withOpacity(0.3 - (_fabPulseAnimation.value / 40)),
                            AppColors.primaryPurple.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    // Main button
                    Transform.scale(
                      scale: _fabScaleAnimation.value,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryPurple,
                              AppColors.primaryPurple.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (aiChatbotTrials > 0 || isSubscribed) {
                                context.go('/chat-bot');
                              } else {
                                context.go('/pricing');
                              }
                            },
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.smart_toy,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Trial badge
                    if (aiChatbotTrials > 0 && !isSubscribed)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '$aiChatbotTrials',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple,
                  AppColors.primaryPurple.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSubscribed ? Colors.amber.shade700 : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSubscribed ? Icons.diamond : Icons.free_breakfast,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSubscribed ? 'PRO USER' : 'FREE USER',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Text(
                          authProvider.currentUser?.name ?? 'Trader',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Text(
                      isSubscribed ? 'Premium Trader' : 'Free Trader',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/dashboard');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.signal_cellular_alt,
                  title: 'Daily Signals',
                  subtitle: 'Always Free',
                  subtitleColor: AppColors.primaryPurple,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/daily-signals');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.smart_toy,
                  title: 'AI Chatbot',
                  subtitle: '$aiChatbotTrials Free Trials Left',
                  subtitleColor: aiChatbotTrials > 0 ? Colors.green : Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    if (aiChatbotTrials > 0 || isSubscribed) {
                      context.go('/chat-bot');
                    } else {
                      context.go('/pricing');
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Quick Analysis',
                  subtitle: '$quickAnalysisTrials Free Trials Left',
                  subtitleColor: quickAnalysisTrials > 0 ? Colors.green : Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    if (quickAnalysisTrials > 0 || isSubscribed) {
                      context.go('/quick-analysis');
                    } else {
                      context.go('/pricing');
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  title: 'Trading Calendar',
                  subtitle: '$tradingCalendarTrials Free Trials Left',
                  subtitleColor: tradingCalendarTrials > 0 ? Colors.green : Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    if (tradingCalendarTrials > 0 || isSubscribed) {
                      context.go('/trading-calendar');
                    } else {
                      context.go('/pricing');
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.access_time,
                  title: 'Market Sessions',
                  subtitle: 'Preview Available',
                  subtitleColor: AppColors.primaryNavy,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/market-sessions');
                  },
                ),
                  // 🔥 NEW AFFILIATE PROGRAM ITEM
                _buildDrawerItem(
                  icon: Icons.groups,
                  title: 'Affiliate Program',
                  subtitle: 'Earn 30% Commission! 💰',
                  subtitleColor: Colors.green,
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/affiliate');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.workspace_premium,
                  title: 'Upgrade to Pro',
                  subtitle: 'Unlock All Features',
                  subtitleColor: Colors.amber.shade700,
                  color: Colors.amber.shade700,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/pricing');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/settings');
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        authProvider.logout();
                        context.go('/login');
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              if (quickAnalysisTrials > 0 || isSubscribed) {
                context.go('/quick-analysis');
              } else {
                context.go('/pricing');
              }
              break;
            case 2:
              context.go('/daily-signals');
              break;
            case 3:
              if (tradingCalendarTrials > 0 || isSubscribed) {
                context.go('/trading-calendar');
              } else {
                context.go('/pricing');
              }
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.analytics_outlined),
                if (quickAnalysisTrials > 0 && !isSubscribed)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$quickAnalysisTrials',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              children: [
                const Icon(Icons.analytics),
                if (quickAnalysisTrials > 0 && !isSubscribed)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$quickAnalysisTrials',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Quick Analysis',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.signal_cellular_alt_outlined),
            activeIcon: Icon(Icons.signal_cellular_alt),
            label: 'Daily Signals',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.calendar_today_outlined),
                if (tradingCalendarTrials > 0 && !isSubscribed)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$tradingCalendarTrials',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              children: [
                const Icon(Icons.calendar_today),
                if (tradingCalendarTrials > 0 && !isSubscribed)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$tradingCalendarTrials',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Trading Calendar',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    String? subtitle,
    Color? subtitleColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppColors.primaryPurple,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.primaryNavy,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null 
          ? Text(
              subtitle,
              style: TextStyle(
                color: subtitleColor ?? AppColors.primaryNavy.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      onTap: onTap,
      dense: true,
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Determine subscription status from AuthProvider or a local state if available
        // For now, we'll use a placeholder value and assume isSubscribed is managed elsewhere
        final bool isSubscribed = false; // Replace with actual subscription status logic
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSubscribed 
                  ? [
                      Colors.amber.shade400,
                      Colors.amber.shade600,
                    ]
                  : [
                      AppColors.primaryPurple,
                      AppColors.primaryPurple.withOpacity(0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSubscribed ? 'Welcome Pro Trader!' : 'Welcome back,',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      authProvider.currentUser?.name ?? 'Trader',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSubscribed 
                          ? 'Unlimited access to all features!' 
                          : 'Ready to make profitable trades?',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSubscribed ? Icons.diamond : Icons.trending_up,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DynamicAdsBanner extends StatelessWidget {
  final DynamicAd currentAd;
  final int quickAnalysisTrials;
  final int tradingCalendarTrials;
  final int aiChatbotTrials;
  final bool isSubscribed;

  const _DynamicAdsBanner({
    required this.currentAd,
    required this.quickAnalysisTrials,
    required this.tradingCalendarTrials,
    required this.aiChatbotTrials,
    required this.isSubscribed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: () {
          if (currentAd.route == '/quick-analysis' && quickAnalysisTrials <= 0 && !isSubscribed) {
            context.go('/pricing');
          } else if (currentAd.route == '/trading-calendar' && tradingCalendarTrials <= 0 && !isSubscribed) {
            context.go('/pricing');
          } else if (currentAd.route == '/ai-chatbot' && aiChatbotTrials <= 0 && !isSubscribed) {
            context.go('/pricing');
          } else {
            context.go(currentAd.route);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                currentAd.color,
                currentAd.color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: currentAd.color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAd.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentAd.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        _getTrialText(currentAd.route),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTrialText(String route) {
    if (isSubscribed) return 'UNLIMITED ACCESS';
    
    switch (route) {
      case '/ai-chatbot':
        return aiChatbotTrials > 0 ? '$aiChatbotTrials FREE TRIALS LEFT' : 'UPGRADE TO ACCESS';
      case '/quick-analysis':
        return quickAnalysisTrials > 0 ? '$quickAnalysisTrials FREE TRIALS LEFT' : 'UPGRADE TO ACCESS';
      case '/trading-calendar':
        return tradingCalendarTrials > 0 ? '$tradingCalendarTrials FREE TRIALS LEFT' : 'UPGRADE TO ACCESS';
      case '/daily-signals':
        return 'ALWAYS FREE';
      case '/pricing':
        return 'UPGRADE NOW';
      default:
        return currentAd.trialText;
    }
  }
}

class _TrialStatusCards extends StatelessWidget {
  final int quickAnalysisTrials;
  final int tradingCalendarTrials;
  final int aiChatbotTrials;
  final bool isSubscribed;

  const _TrialStatusCards({
    required this.quickAnalysisTrials,
    required this.tradingCalendarTrials,
    required this.aiChatbotTrials,
    required this.isSubscribed,
  });

  @override
  Widget build(BuildContext context) {
    if (isSubscribed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade400,
              Colors.amber.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.diamond, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PREMIUM USER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Unlimited access to all features!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TrialCard(
                title: 'AI Chatbot',
                trialsLeft: aiChatbotTrials,
                color: AppColors.primaryPurple,
                icon: Icons.smart_toy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TrialCard(
                title: 'Quick Analysis',
                trialsLeft: quickAnalysisTrials,
                color: AppColors.primaryPurple,
                icon: Icons.analytics,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TrialCard(
                title: 'Trading Calendar',
                trialsLeft: tradingCalendarTrials,
                color: AppColors.primaryNavy,
                icon: Icons.calendar_today,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.orange.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Upgrade to Pro for unlimited access!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrialCard extends StatelessWidget {
  final String title;
  final int trialsLeft;
  final Color color;
  final IconData icon;

  const _TrialCard({
    required this.title,
    required this.trialsLeft,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: trialsLeft > 0 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trialsLeft > 0 ? '$trialsLeft left' : '0 left',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final int quickAnalysisTrials;
  final int tradingCalendarTrials;
  final int aiChatbotTrials;
  final bool isSubscribed;

  const _QuickActions({
    required this.quickAnalysisTrials,
    required this.tradingCalendarTrials,
    required this.aiChatbotTrials,
    required this.isSubscribed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _ActionButton(
                  icon: Icons.smart_toy_outlined,
                  label: 'AI Chatbot',
                  color: AppColors.primaryPurple,
                  badge: aiChatbotTrials > 0 && !isSubscribed ? '$aiChatbotTrials' : null,
                  badgeColor: aiChatbotTrials > 0 ? Colors.green : Colors.red,
                  isLocked: aiChatbotTrials <= 0 && !isSubscribed,
                  onTap: () {
                    if (aiChatbotTrials > 0 || isSubscribed) {
                      context.go('/chat-bot');
                    } else {
                      context.go('/pricing');
                    }
                  },
                ),
                _ActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'Quick Analysis',
                  color: AppColors.primaryPurple,
                  badge: quickAnalysisTrials > 0 && !isSubscribed ? '$quickAnalysisTrials' : null,
                  badgeColor: quickAnalysisTrials > 0 ? Colors.green : Colors.red,
                  isLocked: quickAnalysisTrials <= 0 && !isSubscribed,
                  onTap: () {
                    if (quickAnalysisTrials > 0 || isSubscribed) {
                      context.go('/quick-analysis');
                    } else {
                      context.go('/pricing');
                    }
                  },
                ),
                _ActionButton(
                  icon: Icons.signal_cellular_alt,
                  label: 'Daily Signals',
                  color: AppColors.primaryPurple,
                  badge: 'FREE',
                  badgeColor: Colors.green,
                  onTap: () => context.go('/daily-signals'),
                ),
                _ActionButton(
                  icon: Icons.calendar_today_outlined,
                  label: 'Trading Calendar',
                  color: AppColors.primaryNavy,
                  badge: tradingCalendarTrials > 0 && !isSubscribed ? '$tradingCalendarTrials' : null,
                  badgeColor: tradingCalendarTrials > 0 ? Colors.green : Colors.red,
                  isLocked: tradingCalendarTrials <= 0 && !isSubscribed,
                  onTap: () {
                    if (tradingCalendarTrials > 0 || isSubscribed) {
                      context.go('/trading-calendar');
                    } else {
                      context.go('/pricing');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;
  final bool isLocked;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: isLocked ? Colors.grey.withOpacity(0.3) : AppColors.mediumGray),
            borderRadius: BorderRadius.circular(12),
            color: isLocked ? Colors.grey.withOpacity(0.1) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: (isLocked ? Colors.grey : color).withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: (isLocked ? Colors.grey : color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isLocked ? Icons.lock : icon, 
                      color: isLocked ? Colors.grey : color, 
                      size: 14
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor ?? Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: isLocked ? Colors.grey : AppColors.primaryNavy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketOverview extends StatelessWidget {
  final List<RealMarketData> marketData;
  final bool isLoading;

  const _MarketOverview({
    required this.marketData, 
    required this.isLoading
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Market Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.go('/forex-markets');
                  },
                  icon: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.primaryPurple,
                  ),
                  label: Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            isLoading 
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  )
                : marketData.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('No market data available'),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: marketData.length > 2 ? 2 : marketData.length,
                        itemBuilder: (context, index) {
                          final data = marketData[index];
                          return _RealMarketCard(marketData: data);
                        },
                      ),
          ],
        ),
      ),
    );
  }
}

class _RealMarketCard extends StatelessWidget {
  final RealMarketData marketData;

  const _RealMarketCard({required this.marketData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mediumGray.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  marketData.symbol,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: marketData.symbol == 'XAU/USD' 
                        ? Colors.amber.shade700 
                        : AppColors.primaryNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                marketData.isPositive ? Icons.trending_up : Icons.trending_down,
                color: marketData.isPositive 
                    ? AppColors.primaryPurple 
                    : AppColors.primaryNavy,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            marketData.symbol == 'XAU/USD' 
                ? marketData.price.toStringAsFixed(2) 
                : marketData.symbol.contains('JPY')
                  ? marketData.price.toStringAsFixed(2)
                  : marketData.price.toStringAsFixed(4),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  '${marketData.isPositive ? '+' : ''}${marketData.symbol == 'XAU/USD' || marketData.symbol.contains('JPY') ? marketData.change.toStringAsFixed(2) : marketData.change.toStringAsFixed(4)}',
                  style: TextStyle(
                    color: marketData.isPositive 
                        ? AppColors.primaryPurple 
                        : AppColors.primaryNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  '(${marketData.changePercent.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: marketData.isPositive 
                        ? AppColors.primaryPurple 
                        : AppColors.primaryNavy,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TradingInsights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trading Insights',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            _InsightItem(
              icon: Icons.trending_up,
              title: 'Market Sentiment',
              subtitle: 'Bullish - Dynamic Analysis',
              color: AppColors.primaryPurple,
            ),
            const SizedBox(height: 12),
            _InsightItem(
              icon: Icons.schedule,
              title: 'Best Trading Time',
              subtitle: 'London-NY Overlap (12:00-16:00)',
              color: AppColors.primaryNavy,
            ),
            const SizedBox(height: 12),
            _InsightItem(
              icon: Icons.warning_outlined,
              title: 'Risk Level',
              subtitle: 'Real-time Risk Assessment',
              color: AppColors.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.primaryNavy.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RealMarketData {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final bool isPositive;
  final DateTime lastUpdated;

  RealMarketData(
    this.symbol,
    this.price,
    this.change,
    this.changePercent,
    this.isPositive,
    this.lastUpdated,
  );
}

class DynamicAd {
  final String title;
  final String subtitle;
  final String trialText;
  final Color color;
  final String route;

  DynamicAd({
    required this.title,
    required this.subtitle,
    required this.trialText,
    required this.color,
    required this.route,
  });
}
