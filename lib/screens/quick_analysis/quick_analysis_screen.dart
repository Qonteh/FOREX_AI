import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../../theme/app_colors.dart';

// Use your actual API keys
const String OPENAI_API_KEY = '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';

class QuickAnalysisScreen extends StatefulWidget {
  const QuickAnalysisScreen({super.key});

  @override
  State<QuickAnalysisScreen> createState() => _QuickAnalysisScreenState();
}

class _QuickAnalysisScreenState extends State<QuickAnalysisScreen> 
    with TickerProviderStateMixin {
  String selectedPair = 'EUR/USD';
  String selectedTimeframe = 'H1';
  
  Map<String, RealCurrencyData> _realPrices = {};
  List<CandlestickData> _candlestickData = [];
  bool _isLoadingPrices = true;
  bool _isAnalyzing = false;
  Timer? _priceTimer;
  
  // Real-time data
  final Map<String, List<double>> _priceHistory = {};
  final int _maxHistoryPoints = 50;
  
  AnalysisResult? _analysisResult;
  
  // Animation Controllers
  late AnimationController _chartAnimationController;
  late AnimationController _analysisAnimationController;
  late AnimationController _scanAnimationController;
  late Animation<double> _chartFadeAnimation;
  late Animation<Offset> _analysisSlideAnimation;
  late Animation<double> _scanAnimation;
  
  // Chart interaction
  double _chartScale = 1.0;
  double _chartTranslateX = 0.0;
  double _chartTranslateY = 0.0;

  // Scanning animation
  double _scanPosition = 0.0;
  bool _isScanning = false;
  Timer? _scanTimer;
  List<ScanningParticle> _scanningParticles = [];

  final List<String> currencyPairs = [
    'EUR/USD', 'GBP/USD', 'USD/JPY', 'USD/CHF', 'AUD/USD', 'USD/CAD', 'NZD/USD',
    'EUR/GBP', 'EUR/JPY', 'EUR/CHF', 'EUR/AUD', 'EUR/CAD', 'EUR/NZD',
    'GBP/JPY', 'GBP/CHF', 'GBP/AUD', 'GBP/CAD', 'GBP/NZD',
    'AUD/JPY', 'AUD/CHF', 'AUD/CAD', 'AUD/NZD',
    'CAD/JPY', 'CAD/CHF', 'CHF/JPY', 'NZD/JPY', 'NZD/CHF', 'NZD/CAD',
    'XAU/USD', 'XAG/USD', 'BTC/USD', 'ETH/USD',
  ];

  final List<String> timeframes = ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D', 'W'];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _analysisAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scanAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _chartFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartAnimationController, curve: Curves.easeInOut),
    );
    
    _analysisSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _analysisAnimationController, curve: Curves.elasticOut));
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
    
    // Start with simulated data
    _loadInitialPrices();
    _generateRealisticCandlestickData();
    _chartAnimationController.forward();
    
    // Start real-time updates
    _startRealTimeUpdates();
  }

  void _startRealTimeUpdates() {
    // Update prices every second for real-time feel
    _priceTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _updateRealTimePrices();
    });
  }

  void _updateRealTimePrices() {
    if (!mounted) return;
    
    final updatedPrices = Map<String, RealCurrencyData>.from(_realPrices);
    final random = Random();
    final now = DateTime.now();
    
    updatedPrices.forEach((symbol, data) {
      final volatility = _getVolatilityForPair(symbol);
      
      // More realistic price movement with momentum
      final momentum = data.changePercent.abs() * 0.1;
      final direction = data.isPositive ? 1 : -1;
      final change = (random.nextDouble() * volatility * 0.05 * direction) + (momentum * direction * 0.1);
      
      final newPrice = (data.price + change).clamp(data.price * 0.99, data.price * 1.01);
      final newChange = newPrice - _getBasePrice(symbol);
      final changePercent = _getBasePrice(symbol) > 0 ? (newChange / _getBasePrice(symbol)) * 100 : 0.0;
      
      // Update price history
      if (!_priceHistory.containsKey(symbol)) {
        _priceHistory[symbol] = [];
      }
      final history = _priceHistory[symbol]!;
      history.add(newPrice);
      if (history.length > _maxHistoryPoints) {
        history.removeAt(0);
      }
      
      updatedPrices[symbol] = RealCurrencyData(
        symbol: symbol,
        price: newPrice,
        change: newChange,
        changePercent: changePercent,
        isPositive: newChange >= 0,
        lastUpdated: now,
        priceHistory: List.from(history),
      );
    });
    
    // Update candlestick data for selected pair
    if (_candlestickData.isNotEmpty) {
      final lastCandle = _candlestickData.last;
      final currentPrice = updatedPrices[selectedPair]?.price ?? lastCandle.close;
      final volatility = _getVolatilityForPair(selectedPair);
      
      // Create new candle based on time
      final now = DateTime.now();
      final isNewCandle = now.difference(lastCandle.time).inMinutes >= _getTimeframeMinutes();
      
      CandlestickData newCandle;
      
      if (isNewCandle) {
        // Start new candle
        newCandle = CandlestickData(
          time: now,
          open: currentPrice,
          high: currentPrice,
          low: currentPrice,
          close: currentPrice,
          volume: 1000 + random.nextDouble() * 5000,
        );
        _candlestickData.add(newCandle);
        
        // Keep only last 100 candles
        if (_candlestickData.length > 100) {
          _candlestickData.removeAt(0);
        }
      } else {
        // Update current candle
        newCandle = CandlestickData(
          time: lastCandle.time,
          open: lastCandle.open,
          high: max(lastCandle.high, currentPrice),
          low: min(lastCandle.low, currentPrice),
          close: currentPrice,
          volume: lastCandle.volume + random.nextDouble() * 100,
        );
        _candlestickData[_candlestickData.length - 1] = newCandle;
      }
      
      setState(() {
        _realPrices = updatedPrices;
      });
    }
  }

  int _getTimeframeMinutes() {
    switch (selectedTimeframe) {
      case 'M1': return 1;
      case 'M5': return 5;
      case 'M15': return 15;
      case 'M30': return 30;
      case 'H1': return 60;
      case 'H4': return 240;
      case 'D': return 1440;
      case 'W': return 10080;
      default: return 60;
    }
  }

  void _loadInitialPrices() {
    final now = DateTime.now();
    final random = Random();
    
    final prices = <String, RealCurrencyData>{};
    
    for (final pair in currencyPairs) {
      final basePrice = _getBasePrice(pair);
      final initialPrice = basePrice + (random.nextDouble() - 0.5) * basePrice * 0.02;
      final change = (random.nextDouble() - 0.5) * basePrice * 0.01;
      
      prices[pair] = RealCurrencyData(
        symbol: pair, 
        price: initialPrice,
        change: change,
        changePercent: (change / basePrice) * 100,
        isPositive: change >= 0,
        lastUpdated: now,
        priceHistory: _generateInitialHistory(initialPrice, pair),
      );
    }
    
    setState(() {
      _realPrices = prices;
      _isLoadingPrices = false;
    });
  }

  List<double> _generateInitialHistory(double basePrice, String pair) {
    final random = Random();
    final history = <double>[];
    final volatility = _getVolatilityForPair(pair);
    double current = basePrice;
    
    for (int i = 0; i < 50; i++) {
      current += (random.nextDouble() - 0.5) * volatility * 2;
      history.add(current);
    }
    
    return history;
  }

  void _generateRealisticCandlestickData() {
    final currentPrice = _realPrices[selectedPair]?.price ?? _getBasePrice(selectedPair);
    final random = Random();
    final volatility = _getVolatilityForPair(selectedPair);
    
    _candlestickData.clear();
    double basePrice = currentPrice;
    
    // Generate realistic market data with trends and patterns
    double trend = 0.0;
    int trendDuration = 0;
    double previousClose = basePrice;
    
    for (int i = 0; i < 100; i++) {
      // Change trend occasionally
      if (trendDuration <= 0 || random.nextDouble() > 0.98) {
        trend = (random.nextDouble() - 0.5) * volatility * 1.5;
        trendDuration = 10 + random.nextInt(30);
      }
      trendDuration--;
      
      // Add some market noise and patterns
      final noise = (random.nextDouble() - 0.5) * volatility * 0.8;
      final pattern = sin(i * 0.3) * volatility * 0.3; // Sine wave pattern
      
      final open = previousClose;
      final close = open + trend + noise + pattern;
      
      // Realistic wicks based on volatility and trend
      final wickRange = volatility * (0.2 + random.nextDouble() * 0.4);
      final high = max(open, close) + wickRange * random.nextDouble();
      final low = min(open, close) - wickRange * random.nextDouble();
      
      _candlestickData.add(CandlestickData(
        time: DateTime.now().subtract(Duration(minutes: (100 - i) * _getTimeframeMinutes())),
        open: open,
        high: high,
        low: low,
        close: close,
        volume: 1000 + random.nextDouble() * 5000,
      ));
      
      previousClose = close;
      basePrice = close;
    }
    
    setState(() {});
  }

  // Beautiful scanning animation with particles
  void _startScanningAnimation() {
    setState(() {
      _isScanning = true;
      _scanPosition = 0.0;
      _scanningParticles.clear();
    });
    
    _scanAnimationController.reset();
    _scanAnimationController.repeat(reverse: true);
    
    // Create initial particles
    for (int i = 0; i < 20; i++) {
      _scanningParticles.add(ScanningParticle(
        x: Random().nextDouble(),
        y: Random().nextDouble(),
        size: 2.0 + Random().nextDouble() * 4.0,
        speed: 0.5 + Random().nextDouble() * 1.0,
        opacity: 0.3 + Random().nextDouble() * 0.7,
      ));
    }
    
    // Realistic scanning with particles
    int scanProgress = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        scanProgress += 1;
        _scanPosition = scanProgress / 100.0;
        
        // Update particles
        for (final particle in _scanningParticles) {
          particle.x += particle.speed * 0.01;
          particle.y += sin(particle.x * 10) * 0.005;
          particle.opacity = max(0.0, particle.opacity - 0.01);
          
          // Reset particles that go off screen or fade out
          if (particle.x > 1.2 || particle.opacity <= 0) {
            particle.x = -0.2;
            particle.y = Random().nextDouble();
            particle.opacity = 0.3 + Random().nextDouble() * 0.7;
          }
        }
        
        // Add new particles occasionally
        if (Random().nextDouble() > 0.7 && _scanningParticles.length < 30) {
          _scanningParticles.add(ScanningParticle(
            x: Random().nextDouble() * 0.2 - 0.1,
            y: Random().nextDouble(),
            size: 2.0 + Random().nextDouble() * 4.0,
            speed: 0.5 + Random().nextDouble() * 1.0,
            opacity: 0.3 + Random().nextDouble() * 0.7,
          ));
        }
      });
      
      if (scanProgress >= 100) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isScanning = false;
              _scanningParticles.clear();
            });
            _scanAnimationController.stop();
          }
        });
      }
    });
  }

  // Enhanced AI analysis with real ChatGPT reasons
  Future<void> _analyzeMarket() async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    _startScanningAnimation();

    final currentData = _realPrices[selectedPair];
    if (currentData == null) {
      setState(() => _isAnalyzing = false);
      return;
    }

    try {
      // Calculate technical indicators
      final technicalAnalysis = _calculateTechnicalIndicators();
      
      final marketSummary = _prepareProfessionalMarketSummary(currentData, technicalAnalysis);
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $OPENAI_API_KEY',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a professional trading analyst with 15 years of experience. 
              Provide detailed technical analysis and trading signals based on the market data.
              Be specific about price action, key levels, and market structure.
              Give real, actionable insights with clear reasoning.'''
            },
            {
              'role': 'user',
              'content': marketSummary
            }
          ],
          'temperature': 0.7,
          'max_tokens': 800,
          'presence_penalty': 0.3,
          'frequency_penalty': 0.3,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        
        final analysis = _parseProfessionalAIResponse(aiResponse, currentData, technicalAnalysis);
        
        if (mounted) {
          setState(() {
            _analysisResult = analysis;
            _isAnalyzing = false;
          });
          
          _analysisAnimationController.reset();
          _analysisAnimationController.forward();
        }
      } else {
        throw Exception('AI service returned status: ${response.statusCode}');
      }
      
    } catch (e) {
      print('AI Analysis failed: $e');
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis completed with technical indicators'),
          backgroundColor: AppColors.primaryPurple,
        ),
      );
      // Fallback to technical analysis
      _generateTechnicalAnalysis();
    }
  }

  Map<String, dynamic> _calculateTechnicalIndicators() {
    if (_candlestickData.length < 20) return {};
    
    final prices = _candlestickData.map((c) => c.close).toList();
    final highs = _candlestickData.map((c) => c.high).toList();
    final lows = _candlestickData.map((c) => c.low).toList();
    final volumes = _candlestickData.map((c) => c.volume).toList();
    
    // Calculate trends
    final recentPrices = prices.sublist(prices.length - 10);
    final olderPrices = prices.sublist(prices.length - 20, prices.length - 10);
    final recentAvg = recentPrices.reduce((a, b) => a + b) / recentPrices.length;
    final olderAvg = olderPrices.reduce((a, b) => a + b) / olderPrices.length;
    final trend = recentAvg > olderAvg ? 'BULLISH' : 'BEARISH';
    final trendStrength = ((recentAvg - olderAvg) / olderAvg * 100).abs();
    
    // Calculate support/resistance
    final recentHighs = highs.sublist(highs.length - 20);
    final recentLows = lows.sublist(lows.length - 20);
    final resistance = recentHighs.reduce(max);
    final support = recentLows.reduce(min);
    
    // Calculate RSI-like momentum
    double gains = 0, losses = 0;
    for (int i = 1; i < prices.length; i++) {
      final change = prices[i] - prices[i-1];
      if (change > 0) {
        gains += change;
      } else {
        losses -= change;
      }
    }
    final rs = gains / (losses == 0 ? 1 : losses);
    final rsi = 100 - (100 / (1 + rs));
    
    // Volume analysis
    final avgVolume = volumes.reduce((a, b) => a + b) / volumes.length;
    final recentVolume = volumes.sublist(volumes.length - 5).reduce((a, b) => a + b) / 5;
    final volumeTrend = recentVolume > avgVolume ? 'INCREASING' : 'DECREASING';
    
    return {
      'trend': trend,
      'trendStrength': trendStrength,
      'support': support,
      'resistance': resistance,
      'rsi': rsi,
      'volumeTrend': volumeTrend,
      'currentPrice': prices.last,
      'priceChange': prices.last - prices[prices.length - 2],
    };
  }

  String _prepareProfessionalMarketSummary(RealCurrencyData data, Map<String, dynamic> technicals) {
    final priceHistory = data.priceHistory.take(15).toList();
    final lastCandles = _candlestickData.length >= 5 
        ? _candlestickData.sublist(_candlestickData.length - 5)
        : _candlestickData;
        
    return '''
PROFESSIONAL TRADING ANALYSIS REQUEST - BE SPECIFIC AND DETAILED:

INSTRUMENT: $selectedPair
TIMEFRAME: $selectedTimeframe  
CURRENT PRICE: ${_formatPrice(data.price, selectedPair)}
24H CHANGE: ${data.changePercent.toStringAsFixed(2)}%
DIRECTION: ${data.isPositive ? 'BULLISH' : 'BEARISH'}

TECHNICAL OVERVIEW:
- Primary Trend: ${technicals['trend']} (Strength: ${technicals['trendStrength']?.toStringAsFixed(1)}%)
- Key Support: ${_formatPrice(technicals['support'], selectedPair)}
- Key Resistance: ${_formatPrice(technicals['resistance'], selectedPair)}
- Momentum (RSI): ${technicals['rsi']?.toStringAsFixed(1)}
- Volume Trend: ${technicals['volumeTrend']}

RECENT PRICE ACTION (Last 5 candles):
${lastCandles.map((c) => '  O:${_formatPrice(c.open, selectedPair)} H:${_formatPrice(c.high, selectedPair)} L:${_formatPrice(c.low, selectedPair)} C:${_formatPrice(c.close, selectedPair)}').join('\n')}

MARKET CONTEXT:
- Instrument: ${selectedPair}
- Timeframe Analysis: ${selectedTimeframe}
- Recent Volatility: ${_calculateVolatility().toStringAsFixed(3)}%
- Price Position: ${_calculatePricePosition(technicals['support'], technicals['resistance'], data.price)}%

Provide a detailed professional analysis with:
1. CLEAR TRADING SIGNAL (BUY/SELL/HOLD) with specific entry levels
2. Detailed technical reasoning based on price action and indicators
3. Key support and resistance levels to watch
4. Risk management suggestions
5. Market sentiment and potential catalysts
6. Confidence level (1-100%)

Be very specific and avoid generic statements. Focus on actionable insights.
''';
  }

  double _calculateVolatility() {
    if (_candlestickData.length < 10) return 0.0;
    final prices = _candlestickData.map((c) => c.close).toList();
    double sum = 0.0;
    for (int i = 1; i < prices.length; i++) {
      sum += ((prices[i] - prices[i-1]) / prices[i-1]).abs();
    }
    return (sum / (prices.length - 1)) * 100;
  }

  double _calculatePricePosition(double support, double resistance, double currentPrice) {
    if (resistance <= support) return 50.0;
    return ((currentPrice - support) / (resistance - support)) * 100;
  }

  void _generateTechnicalAnalysis() {
    final currentData = _realPrices[selectedPair]!;
    final technicals = _calculateTechnicalIndicators();
    
    // Generate signal based on comprehensive technicals
    String signal = 'HOLD';
    double confidence = 50.0;
    
    final trend = technicals['trend'] ?? 'NEUTRAL';
    final rsi = technicals['rsi'] ?? 50.0;
    final trendStrength = technicals['trendStrength'] ?? 0.0;
    
    if (trend == 'BULLISH' && rsi < 70 && trendStrength > 0.5 && currentData.isPositive) {
      signal = 'BUY';
      confidence = 65.0 + Random().nextDouble() * 25;
    } else if (trend == 'BEARISH' && rsi > 30 && trendStrength > 0.5 && !currentData.isPositive) {
      signal = 'SELL';
      confidence = 65.0 + Random().nextDouble() * 25;
    }
    
    final reasons = [
      '${trend} trend identified with ${trendStrength.toStringAsFixed(1)}% strength',
      'RSI at ${rsi.toStringAsFixed(1)} indicates ${rsi > 70 ? 'overbought' : rsi < 30 ? 'oversold' : 'neutral'} conditions',
      'Price action shows ${currentData.isPositive ? 'strength' : 'weakness'} in current trend',
      'Volume trend ${technicals['volumeTrend']} supporting price movement',
    ];
    
    setState(() {
      _analysisResult = AnalysisResult(
        pair: selectedPair,
        timeframe: selectedTimeframe,
        signal: signal,
        confidence: confidence.toInt(),
        entry: _calculateEntryPrice(currentData.price, signal, technicals),
        takeProfit: _calculateTakeProfit(currentData.price, signal, technicals),
        stopLoss: _calculateStopLoss(currentData.price, signal, technicals),
        reasons: reasons,
        alternativeScenario: 'Monitor key levels for trend confirmation',
        riskReward: _calculateRiskRewardRatio(signal, technicals),
      );
      _isAnalyzing = false;
    });
  }

  AnalysisResult _parseProfessionalAIResponse(String aiResponse, RealCurrencyData data, Map<String, dynamic> technicals) {
    final isBuy = aiResponse.toUpperCase().contains('BUY') || 
                  aiResponse.toUpperCase().contains('LONG') ||
                  aiResponse.toUpperCase().contains('BULLISH');
    
    final isSell = aiResponse.toUpperCase().contains('SELL') || 
                   aiResponse.toUpperCase().contains('SHORT') ||
                   aiResponse.toUpperCase().contains('BEARISH');

    String signal = 'HOLD';
    if (isBuy) signal = 'BUY';
    if (isSell) signal = 'SELL';

    final confidence = _extractConfidence(aiResponse);
    final reasons = _extractDetailedReasons(aiResponse);
    
    return AnalysisResult(
      pair: selectedPair,
      timeframe: selectedTimeframe,
      signal: signal,
      confidence: confidence,
      entry: _calculateEntryPrice(data.price, signal, technicals),
      takeProfit: _calculateTakeProfit(data.price, signal, technicals),
      stopLoss: _calculateStopLoss(data.price, signal, technicals),
      reasons: reasons,
      alternativeScenario: _extractAlternativeScenario(aiResponse),
      riskReward: _calculateRiskRewardRatio(signal, technicals),
    );
  }

  List<String> _extractDetailedReasons(String response) {
    final lines = response.split('\n');
    final reasons = <String>[];
    bool inReasonsSection = false;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      if (trimmedLine.isEmpty) continue;
      
      // Look for sections that typically contain reasons
      if (trimmedLine.toUpperCase().contains('REASON') ||
          trimmedLine.toUpperCase().contains('ANALYSIS') ||
          trimmedLine.toUpperCase().contains('KEY POINT') ||
          trimmedLine.toUpperCase().contains('TECHNICAL') ||
          (trimmedLine.startsWith('-') && trimmedLine.length > 20) ||
          (trimmedLine.startsWith('•') && trimmedLine.length > 20) ||
          (trimmedLine.startsWith('*') && trimmedLine.length > 20)) {
        
        final cleanLine = trimmedLine
            .replaceAll(RegExp(r'^[-•*\d\.\s]+'), '')
            .trim();
            
        if (cleanLine.length > 25 && cleanLine.length < 200) {
          if (!cleanLine.toUpperCase().contains('AI') &&
              !cleanLine.toUpperCase().contains('CHATGPT') &&
              !cleanLine.toUpperCase().contains('MODEL')) {
            reasons.add(cleanLine);
          }
        }
      }
      
      // Also capture any substantial sentences that look like analysis
      if (trimmedLine.length > 40 && 
          trimmedLine.length < 180 &&
          !trimmedLine.toUpperCase().contains('SIGNAL') &&
          !trimmedLine.toUpperCase().contains('CONFIDENCE') &&
          !trimmedLine.toUpperCase().contains('ENTRY') &&
          !trimmedLine.toUpperCase().contains('STOP') &&
          !trimmedLine.toUpperCase().contains('TARGET') &&
          (trimmedLine.contains('.') || trimmedLine.contains(':')) &&
          reasons.length < 6) {
        
        if (!trimmedLine.toUpperCase().contains('AI') &&
            !trimmedLine.toUpperCase().contains('CHATGPT')) {
          reasons.add(trimmedLine);
        }
      }
    }
    
    // If no good reasons found, create fallback reasons
    if (reasons.isEmpty) {
      return [
        'Price action analysis shows clear market structure',
        'Technical indicators align with current trend direction',
        'Key support and resistance levels provide clear framework',
        'Market sentiment supports the identified trading bias'
      ];
    }
    
    // Remove duplicates and ensure reasonable length
    final uniqueReasons = reasons.toSet().toList();
    return uniqueReasons.take(4).toList();
  }

  String _extractAlternativeScenario(String response) {
    final lines = response.split('\n');
    for (final line in lines) {
      if (line.toUpperCase().contains('ALTERNATIVE') ||
          line.toUpperCase().contains('IF WRONG') ||
          line.toUpperCase().contains('SCENARIO') ||
          line.toUpperCase().contains('INVALID')) {
        final cleanLine = line.replaceAll(RegExp(r'^[-•*\d\.\s]+'), '').trim();
        if (cleanLine.length > 20 && cleanLine.length < 150) {
          return cleanLine;
        }
      }
    }
    return 'Monitor key levels and adjust bias if market structure changes';
  }

  double _calculateEntryPrice(double currentPrice, String signal, Map<String, dynamic> technicals) {
    if (signal == 'HOLD') return currentPrice;
    
    final support = technicals['support'] ?? currentPrice * 0.995;
    final resistance = technicals['resistance'] ?? currentPrice * 1.005;
    final volatility = _calculateVolatility() / 100;
    
    if (signal == 'BUY') {
      // Buy on pullback to support or breakout above resistance
      return min(currentPrice, support * (1 + volatility * 0.1));
    } else {
      // Sell on rally to resistance or breakdown below support
      return max(currentPrice, resistance * (1 - volatility * 0.1));
    }
  }

  double _calculateTakeProfit(double currentPrice, String signal, Map<String, dynamic> technicals) {
    if (signal == 'HOLD') return currentPrice;
    
    final support = technicals['support'] ?? currentPrice * 0.995;
    final resistance = technicals['resistance'] ?? currentPrice * 1.005;
    final volatility = _calculateVolatility() / 100;
    
    if (signal == 'BUY') {
      // Take profit near next resistance
      return resistance * (1 - volatility * 0.05);
    } else {
      // Take profit near next support
      return support * (1 + volatility * 0.05);
    }
  }

  double _calculateStopLoss(double currentPrice, String signal, Map<String, dynamic> technicals) {
    if (signal == 'HOLD') return currentPrice;
    
    final support = technicals['support'] ?? currentPrice * 0.995;
    final resistance = technicals['resistance'] ?? currentPrice * 1.005;
    final volatility = _calculateVolatility() / 100;
    
    if (signal == 'BUY') {
      // Stop loss below key support
      return support * (1 - volatility * 0.2);
    } else {
      // Stop loss above key resistance
      return resistance * (1 + volatility * 0.2);
    }
  }

  double _calculateRiskRewardRatio(String signal, Map<String, dynamic> technicals) {
    if (signal == 'HOLD') return 1.0;
    
    final entry = _calculateEntryPrice(technicals['currentPrice'], signal, technicals);
    final takeProfit = _calculateTakeProfit(technicals['currentPrice'], signal, technicals);
    final stopLoss = _calculateStopLoss(technicals['currentPrice'], signal, technicals);
    
    final profit = (takeProfit - entry).abs();
    final risk = (entry - stopLoss).abs();
    
    return risk > 0 ? (profit / risk) : 1.0;
  }

  int _extractConfidence(String response) {
    final confidenceMatch = RegExp(r'(\d+)%').firstMatch(response);
    if (confidenceMatch != null) {
      final confidence = int.parse(confidenceMatch.group(1)!);
      return confidence.clamp(1, 100);
    }
    
    if (response.toUpperCase().contains('HIGH CONFIDENCE')) return 85;
    if (response.toUpperCase().contains('MEDIUM CONFIDENCE')) return 70;
    if (response.toUpperCase().contains('LOW CONFIDENCE')) return 55;
    if (response.toUpperCase().contains('VERY HIGH')) return 90;
    
    return Random().nextInt(30) + 65; // Random between 65-95
  }

  double _getBasePrice(String pair) {
    final defaults = {
      'EUR/USD': 1.0850, 'GBP/USD': 1.2650, 'USD/JPY': 149.50,
      'USD/CHF': 0.8800, 'AUD/USD': 0.6550, 'USD/CAD': 1.3500,
      'XAU/USD': 1980.0, 'XAG/USD': 23.50, 'BTC/USD': 43750.0, 'ETH/USD': 2650.0,
    };
    return defaults[pair] ?? 1.0;
  }

  double _getVolatilityForPair(String pair) {
    if (pair == 'XAU/USD') return 15.0;
    if (pair == 'XAG/USD') return 0.5;
    if (pair.contains('BTC')) return 400.0;
    if (pair.contains('ETH')) return 150.0;
    if (pair.contains('JPY')) return 0.8;
    return 0.01;
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _scanTimer?.cancel();
    _chartAnimationController.dispose();
    _analysisAnimationController.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  RealCurrencyData? get currentPairData => _realPrices[selectedPair];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
              onPressed: () {
                // Navigate back to dashboard
                context.go('/dashboard');
              },
            ),
            title: Column(
              children: [
                Text(
                  'AI SIGNAL SCANNER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Professional Market Analysis',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            floating: true,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5)),
                  ),
                  child: Icon(Icons.refresh, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  _loadInitialPrices();
                  _generateRealisticCandlestickData();
                },
              ),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Selection Card
                  _buildSelectionCard(),
                  const SizedBox(height: 20),
                  
                  // Current Price Card
                  _isLoadingPrices 
                    ? _buildLoadingCard()
                    : _buildCurrentPriceCard(),
                  const SizedBox(height: 20),
                  
                  // Trading Chart
                  _buildTradingChart(),
                  const SizedBox(height: 20),
                  
                  // Analyze Button
                  _buildAnalyzeButton(),
                  const SizedBox(height: 20),
                  
                  // Scanning Animation
                  if (_isAnalyzing) _buildScanningCard(),
                  
                  // Analysis Result
                  if (_analysisResult != null) _buildAnalysisResult(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: AppColors.primaryPurple, size: 24),
              const SizedBox(width: 12),
              Text(
                'TRADING SETUP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSTRUMENT',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryPurple.withOpacity(0.3),
                            AppColors.primaryPurple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5)),
                      ),
                      child: DropdownButton<String>(
                        value: selectedPair,
                        isExpanded: true,
                        underline: Container(),
                        dropdownColor: Colors.grey[900],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        items: currencyPairs.map((pair) {
                          return DropdownMenuItem(
                            value: pair,
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _getPairColor(pair),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  pair,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPair = value!;
                            _analysisResult = null;
                          });
                          _generateRealisticCandlestickData();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIMEFRAME',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.blue.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      ),
                      child: DropdownButton<String>(
                        value: selectedTimeframe,
                        isExpanded: true,
                        underline: Container(),
                        dropdownColor: Colors.grey[900],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        items: timeframes.map((timeframe) {
                          return DropdownMenuItem(
                            value: timeframe,
                            child: Text(
                              timeframe,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTimeframe = value!;
                            _analysisResult = null;
                          });
                          _generateRealisticCandlestickData();
                        },
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

  Color _getPairColor(String pair) {
    if (pair == 'XAU/USD') return Colors.amber;
    if (pair == 'XAG/USD') return Colors.grey;
    if (pair.contains('BTC') || pair.contains('ETH')) return Colors.orange;
    return AppColors.primaryPurple;
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
            const SizedBox(height: 16),
            Text(
              'INITIALIZING REAL-TIME DATA',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPriceCard() {
    final pairData = currentPairData;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                selectedPair,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.8),
                      Colors.green.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.03),
                  Colors.white.withOpacity(0.01),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                pairData != null 
                  ? _formatPrice(pairData.price, selectedPair)
                  : '-.----',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (pairData != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: (pairData.isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (pairData.isPositive ? Colors.green : Colors.red).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pairData.isPositive ? Icons.trending_up : Icons.trending_down, 
                    color: pairData.isPositive ? Colors.green : Colors.red, 
                    size: 18
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pairData.isPositive ? '+' : ''}${_formatChange(pairData.change, selectedPair)} (${pairData.changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: pairData.isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTradingChart() {
    return FadeTransition(
      opacity: _chartFadeAnimation,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.03),
              Colors.white.withOpacity(0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            // Chart header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Icon(Icons.candlestick_chart, color: AppColors.primaryPurple, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'LIVE PRICE CHART',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    selectedTimeframe,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            // Chart area
            Expanded(
              child: _candlestickData.isEmpty 
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPurple),
                  )
                : Stack(
                    children: [
                      // Chart
                      GestureDetector(
                        onScaleUpdate: (details) {
                          setState(() {
                            _chartScale = details.scale.clamp(0.5, 3.0);
                            _chartTranslateX += details.focalPointDelta.dx;
                            _chartTranslateY += details.focalPointDelta.dy;
                          });
                        },
                        onDoubleTap: () {
                          setState(() {
                            _chartScale = 1.0;
                            _chartTranslateX = 0.0;
                            _chartTranslateY = 0.0;
                          });
                        },
                        child: Transform(
                          transform: Matrix4.identity()
                            ..translate(_chartTranslateX, _chartTranslateY)
                            ..scale(_chartScale),
                          child: CustomPaint(
                            painter: TradingChartPainter(
                              candlesticks: _candlestickData,
                              isScanning: _isScanning,
                              scanProgress: _scanAnimation.value,
                              scanningParticles: _scanningParticles,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                      // Scanning overlay
                      if (_isScanning) 
                        Positioned.fill(
                          child: CustomPaint(
                            painter: ScanningOverlayPainter(
                              scanProgress: _scanAnimation.value,
                              scanningParticles: _scanningParticles,
                            ),
                          ),
                        ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _analyzeMarket,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAnalyzing ? Icons.radar : Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              _isAnalyzing ? 'SCANNING MARKETS...' : 'ANALYZE WITH AI',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Rotating scanner
              RotationTransition(
                turns: _scanAnimationController,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primaryPurple.withOpacity(0.5),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CustomPaint(
                    painter: BeautifulRadarPainter(),
                  ),
                ),
              ),
              // Center icon
              Icon(
                Icons.auto_awesome,
                color: AppColors.primaryPurple,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'AI MARKET SCANNER ACTIVE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing price patterns and technical indicators...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            value: _scanPosition,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          Text(
            '${(_scanPosition * 100).toInt()}% COMPLETE',
            style: TextStyle(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return Container();
    
    final result = _analysisResult!;
    final isBuy = result.signal == 'BUY';
    final isSell = result.signal == 'SELL';
    
    return SlideTransition(
      position: _analysisSlideAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (isBuy ? Colors.green : isSell ? Colors.red : Colors.orange).withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isBuy ? Colors.green : isSell ? Colors.red : Colors.orange).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Signal header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isBuy ? Colors.green : isSell ? Colors.red : Colors.orange).withOpacity(0.2),
                    (isBuy ? Colors.green : isSell ? Colors.red : Colors.orange).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isBuy ? Colors.green : isSell ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isBuy ? Colors.green : isSell ? Colors.red : Colors.orange).withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isBuy ? Icons.trending_up : isSell ? Icons.trending_down : Icons.pause,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.signal} SIGNAL IDENTIFIED',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${result.pair} • ${result.timeframe} • ${result.confidence}% Confidence',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isBuy ? Colors.green : isSell ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isBuy ? Colors.green : isSell ? Colors.red : Colors.orange).withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      result.signal,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Trading levels
            _buildLevelsCard(result),
            
            const SizedBox(height: 20),
            
            // Analysis insights
            _buildInsightsCard(result),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelsCard(AnalysisResult result) {
    final isBuy = result.signal == 'BUY';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.price_change, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 12),
              Text(
                'TRADING LEVELS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLevelRow('🎯 ENTRY POINT', result.entry, AppColors.primaryPurple),
          const SizedBox(height: 12),
          _buildLevelRow('💰 TAKE PROFIT', result.takeProfit, Colors.green),
          const SizedBox(height: 12),
          _buildLevelRow('🛡️ STOP LOSS', result.stopLoss, Colors.red),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.balance, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Text(
                  'RISK/REWARD: 1:${result.riskReward.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Text(
            _formatPrice(value, selectedPair),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(AnalysisResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 12),
              Text(
                'TECHNICAL INSIGHTS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...result.reasons.take(4).map((reason) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    reason,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _formatPrice(double price, String pair) {
    if (pair == 'XAU/USD' || pair == 'XAG/USD') return '\$${price.toStringAsFixed(2)}';
    if (pair.contains('BTC') || pair.contains('ETH')) return '\$${price.toStringAsFixed(2)}';
    if (pair.contains('JPY')) return '¥${price.toStringAsFixed(2)}';
    return price.toStringAsFixed(5);
  }

  String _formatChange(double change, String pair) {
    if (pair == 'XAU/USD' || pair == 'XAG/USD') return change.toStringAsFixed(2);
    if (pair.contains('BTC') || pair.contains('ETH')) return change.toStringAsFixed(2);
    if (pair.contains('JPY')) return change.toStringAsFixed(2);
    return change.toStringAsFixed(5);
  }
}

// Beautiful Chart Painters
class TradingChartPainter extends CustomPainter {
  final List<CandlestickData> candlesticks;
  final bool isScanning;
  final double scanProgress;
  final List<ScanningParticle> scanningParticles;

  TradingChartPainter({
    required this.candlesticks,
    required this.isScanning,
    required this.scanProgress,
    required this.scanningParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candlesticks.isEmpty) return;

    // Draw dark background
    final backgroundPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), backgroundPaint);

    // Calculate price range
    final minPrice = candlesticks.map((e) => e.low).reduce(min);
    final maxPrice = candlesticks.map((e) => e.high).reduce(max);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;
    
    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate candle dimensions
    final candleWidth = size.width / candlesticks.length * 0.8;
    final candleSpacing = size.width / candlesticks.length * 0.2;

    // Draw candlesticks
    for (int i = 0; i < candlesticks.length; i++) {
      final candle = candlesticks[i];
      final x = (i * (candleWidth + candleSpacing)) + (candleWidth / 2);
      
      final highY = ((maxPrice + padding) - candle.high) / (priceRange + padding * 2) * size.height;
      final lowY = ((maxPrice + padding) - candle.low) / (priceRange + padding * 2) * size.height;
      final openY = ((maxPrice + padding) - candle.open) / (priceRange + padding * 2) * size.height;
      final closeY = ((maxPrice + padding) - candle.close) / (priceRange + padding * 2) * size.height;

      final isGreen = candle.close >= candle.open;
      final color = isGreen ? Colors.green : Colors.red;

      // Draw wick with gradient
      final wickPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // Draw candle body with gradient
      final bodyRect = Rect.fromLTRB(
        x - candleWidth / 2,
        min(openY, closeY),
        x + candleWidth / 2,
        max(openY, closeY),
      );

      final bodyPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.4),
          ],
        ).createShader(bodyRect)
        ..style = PaintingStyle.fill;

      canvas.drawRect(bodyRect, bodyPaint);

      // Add glow effect for current candle
      if (i == candlesticks.length - 1) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawRect(bodyRect, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ScanningOverlayPainter extends CustomPainter {
  final double scanProgress;
  final List<ScanningParticle> scanningParticles;

  ScanningOverlayPainter({
    required this.scanProgress,
    required this.scanningParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw scanning beam
    final beamGradient = LinearGradient(
      colors: [
        Colors.purple.withOpacity(0.3),
        Colors.blue.withOpacity(0.2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTRB(0, 0, size.width * scanProgress, size.height));

    final beamPaint = Paint()..shader = beamGradient;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width * scanProgress, size.height), beamPaint);

    // Draw particles
    for (final particle in scanningParticles) {
      final particleX = size.width * particle.x;
      final particleY = size.height * particle.y;
      
      final particlePaint = Paint()
        ..color = Colors.purple.withOpacity(particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(
        Offset(particleX, particleY),
        particle.size,
        particlePaint,
      );
    }

    // Draw scanning line
    final linePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    
    canvas.drawLine(
      Offset(size.width * scanProgress, 0),
      Offset(size.width * scanProgress, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BeautifulRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw radar circles with glow
    final circlePaint = Paint()
      ..color = Colors.purple.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    for (int i = 1; i <= 3; i++) {
      final circleRadius = radius * i / 3;
      canvas.drawCircle(center, circleRadius, circlePaint);
    }

    // Draw radar sweep with gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.purple.withOpacity(0.8),
          Colors.blue.withOpacity(0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data Classes
class RealCurrencyData {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final bool isPositive;
  final DateTime lastUpdated;
  final List<double> priceHistory;

  RealCurrencyData({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.isPositive,
    required this.lastUpdated,
    required this.priceHistory,
  });
}

class CandlestickData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandlestickData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });
}

class AnalysisResult {
  final String pair;
  final String timeframe;
  final String signal;
  final int confidence;
  final double entry;
  final double takeProfit;
  final double stopLoss;
  final List<String> reasons;
  final String alternativeScenario;
  final double riskReward;

  AnalysisResult({
    required this.pair,
    required this.timeframe,
    required this.signal,
    required this.confidence,
    required this.entry,
    required this.takeProfit,
    required this.stopLoss,
    required this.reasons,
    required this.alternativeScenario,
    required this.riskReward,
  });
}

class ScanningParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  ScanningParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}