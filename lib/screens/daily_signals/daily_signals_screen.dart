import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class DailySignalsScreen extends StatefulWidget {
  const DailySignalsScreen({super.key});

  @override
  State<DailySignalsScreen> createState() => _DailySignalsScreenState();
}

class _DailySignalsScreenState extends State<DailySignalsScreen> 
    with TickerProviderStateMixin {
  final Random _rand = Random();
  late Timer _updateTimer;
  List<TradingSignal> _signals = [];
  bool _showOnlyActive = false;
  String _search = '';
  
  int quickAnalysisTrials = 3;
  int tradingCalendarTrials = 3;
  bool isSubscribed = false;
  
  // ANIMATIONS FOR REAL-TIME FEEL
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _generateInitialSignals();
    
    // Real-time updates every 5 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) => _tickUpdate());
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _generateInitialSignals() {
    final now = DateTime.now();
    _signals = [
      // FOREX MAJORS - Mix of statuses and timeframes
      TradingSignal.create('EUR/USD', 'BUY', 1.0850, 1.0820, 1.0890, 85, now.subtract(Duration(minutes: 5)), 'Active', '4H'),
      TradingSignal.create('GBP/USD', 'SELL', 1.2650, 1.2680, 1.2610, 78, now.subtract(Duration(minutes: 15)), 'Pending', '1H'),
      TradingSignal.create('USD/JPY', 'BUY', 149.75, 149.40, 150.20, 92, now.subtract(Duration(hours: 2)), 'Completed', 'Daily'),
      TradingSignal.create('AUD/USD', 'SELL', 0.6720, 0.6700, 0.6750, 73, now.subtract(Duration(hours: 3)), 'Completed', '4H'),
      TradingSignal.create('USD/CAD', 'BUY', 1.3580, 1.3550, 1.3620, 81, now.subtract(Duration(minutes: 8)), 'Active', '1H'),
      
      // GOLD & COMMODITIES
      TradingSignal.create('XAU/USD', 'BUY', 2650.45, 2630.00, 2680.00, 89, now.subtract(Duration(minutes: 3)), 'Active', '4H'),
      TradingSignal.create('XAG/USD', 'SELL', 31.25, 31.50, 30.80, 76, now.subtract(Duration(minutes: 20)), 'Pending', 'Daily'),
      
      // CRYPTO
      TradingSignal.create('BTC/USD', 'SELL', 43750.0, 44000.0, 43200.0, 76, now.subtract(Duration(hours: 1)), 'Completed', '1H'),
      TradingSignal.create('ETH/USD', 'BUY', 2650.0, 2620.0, 2690.0, 80, now.subtract(Duration(minutes: 12)), 'Active', '4H'),
      TradingSignal.create('BNB/USD', 'BUY', 315.50, 310.00, 325.00, 74, now.subtract(Duration(minutes: 25)), 'Pending', 'Daily'),
      
      // STOCKS
      TradingSignal.create('AAPL', 'BUY', 195.50, 193.00, 198.00, 87, now.subtract(Duration(minutes: 7)), 'Active', '1H'),
      TradingSignal.create('TSLA', 'SELL', 242.80, 245.00, 238.00, 82, now.subtract(Duration(hours: 4)), 'Completed', '4H'),
      TradingSignal.create('GOOGL', 'BUY', 140.25, 138.50, 143.00, 79, now.subtract(Duration(minutes: 18)), 'Pending', 'Daily'),
      TradingSignal.create('MSFT', 'BUY', 378.90, 375.00, 385.00, 86, now.subtract(Duration(minutes: 10)), 'Active', '4H'),
    ];
  }

  void _tickUpdate() {
    if (!mounted) return;

    setState(() {
      for (var i = 0; i < _signals.length; i++) {
        final s = _signals[i];
        
        // Only update Active and Pending signals
        if (s.status != 'Completed') {
          // Small price movements
          final delta = (_rand.nextDouble() - 0.5) * 0.002;
          final newEntry = (s.entryPrice * (1 + delta)).clamp(0.00001, double.infinity);

          // Update confidence slightly
          int newConfidence = (s.confidence + (_rand.nextInt(5) - 2)).clamp(70, 95);
          
          // Occasional status changes for Pending signals
          String newStatus = s.status;
          if (s.status == 'Pending' && _rand.nextDouble() < 0.05) {
            newStatus = 'Active';
          }

          _signals[i] = s.copyWith(
            entryPrice: newEntry,
            confidence: newConfidence,
            lastUpdated: DateTime.now(),
            status: newStatus,
          );
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _generateInitialSignals();
    });
  }

  List<TradingSignal> get _visibleSignals {
    final filtered = _signals.where((s) {
      final q = _search.trim().toLowerCase();
      if (q.isNotEmpty && !s.pair.toLowerCase().contains(q)) return false;
      if (_showOnlyActive && s.status != 'Active') return false;
      return true;
    }).toList();
    
    // Sort by status priority: Active > Pending > Completed
    filtered.sort((a, b) {
      final weight = {'Active': 0, 'Pending': 1, 'Completed': 2};
      return weight[a.status]!.compareTo(weight[b.status]!);
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleSignals;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.primaryPurple,
        backgroundColor: Colors.white,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildControls()),
            SliverToBoxAdapter(child: _buildTimeframeInfo()),
            visible.isEmpty ? _emptySliver() : _signalsSliver(visible),
            SliverToBoxAdapter(child: const SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
        currentIndex: 2, // Daily Signals is active (index 2)
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              if (quickAnalysisTrials > 0 || isSubscribed) {
                context.go('/quick-analysis');
              } else {
                context.go('/pricing');
              }
              break;
            case 2:
              // Already on Daily Signals
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryPurple,
                AppColors.primaryPurple.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        onPressed: () => context.go('/dashboard'),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trading Signals',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(_pulseAnimation.value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(
                'Live Updates',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple,
                  AppColors.primaryPurple.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
          onPressed: _onRefresh,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    final active = _signals.where((s) => s.status == 'Active').length;
    final pending = _signals.where((s) => s.status == 'Pending').length;
    final completed = _signals.where((s) => s.status == 'Completed').length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withOpacity(0.1),
            AppColors.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryPurple, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple,
                      AppColors.primaryPurple.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.signal_cellular_alt, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Trading Signals',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time market analysis',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(_pulseAnimation.value * 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withOpacity(_pulseAnimation.value),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBox('Active', active, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox('Pending', pending, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox('Completed', completed, AppColors.primaryPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                style: TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search symbols...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: AppColors.primaryPurple),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _showOnlyActive = !_showOnlyActive),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: _showOnlyActive
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryPurple,
                          AppColors.primaryPurple.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: _showOnlyActive ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showOnlyActive
                      ? AppColors.primaryPurple
                      : AppColors.primaryPurple.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _showOnlyActive
                        ? AppColors.primaryPurple.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: _showOnlyActive ? Colors.white : AppColors.primaryPurple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showOnlyActive ? 'Active' : 'All',
                    style: TextStyle(
                      color: _showOnlyActive ? Colors.white : AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade50.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.access_time, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multiple Timeframe Analysis',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Signals analyzed across 1H, 4H, and Daily charts',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalsSliver(List<TradingSignal> visible) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final s = visible[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSignalCard(s),
            );
          },
          childCount: visible.length,
        ),
      ),
    );
  }

  Widget _emptySliver() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.signal_cellular_off, size: 48, color: AppColors.primaryPurple.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No Signals Found',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try clearing your search or changing filters',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalCard(TradingSignal signal) {
    final isBuy = signal.action == 'BUY';
    final statusColor = _getStatusColor(signal.status);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              // Symbol with icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.1),
                      AppColors.primaryPurple.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSymbolIcon(signal.pair),
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.pair,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _getCategoryLabel(signal.pair),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          ' • ${signal.timeframe}',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Text(
                  signal.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Action Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBuy
                        ? [Colors.green, Colors.green.shade700]
                        : [Colors.red, Colors.red.shade700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: (isBuy ? Colors.green : Colors.red).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  signal.action,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Price Information
          Row(
            children: [
              Expanded(
                child: _buildPriceBox(
                  'ENTRY', 
                  signal.entryPrice, 
                  AppColors.primaryPurple,
                  signal.pair,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriceBox(
                  'STOP LOSS', 
                  signal.stopLoss, 
                  Colors.red,
                  signal.pair,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriceBox(
                  'TAKE PROFIT', 
                  signal.takeProfit, 
                  Colors.green,
                  signal.pair,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bottom Row
          Row(
            children: [
              // Confidence
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.15),
                      Colors.orange.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Confidence: ${signal.confidence}%',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey.shade600, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(signal.lastUpdated),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBox(String label, double price, Color color, String pair) {
    // Determine decimal places based on instrument type
    int decimals = 5;
    if (pair.contains('JPY')) {
      decimals = 3;
    } else if (pair.contains('XAU') || pair.contains('XAG')) {
      decimals = 2;
    } else if (pair.contains('BTC') || pair.contains('ETH') || pair.contains('BNB')) {
      decimals = 2;
    } else if (pair.contains('/USD') && !pair.contains('BTC') && !pair.contains('ETH')) {
      decimals = 5;
    } else {
      decimals = 2;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price.toStringAsFixed(decimals),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSymbolIcon(String pair) {
    if (pair.contains('BTC') || pair.contains('ETH') || pair.contains('BNB')) {
      return Icons.currency_bitcoin;
    } else if (pair.contains('XAU') || pair.contains('XAG')) {
      return Icons.diamond;
    } else if (pair.contains('USD') || pair.contains('EUR') || pair.contains('GBP')) {
      return Icons.attach_money;
    } else {
      return Icons.show_chart;
    }
  }

  String _getCategoryLabel(String pair) {
    if (pair.contains('BTC') || pair.contains('ETH') || pair.contains('BNB')) {
      return 'Cryptocurrency';
    } else if (pair.contains('XAU')) {
      return 'Gold';
    } else if (pair.contains('XAG')) {
      return 'Silver';
    } else if (pair.contains('/')) {
      return 'Forex';
    } else {
      return 'Stock';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return AppColors.primaryPurple;
      default:
        return Colors.grey;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

// Trading Signal Model
class TradingSignal {
  final String pair;
  final String action;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit;
  final int confidence;
  final DateTime lastUpdated;
  final String status;
  final String timeframe;

  TradingSignal({
    required this.pair,
    required this.action,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.confidence,
    required this.lastUpdated,
    required this.status,
    required this.timeframe,
  });

  factory TradingSignal.create(
    String pair,
    String action,
    double entry,
    double sl,
    double tp,
    int conf,
    DateTime updated,
    String status,
    String timeframe,
  ) {
    return TradingSignal(
      pair: pair,
      action: action,
      entryPrice: entry,
      stopLoss: sl,
      takeProfit: tp,
      confidence: conf,
      lastUpdated: updated,
      status: status,
      timeframe: timeframe,
    );
  }

  TradingSignal copyWith({
    String? pair,
    String? action,
    double? entryPrice,
    double? stopLoss,
    double? takeProfit,
    int? confidence,
    DateTime? lastUpdated,
    String? status,
    String? timeframe,
  }) {
    return TradingSignal(
      pair: pair ?? this.pair,
      action: action ?? this.action,
      entryPrice: entryPrice ?? this.entryPrice,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      confidence: confidence ?? this.confidence,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
      timeframe: timeframe ?? this.timeframe,
    );
  }
}
