import 'dart:async';
import 'package:clothesapp/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String token;
  final String userId;
  final String userName;
  const AdminChatDetailScreen({
    super.key,
    required this.token,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  Timer? _timer;

  // Theme Colors
  final Color _kPrimaryColor = const Color(0xFFD4AF37); // Gold
  final Color _kBackgroundColor = const Color(0xFF050505); // Deep Black
  final Color _kSurfaceColor = const Color(0xFF1A1A1A); // Dark Grey
  final Color _kUserBubbleColor = const Color(
    0xFF2A2A2A,
  ); // Lighter Grey for User

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _fetchMessages(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchMessages() async {
    final data = await _chatService.getChatHistory(widget.userId, widget.token);
    if (mounted) {
      setState(() {
        _messages = data;
      });
      // Scroll to bottom optionally, or only on new message
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final success = await _chatService.sendMessage(
      widget.userId,
      text,
      widget.token,
    );
    if (success) {
      _messageController.clear();
      _fetchMessages();
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Chat: ${widget.userName}",
          style: TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kSurfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _kPrimaryColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                // Admin is sender if message is headed TO the user
                bool isAdmin = msg.receiverId == widget.userId;
                return _buildMessageBubble(msg, isAdmin);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isAdmin) {
    final timeStr = DateFormat(
      'HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(msg.createdAt));

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isAdmin
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender Label
            Text(
              isAdmin ? "Admin (Bạn)" : widget.userName,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isAdmin ? _kPrimaryColor : _kUserBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isAdmin ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isAdmin
                      ? Radius.zero
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isAdmin ? Colors.black : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        color: isAdmin ? Colors.black54 : Colors.white54,
                        fontSize: 10,
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurfaceColor,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Nhập tin nhắn...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _kBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: _kPrimaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
