import 'package:flutter/material.dart';
import 'package:money_manage/theme/app_theme.dart';




/// Simple chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, this.isUser = true}) : time = DateTime.now();
}




/// Chatbot screen for Money - FinWise (basic tips only, English)
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);




  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}




class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isBotTyping = false;
  final ScrollController _scrollController = ScrollController();




  // Basic suggested questions (English)
  final List<String> _suggestedQuestions = [
    "How to manage my monthly budget?",
    "Tips to save money effectively?",
    "How to reduce unnecessary expenses?",
    "How to track my spending habits?"
  ];


  // Visible suggestions (will be updated based on last user input)
  List<String> _visibleSuggestions = [];


  // Simple keyword mapping for suggestions
  final Map<String, List<String>> _suggestionKeywords = {
    "How to manage my monthly budget?": ['budget', 'monthly', 'manage'],
    "Tips to save money effectively?": ['save', 'saving', 'savings'],
    "How to reduce unnecessary expenses?": ['reduce', 'cut', 'unnecessary', 'expenses'],
    "How to track my spending habits?": ['track', 'spend', 'spending', 'habits']
  };


  // Related suggestion alternatives: when user already asked one suggestion, show different but related suggestions
  final Map<String, List<String>> _relatedSuggestions = {
    "How to manage my monthly budget?": [
      "What's an easy monthly budget template?",
      "How to split income across bills and savings?"
    ],
    "Tips to save money effectively?": [
      "Small habits that increase savings over time",
      "How to set up automatic savings?"
    ],
    "How to reduce unnecessary expenses?": [
      "Quick ways to cut monthly costs",
      "How to evaluate subscriptions and memberships?"
    ],
    "How to track my spending habits?": [
      "Best ways to record daily expenses",
      "How to categorize spending for analysis?"
    ]
  };






  @override
  void initState() {
    super.initState();
    // start with all suggestions visible
    _visibleSuggestions = List.from(_suggestedQuestions);


    // Add welcome message with a short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      _addBotMessage(
        "Hello — I'm FinWise Assistant. I provide simple tips about budgeting, saving, and tracking your spending. Ask me anything!",
      );
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
    Future.delayed(const Duration(milliseconds: 250), () {
      setState(() {
        _messages.insert(0, ChatMessage(text: "Try one of these:", isUser: false));
        _scrollToBottom();
      });
    });
  }


  /// Update visible suggestions using keywords from the last user message.
  /// If the last user message exactly matches one of the suggestions, show related
  /// alternatives (so we don't repeat the exact same suggestion). If no keyword
  /// match is found, fall back to showing all suggestions.
  void _updateSuggestions(String lastUserText) {
    final text = lastUserText.toLowerCase();
    if (text.trim().isEmpty) {
      setState(() {
        _visibleSuggestions = List.from(_suggestedQuestions);
      });
      return;
    }


    // Find direct suggestion matches by keywords
    final matches = <String>[];
    for (final suggestion in _suggestedQuestions) {
      final keys = _suggestionKeywords[suggestion] ?? [];
      if (keys.any((k) => text.contains(k))) {
        matches.add(suggestion);
      }
    }


    // If user exactly sent one of the suggestions, exclude it and show related alternatives
    final exactMatch = _suggestedQuestions.firstWhere(
      (s) => s.toLowerCase() == text.trim().toLowerCase(),
      orElse: () => '',
    );


    final result = <String>[];


    if (exactMatch.isNotEmpty) {
      // Get related alternatives for the exact match, if available
      final related = _relatedSuggestions[exactMatch] ?? [];
      result.addAll(related);


      // Also add other suggestions that are keyword matches (but avoid the exact one)
      for (final m in matches) {
        if (m.toLowerCase() != exactMatch.toLowerCase()) result.add(m);
      }
    } else {
      // Normal behavior: use keyword matches; if none, show all
      if (matches.isNotEmpty) {
        result.addAll(matches);
      } else {
        result.addAll(_suggestedQuestions);
      }
    }


    // Remove duplicates and ensure we don't show the exact user question
    final visible = result
        .where((s) => s.toLowerCase() != text.trim().toLowerCase())
        .toList();


    setState(() {
      _visibleSuggestions = visible.isNotEmpty ? visible : List.from(_suggestedQuestions);
    });
  }


  /// Mock AI response. ONLY provides basic advice (budgeting, saving, spending tips).
  /// Replace with real API later if needed.
  Future<String> _getBotResponse(String prompt) async {
    // increase delay to simulate longer thinking time
    await Future.delayed(const Duration(seconds: 2));
    final p = prompt.toLowerCase();




    if (p.contains('hello') || p.contains('hi')) {
      return "Hi! I'm FinWise Assistant — I can share quick tips on budgeting, saving, and tracking expenses.";
    }




    if (p.contains('budget') || p.contains('manage my monthly') || p.contains('monthly budget')) {
      return """Simple monthly budgeting (starter):
1. Use the 50/30/20 rule: 50% needs, 30% wants, 20% savings.
2. List recurring bills first (rent, utilities).
3. Set a fixed amount for variable categories (food, transport).
4. Review weekly and adjust.
Would you like a quick template?""";
    }




    if (p.contains('save') || p.contains('saving') || p.contains('tips to save')) {
      return """Quick saving tips:
• Automate transfers to savings each payday.
• Wait 24 hours before big purchases to avoid impulse buys.
• Cancel unused subscriptions.
• Pack lunch, brew coffee at home sometimes.
Small changes add up — try one for a month.""";
    }




    if (p.contains('reduce') || p.contains('unnecessary') || p.contains('cut expenses')) {
      return """How to cut unnecessary spending:
1. Identify top 3 spending categories.
2. Set a small % reduction goal (e.g., -10%).
3. Replace paid habits with low-cost alternatives.
4. Track results and keep what works.""";
    }




    if (p.contains('track') || p.contains('track my spending') || p.contains('spending habits')) {
      return """Tracking basics:
• Record each expense (small or large).
• Categorize immediately (food, transport, bills).
• Review weekly summary to spot trends.
• Set simple goals (e.g., limit dining out to X/month).""";
    }




    // If user asks for tips but doesn't match keywords
    if (p.contains('tips') || p.contains('advice') || p.contains('help')) {
      return "I can help with budgeting, saving strategies, expense trimming, and tracking habits. Which one do you want to start with?";
    }




    // Default fallback for other inputs
    return "I give short, practical tips on budgeting, saving, and tracking expenses. Try: \"How to manage my monthly budget?\" or \"Tips to save money effectively?\"";
  }




  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isSending || _isBotTyping) return; // prevent spamming while bot is typing




    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isSending = true;
      _isBotTyping = true;
    });


    // update suggestions based on this user message
    _updateSuggestions(text);


    _controller.clear();
    _scrollToBottom();




    final botReply = await _getBotResponse(text);




    if (!mounted) return;
    setState(() {
      _messages.insert(0, ChatMessage(text: botReply, isUser: false));
      _isSending = false;
      _isBotTyping = false;
    });




    _scrollToBottom();
  }




  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // animate to top because list is reversed
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
    final textColor = isDarkMode ? Colors.white : Colors.black87;




    return Scaffold(
      appBar: AppBar(
        title: const Text('FinWise Assistant'),
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
                            Icons.savings,
                            size: 64,
                            color: primaryColor.withOpacity(0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to FinWise Assistant',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask for simple tips on budgeting, saving, and tracking expenses.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                            textAlign: TextAlign.center,
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




            // Typing indicator (shows when bot is preparing reply)
            if (_isBotTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: primaryColor,
                      child: const Icon(Icons.savings, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const Text("FinWise is typing"),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 28,
                            height: 14,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(3, (i) {
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 300 + i * 100),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: theme.hintColor,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),




            // Suggestions bar - always visible and responsive to last user message
            _buildSuggestedQuestions(theme, primaryColor),
            _buildInputField(theme, isDarkMode, primaryColor),
          ],
        ),
      ),
    );
  }




  Widget _buildSuggestedQuestions(ThemeData theme, Color primaryColor) {
    // Always show the suggestions bar. Use _visibleSuggestions computed from the last user input.
    final items = _visibleSuggestions;


    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ActionChip(
              label: Text(
                items[index],
                style: TextStyle(color: theme.primaryColor),
              ),
              onPressed: () {
                // put suggestion into input field and send immediately
                _controller.text = items[index];
                _sendMessage(items[index]);
              },
              backgroundColor: theme.primaryColor.withOpacity(0.08),
              side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
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
        : (theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200]);




    final textColor = isUser ? Colors.white : theme.textTheme.bodyLarge?.color;




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
                child: const Icon(Icons.savings, color: Colors.white, size: 20),
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
                  const SizedBox(height: 6),
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




  Widget _buildInputField(ThemeData theme, bool isDarkMode, Color primaryColor) {
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
                  hintText: 'Ask about budgeting, saving, or tracking...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800]?.withOpacity(0.5) : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                enabled: !_isSending && !_isBotTyping,
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: (_isSending || _isBotTyping) ? null : () => _sendMessage(_controller.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
