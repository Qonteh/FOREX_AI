import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> messages = [
    ChatMessage(
      text: "Hello! I'm your AI Trading Assistant. How can I help you today?",
      isBot: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
    ChatMessage(
      text: "You can ask me about:\n• Market analysis\n• Trading strategies\n• Currency pairs\n• Technical indicators\n• Risk management",
      isBot: true,
      timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
    ),
  ];

  final List<String> quickQuestions = [
    "What's the EUR/USD outlook?",
    "Best trading strategy today?",
    "How to use RSI indicator?",
    "Market sentiment analysis",
    "Risk management tips",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryPurple,
          ),
          onPressed: () {
            // Go back to Dashboard using GoRouter
            context.go('/dashboard');
          },
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppColors.primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Trading Assistant',
                  style: TextStyle(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: AppColors.primaryNavy,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryPurple),
            onPressed: () {
              _clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (messages.isEmpty) _buildWelcomeScreen(),
          if (messages.isNotEmpty) _buildQuickQuestions(),
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppColors.primaryPurple,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'AI Trading Assistant',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about trading!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
          Text(
            'Quick Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryPurple),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        quickQuestions[index],
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 12,
                        ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppColors.primaryPurple,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isBot 
                    ? AppColors.primaryPurple.withOpacity(0.1)
                    : AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isBot ? AppColors.primaryNavy : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isBot 
                          ? AppColors.textSecondary 
                          : Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!message.isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primaryNavy,
                size: 16,
              ),
            ),
          ],
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
            color: AppColors.mediumGray.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.mediumGray),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask me about trading...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _sendMessage(text.trim());
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_messageController.text.trim().isNotEmpty) {
                _sendMessage(_messageController.text.trim());
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    setState(() {
      messages.add(ChatMessage(
        text: text,
        isBot: false,
        timestamp: DateTime.now(),
      ));
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // Simulate bot response
    Future.delayed(const Duration(seconds: 1), () {
      _simulateBotResponse(text);
    });
  }

  void _simulateBotResponse(String userMessage) {
    String botResponse = _generateBotResponse(userMessage);
    
    setState(() {
      messages.add(ChatMessage(
        text: botResponse,
        isBot: true,
        timestamp: DateTime.now(),
      ));
    });
    
    _scrollToBottom();
  }

  String _generateBotResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('eur/usd') || message.contains('eurusd')) {
      return "EUR/USD Analysis:\n\n• Current trend: Bullish\n• Key resistance: 1.0920\n• Key support: 1.0800\n• RSI: 68 (neutral to overbought)\n• Recommendation: Look for buying opportunities on dips to 1.0820-1.0840 range.";
    } else if (message.contains('strategy') || message.contains('trading')) {
      return "Here are some effective trading strategies:\n\n1. **Trend Following**: Trade in the direction of the main trend\n2. **Support/Resistance**: Buy at support, sell at resistance\n3. **Breakout Trading**: Trade when price breaks key levels\n4. **Risk Management**: Never risk more than 2% per trade\n\nWhich strategy would you like me to explain in detail?";
    } else if (message.contains('rsi')) {
      return "RSI (Relative Strength Index) Guide:\n\n• **Above 70**: Overbought (consider selling)\n• **Below 30**: Oversold (consider buying)\n• **50 Line**: Neutral momentum\n• **Divergence**: Price vs RSI moving in opposite directions\n\nBest used with other indicators for confirmation!";
    } else if (message.contains('risk')) {
      return "Risk Management Tips:\n\n• **Position Size**: Never risk more than 1-2% per trade\n• **Stop Loss**: Always set before entering trade\n• **Risk/Reward**: Aim for 1:2 or better ratio\n• **Diversification**: Don't put all eggs in one basket\n• **Emotional Control**: Stick to your plan\n\nRemember: Protect your capital first!";
    } else if (message.contains('sentiment') || message.contains('market')) {
      return "Current Market Sentiment:\n\n• **Overall**: Cautiously optimistic\n• **USD**: Strong due to Fed policy\n• **EUR**: Weakening on ECB concerns\n• **Risk Appetite**: Medium\n• **Volatility**: Expected to increase\n\nKey events to watch: Central bank meetings, economic data releases.";
    } else {
      return "I understand you're asking about trading. I can help with:\n\n• Technical analysis\n• Currency pair insights\n• Trading strategies\n• Risk management\n• Market sentiment\n• Economic indicators\n\nCould you be more specific about what you'd like to know?";
    }
  }

  void _clearChat() {
    setState(() {
      messages.clear();
      messages.addAll([
        ChatMessage(
          text: "Hello! I'm your AI Trading Assistant. How can I help you today?",
          isBot: true,
          timestamp: DateTime.now(),
        ),
      ]);
    });
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
  });
}