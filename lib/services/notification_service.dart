import 'dart:convert';
import 'package:clothesapp/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = ApiConstants.notificationsSubRoute;

  Future<List<Map<String, dynamic>>> getNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      // print('Get Notifications Error: $e');
      return [];
    }
  }

  Future<bool> markAsRead(String token, String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      // print('Mark Read Error: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead(String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/read-all'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      // print('Mark All Read Error: $e');
      return false;
    }
  }
}
