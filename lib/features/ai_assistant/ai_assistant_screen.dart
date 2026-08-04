import 'package:flutter/material.dart';
import '../../core/services/commerce_api_service.dart';
import '../../core/theme/app_colors.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({
    super.key,
    this.apiService = const CommerceApiService(),
  });

  final CommerceApiService apiService;

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _quickSuggestions = const [
    '📚 Gợi ý sách phát triển bản thân',
    '📖 Tóm tắt cuốn Đắc Nhân Tâm',
    '🎧 Sách nói kinh doanh hay nhất',
    '💡 Cách chọn sách đọc hiệu quả',
  ];

  @override
  void initState() {
    super.initState();
    // Tin nhắn chào mừng ban đầu từ AI
    _messages.add(
      ChatMessage(
        text:
            'Xin chào! Tôi là Trợ lý AI Waka 🤖✨\n\n'
            'Tôi có thể giúp bạn gợi ý sách hay, tóm tắt nội dung cuốn sách yêu thích hoặc giải đáp thắc mắc về đọc sách. Hãy đặt câu hỏi cho tôi nhé!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    if (customText == null) {
      _textController.clear();
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    // Gọi API từ CommerceApiService
    final reply = await widget.apiService.askAiAssistant(text);

    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = false;
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: WakaColors.navBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: WakaColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: WakaColors.accent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: WakaColors.accent,
                    size: 20,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: WakaColors.navBackground,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Trợ lý AI Waka',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Trực tuyến • Đăng bởi Gemini AI',
                  style: TextStyle(
                    color: WakaColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: WakaColors.divider,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageItem(_messages[index]);
                } else {
                  return _buildLoadingBubble();
                }
              },
            ),
          ),

          // Gợi ý câu hỏi nhanh (nếu tin nhắn ít)
          if (_messages.length <= 2 && !_isLoading) _buildQuickSuggestions(),

          // Thanh nhập tin nhắn
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isUser = message.isUser;
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 10, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: WakaColors.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: WakaColors.accent,
                size: 18,
              ),
            ),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? WakaColors.accent
                    : WakaColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: WakaColors.divider, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.black : WakaColors.text,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isUser
                          ? Colors.black.withValues(alpha: 0.6)
                          : WakaColors.mutedText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: WakaColors.elevatedSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10, top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: WakaColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: WakaColors.accent,
              size: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: WakaColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: WakaColors.divider, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(WakaColors.accent),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI đang suy nghĩ...',
                  style: TextStyle(
                    color: WakaColors.mutedText,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickSuggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _quickSuggestions[index];
          return ActionChip(
            label: Text(
              suggestion,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            backgroundColor: WakaColors.surface,
            side: const BorderSide(color: WakaColors.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => _sendMessage(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: WakaColors.navBackground,
        border: Border(
          top: BorderSide(color: WakaColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: WakaColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: WakaColors.divider),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: WakaColors.text, fontSize: 15),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Hỏi AI về sách Waka...',
                    hintStyle: TextStyle(color: WakaColors.mutedText, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _isLoading ? WakaColors.elevatedSoft : WakaColors.accent,
              shape: const CircleBorder(),
              elevation: _isLoading ? 0 : 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isLoading ? null : () => _sendMessage(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
