import 'package:flutter/material.dart';
import 'package:money_manage/theme/app_theme.dart';

// Simple chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, this.isUser = true}) : time = DateTime.now();
}

// Chatbot screen
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();
  final List<String> _suggestedQuestions = [
    "4-week learning plan for beginners?",
    "How to choose the right board and sail?",
    "Waterstart technique guide",
    "Safety check before going to the sea"
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message with a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage("Hello! I am WindSurf Coach AI. How can I help you today?");
      _showSuggestedQuestions();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: false));
      _scrollToBottom();
    });
  }

  void _showSuggestedQuestions() {
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _messages.insert(0, ChatMessage(
          text: "You can ask me about:",
          isUser: false
        ));
        _scrollToBottom();
      });
    });
  }

  // Mock call to AI - replace with real API
  Future<String> _getBotResponse(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simple responses based on keywords
    prompt = prompt.toLowerCase();
    
    if (prompt.contains('hello') || prompt.contains('hi')) {
      return 'Hello! I am WindSurf Coach AI. I can help you with windsurfing topics, from basic to advanced.';
    }
    if (prompt.contains('plan') || prompt.contains('learn') || prompt.contains('beginner')) {
      return '''4-Week Beginner's Plan:
      
Week 1: Getting to Know the Equipment
- Practice balancing on the board
- Get familiar with wind and sail
- Time: 3-4 sessions, 1-2 hours each

Week 2: Basic Techniques
- How to hold and control the sail
- Basic movements
- Practice simple turns

Week 3: Skill Improvement
- Quick turn techniques
- Speed adjustment
- Handling different situations

Week 4: Advanced Practice
- Speed sailing practice
- Basic jumping techniques
- Surfing safety''';
    }
    if (prompt.contains('board') || prompt.contains('sail') || prompt.contains('equipment')) {
      return '''To choose the right equipment, I need to know:
- What is your weight?
- Have you ever windsurfed before?
- Wind conditions where you usually surf?

General guidelines:
- Beginners should use a larger board (180-220L) for better balance
- Sail size should be between 3.5m² - 5.0m² depending on wind conditions''';
    }
    if (prompt.contains('waterstart') || prompt.contains('technique') || prompt.contains('surfing')) {
      return '''Basic Waterstart Technique Guide:

1. Preparation:
- Stand in a balanced position on the board
- Hold the sail lines firmly with both hands
- Keep your knees slightly bent

2. Execution:
- Pull the sail up slowly with your back hand
- Push up strongly with your legs to stand
- Maintain balance and point the board with the wind

Important Notes:
- Always wear a helmet
- Wear a life jacket
- Check equipment before going out to sea''';
    }
    if (prompt.contains('safety') || prompt.contains('check')) {
      return '''Pre-Surfing Safety Checklist:

1. Weather Check:
- Appropriate wind speed
- Wind direction and tides
- Weather forecast

2. Equipment:
- Life jacket is worn
- Safety leash attached to the board
- Sail is not torn, lines are not worn out

3. Personal:
- Proper warm-up done
- Wearing all protective gear
- No alcohol before surfing''';
    }
    
    // Default response
    return 'I am WindSurf Coach AI. I can help you with windsurfing topics, techniques, equipment, and safety. What specific assistance do you need?';
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isSending = true;
    });
    
    _controller.clear();
    _scrollToBottom();

    final botReply = await _getBotResponse(text);

    setState(() {
      _messages.insert(0, ChatMessage(text: botReply, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.grey[100];
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WindSurf Coach AI'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: backgroundColor,
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sailing,
                            size: 64,
                            color: primaryColor.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to WindSurf Coach AI',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask me anything about windsurfing!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message, theme, primaryColor);
                      },
                    ),
            ),
            _buildSuggestedQuestions(theme, primaryColor),
            _buildInputField(theme, isDarkMode, primaryColor, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestions(ThemeData theme, Color primaryColor) {
    if (_messages.length > 3) return const SizedBox.shrink();
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedQuestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(
                _suggestedQuestions[index],
                style: TextStyle(color: theme.primaryColor),
              ),
              onPressed: () => _sendMessage(_suggestedQuestions[index]),
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              side: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme, Color primaryColor) {
    final isUser = message.isUser;
    final bgColor = isUser
        ? primaryColor
        : (theme.brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200]);

    final textColor = isUser
        ? Colors.white
        : theme.textTheme.bodyLarge?.color;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: primaryColor,
                child: const Icon(Icons.sailing, color: Colors.white, size: 20),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: (isUser ? Colors.white70 : theme.hintColor),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: theme.hintColor.withOpacity(0.2),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(ThemeData theme, bool isDarkMode, Color primaryColor, Color? cardColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask a question about windsurfing...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.grey[800]?.withOpacity(0.5)
                      : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending
                    ? null
                    : () => _sendMessage(_controller.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}