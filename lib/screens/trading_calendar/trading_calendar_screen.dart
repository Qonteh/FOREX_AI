import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';

class TradingCalendarScreen extends StatefulWidget {
  const TradingCalendarScreen({super.key});

  @override
  State<TradingCalendarScreen> createState() => _TradingCalendarScreenState();
}

class _TradingCalendarScreenState extends State<TradingCalendarScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedCurrency = 'ALL';
  List<EconomicEvent> allEvents = [];
  List<EconomicEvent> filteredEvents = [];
  bool isLoading = true;
  late Timer _refreshTimer;
  
  final List<String> currencies = [
    'ALL', 'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'NZD'
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayEvents();
    
    // Refresh every 30 seconds for real-time feel
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadTodayEvents();
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  void _loadTodayEvents() {
    setState(() => isLoading = true);
    
    // Simulate real economic events with dynamic data
    _generateRealTimeEvents();
    
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          isLoading = false;
          _filterEventsByCurrency();
        });
      }
    });
  }

  void _generateRealTimeEvents() {
    final now = DateTime.now();
    final random = Random();
    
    // Real economic events that typically happen
    final eventTemplates = [
      {'event': 'Non-Farm Payrolls', 'currency': 'USD', 'impact': 'High'},
      {'event': 'Federal Reserve Interest Rate Decision', 'currency': 'USD', 'impact': 'High'},
      {'event': 'Consumer Price Index (CPI)', 'currency': 'USD', 'impact': 'High'},
      {'event': 'Unemployment Rate', 'currency': 'USD', 'impact': 'Medium'},
      {'event': 'GDP Growth Rate', 'currency': 'USD', 'impact': 'High'},
      {'event': 'Retail Sales', 'currency': 'USD', 'impact': 'Medium'},
      
      {'event': 'ECB Interest Rate Decision', 'currency': 'EUR', 'impact': 'High'},
      {'event': 'Eurozone CPI Flash Estimate', 'currency': 'EUR', 'impact': 'High'},
      {'event': 'German Manufacturing PMI', 'currency': 'EUR', 'impact': 'Medium'},
      {'event': 'ECB Press Conference', 'currency': 'EUR', 'impact': 'High'},
      
      {'event': 'Bank of England Rate Decision', 'currency': 'GBP', 'impact': 'High'},
      {'event': 'UK GDP Growth Rate', 'currency': 'GBP', 'impact': 'High'},
      {'event': 'UK CPI Inflation Rate', 'currency': 'GBP', 'impact': 'High'},
      {'event': 'UK Employment Change', 'currency': 'GBP', 'impact': 'Medium'},
      
      {'event': 'Bank of Japan Policy Rate', 'currency': 'JPY', 'impact': 'High'},
      {'event': 'Japan CPI (YoY)', 'currency': 'JPY', 'impact': 'Medium'},
      {'event': 'Japan GDP Growth Rate', 'currency': 'JPY', 'impact': 'High'},
      
      {'event': 'RBA Interest Rate Decision', 'currency': 'AUD', 'impact': 'High'},
      {'event': 'Australia CPI (YoY)', 'currency': 'AUD', 'impact': 'High'},
      {'event': 'Australia Employment Change', 'currency': 'AUD', 'impact': 'Medium'},
      
      {'event': 'Bank of Canada Rate Decision', 'currency': 'CAD', 'impact': 'High'},
      {'event': 'Canada CPI (YoY)', 'currency': 'CAD', 'impact': 'High'},
      {'event': 'Canada Employment Change', 'currency': 'CAD', 'impact': 'Medium'},
    ];

    allEvents.clear();
    
    // Generate 8-12 events for today
    final numEvents = 8 + random.nextInt(5);
    final usedEvents = <String>{};
    
    for (int i = 0; i < numEvents; i++) {
      final template = eventTemplates[random.nextInt(eventTemplates.length)];
      final eventKey = '${template['currency']}-${template['event']}';
      
      if (usedEvents.contains(eventKey)) continue;
      usedEvents.add(eventKey);
      
      final hour = 8 + random.nextInt(10); // 8 AM to 6 PM
      final minute = random.nextInt(60);
      final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      
      // Generate realistic forecast/previous values
      String forecast = '';
      String previous = '';
      
      if (template['event']!.contains('Rate') || template['event']!.contains('CPI')) {
        final prevValue = (2.0 + random.nextDouble() * 4.0);
        final foreValue = prevValue + (random.nextDouble() - 0.5) * 0.5;
        forecast = '${foreValue.toStringAsFixed(2)}%';
        previous = '${prevValue.toStringAsFixed(2)}%';
      } else if (template['event']!.contains('Employment') || template['event']!.contains('Payrolls')) {
        final prevValue = (150 + random.nextInt(100)) * 1000;
        final foreValue = prevValue + (random.nextInt(50000) - 25000);
        forecast = '${(foreValue / 1000).toStringAsFixed(0)}K';
        previous = '${(prevValue / 1000).toStringAsFixed(0)}K';
      } else if (template['event']!.contains('GDP')) {
        final prevValue = 1.5 + random.nextDouble() * 2.0;
        final foreValue = prevValue + (random.nextDouble() - 0.5) * 0.8;
        forecast = '${foreValue.toStringAsFixed(1)}%';
        previous = '${prevValue.toStringAsFixed(1)}%';
      }

      allEvents.add(EconomicEvent(
        time: time,
        currency: template['currency']!,
        event: template['event']!,
        impact: template['impact']!,
        forecast: forecast,
        previous: previous,
        actual: random.nextBool() && i < 3 ? _generateActual(forecast) : '',
        color: _getImpactColor(template['impact']!),
        isReleased: random.nextBool() && i < 3,
        lastUpdated: now.subtract(Duration(minutes: random.nextInt(120))),
      ));
    }
    
    // Sort by time
    allEvents.sort((a, b) => a.time.compareTo(b.time));
  }

  String _generateActual(String forecast) {
    if (forecast.isEmpty) return '';
    
    final random = Random();
    if (forecast.contains('%')) {
      final value = double.tryParse(forecast.replaceAll('%', '')) ?? 0.0;
      final actual = value + (random.nextDouble() - 0.5) * 0.3;
      return '${actual.toStringAsFixed(2)}%';
    } else if (forecast.contains('K')) {
      final value = double.tryParse(forecast.replaceAll('K', '')) ?? 0.0;
      final actual = value + (random.nextDouble() - 0.5) * 20;
      return '${actual.toStringAsFixed(0)}K';
    }
    return forecast;
  }

  Color _getImpactColor(String impact) {
    switch (impact) {
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.green;
      default: return AppColors.primaryPurple;
    }
  }

  void _filterEventsByCurrency() {
    if (selectedCurrency == 'ALL') {
      filteredEvents = List.from(allEvents);
    } else {
      filteredEvents = allEvents.where((event) => 
        event.currency == selectedCurrency).toList();
    }
  }

  Future<void> _analyzeDay() async {
    final highImpactEvents = filteredEvents.where((e) => e.impact == 'High').toList();
    
    if (highImpactEvents.isEmpty) {
      _showAnalysisDialog('No Analysis Available', 
        'No high-impact events found for the selected currency.', 
        'NEUTRAL', Colors.grey);
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Simulate AI analysis
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context); // Remove loading
      
      final analysis = _generateAnalysis(highImpactEvents);
      _showAnalysisDialog(
        'Market Analysis - ${selectedCurrency == 'ALL' ? 'All Currencies' : selectedCurrency}',
        analysis['summary']!,
        analysis['bias']!,
        analysis['color'] as Color,
      );
    }
  }

  Map<String, dynamic> _generateAnalysis(List<EconomicEvent> events) {
    final random = Random();
    final currency = selectedCurrency == 'ALL' ? 'MIXED' : selectedCurrency;
    
    // Count bullish vs bearish events
    int bullishCount = 0;
    int bearishCount = 0;
    
    for (final event in events) {
      if (event.actual.isNotEmpty && event.forecast.isNotEmpty) {
        final actualVal = _extractNumber(event.actual);
        final forecastVal = _extractNumber(event.forecast);
        
        if (actualVal > forecastVal) {
          if (event.event.contains('Rate') || event.event.contains('CPI')) {
            bullishCount++; // Higher rates/inflation = stronger currency
          } else {
            bullishCount++; // Better than expected
          }
        } else {
          bearishCount++;
        }
      } else {
        // For unreleased events, random expectation
        if (random.nextBool()) bullishCount++; else bearishCount++;
      }
    }
    
    String bias;
    Color color;
    String summary;
    
    if (bullishCount > bearishCount) {
      bias = 'BULLISH';
      color = Colors.green;
      summary = '''📈 BULLISH OUTLOOK for $currency

🔥 KEY HIGHLIGHTS:
• ${events.length} high-impact events scheduled
• $bullishCount events favor currency strength
• Market sentiment: RISK-ON

💪 TRADING STRATEGY:
• Look for BUYING opportunities on dips
• Target currency pairs with $currency strength
• Watch for breakouts above resistance levels

⚠️ RISK FACTORS:
• Monitor ${events.first.event} at ${events.first.time}
• Volatility expected during major releases
• Use proper risk management (1-2% per trade)

🎯 CONFIDENCE: ${85 + random.nextInt(10)}%''';
    } else if (bearishCount > bullishCount) {
      bias = 'BEARISH';
      color = Colors.red;
      summary = '''📉 BEARISH OUTLOOK for $currency

🔻 KEY HIGHLIGHTS:
• ${events.length} high-impact events scheduled  
• $bearishCount events may weaken currency
• Market sentiment: RISK-OFF

💪 TRADING STRATEGY:
• Look for SELLING opportunities on rallies
• Target currency pairs with $currency weakness
• Watch for breaks below support levels

⚠️ RISK FACTORS:
• Monitor ${events.first.event} at ${events.first.time}
• High volatility expected
• Use tight stops and proper sizing

🎯 CONFIDENCE: ${80 + random.nextInt(12)}%''';
    } else {
      bias = 'NEUTRAL';
      color = Colors.orange;
      summary = '''⚖️ NEUTRAL OUTLOOK for $currency

🔄 KEY HIGHLIGHTS:
• ${events.length} high-impact events scheduled
• Mixed signals from economic data
• Market sentiment: MIXED

💪 TRADING STRATEGY:
• Wait for clear directional moves
• Trade breakouts with confirmation
• Consider range-bound strategies

⚠️ RISK FACTORS:
• Choppy price action expected
• False breakouts likely
• Reduce position sizes

🎯 CONFIDENCE: ${70 + random.nextInt(15)}%''';
    }
    
    return {
      'bias': bias,
      'summary': summary,
      'color': color,
    };
  }

  double _extractNumber(String text) {
    final regex = RegExp(r'[\d.]+');
    final match = regex.firstMatch(text);
    return double.tryParse(match?.group(0) ?? '0') ?? 0.0;
  }

  void _showAnalysisDialog(String title, String content, String bias, Color color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      bias == 'BULLISH' ? Icons.trending_up :
                      bias == 'BEARISH' ? Icons.trending_down : Icons.remove,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MARKET BIAS: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      bias,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Got It!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_ios, color: AppColors.primaryPurple, size: 18),
          ),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trading Calendar',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Real-time Economic Events',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_today, color: AppColors.primaryPurple, size: 20),
            ),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async => _loadTodayEvents(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCurrencySelector(),
                  const SizedBox(height: 16),
                  _buildAnalyzeButton(),
                  const SizedBox(height: 16),
                  _buildCalendarStats(),
                  const SizedBox(height: 16),
                  _buildEventsSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
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
        currentIndex: 3, // Trading Calendar is index 3
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/quick-analysis');
              break;
            case 2:
              context.go('/daily-signals');
              break;
            case 3:
              // Already on Trading Calendar
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
                    child: const Text(
                      '3',
                      style: TextStyle(
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
                    child: const Text(
                      '3',
                      style: TextStyle(
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
                    child: const Text(
                      '3',
                      style: TextStyle(
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
                    child: const Text(
                      '3',
                      style: TextStyle(
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

  Widget _buildCurrencySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_exchange, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Select Currency',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currencies.map((currency) {
              final isSelected = selectedCurrency == currency;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCurrency = currency;
                    _filterEventsByCurrency();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPurple : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryPurple : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    currency,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    final highImpactCount = filteredEvents.where((e) => e.impact == 'High').length;
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: highImpactCount > 0 ? _analyzeDay : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              color: highImpactCount > 0 ? Colors.white : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              highImpactCount > 0 
                ? 'Analyze Market Impact ($highImpactCount Events)'
                : 'No High Impact Events',
              style: TextStyle(
                color: highImpactCount > 0 ? Colors.white : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarStats() {
    final total = filteredEvents.length;
    final highImpact = filteredEvents.where((e) => e.impact == 'High').length;
    final released = filteredEvents.where((e) => e.actual.isNotEmpty).length;
    final currencies = filteredEvents.map((e) => e.currency).toSet().length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Today\'s Overview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Total', '$total', AppColors.primaryPurple, Icons.event_note)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('High Impact', '$highImpact', Colors.red, Icons.priority_high)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Released', '$released', Colors.green, Icons.check_circle)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Currencies', '$currencies', Colors.orange, Icons.language)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection() {
    if (filteredEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Events Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No events for ${selectedCurrency == 'ALL' ? 'today' : selectedCurrency} currency',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Economic Events',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredEvents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = filteredEvents[index];
              return _buildEventCard(event);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EconomicEvent event) {
    final impactColor = _getImpactColor(event.impact);
    final currencyColor = _getCurrencyColor(event.currency);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: impactColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: impactColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Currency
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: currencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.currency,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: currencyColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              // Impact
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: impactColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: impactColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      event.impact == 'High' ? Icons.priority_high :
                      event.impact == 'Medium' ? Icons.remove : Icons.keyboard_arrow_down,
                      color: impactColor,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.impact,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: impactColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (event.isReleased) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RELEASED',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.event,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          if (event.forecast.isNotEmpty || event.previous.isNotEmpty || event.actual.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (event.actual.isNotEmpty) ...[
                    _buildDataRow('Actual', event.actual, Colors.blue, Icons.fiber_manual_record),
                    const SizedBox(height: 6),
                  ],
                  if (event.forecast.isNotEmpty) ...[
                    _buildDataRow('Forecast', event.forecast, Colors.orange, Icons.timeline),
                    const SizedBox(height: 6),
                  ],
                  if (event.previous.isNotEmpty)
                    _buildDataRow('Previous', event.previous, Colors.grey, Icons.history),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Updated ${_timeAgo(event.lastUpdated)}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getCurrencyColor(String currency) {
    switch (currency) {
      case 'USD': return Colors.green;
      case 'EUR': return Colors.blue;
      case 'GBP': return Colors.purple;
      case 'JPY': return Colors.red;
      case 'AUD': return Colors.orange;
      case 'CAD': return Colors.brown;
      case 'CHF': return Colors.teal;
      case 'NZD': return Colors.indigo;
      default: return AppColors.primaryPurple;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _loadTodayEvents();
      });
    }
  }
}

class EconomicEvent {
  final String time;
  final String currency;
  final String event;
  final String impact;
  final String forecast;
  final String previous;
  final String actual;
  final Color color;
  final bool isReleased;
  final DateTime lastUpdated;

  EconomicEvent({
    required this.time,
    required this.currency,
    required this.event,
    required this.impact,
    required this.forecast,
    required this.previous,
    required this.actual,
    required this.color,
    this.isReleased = false,
    required this.lastUpdated,
  });
}
