import 'package:clothesapp/screens/admin/admin_chat_detail_screen.dart';
import 'package:clothesapp/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminChatListScreen extends StatefulWidget {
  final String token;
  const AdminChatListScreen({super.key, required this.token});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  // Theme Colors
  final Color _kPrimaryColor = const Color(0xFFD4AF37); // Gold
  final Color _kBackgroundColor = const Color(0xFF050505); // Deep Black
  final Color _kSurfaceColor = const Color(0xFF1A1A1A); // Dark Grey
  final Color _kSubTextColor = Colors.white54;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  void _fetchConversations() async {
    setState(() => _isLoading = true);
    final data = await _chatService.getAdminConversations(widget.token);
    if (mounted) {
      setState(() {
        _conversations = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Hội Thoại Khách Hàng",
          style: TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kSurfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _kPrimaryColor),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _kPrimaryColor))
          : _conversations.isEmpty
          ? Center(
              child: Text(
                "Chưa có hội thoại nào",
                style: TextStyle(color: _kSubTextColor),
              ),
            )
          : RefreshIndicator(
              color: _kPrimaryColor,
              backgroundColor: _kSurfaceColor,
              onRefresh: () async => _fetchConversations(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _conversations.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.white10,
                  indent: 70, // Align with text start
                ),
                itemBuilder: (context, index) {
                  final conv = _conversations[index];
                  final lastTime = DateTime.fromMillisecondsSinceEpoch(
                    conv['lastTime'],
                  );
                  final timeStr = DateFormat('HH:mm dd/MM').format(lastTime);

                  return ListTile(
                    tileColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kPrimaryColor, width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: _kSurfaceColor,
                        child: Text(
                          (conv['name'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _kPrimaryColor,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      conv['name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        conv['lastMessage'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _kSubTextColor),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(fontSize: 12, color: _kSubTextColor),
                        ),
                        const SizedBox(height: 4),
                        // Optional: Unread badge if valid
                        // Icon(Icons.arrow_forward_ios, size: 12, color: _kPrimaryColor),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminChatDetailScreen(
                            token: widget.token,
                            userId: conv['userId'],
                            userName: conv['name'],
                          ),
                        ),
                      ).then((_) => _fetchConversations());
                    },
                  );
                },
              ),
            ),
    );
  }
}
