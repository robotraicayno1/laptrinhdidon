import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clothesapp/core/constants/api_constants.dart';

class UserService {
  final String baseUrl = ApiConstants.userSubRoute;

  Future<bool> addToCart(
    String productId,
    int quantity,
    String selectedColor,
    String selectedSize,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({
          'productId': productId,
          'quantity': quantity,
          'selectedColor': selectedColor,
          'selectedSize': selectedSize,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      // print(e);
      return false;
    }
  }

  Future<bool> toggleFavorite(String productId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({'productId': productId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      // print(e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {'x-auth-token': token},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      // print(e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      // print(e);
      return null;
    }
  }

  Future<List<dynamic>> getFavorites(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: {'x-auth-token': token},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      // print(e);
      return [];
    }
  }
}
