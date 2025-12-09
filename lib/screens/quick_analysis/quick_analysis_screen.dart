import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../../theme/app_colors.dart';

// API Configuration
const String DERIV_API_TOKEN = '2BqbsdE4NSUtzlm'; // Your Deriv token
const String DERIV_APP_ID = '115360';
const String DERIV_WS_URL = 'wss://ws.binaryws.com/websockets/v3';
const String DERIV_API_URL = 'https://api.deriv.com';

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
  
  // Deriv WebSocket connection
  WebSocketChannel? _derivChannel;
  StreamSubscription? _derivSubscription;
  
  // Real-time data tracking
  final Map<String, double> _lastPrices = {};
  final Map<String, List<PriceUpdate>> _realtimePriceData = {};
  Timer? _chartUpdateTimer;
  
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
  Offset _dragStart = Offset.zero;

  // Scanning animation
  double _scanPosition = 0.0;
  bool _isScanning = false;
  Timer? _scanTimer;
  List<ScanningParticle> _scanningParticles = [];

  // Deriv supported symbols
  final Map<String, String> _derivSymbols = {
    'EUR/USD': 'frxEURUSD',
    'GBP/USD': 'frxGBPUSD',
    'USD/JPY': 'frxUSDJPY',
    'USD/CHF': 'frxUSDCHF',
    'AUD/USD': 'frxAUDUSD',
    'USD/CAD': 'frxUSDCAD',
    'XAU/USD': 'frxXAUUSD',
    'XAG/USD': 'frxXAGUSD',
    'BTC/USD': 'cryBTCUSD',
    'ETH/USD': 'cryETHUSD',
  };

  final Map<String, int> _timeframeToSeconds = {
    'M1': 60,
    'M5': 300,
    'M15': 900,
    'M30': 1800,
    'H1': 3600,
    'H4': 14400,
    'D': 86400,
  };

  final List<String> currencyPairs = [
    'EUR/USD', 'GBP/USD', 'USD/JPY', 'USD/CHF', 'AUD/USD', 'USD/CAD',
    'XAU/USD', 'XAG/USD', 'BTC/USD', 'ETH/USD',
  ];

  final List<String> timeframes = ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D'];

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
    
    // Connect to Deriv WebSocket
    _connectToDeriv();
    
    // Start animations
    _chartAnimationController.forward();
    
    // Start chart update timer
    _startChartUpdates();
  }

  void _startChartUpdates() {
    _chartUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          // This triggers chart repaint
        });
      }
    });
  }

  Future<void> _connectToDeriv() async {
    try {
      // Close existing connection if any
      await _disconnectFromDeriv();
      
      // Create new WebSocket connection
      _derivChannel = WebSocketChannel.connect(
        Uri.parse('$DERIV_WS_URL?app_id=$DERIV_APP_ID'),
      );
      
      // Authorize with API token
      _derivChannel!.sink.add(json.encode({
        'authorize': DERIV_API_TOKEN,
      }));
      
      // Listen for responses
      _derivSubscription = _derivChannel!.stream.listen(
        (message) {
          _handleDerivMessage(message);
        },
        onError: (error) {
          print('Deriv WebSocket error: $error');
          _reconnectToDeriv();
        },
        onDone: () {
          print('Deriv WebSocket closed');
          _reconnectToDeriv();
        },
      );
      
    } catch (e) {
      print('Failed to connect to Deriv: $e');
      // Start with simulated data but keep trying to reconnect
      _startWithSimulatedData();
      _reconnectToDeriv();
    }
  }

  void _handleDerivMessage(dynamic message) {
    try {
      final data = json.decode(message);
      
      if (data['msg_type'] == 'authorize') {
        if (data['error'] != null) {
          print('Deriv authorization error: ${data['error']['message']}');
          _startWithSimulatedData();
          return;
        }
        print('✅ Successfully authorized with Deriv API');
        
        // Subscribe to all symbols
        _subscribeToAllSymbols();
        
      } else if (data['msg_type'] == 'tick') {
        _handleTickUpdate(data['tick']);
        
      } else if (data['msg_type'] == 'ohlc') {
        _handleOHLCUpdate(data['ohlc']);
        
      } else if (data['msg_type'] == 'history') {
        _handleHistoryData(data['history']);
        
      } else if (data['msg_type'] == 'candles') {
        _handleCandlesData(data['candles']);
      }
    } catch (e) {
      print('Error handling Deriv message: $e');
    }
  }

  void _handleTickUpdate(Map<String, dynamic> tick) {
    final symbol = tick['symbol'];
    final quote = tick['quote'];
    final epoch = tick['epoch'];
    
    if (quote != null && symbol != null) {
      final double price = double.parse(quote);
      final displaySymbol = _getDisplaySymbol(symbol);
      final now = DateTime.now();
      
      // Store real-time price update
      if (!_realtimePriceData.containsKey(displaySymbol)) {
        _realtimePriceData[displaySymbol] = [];
      }
      
      _realtimePriceData[displaySymbol]!.add(PriceUpdate(
        price: price,
        timestamp: now,
      ));
      
      // Keep only last 100 updates
      if (_realtimePriceData[displaySymbol]!.length > 100) {
        _realtimePriceData[displaySymbol]!.removeAt(0);
      }
      
      // Calculate change from previous price
      double change = 0.0;
      double changePercent = 0.0;
      
      if (_lastPrices.containsKey(displaySymbol)) {
        final lastPrice = _lastPrices[displaySymbol]!;
        change = price - lastPrice;
        changePercent = (change / lastPrice) * 100;
      }
      
      _lastPrices[displaySymbol] = price;
      
      // Update price history for line chart
      if (!_realPrices.containsKey(displaySymbol)) {
        _realPrices[displaySymbol] = RealCurrencyData(
          symbol: displaySymbol,
          price: price,
          change: change,
          changePercent: changePercent,
          isPositive: change >= 0,
          lastUpdated: now,
          priceHistory: [price],
        );
      } else {
        final existing = _realPrices[displaySymbol]!;
        final history = List<double>.from(existing.priceHistory)..add(price);
        if (history.length > 50) history.removeAt(0);
        
        _realPrices[displaySymbol] = RealCurrencyData(
          symbol: displaySymbol,
          price: price,
          change: change,
          changePercent: changePercent,
          isPositive: change >= 0,
          lastUpdated: now,
          priceHistory: history,
        );
      }
      
      // Update current candle for selected pair
      if (displaySymbol == selectedPair) {
        _updateCurrentCandle(price, now);
      }
      
      if (mounted) {
        setState(() {
          _isLoadingPrices = false;
        });
      }
    }
  }

  void _updateCurrentCandle(double price, DateTime timestamp) {
    if (_candlestickData.isEmpty) {
      // Create first candle
      _candlestickData.add(CandlestickData(
        time: timestamp,
        open: price,
        high: price,
        low: price,
        close: price,
        volume: 1000,
      ));
    } else {
      final lastCandle = _candlestickData.last;
      final timeframeSeconds = _timeframeToSeconds[selectedTimeframe] ?? 3600;
      final currentTime = timestamp;
      final lastCandleEndTime = lastCandle.time.add(Duration(seconds: timeframeSeconds));
      
      if (currentTime.isAfter(lastCandleEndTime)) {
        // Create new candle
        _candlestickData.add(CandlestickData(
          time: currentTime,
          open: price,
          high: price,
          low: price,
          close: price,
          volume: 1000,
        ));
        
        // Keep only last 100 candles
        if (_candlestickData.length > 100) {
          _candlestickData.removeAt(0);
        }
      } else {
        // Update current candle
        _candlestickData[_candlestickData.length - 1] = CandlestickData(
          time: lastCandle.time,
          open: lastCandle.open,
          high: max(lastCandle.high, price),
          low: min(lastCandle.low, price),
          close: price,
          volume: lastCandle.volume + 100,
        );
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _handleOHLCUpdate(Map<String, dynamic> ohlc) {
    // Handle OHLC updates from Deriv
    print('OHLC update received: $ohlc');
  }

  void _handleHistoryData(Map<String, dynamic> history) {
    final prices = history['prices'] as List<dynamic>?;
    if (prices != null && prices.isNotEmpty) {
      _candlestickData.clear();
      
      for (final price in prices.reversed) {
        final candle = CandlestickData(
          time: DateTime.fromMillisecondsSinceEpoch(price['epoch'] * 1000),
          open: double.parse(price['open']),
          high: double.parse(price['high']),
          low: double.parse(price['low']),
          close: double.parse(price['close']),
          volume: 1000,
        );
        _candlestickData.add(candle);
      }
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _handleCandlesData(Map<String, dynamic> candles) {
    final candlesList = candles['candles'] as List<dynamic>?;
    if (candlesList != null) {
      _candlestickData.clear();
      
      for (final candle in candlesList.reversed) {
        _candlestickData.add(CandlestickData(
          time: DateTime.fromMillisecondsSinceEpoch(candle['epoch'] * 1000),
          open: double.parse(candle['open']),
          high: double.parse(candle['high']),
          low: double.parse(candle['low']),
          close: double.parse(candle['close']),
          volume: 1000,
        ));
      }
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _subscribeToAllSymbols() {
    // Subscribe to tick updates for all symbols
    for (final displaySymbol in currencyPairs) {
      final derivSymbol = _derivSymbols[displaySymbol];
      if (derivSymbol != null) {
        _derivChannel!.sink.add(json.encode({
          'ticks': derivSymbol,
          'subscribe': 1,
        }));
      }
    }
    
    // Load historical data for selected pair
    _loadHistoricalData();
  }

  void _loadHistoricalData() {
    final derivSymbol = _derivSymbols[selectedPair];
    if (derivSymbol != null && _derivChannel != null) {
      final seconds = _timeframeToSeconds[selectedTimeframe] ?? 3600;
      
      _derivChannel!.sink.add(json.encode({
        'ticks_history': derivSymbol,
        'adjust_start_time': 1,
        'count': 100,
        'end': 'latest',
        'start': 1,
        'style': 'candles',
        'granularity': seconds,
      }));
    }
  }

  void _startWithSimulatedData() {
    // Start with realistic simulated data
    _loadRealisticSimulatedData();
    
    // Start simulated price updates
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _derivChannel?.closeCode == null) {
        timer.cancel();
        return;
      }
      
      _updateSimulatedPrices();
    });
  }

  void _loadRealisticSimulatedData() {
    final now = DateTime.now();
    final random = Random();
    
    // Realistic base prices
    final basePrices = {
      'EUR/USD': 1.0850,
      'GBP/USD': 1.2650,
      'USD/JPY': 149.50,
      'USD/CHF': 0.8800,
      'AUD/USD': 0.6550,
      'USD/CAD': 1.3500,
      'XAU/USD': 1980.0,
      'XAG/USD': 23.50,
      'BTC/USD': 43750.0,
      'ETH/USD': 2650.0,
    };
    
    // Generate initial prices with realistic variations
    for (final pair in currencyPairs) {
      final basePrice = basePrices[pair] ?? 1.0;
      final initialPrice = basePrice + (random.nextDouble() - 0.5) * basePrice * 0.01;
      final change = (random.nextDouble() - 0.5) * basePrice * 0.005;
      
      // Generate realistic price history
      final history = <double>[initialPrice];
      double current = initialPrice;
      for (int i = 0; i < 49; i++) {
        final variation = (random.nextDouble() - 0.5) * basePrice * 0.002;
        current += variation;
        history.add(current);
      }
      
      _realPrices[pair] = RealCurrencyData(
        symbol: pair,
        price: initialPrice,
        change: change,
        changePercent: (change / basePrice) * 100,
        isPositive: change >= 0,
        lastUpdated: now,
        priceHistory: history,
      );
      
      _lastPrices[pair] = initialPrice;
    }
    
    // Generate realistic candlestick data for selected pair
    _generateRealisticCandles();
    
    setState(() {
      _isLoadingPrices = false;
    });
  }

  void _generateRealisticCandles() {
    final basePrice = _realPrices[selectedPair]?.price ?? 1.0;
    final random = Random();
    final volatility = _getVolatilityForPair(selectedPair);
    
    _candlestickData.clear();
    final now = DateTime.now();
    final timeframeSeconds = _timeframeToSeconds[selectedTimeframe] ?? 3600;
    
    double currentPrice = basePrice;
    
    // Generate 100 candles with realistic patterns
    for (int i = 0; i < 100; i++) {
      final candleTime = now.subtract(Duration(seconds: (100 - i) * timeframeSeconds));
      
      // Create trends and patterns
      final trend = sin(i * 0.1) * volatility * 0.5;
      final noise = (random.nextDouble() - 0.5) * volatility;
      
      final open = currentPrice;
      final close = open + trend + noise;
      
      // Realistic wicks
      final wickRange = volatility * (0.2 + random.nextDouble() * 0.3);
      final high = max(open, close) + wickRange * random.nextDouble();
      final low = min(open, close) - wickRange * random.nextDouble();
      
      _candlestickData.add(CandlestickData(
        time: candleTime,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: 1000 + random.nextDouble() * 5000,
      ));
      
      currentPrice = close;
    }
  }

  void _updateSimulatedPrices() {
    final random = Random();
    
    for (final pair in currencyPairs) {
      final currentData = _realPrices[pair];
      if (currentData != null) {
        final volatility = _getVolatilityForPair(pair);
        final change = (random.nextDouble() - 0.5) * volatility * 0.1;
        final newPrice = currentData.price + change;
        final now = DateTime.now();
        
        // Update price history
        final history = List<double>.from(currentData.priceHistory)..add(newPrice);
        if (history.length > 50) history.removeAt(0);
        
        _realPrices[pair] = RealCurrencyData(
          symbol: pair,
          price: newPrice,
          change: change,
          changePercent: (change / currentData.price) * 100,
          isPositive: change >= 0,
          lastUpdated: now,
          priceHistory: history,
        );
        
        _lastPrices[pair] = newPrice;
        
        // Update candle for selected pair
        if (pair == selectedPair) {
          _updateCurrentCandle(newPrice, now);
        }
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  double _getVolatilityForPair(String pair) {
    if (pair == 'XAU/USD') return 15.0;
    if (pair == 'XAG/USD') return 0.5;
    if (pair.contains('BTC')) return 400.0;
    if (pair.contains('ETH')) return 150.0;
    if (pair.contains('JPY')) return 0.8;
    return 0.01;
  }

  void _reconnectToDeriv() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _connectToDeriv();
      }
    });
  }

  Future<void> _disconnectFromDeriv() async {
    await _derivSubscription?.cancel();
    await _derivChannel?.sink.close();
    _derivSubscription = null;
    _derivChannel = null;
  }

  String _getDisplaySymbol(String derivSymbol) {
    for (final entry in _derivSymbols.entries) {
      if (entry.value == derivSymbol) {
        return entry.key;
      }
    }
    return derivSymbol;
  }

  void _onPairChanged(String? value) {
    if (value != null && value != selectedPair) {
      setState(() {
        selectedPair = value;
        _analysisResult = null;
        _candlestickData.clear();
      });
      
      // Load historical data for new pair
      if (_derivChannel?.closeCode == null) {
        _loadHistoricalData();
      } else {
        _generateRealisticCandles();
      }
    }
  }

  void _onTimeframeChanged(String? value) {
    if (value != null && value != selectedTimeframe) {
      setState(() {
        selectedTimeframe = value;
        _analysisResult = null;
        _candlestickData.clear();
      });
      
      // Load historical data with new timeframe
      if (_derivChannel?.closeCode == null) {
        _loadHistoricalData();
      } else {
        _generateRealisticCandles();
      }
    }
  }

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
      // Simulate analysis with real data
      await Future.delayed(const Duration(seconds: 3));
      
      final analysis = _generateAnalysis(currentData);
      
      if (mounted) {
        setState(() {
          _analysisResult = analysis;
          _isAnalyzing = false;
        });
        
        _analysisAnimationController.reset();
        _analysisAnimationController.forward();
      }
      
    } catch (e) {
      print('Analysis failed: $e');
      setState(() => _isAnalyzing = false);
      
      final analysis = _generateAnalysis(currentData);
      setState(() {
        _analysisResult = analysis;
      });
    }
  }

  AnalysisResult _generateAnalysis(RealCurrencyData data) {
    final random = Random();
    final technicals = _calculateTechnicalIndicators();
    
    // Determine signal based on technicals
    String signal = 'HOLD';
    double confidence = 50.0;
    
    final trend = technicals['trend'] ?? 'NEUTRAL';
    final rsi = technicals['rsi'] ?? 50.0;
    final trendStrength = technicals['trendStrength'] ?? 0.0;
    
    if (trend == 'BULLISH' && rsi < 70 && trendStrength > 0.5 && data.isPositive) {
      signal = 'BUY';
      confidence = 65.0 + random.nextDouble() * 25;
    } else if (trend == 'BEARISH' && rsi > 30 && trendStrength > 0.5 && !data.isPositive) {
      signal = 'SELL';
      confidence = 65.0 + random.nextDouble() * 25;
    }
    
    final reasons = [
      '${trend} trend identified with ${trendStrength.toStringAsFixed(1)}% strength',
      'RSI at ${rsi.toStringAsFixed(1)} indicates ${rsi > 70 ? 'overbought' : rsi < 30 ? 'oversold' : 'neutral'} conditions',
      'Price action shows ${data.isPositive ? 'strength' : 'weakness'} in current trend',
      'Real-time volatility: ${_calculateVolatility().toStringAsFixed(2)}%',
    ];
    
    return AnalysisResult(
      pair: selectedPair,
      timeframe: selectedTimeframe,
      signal: signal,
      confidence: confidence.toInt(),
      entry: _calculateEntryPrice(data.price, signal, technicals),
      takeProfit: _calculateTakeProfit(data.price, signal, technicals),
      stopLoss: _calculateStopLoss(data.price, signal, technicals),
      reasons: reasons,
      alternativeScenario: 'Monitor key levels for trend confirmation',
      riskReward: _calculateRiskRewardRatio(signal, technicals),
    );
  }

  Map<String, dynamic> _calculateTechnicalIndicators() {
    if (_candlestickData.length < 20) return {};
    
    final prices = _candlestickData.map((c) => c.close).toList();
    final highs = _candlestickData.map((c) => c.high).toList();
    final lows = _candlestickData.map((c) => c.low).toList();
    
    // Calculate trend
    final recentPrices = prices.sublist(prices.length - 10);
    final olderPrices = prices.sublist(prices.length - 20, prices.length - 10);
    final recentAvg = recentPrices.reduce((a, b) => a + b) / recentPrices.length;
    final olderAvg = olderPrices.reduce((a, b) => a + b) / olderPrices.length;
    final trend = recentAvg > olderAvg ? 'BULLISH' : 'BEARISH';
    final trendStrength = ((recentAvg - olderAvg) / olderAvg * 100).abs();
    
    // Support/resistance
    final recentHighs = highs.sublist(highs.length - 20);
    final recentLows = lows.sublist(lows.length - 20);
    final resistance = recentHighs.reduce(max);
    final support = recentLows.reduce(min);
    
    // RSI calculation
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
    
    return {
      'trend': trend,
      'trendStrength': trendStrength,
      'support': support,
      'resistance': resistance,
      'rsi': rsi,
      'currentPrice': prices.last,
    };
  }

  double _calculateEntryPrice(double currentPrice, String signal, Map<String, dynamic> technicals) {
    if (signal == 'HOLD') return currentPrice;
    
    final support = technicals['support'] ?? currentPrice * 0.995;
    final resistance = technicals['resistance'] ?? currentPrice * 1.005;
    
    if (signal == 'BUY') {
      return min(currentPrice, support * 1.001);
    } else {
      return max(currentPrice, resistance * 0.999);
    }
  }

  double _calculateTakeProfit(double currentPrice, String signal, Map<String, dynamic> technicals) {
    if (signal == 'HOLD') return currentPrice;
    
    final support = technicals['support'] ?? currentPrice * 0.995;
    final resistance = technicals['resistance'] ?? currentPrice * 1.005;
    
    if (signal == 'BUY') {
      return resistance * 0.998;
    } else {
      return support * 1.002;
    }
  }

  double _calculateStopLoss(double currentPrice, String signal, Map<String, dynamic> technicals) {
    if (signal == 'HOLD') return currentPrice;
    
    final support = technicals['support'] ?? currentPrice * 0.995;
    final resistance = technicals['resistance'] ?? currentPrice * 1.005;
    
    if (signal == 'BUY') {
      return support * 0.998;
    } else {
      return resistance * 1.002;
    }
  }

  double _calculateRiskRewardRatio(String signal, Map<String, dynamic> technicals) {
    if (signal == 'HOLD') return 1.0;
    
    final currentPrice = technicals['currentPrice'] ?? 1.0;
    final entry = _calculateEntryPrice(currentPrice, signal, technicals);
    final takeProfit = _calculateTakeProfit(currentPrice, signal, technicals);
    final stopLoss = _calculateStopLoss(currentPrice, signal, technicals);
    
    final profit = (takeProfit - entry).abs();
    final risk = (entry - stopLoss).abs();
    
    return risk > 0 ? (profit / risk) : 1.0;
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

  void _startScanningAnimation() {
    setState(() {
      _isScanning = true;
      _scanPosition = 0.0;
      _scanningParticles.clear();
    });
    
    _scanAnimationController.reset();
    _scanAnimationController.repeat(reverse: true);
    
    // Create particles
    final random = Random();
    for (int i = 0; i < 20; i++) {
      _scanningParticles.add(ScanningParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 2.0 + random.nextDouble() * 4.0,
        speed: 0.5 + random.nextDouble() * 1.0,
        opacity: 0.3 + random.nextDouble() * 0.7,
      ));
    }
    
    // Scanning animation
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
          
          if (particle.x > 1.2 || particle.opacity <= 0) {
            particle.x = -0.2;
            particle.y = random.nextDouble();
            particle.opacity = 0.3 + random.nextDouble() * 0.7;
          }
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

  @override
  void dispose() {
    _disconnectFromDeriv();
    _chartUpdateTimer?.cancel();
    _scanTimer?.cancel();
    _chartAnimationController.dispose();
    _analysisAnimationController.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _realPrices[selectedPair];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
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
              onPressed: () => context.go('/dashboard'),
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
                  'Real-time Market Analysis',
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
                onPressed: _connectToDeriv,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Selection Card
                  Container(
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
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _derivChannel?.closeCode == null 
                                  ? Colors.green.withOpacity(0.2) 
                                  : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _derivChannel?.closeCode == null 
                                    ? Colors.green 
                                    : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _derivChannel?.closeCode == null 
                                        ? Colors.green 
                                        : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _derivChannel?.closeCode == null ? 'LIVE' : 'SIM',
                                    style: TextStyle(
                                      color: _derivChannel?.closeCode == null 
                                        ? Colors.green 
                                        : Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
                                      onChanged: _onPairChanged,
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
                                      onChanged: _onTimeframeChanged,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Current Price Card
                  _isLoadingPrices 
                    ? _buildLoadingCard()
                    : _buildCurrentPriceCard(currentData),
                  const SizedBox(height: 20),
                  
                  // Technical Chart
                  _buildTechnicalChart(),
                  const SizedBox(height: 20),
                  
                  // Chart Tools
                  _buildChartTools(),
                  const SizedBox(height: 20),
                  
                  // Scan & Analyze Button
                  _buildScanAnalyzeButton(),
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
              _derivChannel?.closeCode == null 
                ? 'CONNECTING TO DERIV...' 
                : 'LOADING MARKET DATA...',
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

  Widget _buildCurrentPriceCard(RealCurrencyData? data) {
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
                      (_derivChannel?.closeCode == null ? Colors.green : Colors.amber).withOpacity(0.8),
                      (_derivChannel?.closeCode == null ? Colors.green : Colors.amber).withOpacity(0.4),
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
                    Text(
                      _derivChannel?.closeCode == null ? 'LIVE' : 'SIM',
                      style: const TextStyle(
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
                data != null 
                  ? _formatPrice(data.price, selectedPair)
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
          
          if (data != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (data.isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (data.isPositive ? Colors.green : Colors.red).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    data.isPositive ? Icons.trending_up : Icons.trending_down, 
                    color: data.isPositive ? Colors.green : Colors.red, 
                    size: 20
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${data.isPositive ? '+' : ''}${_formatChange(data.change, selectedPair)} (${data.changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: data.isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  Widget _buildTechnicalChart() {
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
            // Chart Header
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
                    'TECHNICAL CHART',
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
            
            // Chart Area
            Expanded(
              child: GestureDetector(
                onScaleStart: (details) {
                  _dragStart = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _chartTranslateX += details.focalPoint.dx - _dragStart.dx;
                    _chartTranslateY += details.focalPoint.dy - _dragStart.dy;
                    _dragStart = details.focalPoint;
                  });
                },
                onScaleEnd: (details) {
                  _dragStart = Offset.zero;
                },
                onDoubleTap: () {
                  setState(() {
                    _chartScale = 1.0;
                    _chartTranslateX = 0.0;
                    _chartTranslateY = 0.0;
                  });
                },
                child: Stack(
                  children: [
                    // Background Grid
                    CustomPaint(
                      size: Size.infinite,
                      painter: ChartGridPainter(),
                    ),
                    
                    // Candlestick Chart
                    if (_candlestickData.isNotEmpty)
                      Transform(
                        transform: Matrix4.identity()
                          ..translate(_chartTranslateX, _chartTranslateY)
                          ..scale(_chartScale),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: ProfessionalCandlestickPainter(
                            candles: _candlestickData,
                            showGrid: true,
                          ),
                        ),
                      ),
                    
                    // Real-time price line
                    if (_realtimePriceData.containsKey(selectedPair) && 
                        _realtimePriceData[selectedPair]!.isNotEmpty)
                      CustomPaint(
                        size: Size.infinite,
                        painter: RealtimeLinePainter(
                          priceUpdates: _realtimePriceData[selectedPair]!,
                          color: AppColors.primaryPurple,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTools() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 12),
              Text(
                'CHART TOOLS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.zoom_in, color: Colors.white70, size: 20),
                onPressed: () {
                  setState(() {
                    _chartScale = min(_chartScale + 0.1, 3.0);
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.zoom_out, color: Colors.white70, size: 20),
                onPressed: () {
                  setState(() {
                    _chartScale = max(_chartScale - 0.1, 0.5);
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.center_focus_strong, color: Colors.white70, size: 20),
                onPressed: () {
                  setState(() {
                    _chartScale = 1.0;
                    _chartTranslateX = 0.0;
                    _chartTranslateY = 0.0;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(Icons.show_chart, 'Line'),
              _buildToolButton(Icons.candlestick_chart, 'Candle'),
              _buildToolButton(Icons.bar_chart, 'Bar'),
              _buildToolButton(Icons.trending_up, 'Trend'),
              _buildToolButton(Icons.horizontal_rule, 'Support'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: Colors.white70, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildScanAnalyzeButton() {
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
              _isAnalyzing ? 'SCANNING MARKETS...' : 'SCAN & ANALYZE',
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

  Color _getPairColor(String pair) {
    if (pair == 'XAU/USD') return Colors.amber;
    if (pair == 'XAG/USD') return Colors.grey;
    if (pair.contains('BTC') || pair.contains('ETH')) return Colors.orange;
    return AppColors.primaryPurple;
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

// Professional Chart Painters
class ChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;

    // Draw vertical grid lines
    for (int i = 1; i <= 4; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal grid lines
    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProfessionalCandlestickPainter extends CustomPainter {
  final List<CandlestickData> candles;
  final bool showGrid;

  ProfessionalCandlestickPainter({
    required this.candles,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // Calculate price range
    final minPrice = candles.map((e) => e.low).reduce(min);
    final maxPrice = candles.map((e) => e.high).reduce(max);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1;

    // Calculate dimensions
    final candleWidth = size.width / candles.length * 0.7;
    final candleSpacing = size.width / candles.length * 0.3;
    final usableHeight = size.height * 0.9;
    final topPadding = size.height * 0.05;

    // Draw each candle
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = (i * (candleWidth + candleSpacing)) + candleWidth / 2;
      
      // Calculate Y positions
      final highY = topPadding + ((maxPrice + padding) - candle.high) / (priceRange + padding * 2) * usableHeight;
      final lowY = topPadding + ((maxPrice + padding) - candle.low) / (priceRange + padding * 2) * usableHeight;
      final openY = topPadding + ((maxPrice + padding) - candle.open) / (priceRange + padding * 2) * usableHeight;
      final closeY = topPadding + ((maxPrice + padding) - candle.close) / (priceRange + padding * 2) * usableHeight;

      final isBullish = candle.close >= candle.open;
      final color = isBullish ? Colors.green : Colors.red;

      // Draw wick
      final wickPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // Draw candle body
      final bodyTop = min(openY, closeY);
      final bodyBottom = max(openY, closeY);
      final bodyHeight = max(1.0, bodyBottom - bodyTop);
      
      if (bodyHeight > 0) {
        final bodyRect = Rect.fromLTRB(
          x - candleWidth / 2,
          bodyTop,
          x + candleWidth / 2,
          bodyBottom,
        );

        final bodyPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isBullish
                ? [Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.4)]
                : [Colors.red.withOpacity(0.8), Colors.red.withOpacity(0.4)],
          ).createShader(bodyRect)
          ..style = PaintingStyle.fill;

        canvas.drawRect(bodyRect, bodyPaint);

        // Add subtle border
        final borderPaint = Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        
        canvas.drawRect(bodyRect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RealtimeLinePainter extends CustomPainter {
  final List<PriceUpdate> priceUpdates;
  final Color color;

  RealtimeLinePainter({
    required this.priceUpdates,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (priceUpdates.length < 2) return;

    // Find min and max prices
    final prices = priceUpdates.map((p) => p.price).toList();
    final minPrice = prices.reduce(min);
    final maxPrice = prices.reduce(max);
    final priceRange = maxPrice - minPrice;
    
    if (priceRange == 0) return;

    final usableHeight = size.height * 0.9;
    final topPadding = size.height * 0.05;

    // Create path for line
    final path = Path();
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Calculate first point
    final firstUpdate = priceUpdates.first;
    final firstX = 0.0;
    final firstY = topPadding + ((maxPrice - firstUpdate.price) / priceRange) * usableHeight;
    path.moveTo(firstX, firstY);

    // Add remaining points
    for (int i = 1; i < priceUpdates.length; i++) {
      final update = priceUpdates[i];
      final x = (i / (priceUpdates.length - 1)) * size.width;
      final y = topPadding + ((maxPrice - update.price) / priceRange) * usableHeight;
      path.lineTo(x, y);
    }

    // Draw line
    canvas.drawPath(path, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(path, glowPaint);
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
    // Draw scanning beam with gradient
    final beamGradient = LinearGradient(
      colors: [
        Colors.purple.withOpacity(0.3),
        Colors.blue.withOpacity(0.2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTRB(0, 0, size.width * scanProgress, size.height));

    final beamPaint = Paint()..shader = beamGradient;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width * scanProgress, size.height), beamPaint);

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

class PriceUpdate {
  final double price;
  final DateTime timestamp;

  PriceUpdate({
    required this.price,
    required this.timestamp,
  });
}