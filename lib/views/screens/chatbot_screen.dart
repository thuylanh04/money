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
    "Kế hoạch học 4 tuần cho người mới?",
    "Chọn ván và buồm phù hợp?",
    "Hướng dẫn kỹ thuật waterstart",
    "Kiểm tra an toàn trước khi ra biển"
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message with a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage("Xin chào! Tôi là WindSurf Coach AI. Tôi có thể giúp gì cho bạn hôm nay?");
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
          text: "Bạn có thể hỏi tôi về:",
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
    
    if (prompt.contains('xin chào') || prompt.contains('hello') || prompt.contains('hi')) {
      return 'Xin chào! Tôi là WindSurf Coach AI. Tôi có thể giúp bạn với các vấn đề về lướt ván buồm, từ cơ bản đến nâng cao.';
    }
    if (prompt.contains('kế hoạch') || prompt.contains('học') || prompt.contains('bắt đầu')) {
      return '''Kế hoạch 4 tuần cho người mới bắt đầu:
      
Tuần 1: Làm quen với thiết bị
- Tập thăng bằng trên ván
- Làm quen với gió và buồm
- Thời gian: 3-4 buổi, mỗi buổi 1-2 tiếng

Tuần 2: Kỹ thuật cơ bản
- Cách cầm và điều khiển buồm
- Di chuyển cơ bản
- Tập quay đầu đơn giản

Tuần 3: Nâng cao kỹ năng
- Kỹ thuật quay nhanh
- Điều chỉnh tốc độ
- Xử lý tình huống

Tuần 4: Thực hành nâng cao
- Tập lướt với tốc độ
- Kỹ thuật nhảy cơ bản
- An toàn khi lướt sóng''';
    }
    if (prompt.contains('ván') || prompt.contains('buồm') || prompt.contains('thiết bị')) {
      return '''Để chọn thiết bị phù hợp, tôi cần biết:
- Cân nặng của bạn là bao nhiêu?
- Bạn đã từng lướt ván buồm chưa?
- Điều kiện gió nơi bạn thường lướt?

Thông thường:
- Người mới nên dùng ván to (180-220L) để dễ giữ thăng bằng
- Buồm nên chọn từ 3.5m² - 5.0m² tùy điều kiện gió''';
    }
    if (prompt.contains('waterstart') || prompt.contains('kỹ thuật') || prompt.contains('lướt')) {
      return '''Hướng dẫn kỹ thuật Waterstart cơ bản:

1. Chuẩn bị:
- Đứng ở vị trí cân bằng trên ván
- Hai tay nắm chặt dây buồm
- Đầu gối hơi khuỵu

2. Thực hiện:
- Kéo buồm lên từ từ bằng tay sau
- Dùng chân đẩy mạnh để đứng lên
- Giữ thăng bằng và hướng ván theo chiều gió

Lưu ý:
- Luôn đội mũ bảo hiểm
- Mặc áo phao
- Kiểm tra thiết bị trước khi ra khơi''';
    }
    if (prompt.contains('an toàn') || prompt.contains('kiểm tra')) {
      return '''Checklist an toàn trước khi lướt:

1. Kiểm tra thời tiết:
- Tốc độ gió phù hợp
- Hướng gió và thủy triều
- Dự báo thời tiết

2. Thiết bị:
- Áo phao đã đeo
- Dây an toàn gắn vào ván
- Buồm không rách, dây không mục

3. Bản thân:
- Đã khởi động kỹ
- Mặc đồ bảo hộ đầy đủ
- Không uống rượu bia trước khi lướt''';
    }
    
    // Default response
    return 'Tôi là WindSurf Coach AI. Tôi có thể giúp bạn với các vấn đề về lướt ván buồm, kỹ thuật, thiết bị và an toàn. Bạn cần hỗ trợ gì cụ thể?';
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
                            'Chào mừng đến với WindSurf Coach AI',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hỏi tôi bất cứ điều gì về lướt ván buồm!',
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
                  hintText: 'Nhập câu hỏi về lướt ván buồm...',
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