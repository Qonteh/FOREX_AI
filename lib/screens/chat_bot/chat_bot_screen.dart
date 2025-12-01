import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_colors.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Your OpenAI API Key
  final String _openAIApiKey = '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';
  
  bool _isTyping = false;
  bool _isConnected = true;
  
  // Voice features
  late SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechEnabled = false;
  
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  late AnimationController _voiceAnimationController;
  late Animation<double> _voiceAnimation;
  
  List<ChatMessage> messages = [
    ChatMessage(
      text: "Hello! I'm your **Quantis Trading AI Assistant**! 🚀\n\nI can help you with:\n• Real-time market analysis\n• Advanced trading strategies\n• Currency pair insights\n• Technical analysis\n• Risk management\n• Economic news impact\n\nAsk me anything about trading and I'll give you professional insights!",
      isBot: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  final List<String> quickQuestions = [
    "Analyze EUR/USD today",
    "Best scalping strategy?", 
    "How to trade NFP news?",
    "Bitcoin price prediction",
    "Risk management tips",
    "Support/Resistance levels",
    "Market sentiment now",
    "Best timeframe for day trading?"
  ];

  @override
  void initState() {
    super.initState();
    
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _voiceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _voiceAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _initSpeech();
    _initTts();
    _checkAPIConnection();
    _requestPermissions();
  }

  void _initSpeech() async {
    _speechToText = SpeechToText();
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => print('Speech Error: $error'),
      onStatus: (status) => print('Speech Status: $status'),
    );
    setState(() {});
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.camera.request();
    await Permission.storage.request();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _voiceAnimationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _checkAPIConnection() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': 'Test connection'}
          ],
          'max_tokens': 10,
        }),
      ).timeout(const Duration(seconds: 10));
      
      setState(() {
        _isConnected = response.statusCode == 200;
      });
      
      if (_isConnected) {
        print('✅ Quantis AI Connected Successfully!');
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
      print('❌ Quantis AI Connection Failed: $e');
    }
  }

  void _startListening() async {
    if (_speechEnabled && !_isListening) {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: "en_US",
        onSoundLevelChange: (level) => {},
      );
      setState(() {
        _isListening = true;
      });
      _voiceAnimationController.repeat(reverse: true);
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    _voiceAnimationController.stop();
    _voiceAnimationController.reset();
  }

  void _onSpeechResult(result) {
    setState(() {
      _messageController.text = result.recognizedWords;
    });
    
    if (result.finalResult) {
      _stopListening();
      if (_messageController.text.trim().isNotEmpty) {
        _sendMessage(_messageController.text.trim());
      }
    }
  }

  Future<void> _speak(String text) async {
    // Remove markdown and special characters for better TTS
    String cleanText = text
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1') // Remove bold markdown
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'\1') // Remove italic markdown
        .replaceAll(RegExp(r'[📊📈📰💼🚀⚡₿🎯🛡️💡💪⚠️🔥✅❌]'), '') // Remove emojis
        .replaceAll('•', '') // Remove bullet points
        .replaceAll('\n', '. ') // Replace newlines with pauses
        .trim();
    
    if (cleanText.isNotEmpty) {
      await _flutterTts.speak(cleanText);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        _sendImageMessage(image);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        _sendImageMessage(image);
      }
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to take picture')),
      );
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Image for Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload trading charts or screenshots for AI analysis',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageOption(
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageOption(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePicture();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryPurple.withOpacity(0.1),
              AppColors.primaryNavy.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primaryPurple,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.primaryPurple,
            ),
          ),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Row(
          children: [
            // QUANTIS LOGO HERE BRO! 🔥
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/log.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient container if logo fails to load
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.primaryNavy],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 22,
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
                  Text(
                    'Quantis Trading AI',
                    style: TextStyle(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isConnected ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.volume_off, color: Colors.blue.shade600),
              ),
              onPressed: () => _flutterTts.stop(),
            ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.refresh, color: Colors.red.shade600),
            ),
            onPressed: _clearChat,
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: Column(
        children: [
          if (messages.length <= 1) _buildWelcomeScreen(),
          if (messages.length > 1) _buildQuickQuestions(),
          
          Expanded(
            child: _buildMessagesList(),
          ),
          
          if (_isTyping) _buildTypingIndicator(),
          
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Expanded(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QUANTIS LOGO IN WELCOME SCREEN TOO! 🔥
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    'assets/images/log.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to gradient container if logo fails to load
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryPurple, AppColors.primaryNavy],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quantis Trading AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Advanced AI Trading Assistant',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Ask me anything about trading!\nI provide professional insights using advanced AI.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  'AI POWERED',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 35,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quickQuestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _sendMessage(quickQuestions[index]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryPurple.withOpacity(0.1),
                            AppColors.primaryNavy.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: AppColors.primaryPurple,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            quickQuestions[index],
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            // QUANTIS LOGO IN CHAT BUBBLES TOO! 🔥
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/log.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient container if logo fails to load
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.primaryNavy],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 18,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isBot 
                    ? Colors.white
                    : AppColors.primaryPurple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isBot ? 4 : 20),
                  topRight: Radius.circular(message.isBot ? 20 : 4),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isBot 
                        ? Colors.grey.withOpacity(0.1)
                        : AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: message.isBot 
                    ? Border.all(color: AppColors.primaryPurple.withOpacity(0.2))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isBot)
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.primaryPurple,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Quantis AI',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _speak(message.text),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                              color: Colors.blue.shade600,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (message.isBot) const SizedBox(height: 8),
                  
                  // Display image if exists
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(message.imagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isBot ? AppColors.primaryNavy : Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isBot 
                              ? AppColors.textSecondary 
                              : Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      if (message.isBot) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'AI',
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
                ],
              ),
            ),
          ),
          if (!message.isBot) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryNavy.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primaryNavy,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // QUANTIS LOGO IN TYPING INDICATOR TOO! 🔥
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/log.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient container if logo fails to load
                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryPurple, AppColors.primaryNavy],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 18,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quantis AI is analyzing',
                  style: TextStyle(
                    color: AppColors.primaryNavy,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(
                              ((_typingAnimation.value + index * 0.3) % 1.0).clamp(0.3, 1.0)
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !_isTyping,
                decoration: InputDecoration(
                  hintText: _isConnected 
                      ? 'Ask Quantis AI about trading...'
                      : 'AI offline, using local responses...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  prefixIcon: Icon(
                    Icons.psychology,
                    color: AppColors.primaryPurple.withOpacity(0.6),
                    size: 20,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty && !_isTyping) {
                    _sendMessage(text.trim());
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Image Upload Button
          GestureDetector(
            onTap: _showImageOptions,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.image,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Voice Input Button
          if (_speechEnabled)
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedBuilder(
                animation: _voiceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _voiceAnimation.value : 1.0,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isListening 
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.red : Colors.blue).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          
          if (_speechEnabled) const SizedBox(width: 8),
          
          // Send Button
          GestureDetector(
            onTap: () {
              if (_messageController.text.trim().isNotEmpty && !_isTyping) {
                _sendMessage(_messageController.text.trim());
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isTyping 
                      ? [Colors.grey.shade400, Colors.grey.shade500]
                      : [AppColors.primaryPurple, AppColors.primaryNavy],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: _isTyping ? [] : [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isTyping ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ...existing code...
  void _sendMessage(String text) {
    if (_isTyping) return;
    
    setState(() {
      messages.add(ChatMessage(
        text: text,
        isBot: false,
        timestamp: DateTime.now(),
      ));
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // Get response from Quantis AI
    _getQuantisAIResponse(text);
  }

  void _sendImageMessage(XFile image) {
    if (_isTyping) return;
    
    setState(() {
      messages.add(ChatMessage(
        text: "Please analyze this trading chart/screenshot for me 📊",
        isBot: false,
        timestamp: DateTime.now(),
        imagePath: image.path,
      ));
    });
    
    _scrollToBottom();
    
    // Get AI analysis of the image
    _getImageAnalysis(image);
  }

  Future<void> _getImageAnalysis(XFile image) async {
    setState(() {
      _isTyping = true;
    });
    
    _typingAnimationController.repeat();
    
    try {
      // For now, we'll provide a general response since GPT-4 Vision API is more complex
      String response = "**Image Analysis** 📊\n\nI can see you've uploaded an image! While I can't process images directly yet, I can help you analyze trading charts by describing what you see:\n\n**Common Chart Patterns to Look For:**\n• **Support/Resistance Levels**: Horizontal lines where price bounces\n• **Trend Lines**: Diagonal lines connecting highs or lows\n• **Chart Patterns**: Triangles, flags, head & shoulders\n• **Candlestick Patterns**: Doji, hammer, engulfing patterns\n• **Volume Analysis**: High/low volume confirmation\n\n**Tell me what you see in your chart:**\n- What timeframe are you looking at?\n- What currency pair or asset?\n- What specific pattern or setup interests you?\n- Are you looking for entry or exit signals?\n\n💡 **Tip**: Describe the chart details and I'll provide professional analysis and trading recommendations!";
      
      await Future.delayed(const Duration(seconds: 3)); // Simulate analysis time
      
      if (mounted) {
        setState(() {
          messages.add(ChatMessage(
            text: response,
            isBot: true,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        
        _typingAnimationController.stop();
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Error analyzing image: $e');
      
      if (mounted) {
        setState(() {
          messages.add(ChatMessage(
            text: "I had trouble analyzing the image, but I can still help! Please describe what you see in your trading chart and I'll provide professional analysis.",
            isBot: true,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        
        _typingAnimationController.stop();
        _scrollToBottom();
      }
    }
  }

  Future<void> _getQuantisAIResponse(String userMessage) async {
    setState(() {
      _isTyping = true;
    });
    
    _typingAnimationController.repeat();
    
    try {
      String response;
      if (_isConnected) {
        response = await _callQuantisAIAPI(userMessage);
      } else {
        // Fallback to local responses
        response = _generateFallbackResponse(userMessage);
        await Future.delayed(const Duration(seconds: 2)); // Simulate thinking time
      }
      
      if (mounted) {
        setState(() {
          messages.add(ChatMessage(
            text: response,
            isBot: true,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        
        _typingAnimationController.stop();
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Error getting Quantis AI response: $e');
      
      if (mounted) {
        setState(() {
          messages.add(ChatMessage(
            text: "I apologize, but I'm having trouble connecting to my AI services right now. Let me try to help with a general trading response:\n\n${_generateFallbackResponse(userMessage)}",
            isBot: true,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        
        _typingAnimationController.stop();
        _scrollToBottom();
      }
    }
  }

  Future<String> _callQuantisAIAPI(String userMessage) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openAIApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '''You are Quantis AI, a professional forex and cryptocurrency trading assistant. You provide expert analysis, trading strategies, and market insights. Be helpful, accurate, and professional. 

IMPORTANT: When providing market prices or analysis, always include a disclaimer that prices are indicative and users should check live market data. Do not provide specific current prices unless you clearly state they are examples or historical references.

Always include practical trading advice and risk management tips. Use bullet points and clear formatting when appropriate. Keep responses concise but informative. Never mention OpenAI or ChatGPT - you are Quantis AI.

For price requests, focus on technical levels, trends, and analysis rather than exact current prices.'''
          },
          {
            'role': 'user',
            'content': userMessage
          }
        ],
        'max_tokens': 600,
        'temperature': 0.7,
        'presence_penalty': 0.1,
        'frequency_penalty': 0.1,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'].toString().trim();
      
      print('✅ Quantis AI Response: ${content.substring(0, min(100, content.length))}...');
      return content;
    } else {
      print('❌ Quantis AI API Error: ${response.statusCode} - ${response.body}');
      throw Exception('Quantis AI API Error: ${response.statusCode}');
    }
  }

  String _generateFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('price') || message.contains('current') || message.contains('eur/usd') || message.contains('eurusd')) {
      return "**EUR/USD Market Analysis** 📊\n\n⚠️ **Disclaimer**: Please check live market data for current prices. This is technical analysis only.\n\n• **Technical Outlook**: Consolidation phase\n• **Key Resistance**: 1.0920-1.0950 area\n• **Key Support**: 1.0800-1.0820 zone\n• **Trend**: Sideways with bullish bias\n• **RSI**: Neutral territory (45-55)\n\n**Trading Strategy:**\n• Buy near support with tight stops\n• Sell at resistance levels\n• Wait for breakout confirmation\n\n💡 **Tip**: Always use live charts and current market data for trading decisions!";
    } else if (message.contains('bitcoin') || message.contains('btc')) {
      return "**Bitcoin Technical Analysis** ₿\n\n⚠️ **Disclaimer**: Crypto prices are highly volatile. Check live data before trading.\n\n• **Market Status**: High volatility asset\n• **Key Levels**: Major psychological levels (round numbers)\n• **Trend Analysis**: Use multiple timeframes\n• **Volume**: Monitor for confirmation\n• **Correlation**: Often inverse to USD strength\n\n**BTC Trading Tips:**\n• Use wider stop losses (3-5%)\n• Monitor weekend gaps\n• Watch whale wallet movements\n• Consider regulatory news impact\n\n⚠️ **High Risk**: Only trade with money you can afford to lose!";
    } else if (message.contains('strategy') || message.contains('trading')) {
      return "**Professional Trading Strategies** 🎯\n\n**1. Trend Following**\n• Identify the major trend (daily/weekly charts)\n• Use moving average crossovers\n• Enter on pullbacks in trend direction\n\n**2. Support/Resistance Trading**\n• Mark key horizontal levels\n• Buy at support, sell at resistance\n• Wait for confirmation signals\n\n**3. Breakout Strategy**\n• Identify consolidation patterns\n• Set pending orders above/below key levels\n• Use volume confirmation\n\n**4. News Trading**\n• Focus on high-impact events\n• Wait for initial volatility to settle\n• Trade the continuation move\n\n💡 **Golden Rule**: Always use proper risk management - never risk more than 1-2% per trade!";
    } else {
      return "**Quantis AI Trading Assistant** 💼\n\nI can help you with:\n\n• **Technical Analysis**: Chart patterns, indicators, key levels\n• **Market Analysis**: Trend identification, support/resistance\n• **Risk Management**: Position sizing, stop loss strategies\n• **Trading Psychology**: Emotional control, discipline\n• **Strategy Development**: Entry/exit rules, backtesting\n• **News Impact**: Economic events, market reactions\n\n🎯 **Ask me about:**\n- Specific currency pairs\n- Trading strategies\n- Technical indicators\n- Risk management\n- Market sentiment\n\n💡 **Tip**: Be specific in your questions for better assistance!\n\n⚠️ **Disclaimer**: All analysis is for educational purposes. Always verify with live market data and use proper risk management.";
    }
  }

  void _clearChat() {
    setState(() {
      messages.clear();
      messages.add(
        ChatMessage(
          text: "Hello! I'm your **Quantis Trading AI Assistant**! 🚀\n\nI can help you with:\n• Real-time market analysis\n• Advanced trading strategies\n• Currency pair insights\n• Technical analysis\n• Risk management\n• Economic news impact\n\nAsk me anything about trading and I'll give you professional insights!",
          isBot: true,
          timestamp: DateTime.now(),
        ),
      );
    });
    _checkAPIConnection();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.imagePath,
  });
}