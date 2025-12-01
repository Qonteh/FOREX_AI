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
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _aiAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _orbitAnimation;
  late Animation<double> _glowAnimation;
  
  // AI ASSISTANT VARIABLES
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isAiActive = false;
  String _lastWords = '';
  
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
    
    // INITIALIZE AI ASSISTANT
    _initializeAI();
  }

  void _initializeAI() async {
    _flutterTts = FlutterTts();
    
    // SETUP NORMAL SPEED HUMAN VOICE
    await _setupHumanVoice();
    
    _flutterTts.setCompletionHandler(() {
      Timer(Duration(seconds: 1), () {
        _stopListening();
      });
    });
    
    _speech = stt.SpeechToText();
    await _speech.initialize();
  }

  // NORMAL SPEED HUMAN VOICE - PERFECT CONVERSATION SPEED!
  Future<void> _setupHumanVoice() async {
    try {
      await _flutterTts.setLanguage("en-US");
      
      List<dynamic> voices = await _flutterTts.getVoices;
      print('🎤 SEARCHING FOR HUMAN VOICES: ${voices.length} available');
      
      // PRIORITIZE MOST HUMAN-LIKE VOICES
      List<String> humanVoices = [
        'samantha', 'alex', 'daniel', 'karen', 'susan', 'allison',
        'victoria', 'ava', 'serena', 'zoe', 'tessa', 'fiona',
        'enhanced', 'natural', 'neural', 'premium', 'high-quality',
        'alice', 'emma', 'olivia', 'sophia', 'emily', 'madison',
        'david', 'michael', 'james', 'robert', 'william', 'richard'
      ];
      
      String? bestHumanVoice;
      
      // FIND BEST HUMAN VOICE
      for (String humanName in humanVoices) {
        for (var voice in voices) {
          String voiceName = voice['name'].toString().toLowerCase();
          String voiceLocale = voice['locale'].toString();
          
          if ((voiceLocale.contains('en-US') || voiceLocale.contains('en_US')) && 
              voiceName.contains(humanName)) {
            bestHumanVoice = voice['name'];
            print('🎯 FOUND HUMAN VOICE: $bestHumanVoice');
            break;
          }
        }
        if (bestHumanVoice != null) break;
      }
      
      // SET HUMAN VOICE
      if (bestHumanVoice != null) {
        await _flutterTts.setVoice({
          "name": bestHumanVoice,
          "locale": "en-US"
        });
        print('✅ HUMAN VOICE ACTIVATED: $bestHumanVoice');
      }
      
      // NORMAL HUMAN SPEECH SETTINGS - PERFECT CONVERSATION SPEED!
      await _flutterTts.setSpeechRate(0.8);   // NORMAL CONVERSATION SPEED
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
    _flutterTts.stop();
    super.dispose();
  }

  void _activateQuantisAI() async {
    setState(() {
      _isAiActive = true;
    });
    
    _aiController.repeat(reverse: true);
    
    String timeGreeting = _getDetailedTimeBasedGreeting();
    String introduction = "My name is QT, your personal AI trading assistant! I'm here to help you analyze markets, manage your portfolio, and make profitable trading decisions. How can I assist you today?";
    String fullGreeting = "$timeGreeting $introduction";
    
    await _speakNaturally(fullGreeting);
    
    _startListening();
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
    text = text.replaceAll('does not', "doesn't");
    text = text.replaceAll('have not', "haven't");
    text = text.replaceAll('is not', "isn't");
    text = text.replaceAll('are not', "aren't");
    
    // NATURAL PRONUNCIATION FOR TERMS
    text = text.replaceAll(' AI ', ' A.I. ');
    text = text.replaceAll(' QT ', ' Q.T. ');
    
    // NATURAL PAUSES - LIKE REAL CONVERSATION
    text = text.replaceAll('!', '! ');      // Short pause after excitement
    text = text.replaceAll('.', '. ');      // Natural pause after sentences
    text = text.replaceAll(',', ', ');      // Brief pause after commas
    text = text.replaceAll('?', '? ');      // Question pause
    
    // REMOVE EXTRA SPACES
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    return text.trim();
  }

  // NATURAL HUMAN-LIKE SPEECH
  Future<void> _speakNaturally(String text) async {
    String naturalText = _makeNatural(text);
    
    print('🗣️ SPEAKING NATURALLY: $naturalText');
    
    // SPEAK WITH NATURAL HUMAN RHYTHM
    await _flutterTts.speak(naturalText);
  }

  String _getDetailedTimeBasedGreeting() {
    DateTime now = DateTime.now();
    int hour = now.hour;
    int minute = now.minute;
    
    if (hour >= 5 && hour < 12) {
      if (hour >= 5 && hour < 7) {
        return "Good early morning! It's ${_formatTime(hour, minute)} and the markets are getting ready to open.";
      } else if (hour >= 7 && hour < 9) {
        return "Good morning! It's ${_formatTime(hour, minute)}, perfect time for market analysis.";
      } else {
        return "Good morning! It's ${_formatTime(hour, minute)} and trading opportunities are everywhere.";
      }
    }
    else if (hour >= 12 && hour < 17) {
      if (hour == 12) {
        return "Good afternoon! It's ${_formatTime(hour, minute)}, lunch time but markets never sleep.";
      } else if (hour >= 13 && hour < 15) {
        return "Good afternoon! It's ${_formatTime(hour, minute)} and markets are in full swing.";
      } else {
        return "Good afternoon! It's ${_formatTime(hour, minute)}, great time to check your portfolio.";
      }
    }
    else {
      if (hour >= 17 && hour < 19) {
        return "Good evening! It's ${_formatTime(hour, minute)}, markets are closing but crypto never stops.";
      } else if (hour >= 19 && hour < 23) {
        return "Good evening! It's ${_formatTime(hour, minute)}, time to review today's trading performance.";
      } else {
        return "Good evening! It's ${_formatTime(hour, minute)}, the dedicated trader's hour when Asian markets are active.";
      }
    }
  }

  String _formatTime(int hour, int minute) {
    String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    if (minute == 0) {
      return "$displayHour o'clock $period";
    } else if (minute < 10) {
      return "$displayHour oh $minute $period";
    } else {
      return "$displayHour $minute $period";
    }
  }

  Future<void> _speak(String text) async {
    await _speakNaturally(text);
  }

  void _startListening() async {
    if (!_isListening && _speech.isAvailable) {
      setState(() {
        _isListening = true;
      });
      
      _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
          
          if (result.finalResult) {
            _processCommand(_lastWords);
          }
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 3),
      );
    }
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _isAiActive = false;
    });
    _speech.stop();
    _aiController.stop();
    _aiController.reset();
  }

  void _processCommand(String command) async {
    command = command.toLowerCase();
    
    if (command.contains('hello') || command.contains('hi')) {
      String timeGreeting = _getQuickTimeGreeting();
      await _speakNaturally("$timeGreeting I'm Q.T., ready to help you with trading analysis!");
    }
    else if (command.contains('market') || command.contains('analysis')) {
      await _speakNaturally("I'm Q.T. and I can provide market analysis for you! Let me take you to the quick analysis section.");
      context.go('/quick-analysis');
    }
    else if (command.contains('portfolio') || command.contains('trading')) {
      await _speakNaturally("Hi, I'm Q.T.! I'll help you with your trading portfolio. Opening your trading calendar now!");
      context.go('/trading-calendar');
    }
    else if (command.contains('signal') || command.contains('signals')) {
      await _speakNaturally("I'm Q.T.! Here are your daily trading signals! These will help guide your trading decisions.");
      context.go('/daily-signals');
    }
    else if (command.contains('chat') || command.contains('talk')) {
      await _speakNaturally("I'm Q.T.! Let's have a conversation! I'll open the A.I. chatbot for you.");
      context.go('/chat-bot');
    }
    else if (command.contains('upgrade') || command.contains('pro')) {
      await _speakNaturally("I'm Q.T. and I think that's a great choice! Let me show you our premium features. Upgrading will give you unlimited access to all A.I. tools!");
      context.go('/pricing');
    }
    else if (command.contains('help')) {
      await _speakNaturally("I'm Q.T.! I can help you with market analysis, trading signals, portfolio management, and A.I. chat. Just ask me about any of these features!");
    }
    else if (command.contains('time') || command.contains('clock')) {
      String currentTime = _getCurrentTimeMessage();
      await _speakNaturally("I'm Q.T.! $currentTime");
    }
    else if (command.contains('bye') || command.contains('stop')) {
      String timeGoodbye = _getTimeBasedGoodbye();
      await _speakNaturally("$timeGoodbye I'm Q.T. and I'm always here when you need trading assistance. Have profitable trading!");
    }
    else {
      await _speakNaturally("I'm Q.T.! I can help you with market analysis, trading signals, portfolio management, and A.I. chat. What would you like to explore?");
    }
  }

  String _getQuickTimeGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good morning!";
    } else if (hour >= 12 && hour < 17) {
      return "Good afternoon!";
    } else {
      return "Good evening!";
    }
  }

  String _getCurrentTimeMessage() {
    DateTime now = DateTime.now();
    String formattedTime = _formatTime(now.hour, now.minute);
    String day = _getDayName(now.weekday);
    return "Right now it's $formattedTime on $day. Perfect time for trading analysis!";
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _getTimeBasedGoodbye() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Have a great morning!";
    } else if (hour >= 12 && hour < 17) {
      return "Have a wonderful afternoon!";
    } else {
      return "Have a pleasant evening!";
    }
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

  // AMAZING ANIMATED ROBOT WITH BEAUTIFUL CIRCLE EFFECTS
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
          onTap: () {
            if (_isAiActive) {
              _stopListening();
            } else {
              _activateQuantisAI();
            }
          },
          child: Container(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // OUTERMOST GLOW RING - BREATHING EFFECT
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
                          _isAiActive 
                            ? Colors.greenAccent.withOpacity(0.1 * _glowAnimation.value)
                            : AppColors.primaryPurple.withOpacity(0.05 * _glowAnimation.value),
                          _isAiActive 
                            ? Colors.greenAccent.withOpacity(0.2 * _glowAnimation.value)
                            : AppColors.primaryPurple.withOpacity(0.1 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // OUTER ORBITAL RING - ROTATING SLOWLY
                Transform.rotate(
                  angle: _orbitAnimation.value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isAiActive 
                          ? Colors.greenAccent.withOpacity(0.4)
                          : AppColors.primaryPurple.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isAiActive 
                            ? Colors.greenAccent.withOpacity(0.3)
                            : AppColors.primaryPurple.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // ORBITAL DOTS
                        ...List.generate(6, (index) {
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
                                  color: _isAiActive 
                                    ? Colors.greenAccent
                                    : AppColors.primaryPurple,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isAiActive 
                                        ? Colors.greenAccent.withOpacity(0.8)
                                        : AppColors.primaryPurple.withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
                // MIDDLE ORBITAL RING - COUNTER ROTATION
                Transform.rotate(
                  angle: -_orbitAnimation.value * 0.7,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isAiActive 
                          ? Colors.greenAccent.withOpacity(0.3)
                          : AppColors.primaryPurple.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // MIDDLE RING PARTICLES
                        ...List.generate(4, (index) {
                          final angle = (index * pi * 2 / 4) + pi / 4;
                          return Transform.rotate(
                            angle: _orbitAnimation.value * 0.7,
                            child: Transform.translate(
                              offset: Offset(
                                cos(angle) * 75,
                                sin(angle) * 75,
                              ),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isAiActive 
                                    ? Colors.greenAccent.withOpacity(0.7)
                                    : AppColors.primaryPurple.withOpacity(0.5),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
                // INNER ENERGY RING - PULSING
                Transform.scale(
                  scale: _isAiActive ? _aiAnimation.value : _scaleAnimation.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          _isAiActive 
                            ? Colors.greenAccent.withOpacity(0.1)
                            : AppColors.primaryPurple.withOpacity(0.1),
                          _isAiActive 
                            ? Colors.greenAccent.withOpacity(0.3)
                            : AppColors.primaryPurple.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isAiActive 
                            ? Colors.greenAccent.withOpacity(0.4 * _glowAnimation.value)
                            : AppColors.primaryPurple.withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 25 * _glowAnimation.value,
                          spreadRadius: 8 * _glowAnimation.value,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // MAIN ROBOT CONTAINER WITH BEAUTIFUL EFFECTS
                Transform.rotate(
                  angle: _rotationAnimation.value * 0.1, // VERY SLOW ROTATION
                  child: Transform.scale(
                    scale: _isAiActive ? _aiAnimation.value : _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isAiActive ? [
                            Colors.greenAccent.withOpacity(0.1),
                            Colors.white,
                            Colors.greenAccent.withOpacity(0.05),
                          ] : [
                            AppColors.primaryPurple.withOpacity(0.1),
                            Colors.white,
                            AppColors.primaryPurple.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: _isAiActive 
                            ? Colors.greenAccent.withOpacity(0.6)
                            : AppColors.primaryPurple.withOpacity(0.4),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isAiActive 
                              ? Colors.greenAccent.withOpacity(0.4)
                              : AppColors.primaryPurple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: _isAiActive 
                              ? Colors.greenAccent.withOpacity(0.2)
                              : AppColors.primaryPurple.withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          children: [
                            // ROBOT IMAGE FILLS ENTIRE CIRCLE
                            Container(
                              width: 120,
                              height: 120,
                              child: Image.asset(
                                'assets/images/robot.jpeg',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
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
                            
                            // SCANNING EFFECT WHEN AI IS ACTIVE
                            if (_isAiActive)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: SweepGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.greenAccent.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                      transform: GradientRotation(_rotationAnimation.value * 2),
                                    ),
                                  ),
                                ),
                              ),
                            
                            // AI ACTIVE OVERLAY WITH PULSE
                            if (_isAiActive)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.greenAccent.withOpacity(0.2 * _glowAnimation.value),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Transform.scale(
                                      scale: _glowAnimation.value,
                                      child: Icon(
                                        Icons.mic,
                                        color: Colors.greenAccent,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            // HOLOGRAPHIC EFFECT OVERLAY
                            if (!_isAiActive)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primaryPurple.withOpacity(0.1 * _pulseAnimation.value),
                                        Colors.transparent,
                                        AppColors.primaryPurple.withOpacity(0.05 * _pulseAnimation.value),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // FLOATING ENERGY PARTICLES - BEAUTIFUL MOVEMENT
                ...List.generate(12, (index) {
                  final angle = (index * pi * 2 / 12) + _orbitAnimation.value * 0.5;
                  final radius = 95 + sin(_glowAnimation.value * pi * 2 + index) * 10;
                  final size = 3 + sin(_glowAnimation.value * pi * 4 + index * 0.5) * 2;
                  return Transform.translate(
                    offset: Offset(
                      cos(angle) * radius,
                      sin(angle) * radius,
                    ),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isAiActive 
                          ? Colors.greenAccent.withOpacity(0.8 * _glowAnimation.value)
                          : AppColors.primaryPurple.withOpacity(0.6 * _glowAnimation.value),
                        boxShadow: [
                          BoxShadow(
                            color: _isAiActive 
                              ? Colors.greenAccent.withOpacity(0.9)
                              : AppColors.primaryPurple.withOpacity(0.7),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                // CENTRAL ENERGY CORE - PULSING DOT
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAiActive ? Colors.greenAccent : AppColors.primaryPurple,
                    boxShadow: [
                      BoxShadow(
                        color: _isAiActive 
                          ? Colors.greenAccent.withOpacity(0.8)
                          : AppColors.primaryPurple.withOpacity(0.6),
                        blurRadius: 15 * _glowAnimation.value,
                        spreadRadius: 5 * _glowAnimation.value,
                      ),
                    ],
                  ),
                ),
              ],
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
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            isSubscribed ? 'QUANTIS PRO' : 'QUANTIS TRADER',
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
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () => _showProfileMenu(context),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.primaryNavy],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: AppColors.primaryPurple,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      drawer: _buildDrawer(context),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // AMAZING ANIMATED ROBOT WITH BEAUTIFUL CIRCLE EFFECTS
                _buildAnimatedRobot(),
                
                const SizedBox(height: 20),
                
                // AI STATUS INDICATOR
                if (_isAiActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening ? 'QT is listening...' : 'QT is speaking...',
                          style: TextStyle(
                            color: Colors.greenAccent.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 10),
                
                // Welcome Text
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Column(
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: AppColors.primaryNavy.withOpacity(0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          authProvider.currentUser?.name ?? 'Quantis Trader',
                          style: TextStyle(
                            color: AppColors.primaryNavy,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isSubscribed 
                            ? '🚀 Unlimited QT AI access' 
                            : '🤖 Tap the robot to activate QT AI!',
                          style: TextStyle(
                            color: AppColors.primaryNavy.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      onTap: () => context.go('/chat-bot'),
                    ),
                    _buildMainActionButton(
                      icon: Icons.mic,
                      onTap: () {
                        if (aiChatbotTrials > 0 || isSubscribed) {
                          context.go('/chat-bot');
                        } else {
                          context.go('/pricing');
                        }
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.dashboard_outlined,
                      onTap: () => context.go('/pricing'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
              color: AppColors.primaryPurple.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
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

  Widget _buildMainActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: Transform.scale(
            scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.03,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.primaryNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
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
            color: AppColors.primaryPurple.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
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