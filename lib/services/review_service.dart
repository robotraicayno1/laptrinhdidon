import 'dart:convert';
import 'package:clothesapp/core/constants/api_constants.dart';
import 'package:clothesapp/models/review.dart';
import 'package:http/http.dart' as http;

class ReviewService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<List<Review>> getReviews(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/reviews'),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Review> reviews = body
            .map((dynamic item) => Review.fromJson(item))
            .toList();
        return reviews;
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      // print('Error loading reviews: $e');
      return [];
    }
  }

  Future<bool> addReview(
    String productId,
    int rating,
    String comment,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/reviews'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({'rating': rating, 'comment': comment}),
      );
      return response.statusCode == 201;
    } catch (e) {
      // print('Error adding review: $e');
      return false;
    }
  }

  Future<bool> deleteReview(String reviewId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      // print('Error deleting review: $e');
      return false;
    }
  }
}
