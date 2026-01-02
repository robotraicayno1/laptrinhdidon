import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clothesapp/core/constants/api_constants.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final int createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] ?? 0,
    );
  }
}

class ChatService {
  final String baseUrl = ApiConstants.chatSubRoute;

  Future<List<ChatMessage>> getChatHistory(
    String otherUserId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history/$otherUserId'),
        headers: {'x-auth-token': token},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((m) => ChatMessage.fromJson(m)).toList();
      }
    } catch (e) {
      // print(e);
    }
    return [];
  }

  Future<bool> sendMessage(String receiverId, String text, String token) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({'receiverId': receiverId, 'text': text}),
      );
      return response.statusCode == 200;
    } catch (e) {
      // print(e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAdminConversations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/conversations'),
        headers: {'x-auth-token': token},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      // print(e);
    }
    return [];
  }
}
