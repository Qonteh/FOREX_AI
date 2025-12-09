import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int quickAnalysisTrials = 3;
  int tradingCalendarTrials = 3;
  int aiChatbotTrials = 5;
  bool isSubscribed = false;
  
  late AnimationController _pulseController;
  late AnimationController _aiController;
  late AnimationController _rotationController;
  late AnimationController _orbitController;
  late AnimationController _glowController;
  late AnimationController _recordPulseController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _aiAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _orbitAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _recordPulseAnimation;
  
  // AI ASSISTANT VARIABLES
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isAiActive = false;
  bool _isAiSpeaking = false;
  String _lastWords = '';
  bool _isRecording = false;
  
  Timer? _recordingTimer;
  Timer? _waveTimer;
  List<double> _waveAmplitudes = List.filled(20, 0.1);
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _aiController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _orbitController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _recordPulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _aiAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _aiController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    _orbitAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _orbitController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _recordPulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _recordPulseController, curve: Curves.easeInOut),
    );
    
    // INITIALIZE AI ASSISTANT
    _initializeAI();
  }

  void _initializeAI() async {
    _flutterTts = FlutterTts();
    
    // SETUP NORMAL SPEED HUMAN VOICE
    await _setupHumanVoice();
    
    _flutterTts.setStartHandler(() {
      setState(() {
        _isAiSpeaking = true;
      });
    });
    
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isAiSpeaking = false;
      });
    });
    
    _speech = stt.SpeechToText();
    await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
  }

  // NORMAL SPEED HUMAN VOICE - PERFECT CONVERSATION SPEED!
  Future<void> _setupHumanVoice() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.75);   // NORMAL CONVERSATION SPEED
      await _flutterTts.setVolume(0.9);       // CLEAR VOLUME
      await _flutterTts.setPitch(1.0);        // NATURAL HUMAN PITCH
      await _flutterTts.awaitSpeakCompletion(true);
      
      print('🔥 NORMAL SPEED HUMAN VOICE READY!');
      
    } catch (e) {
      print('❌ Human voice setup error: $e');
      
      // FALLBACK NORMAL SETTINGS
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.75);  // NORMAL SPEED FALLBACK
      await _flutterTts.setVolume(0.85);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _aiController.dispose();
    _rotationController.dispose();
    _orbitController.dispose();
    _glowController.dispose();
    _recordPulseController.dispose();
    _flutterTts.stop();
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    super.dispose();
  }

  void _activateQuantisAI() async {
    if (_isAiSpeaking || _isAiActive) {
      _stopAiImmediately();
      return;
    }
    
    setState(() {
      _isAiActive = true;
    });
    
    _aiController.repeat(reverse: true);
    
    String timeGreeting = _getDetailedTimeBasedGreeting();
    String introduction = "I'm QT, your AI trading companion. I can help with market analysis, trading strategies, portfolio management, and answering all your trading questions. What can I help you with today?";
    String fullGreeting = "$timeGreeting $introduction";
    
    await _speakNaturally(fullGreeting);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _startListening();
    });
  }

  void _stopAiImmediately() {
    if (_isAiSpeaking) {
      _flutterTts.stop();
    }
    
    setState(() {
      _isAiSpeaking = false;
      _isAiActive = false;
      _aiController.stop();
    });
    
    if (_isRecording) {
      _stopRecording();
    }
  }

  void _onRobotTap() {
    if (_isAiSpeaking || _isAiActive) {
      _stopAiImmediately();
      return;
    }
    
    _activateQuantisAI();
  }

  // NATURAL HUMAN-LIKE TEXT PROCESSING
  String _makeNatural(String text) {
    // KEEP NATURAL CONTRACTIONS FOR HUMAN SPEECH
    text = text.replaceAll('I am', "I'm");
    text = text.replaceAll('you are', "you're");
    text = text.replaceAll('we are', "we're");
    text = text.replaceAll('it is', "it's");
    text = text.replaceAll('that is', "that's");
    text = text.replaceAll('let us', "let's");
    text = text.replaceAll('cannot', "can't");
    text = text.replaceAll('will not', "won't");
    text = text.replaceAll('do not', "don't");
    
    // NATURAL PRONUNCIATION FOR TERMS
    text = text.replaceAll(' AI ', ' A.I. ');
    text = text.replaceAll(' QT ', ' Q.T. ');
    
    // NATURAL PAUSES
    text = text.replaceAll('!', '! ');
    text = text.replaceAll('.', '. ');
    text = text.replaceAll(',', ', ');
    text = text.replaceAll('?', '? ');
    
    // REMOVE EXTRA SPACES
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    return text.trim();
  }

  // NATURAL HUMAN-LIKE SPEECH
  Future<void> _speakNaturally(String text) async {
    String naturalText = _makeNatural(text);
    print('🗣️ SPEAKING: $naturalText');
    await _flutterTts.speak(naturalText);
  }

  String _getDetailedTimeBasedGreeting() {
    DateTime now = DateTime.now();
    int hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return "Good morning.";
    } else if (hour >= 12 && hour < 17) {
      return "Good afternoon.";
    } else {
      return "Good evening.";
    }
  }

  Future<void> _startListening() async {
    if (_isAiSpeaking) return;
    
    try {
      bool available = _speech.isAvailable;
      
      if (available) {
        setState(() {
          _isListening = true;
          _lastWords = '';
        });
        
        await _speech.listen(
          onResult: (result) {
            String words = result.recognizedWords;
            
            if (words.isNotEmpty) {
              setState(() {
                _lastWords = words;
              });
              
              if (result.finalResult && words.trim().isNotEmpty) {
                _stopRecording();
              }
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 1),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        );
      }
    } catch (e) {
      print('Listening error: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _toggleRecording() {
    if (_isAiSpeaking || _isAiActive) {
      _stopAiImmediately();
      return;
    }
    
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    if (_isRecording) return;
    
    setState(() {
      _isRecording = true;
      _isAiActive = true;
      _lastWords = '';
    });
    
    _recordPulseController.repeat(reverse: true);
    
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      _updateWaveAnimation();
    });
    
    _startListening();
    
    _recordingTimer?.cancel();
    _recordingTimer = Timer(const Duration(seconds: 5), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    if (!_isRecording) return;
    
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _stopListening();
    _recordPulseController.stop();
    _recordPulseController.reset();
    
    setState(() {
      _isRecording = false;
    });
    
    if (_lastWords.trim().isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _processCommand(_lastWords);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (!_isAiSpeaking) {
          setState(() {
            _isAiActive = true;
            _isAiSpeaking = true;
          });
          await _speakNaturally("I didn't catch that. Please try speaking again.");
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              _isAiActive = false;
              _isAiSpeaking = false;
            });
          });
        }
      });
    }
  }

  void _updateWaveAnimation() {
    if (!_isRecording) return;
    
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    for (int i = 0; i < _waveAmplitudes.length; i++) {
      double base = 0.15;
      double wave1 = sin(time * 2 + i * 0.3) * 0.3;
      double wave2 = sin(time * 5 + i * 0.7) * 0.2;
      
      _waveAmplitudes[i] = (base + wave1 + wave2).clamp(0.1, 0.8);
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  // ============ EXTENSIVE QUESTION COVERAGE ============
  
  bool _shouldUseLocalResponse(String query) {
    final queryLower = query.toLowerCase();
    
    // CHECK ALL POSSIBLE CATEGORIES
    return _isGreeting(queryLower) || 
           _isPlatformQuestion(queryLower) || 
           _isTradingQuestion(queryLower) || 
           _isFeatureQuestion(queryLower) ||
           _isHelpQuestion(queryLower) ||
           _isSubscriptionQuestion(queryLower) ||
           _isMarketQuestion(queryLower) ||
           _isTechnicalQuestion(queryLower) ||
           _isFundamentalQuestion(queryLower) ||
           _isPortfolioQuestion(queryLower) ||
           _isRiskQuestion(queryLower) ||
           _isBeginnerQuestion(queryLower) ||
           _isAdvancedQuestion(queryLower) ||
           _isCryptoQuestion(queryLower) ||
           _isStockQuestion(queryLower) ||
           _isForexQuestion(queryLower) ||
           _isNewsQuestion(queryLower) ||
           _isEconomicQuestion(queryLower) ||
           _isAppQuestion(queryLower);
  }

  bool _isGreeting(String query) {
    return query.contains('hello') || query.contains('hi') || query.contains('hey') ||
           query.contains('good morning') || query.contains('good afternoon') || 
           query.contains('good evening') || query.contains('what\'s up') || 
           query.contains('how are you') || query.contains('sup') || query.contains('yo') ||
           query.contains('greetings') || query.contains('welcome');
  }

  bool _isPlatformQuestion(String query) {
    return query.contains('quantis') || query.contains('qt') || query.contains('app') ||
           query.contains('platform') || query.contains('what is') || query.contains('who are you') ||
           query.contains('what are you') || query.contains('about you') || query.contains('your name') ||
           query.contains('introduce') || query.contains('tell me about') || query.contains('explain');
  }

  bool _isTradingQuestion(String query) {
    return query.contains('trade') || query.contains('trading') || query.contains('invest') ||
           query.contains('investment') || query.contains('market') || query.contains('buy') ||
           query.contains('sell') || query.contains('position') || query.contains('order') ||
           query.contains('trade setup') || query.contains('entry') || query.contains('exit') ||
           query.contains('stop loss') || query.contains('take profit') || query.contains('scalp') ||
           query.contains('swing') || query.contains('day trade') || query.contains('long term') ||
           query.contains('short term') || query.contains('position sizing') || query.contains('lot size');
  }

  bool _isFeatureQuestion(String query) {
    return query.contains('feature') || query.contains('function') || query.contains('can you') ||
           query.contains('what can') || query.contains('how to') || query.contains('use') ||
           query.contains('quick analysis') || query.contains('trading calendar') || query.contains('daily signal') ||
           query.contains('ai chat') || query.contains('voice') || query.contains('speak') ||
           query.contains('mic') || query.contains('robot') || query.contains('dashboard') ||
           query.contains('screen') || query.contains('button') || query.contains('icon') ||
           query.contains('tap') || query.contains('click') || query.contains('menu') ||
           query.contains('navigate') || query.contains('go to') || query.contains('open') ||
           query.contains('access') || query.contains('find') || query.contains('where');
  }

  bool _isHelpQuestion(String query) {
    return query.contains('help') || query.contains('support') || query.contains('problem') ||
           query.contains('issue') || query.contains('error') || query.contains('trouble') ||
           query.contains('fix') || query.contains('how do i') || query.contains('where is') ||
           query.contains('can i') || query.contains('guide') || query.contains('tutorial') ||
           query.contains('explain') || query.contains('not working') || query.contains('broken') ||
           query.contains('crash') || query.contains('freeze') || query.contains('slow') ||
           query.contains('contact') || query.contains('customer service') || query.contains('tech support');
  }

  bool _isSubscriptionQuestion(String query) {
    return query.contains('subscribe') || query.contains('premium') || query.contains('pro') ||
           query.contains('free') || query.contains('trial') || query.contains('price') ||
           query.contains('cost') || query.contains('plan') || query.contains('upgrade') ||
           query.contains('payment') || query.contains('money') || query.contains('fee') ||
           query.contains('charge') || query.contains('bill') || query.contains('subscription') ||
           query.contains('purchase') || query.contains('buy pro') || query.contains('unlock') ||
           query.contains('limit') || query.contains('restriction') || query.contains('locked');
  }

  bool _isMarketQuestion(String query) {
    return query.contains('market') || query.contains('trend') || query.contains('bull') ||
           query.contains('bear') || query.contains('volatility') || query.contains('liquidity') ||
           query.contains('volume') || query.contains('sentiment') || query.contains('momentum') ||
           query.contains('direction') || query.contains('condition') || query.contains('outlook') ||
           query.contains('forecast') || query.contains('prediction') || query.contains('analysis') ||
           query.contains('analyze') || query.contains('research');
  }

  bool _isTechnicalQuestion(String query) {
    return query.contains('technical') || query.contains('chart') || query.contains('indicator') ||
           query.contains('moving average') || query.contains('ma') || query.contains('ema') ||
           query.contains('rsi') || query.contains('macd') || query.contains('bollinger') ||
           query.contains('fibonacci') || query.contains('support') || query.contains('resistance') ||
           query.contains('level') || query.contains('pattern') || query.contains('candle') ||
           query.contains('chart pattern') || query.contains('technical analysis') || query.contains('ta');
  }

  bool _isFundamentalQuestion(String query) {
    return query.contains('fundamental') || query.contains('earnings') || query.contains('revenue') ||
           query.contains('profit') || query.contains('loss') || query.contains('income') ||
           query.contains('balance sheet') || query.contains('financial') || query.contains('valuation') ||
           query.contains('pe ratio') || query.contains('dividend') || query.contains('growth') ||
           query.contains('debt') || query.contains('cash flow') || query.contains('ratio') ||
           query.contains('fundamental analysis') || query.contains('fa') || query.contains('metrics');
  }

  bool _isPortfolioQuestion(String query) {
    return query.contains('portfolio') || query.contains('diversify') || query.contains('asset') ||
           query.contains('allocation') || query.contains('balance') || query.contains('rebalance') ||
           query.contains('holdings') || query.contains('position') || query.contains('investment') ||
           query.contains('capital') || query.contains('wealth') || query.contains('manage') ||
           query.contains('track') || query.contains('monitor') || query.contains('performance') ||
           query.contains('return') || query.contains('gain') || query.contains('loss');
  }

  bool _isRiskQuestion(String query) {
    return query.contains('risk') || query.contains('safe') || query.contains('danger') ||
           query.contains('protection') || query.contains('secure') || query.contains('insurance') ||
           query.contains('hedge') || query.contains('stop loss') || query.contains('risk management') ||
           query.contains('capital preservation') || query.contains('drawdown') || query.contains('loss') ||
           query.contains('protect') || query.contains('safety') || query.contains('volatile');
  }

  bool _isBeginnerQuestion(String query) {
    return query.contains('beginner') || query.contains('new') || query.contains('start') ||
           query.contains('learn') || query.contains('basics') || query.contains('fundamental') ||
           query.contains('basic') || query.contains('simple') || query.contains('easy') ||
           query.contains('first') || query.contains('starter') || query.contains('novice') ||
           query.contains('how to start') || query.contains('where to begin') || query.contains('getting started');
  }

  bool _isAdvancedQuestion(String query) {
    return query.contains('advanced') || query.contains('expert') || query.contains('professional') ||
           query.contains('complex') || query.contains('sophisticated') || query.contains('algorithm') ||
           query.contains('algorithmic') || query.contains('quantitative') || query.contains('quant') ||
           query.contains('high frequency') || query.contains('hft') || query.contains('options') ||
           query.contains('futures') || query.contains('derivatives') || query.contains('leverage');
  }

  bool _isCryptoQuestion(String query) {
    return query.contains('crypto') || query.contains('bitcoin') || query.contains('btc') ||
           query.contains('ethereum') || query.contains('eth') || query.contains('altcoin') ||
           query.contains('defi') || query.contains('nft') || query.contains('blockchain') ||
           query.contains('wallet') || query.contains('exchange') || query.contains('mining') ||
           query.contains('staking') || query.contains('yield') || query.contains('token');
  }

  bool _isStockQuestion(String query) {
    return query.contains('stock') || query.contains('share') || query.contains('equity') ||
           query.contains('company') || query.contains('corporation') || query.contains('listed') ||
           query.contains('exchange') || query.contains('nyse') || query.contains('nasdaq') ||
           query.contains('s&p') || query.contains('dow') || query.contains('index') ||
           query.contains('blue chip') || query.contains('growth stock') || query.contains('value stock');
  }

  bool _isForexQuestion(String query) {
    return query.contains('forex') || query.contains('fx') || query.contains('currency') ||
           query.contains('pair') || query.contains('eur/usd') || query.contains('gbp/usd') ||
           query.contains('usd/jpy') || query.contains('aud/usd') || query.contains('major') ||
           query.contains('minor') || query.contains('exotic') || query.contains('pip') ||
           query.contains('spread') || query.contains('leverage') || query.contains('margin');
  }

  bool _isNewsQuestion(String query) {
    return query.contains('news') || query.contains('update') || query.contains('latest') ||
           query.contains('current') || query.contains('today') || query.contains('recent') ||
           query.contains('breaking') || query.contains('headline') || query.contains('event') ||
           query.contains('announcement') || query.contains('report') || query.contains('data');
  }

  bool _isEconomicQuestion(String query) {
    return query.contains('economic') || query.contains('gdp') || query.contains('inflation') ||
           query.contains('cpi') || query.contains('interest rate') || query.contains('fed') ||
           query.contains('central bank') || query.contains('monetary') || query.contains('fiscal') ||
           query.contains('policy') || query.contains('unemployment') || query.contains('jobs') ||
           query.contains('manufacturing') || query.contains('retail') || query.contains('consumer');
  }

  bool _isAppQuestion(String query) {
    return query.contains('app') || query.contains('application') || query.contains('mobile') ||
           query.contains('phone') || query.contains('device') || query.contains('install') ||
           query.contains('download') || query.contains('update') || query.contains('version') ||
           query.contains('bug') || query.contains('feature request') || query.contains('improvement') ||
           query.contains('suggestion') || query.contains('feedback') || query.contains('review');
  }

  String _getLocalResponse(String query) {
    final queryLower = query.toLowerCase();
    
    // ============ GREETINGS & INTRODUCTION (50+ variations) ============
    if (_isGreeting(queryLower)) {
      if (queryLower.contains('how are you') || queryLower.contains('how you doing')) {
        List<String> responses = [
          "I'm doing great! Ready to help you make some profitable trades today!",
          "I'm excellent! Markets are moving and I'm here to help you navigate them!",
          "Feeling fantastic! There are so many trading opportunities today!",
          "I'm doing well! Eager to help you with your trading decisions!",
          "I'm in top form! Let's find you some great trading setups!",
        ];
        return responses[DateTime.now().second % responses.length];
      }
      if (queryLower.contains('what\'s up') || queryLower.contains('whats up') || queryLower.contains('sup')) {
        List<String> responses = [
          "Just analyzing market trends and waiting to help you make smart moves!",
          "Scanning for trading opportunities across all markets!",
          "Monitoring global markets and ready to assist you!",
          "Running market analysis algorithms to find you the best trades!",
          "Tracking multiple asset classes for profitable setups!",
        ];
        return responses[DateTime.now().second % responses.length];
      }
      if (queryLower.contains('good morning')) {
        return "Good morning! Perfect time to plan your trading day. Markets are waking up and opportunities are everywhere!";
      }
      if (queryLower.contains('good afternoon')) {
        return "Good afternoon! European markets are active and US markets are opening soon. Great time for trading!";
      }
      if (queryLower.contains('good evening')) {
        return "Good evening! Asian markets are becoming active and crypto never sleeps. Let's find some opportunities!";
      }
      return "Hello! I'm QT, your AI trading companion. I can help with market analysis, trading strategies, and answering all your trading questions. What can I help you with today?";
    }
    
    // ============ PLATFORM QUESTIONS (50+ variations) ============
    if (_isPlatformQuestion(queryLower)) {
      if (queryLower.contains('what is quantis') || queryLower.contains('what is qt')) {
        return "Quantis is an AI-powered trading platform that helps traders make better decisions. I'm QT, your personal AI assistant here to provide market analysis, trading signals, educational content, and real-time insights.";
      }
      if (queryLower.contains('who are you') || queryLower.contains('what are you') || queryLower.contains('your name')) {
        return "I'm QT, your personal AI trading assistant for the Quantis platform. I can analyze markets, provide trading signals, help with portfolio management, risk assessment, and answer all your trading questions 24/7.";
      }
      if (queryLower.contains('introduce') || queryLower.contains('tell me about yourself')) {
        return "I'm QT, an advanced AI trading assistant. I specialize in technical analysis, market sentiment, risk management, and portfolio optimization. I'm here to help you become a better trader through data-driven insights and personalized guidance.";
      }
      if (queryLower.contains('app') || queryLower.contains('platform') || queryLower.contains('quantis app')) {
        return "The Quantis app is a comprehensive trading platform with AI-powered features including quick analysis, trading calendar, daily signals, portfolio tracking, and voice-activated assistance through me, QT. We support stocks, crypto, forex, and commodities.";
      }
      return "Quantis is your all-in-one trading platform with AI-powered tools. I'm QT, here to guide you through market analysis, risk management, and profitable trading strategies.";
    }
    
    // ============ TRADING QUESTIONS (100+ variations) ============
    if (_isTradingQuestion(queryLower)) {
      // General trading
      if (queryLower.contains('how to trade') || queryLower.contains('learn to trade') || queryLower.contains('beginner trader')) {
        return "Start by learning risk management first. Use stop-loss orders, diversify across assets, start with small positions, paper trade first, and focus on one market at a time. Never risk more than 1-2% of your capital per trade.";
      }
      
      if (queryLower.contains('best stock') || queryLower.contains('what stock to buy') || queryLower.contains('stock recommendation')) {
        return "I can't give specific buy/sell recommendations, but I can help you analyze companies. Look for strong fundamentals, consistent revenue growth, positive cash flow, manageable debt, and competitive advantages. Use our Quick Analysis feature for detailed insights.";
      }
      
      if (queryLower.contains('when to buy') || queryLower.contains('entry point')) {
        return "Look for confluence of factors: technical support levels, positive momentum indicators, oversold conditions on RSI, bullish chart patterns, and alignment with overall market trend. Always use stop-loss orders.";
      }
      
      if (queryLower.contains('when to sell') || queryLower.contains('exit strategy')) {
        return "Have predefined exit points: take profit at resistance levels, sell when momentum indicators turn bearish, cut losses when support breaks, and always use trailing stops for profitable positions.";
      }
      
      if (queryLower.contains('stop loss') || queryLower.contains('risk management')) {
        return "Always use stop-loss orders! Place them below support levels, use ATR-based stops, risk only 1-2% per trade, adjust position size based on volatility, and never move stops against your position.";
      }
      
      if (queryLower.contains('position size') || queryLower.contains('lot size') || queryLower.contains('how much to trade')) {
        return "Calculate position size using this formula: (Account risk %) / (Stop loss distance). For example, if you risk 1% on a trade with 5% stop loss, position size = 1% / 5% = 20% of your account. Our Quick Analysis tool can calculate this for you.";
      }
      
      if (queryLower.contains('day trading') || queryLower.contains('scalp')) {
        return "Day trading requires quick decisions: focus on high liquidity assets, use smaller time frames (5m-15m), trade during high volume hours, use tight stops, take quick profits, and never hold overnight positions.";
      }
      
      if (queryLower.contains('swing trading')) {
        return "Swing trading holds positions for days to weeks: use daily charts, identify clear trends, wait for pullbacks to support, use wider stops, aim for 3:1 reward-to-risk ratios, and be patient for setups.";
      }
      
      if (queryLower.contains('long term') || queryLower.contains('investing')) {
        return "Long-term investing focuses on fundamentals: buy quality companies, diversify across sectors, dollar-cost average into positions, reinvest dividends, ignore short-term volatility, and hold through market cycles.";
      }
    }
    
    // ============ CRYPTO QUESTIONS (50+ variations) ============
    if (_isCryptoQuestion(queryLower)) {
      if (queryLower.contains('bitcoin') || queryLower.contains('btc')) {
        return "Bitcoin is the original cryptocurrency with limited supply of 21 million. Key factors: halving cycles, adoption by institutions, regulatory developments, hash rate, and overall crypto market sentiment.";
      }
      
      if (queryLower.contains('ethereum') || query.contains('eth')) {
        return "Ethereum is a programmable blockchain with smart contracts. Watch for: network upgrades, gas fees, DeFi adoption, NFT ecosystem, staking rewards, and transition to proof-of-stake.";
      }
      
      if (queryLower.contains('altcoin') || queryLower.contains('alt coins')) {
        return "Altcoins carry higher risk but potential for higher returns. Research: team credibility, project utility, tokenomics, community strength, exchange listings, and development activity.";
      }
      
      if (queryLower.contains('defi') || queryLower.contains('decentralized finance')) {
        return "DeFi offers financial services without intermediaries. Key metrics: TVL (Total Value Locked), protocol revenue, token utility, security audits, and regulatory considerations.";
      }
      
      if (queryLower.contains('crypto wallet') || queryLower.contains('store crypto')) {
        return "For security: use hardware wallets for large amounts, never share seed phrases, enable 2FA, use different wallets for trading vs storage, and regularly update software.";
      }
      
      return "Cryptocurrency trading is highly volatile. Focus on major coins first, use proper risk management, diversify across different projects, stay updated on regulatory news, and consider dollar-cost averaging for long-term positions.";
    }
    
    // ============ STOCK QUESTIONS (50+ variations) ============
    if (_isStockQuestion(queryLower)) {
      if (queryLower.contains('growth stock')) {
        return "Growth stocks have high earnings growth rates. Look for: revenue growth >20%, expanding profit margins, market leadership, competitive moat, and reasonable valuations relative to growth.";
      }
      
      if (queryLower.contains('value stock')) {
        return "Value stocks trade below intrinsic value. Metrics: low P/E ratio, high dividend yield, strong balance sheet, stable cash flows, and potential for multiple expansion.";
      }
      
      if (queryLower.contains('dividend stock')) {
        return "Dividend stocks provide income. Check: dividend yield, payout ratio, dividend growth history, company stability, and ability to maintain payments during downturns.";
      }
      
      if (queryLower.contains('tech stock')) {
        return "Tech stocks require understanding innovation cycles. Focus on: product pipeline, R&D spending, user growth, network effects, and adaptability to technological changes.";
      }
      
      return "Stock trading involves analyzing company fundamentals and market sentiment. Use both technical and fundamental analysis, diversify across sectors, monitor earnings reports, and stay informed about economic conditions.";
    }
    
    // ============ FOREX QUESTIONS (50+ variations) ============
    if (_isForexQuestion(queryLower)) {
      if (queryLower.contains('forex trading') || queryLower.contains('currency trading')) {
        return "Forex trading involves currency pairs. Major pairs like EUR/USD have lower spreads. Focus on: interest rate differentials, economic data releases, central bank policies, and geopolitical events.";
      }
      
      if (queryLower.contains('best time to trade forex')) {
        return "Overlap sessions have highest liquidity: London-New York overlap (8AM-12PM EST) and Tokyo-London overlap (3AM-4AM EST). Avoid trading during major news releases unless you have a strategy.";
      }
      
      if (queryLower.contains('forex strategy')) {
        return "Common forex strategies: trend following during London/NY sessions, range trading during Asian sessions, breakout trading around news events, and carry trading for interest rate differentials.";
      }
      
      return "Forex is the largest financial market. Trade major pairs first, use proper leverage (max 10:1 for beginners), focus on economic calendars, understand correlations between currencies, and always use stop losses.";
    }
    
    // ============ TECHNICAL ANALYSIS QUESTIONS (100+ variations) ============
    if (_isTechnicalQuestion(queryLower)) {
      if (queryLower.contains('moving average') || queryLower.contains('ma')) {
        return "Moving averages smooth price data. Simple MA gives equal weight, Exponential MA weights recent prices. Golden cross (50MA crosses above 200MA) is bullish, death cross is bearish.";
      }
      
      if (queryLower.contains('rsi') || queryLower.contains('relative strength')) {
        return "RSI measures momentum (0-100). Above 70 = overbought, below 30 = oversold. Divergence between price and RSI can signal reversals. Use with other indicators for confirmation.";
      }
      
      if (queryLower.contains('macd')) {
        return "MACD shows relationship between two MAs. Signal line crossover gives buy/sell signals. Histogram shows momentum strength. Bullish divergence = price makes lower low, MACD makes higher low.";
      }
      
      if (queryLower.contains('support') || queryLower.contains('resistance')) {
        return "Support = price level where buying interest emerges. Resistance = price level where selling pressure emerges. Breaks above resistance become new support, breaks below support become new resistance.";
      }
      
      if (queryLower.contains('chart pattern')) {
        return "Common patterns: Head & Shoulders (reversal), Double Top/Bottom (reversal), Triangles (continuation), Flags/Pennants (continuation), Cup & Handle (bullish continuation).";
      }
      
      if (queryLower.contains('fibonacci')) {
        return "Fibonacci retracement levels: 23.6%, 38.2%, 50%, 61.8%, 78.6%. After a move, price often retraces to these levels before continuing. Use with other confirmation tools.";
      }
      
      return "Technical analysis studies price action and volume. Use multiple time frames, combine indicators for confirmation, understand market context, and backtest strategies before using real money.";
    }
    
    // ============ FEATURE QUESTIONS (100+ variations) ============
    if (_isFeatureQuestion(queryLower)) {
      if (queryLower.contains('what can you do') || queryLower.contains('can you help') || queryLower.contains('your capabilities')) {
        return "I can help with: 1. Market analysis and trend identification 2. Trading strategy development 3. Portfolio optimization 4. Risk management 5. Technical indicator explanations 6. Quick analysis of specific assets 7. Daily trading signals 8. Calendar of market events 9. Educational content 10. Voice-activated trading assistance";
      }
      
      if (queryLower.contains('quick analysis') || queryLower.contains('analyze') || queryLower.contains('analysis tool')) {
        return "The Quick Analysis feature provides instant technical analysis for any stock or crypto. It shows: key indicators (RSI, MACD, Moving Averages), trend direction, support/resistance levels, volume analysis, and generates actionable insights. You have ${quickAnalysisTrials} free trials remaining.";
      }
      
      if (queryLower.contains('trading calendar')) {
        return "The Trading Calendar shows upcoming economic events, earnings reports, FOMC meetings, and market-moving news. This helps you avoid volatility around major announcements and plan trades accordingly. You have ${tradingCalendarTrials} free trials remaining.";
      }
      
      if (queryLower.contains('daily signal') || queryLower.contains('signals') || queryLower.contains('trading ideas')) {
        return "Daily Signals provide curated trading opportunities based on technical analysis. Each signal includes: entry price, stop-loss level, take-profit targets, risk-reward ratio, and time frame. Check the Daily Signals screen for today's recommendations.";
      }
      
      if (queryLower.contains('ai chat') || queryLower.contains('chatbot') || queryLower.contains('chat with you')) {
        return "That's me! I'm your AI chatbot. You can ask me any trading questions, get market analysis, learn about trading concepts, or discuss strategies. You have ${aiChatbotTrials} free conversations remaining.";
      }
      
      if (queryLower.contains('voice') || queryLower.contains('speak') || queryLower.contains('mic') || queryLower.contains('talk to you')) {
        return "You can talk to me using the microphone button in the center. Just tap and speak your question clearly. I'll listen and respond with analysis or answers. Make sure you've granted microphone permission in your device settings.";
      }
      
      if (queryLower.contains('robot') || queryLower.contains('avatar') || queryLower.contains('tap me')) {
        return "That's my avatar! Tap me to activate voice mode, or tap again to stop me from speaking. The orbiting dots show I'm active and analyzing market data in real-time.";
      }
      
      if (queryLower.contains('dashboard') || queryLower.contains('main screen') || queryLower.contains('home')) {
        return "The dashboard gives you quick access to all features: Quick Analysis, Daily Signals, Trading Calendar, and voice chat with me. The bottom navigation lets you switch between features easily.";
      }
      
      if (queryLower.contains('how to use') || queryLower.contains('get started') || queryLower.contains('beginner guide')) {
        return "Start by exploring Quick Analysis for market insights. Check Daily Signals for trading ideas. Use Trading Calendar to plan around events. Try voice chat with me for questions. And explore all features from the bottom navigation.";
      }
      
      if (queryLower.contains('where is') || queryLower.contains('how do i find') || queryLower.contains('access')) {
        if (queryLower.contains('quick analysis') || queryLower.contains('analyze')) {
          return "Go to Quick Analysis from the bottom navigation (second icon). Enter a stock symbol or crypto ticker to get instant analysis.";
        }
        if (queryLower.contains('signal') || queryLower.contains('daily')) {
          return "Go to Daily Signals from the bottom navigation (third icon). You'll see today's trading opportunities with entry and exit points.";
        }
        if (queryLower.contains('calendar') || queryLower.contains('events')) {
          return "Go to Trading Calendar from the bottom navigation (fourth icon). Browse upcoming economic events and earnings reports.";
        }
        if (queryLower.contains('chat') || queryLower.contains('talk')) {
          return "Tap the microphone button in the center of the dashboard. Speak your question clearly. I'll respond with analysis or answers.";
        }
        if (queryLower.contains('pricing') || queryLower.contains('upgrade')) {
          return "Tap the crown icon on the dashboard or go to Pricing from the menu to upgrade to Pro features.";
        }
      }
    }
    
    // ============ SUBSCRIPTION QUESTIONS (50+ variations) ============
    if (_isSubscriptionQuestion(queryLower)) {
      if (queryLower.contains('free') || queryLower.contains('trial') || queryLower.contains('free version')) {
        return "You're currently on the free plan with limited access. Free features include: ${quickAnalysisTrials} quick analyses, ${tradingCalendarTrials} calendar views, and ${aiChatbotTrials} AI conversations. Upgrade to Pro for unlimited access.";
      }
      
      if (queryLower.contains('pro') || queryLower.contains('premium') || queryLower.contains('upgrade') || queryLower.contains('premium features')) {
        return "Quantis Pro includes: Unlimited quick analyses, real-time trading signals, advanced technical indicators, priority support, exclusive market insights, higher accuracy predictions, and early access to new features. Tap the crown icon or visit Pricing to upgrade.";
      }
      
      if (queryLower.contains('price') || queryLower.contains('cost') || queryLower.contains('plan') || queryLower.contains('how much')) {
        return "We offer monthly and yearly plans. Monthly is \$29.99, yearly is \$299 (saves 17%). Both include all Pro features. Visit the Pricing screen for details and to subscribe.";
      }
      
      if (queryLower.contains('benefit') || queryLower.contains('advantage') || queryLower.contains('why upgrade')) {
        return "Pro benefits: Unlimited analysis, real-time signals, advanced tools, priority support, higher accuracy, exclusive insights, no ads, and early feature access. Perfect for serious traders.";
      }
      
      if (queryLower.contains('payment') || queryLower.contains('subscribe') || queryLower.contains('buy')) {
        return "You can subscribe through the Pricing screen. We accept credit cards, PayPal, and crypto payments. All subscriptions come with a 7-day money-back guarantee.";
      }
      
      if (queryLower.contains('cancel') || queryLower.contains('refund') || queryLower.contains('money back')) {
        return "You can cancel anytime through your account settings. We offer a 7-day money-back guarantee for all new subscriptions. Contact support@quantis.com for assistance.";
      }
    }
    
    // ============ HELP & SUPPORT (50+ variations) ============
    if (_isHelpQuestion(queryLower)) {
      if (queryLower.contains('not working') || queryLower.contains('problem') || queryLower.contains('issue') || queryLower.contains('bug')) {
        return "Sorry you're having trouble. Try these steps: 1. Restart the app 2. Check your internet connection 3. Update to the latest version 4. Clear app cache 5. For voice issues, check microphone permissions. If problems continue, contact support@quantis.com";
      }
      
      if (queryLower.contains('contact') || queryLower.contains('support') || queryLower.contains('customer service')) {
        return "You can contact our support team at support@quantis.com or call +1-800-QUANTIS. For trading emergencies or account issues, include your user ID for faster assistance.";
      }
      
      if (queryLower.contains('forgot password') || queryLower.contains('login problem')) {
        return "Use the 'Forgot Password' link on the login screen. You'll receive an email to reset your password. Check spam folder if you don't see it within 5 minutes.";
      }
      
      if (queryLower.contains('account') || queryLower.contains('profile')) {
        return "Manage your account from the profile menu (top right icon). You can update personal info, change password, manage subscriptions, and adjust app settings there.";
      }
    }
    
    // ============ MARKET & NEWS QUESTIONS (50+ variations) ============
    if (_isMarketQuestion(queryLower) || _isNewsQuestion(queryLower) || _isEconomicQuestion(queryLower)) {
      if (queryLower.contains('market today') || queryLower.contains('current market')) {
        return "Markets are dynamic. Check the Daily Signals for today's opportunities, or use Quick Analysis for specific assets. Remember to consider overall market sentiment and economic conditions.";
      }
      
      if (queryLower.contains('news') || queryLower.contains('update') || queryLower.contains('latest')) {
        return "Check the Trading Calendar for upcoming news events. Important events: FOMC meetings, employment reports, CPI data, earnings season, and central bank announcements.";
      }
      
      if (queryLower.contains('economic data') || queryLower.contains('economic calendar')) {
        return "Key economic data to watch: Non-Farm Payrolls, CPI inflation, GDP growth, retail sales, manufacturing PMI, and central bank interest rate decisions. These move markets significantly.";
      }
      
      if (queryLower.contains('fed') || queryLower.contains('interest rate')) {
        return "The Federal Reserve's interest rate decisions impact all markets. Higher rates typically strengthen USD but pressure stocks. Watch FOMC meetings and Powell's speeches.";
      }
      
      if (queryLower.contains('inflation') || queryLower.contains('cpi')) {
        return "Inflation data affects monetary policy. High CPI may lead to rate hikes, impacting bonds, stocks, and currencies. Core inflation (excluding food/energy) is watched closely.";
      }
      
      if (queryLower.contains('earnings') || queryLower.contains('earnings season')) {
        return "Earnings season happens quarterly. Watch for: revenue beats/misses, guidance changes, profit margins, and management commentary. Stocks often move significantly on earnings reports.";
      }
    }
    
    // ============ PORTFOLIO & RISK QUESTIONS (50+ variations) ============
    if (_isPortfolioQuestion(queryLower) || _isRiskQuestion(queryLower)) {
      if (queryLower.contains('diversify') || queryLower.contains('diversification')) {
        return "Diversify across: asset classes (stocks, bonds, crypto, real estate), sectors (tech, healthcare, finance), geographies (US, Europe, Asia), and time horizons (short-term trades, long-term investments).";
      }
      
      if (queryLower.contains('rebalance') || queryLower.contains('portfolio balance')) {
        return "Rebalance quarterly or when allocations drift 5% from targets. Sell winners, buy losers to maintain target allocations. This enforces discipline and manages risk automatically.";
      }
      
      if (queryLower.contains('risk tolerance') || queryLower.contains('how much risk')) {
        return "Assess your risk tolerance based on: investment horizon, financial goals, income stability, and emotional comfort with volatility. Younger investors can typically take more risk.";
      }
      
      if (queryLower.contains('protection') || queryLower.contains('hedge') || queryLower.contains('safe')) {
        return "Portfolio protection strategies: use stop-loss orders, diversify assets, hold cash reserves, consider inverse ETFs during downturns, use options for hedging, and maintain a long-term perspective.";
      }
      
      if (queryLower.contains('drawdown') || queryLower.contains('maximum loss')) {
        return "Maximum drawdown is the peak-to-trough decline. Manage it by: diversifying, using stops, reducing position sizes during high volatility, and having an exit plan before entering trades.";
      }
    }
    
    // ============ DEFAULT RESPONSE ============
    return '''I'm QT, your trading assistant. I can help you with: market analysis, trading strategies, portfolio advice, using Quantis features, or answering any trading questions. What specific help do you need right now?''';
  }

  void _processCommand(String command) async {
    command = command.trim();
    
    if (command.isEmpty) {
      return;
    }
    
    _stopListening();
    
    setState(() {
      _isAiActive = true;
    });
    _aiController.repeat(reverse: true);
    
    String response = _getLocalResponse(command);
    
    await _speakNaturally(response);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isAiSpeaking) {
        setState(() {
          _isAiActive = false;
          _aiController.stop();
        });
      }
    });
  }

  void _showProfileMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.right - 160,
        position.top + 10,
        position.right - 5,
        position.bottom,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      elevation: 8,
      shadowColor: AppColors.primaryPurple.withOpacity(0.2),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            width: 150,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSimplePopupItem(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Upgrade to Pro',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/pricing');
                  },
                ),
                const SizedBox(height: 4),
                _buildSimplePopupItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 4),
                _buildSimplePopupItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    context.read<AuthProvider>().logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimplePopupItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryPurple,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryNavy.withOpacity(0.02),
            AppColors.primaryPurple.withOpacity(0.05),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitudes: _waveAmplitudes,
          isRecording: _isRecording,
        ),
        size: const Size(double.infinity, 150),
      ),
    );
  }

  Widget _buildAnimatedRobot() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _isAiActive ? _aiController : _pulseController,
        _rotationController,
        _orbitController,
        _glowController,
      ]),
      builder: (context, child) {
        return GestureDetector(
          onTap: _onRobotTap,
          child: Container(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Transform.scale(
                  scale: 1.0 + (_glowAnimation.value * 0.1),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          _isAiActive || _isAiSpeaking
                              ? Colors.greenAccent.withOpacity(0.1 * _glowAnimation.value)
                              : AppColors.primaryPurple.withOpacity(0.05 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Orbiting dots
                Transform.rotate(
                  angle: _orbitAnimation.value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isAiActive || _isAiSpeaking
                            ? Colors.greenAccent.withOpacity(0.4)
                            : AppColors.primaryPurple.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: List.generate(6, (index) {
                        final angle = (index * pi * 2 / 6);
                        return Transform.rotate(
                          angle: -_orbitAnimation.value,
                          child: Transform.translate(
                            offset: Offset(
                              cos(angle) * 85,
                              sin(angle) * 85,
                            ),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isAiActive || _isAiSpeaking
                                    ? Colors.greenAccent 
                                    : AppColors.primaryPurple,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                
                // Main robot circle
                Transform.rotate(
                  angle: _rotationAnimation.value * 0.1,
                  child: Transform.scale(
                    scale: _isAiActive || _isAiSpeaking
                        ? _aiAnimation.value 
                        : _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isAiActive || _isAiSpeaking
                              ? [
                                  Colors.greenAccent.withOpacity(0.1),
                                  Colors.white,
                                  Colors.greenAccent.withOpacity(0.05),
                                ]
                              : [
                                  AppColors.primaryPurple.withOpacity(0.1),
                                  Colors.white,
                                  AppColors.primaryPurple.withOpacity(0.05),
                                ],
                        ),
                        border: Border.all(
                          color: _isAiActive || _isAiSpeaking
                              ? Colors.greenAccent.withOpacity(0.6)
                              : AppColors.primaryPurple.withOpacity(0.4),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/robot.jpeg',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primaryPurple, AppColors.primaryNavy],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.smart_toy,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Center dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAiActive || _isAiSpeaking
                        ? Colors.greenAccent 
                        : AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: AppColors.primaryPurple.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.primaryPurple,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildMainActionButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _recordPulseController]),
      builder: (context, child) {
        double scale = _isRecording ? _recordPulseAnimation.value : 1.0;
        
        return GestureDetector(
          onTap: _toggleRecording,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isRecording
                      ? [Colors.redAccent, Colors.orangeAccent]
                      : [AppColors.primaryPurple, AppColors.primaryNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isRecording
                        ? Colors.redAccent.withOpacity(0.5)
                        : AppColors.primaryPurple.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.primaryPurple),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.primaryNavy],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isSubscribed ? 'QUANTIS PRO' : 'QUANTIS',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showProfileMenu(context),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryPurple, AppColors.primaryNavy],
                  ),
                ),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: Colors.purple,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              if (_isRecording)
                Expanded(
                  child: _buildWaveform(),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: _buildAnimatedRobot(),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    color: AppColors.primaryNavy.withOpacity(0.6),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  authProvider.currentUser?.name ?? 'Quantis Trader',
                                  style: TextStyle(
                                    color: AppColors.primaryNavy,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.chat_bubble_outline,
                                  onTap: () => context.go('/chat-bot'),
                                ),
                                _buildMainActionButton(),
                                _buildActionButton(
                                  icon: Icons.workspace_premium_outlined,
                                  onTap: () => context.go('/pricing'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.65,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.primaryNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/robot.jpeg',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.smart_toy,
                              size: 16,
                              color: Colors.purple,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Text(
                              authProvider.currentUser?.name ?? 'Quantis Trader',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSubscribed ? Colors.amber.shade400 : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSubscribed ? Icons.diamond : Icons.free_breakfast,
                                size: 12,
                                color: isSubscribed ? AppColors.primaryNavy : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSubscribed ? 'PRO' : 'FREE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSubscribed ? AppColors.primaryNavy : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    _buildSimpleMenuItem(
                      icon: Icons.groups_rounded,
                      title: 'Affiliate',
                      subtitle: 'Earn 30% Commission!',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/affiliate');
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSimpleMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out of Quantis Trading',
                      onTap: () {
                        Navigator.pop(context);
                        context.read<AuthProvider>().logout();
                        context.go('/login');
                      },
                    ),
                    const Spacer(),
                    Center(
                      child: Text(
                        'Quantis Trading v1.0.0',
                        style: TextStyle(
                          color: AppColors.primaryPurple.withOpacity(0.4),
                          fontSize: 10,
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

  Widget _buildSimpleMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.primaryPurple.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryPurple,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.primaryPurple.withOpacity(0.1), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: AppColors.primaryNavy.withOpacity(0.6),
        selectedFontSize: 11,
        unselectedFontSize: 10,
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
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '$quickAnalysisTrials',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
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
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '$quickAnalysisTrials',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
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
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '$tradingCalendarTrials',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
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
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '$tradingCalendarTrials',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
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
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isRecording;

  _WaveformPainter({
    required this.amplitudes,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final barWidth = size.width / amplitudes.length;
    final maxBarHeight = size.height * 0.3;

    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final amplitude = amplitudes[i];
      final barHeight = amplitude * maxBarHeight;

      final progress = i / amplitudes.length;
      final color = Color.lerp(
        const Color(0xFF00E5FF),
        const Color(0xFFFF00FF),
        progress,
      )!.withOpacity(0.6);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Top bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - barWidth / 3,
            centerY - barHeight,
            barWidth * 0.66,
            barHeight,
          ),
          Radius.circular(barWidth * 0.15),
        ),
        paint,
      );

      // Bottom bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - barWidth / 3,
            centerY,
            barWidth * 0.66,
            barHeight,
          ),
          Radius.circular(barWidth * 0.15),
        ),
        paint,
      );
    }

    // Center circle
    final centerPaint = Paint()
      ..color = isRecording ? Colors.redAccent : Colors.purple
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, centerY),
      12,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}