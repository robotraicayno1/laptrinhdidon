import 'dart:convert';
import 'package:clothesapp/core/constants/api_constants.dart';
import 'package:clothesapp/models/product.dart';
import 'package:http/http.dart' as http;

class ProductService {
  final String baseUrl = ApiConstants.productsSubRoute;

  Future<List<Product>> getProducts({
    String category = 'All',
    bool isFeatured = false,
    bool isBestSeller = false,
    String search = '',
    double? minPrice,
    double? maxPrice,
    String? gender,
  }) async {
    try {
      String query = "?category=$category";
      if (isFeatured) query += "&isFeatured=true";
      if (isBestSeller) query += "&isBestSeller=true";
      if (search.isNotEmpty) query += "&search=$search";
      if (minPrice != null) query += "&minPrice=$minPrice";
      if (maxPrice != null) query += "&maxPrice=$maxPrice";
      if (gender != null && gender != 'All') query += "&gender=$gender";

      final response = await http.get(Uri.parse('$baseUrl$query'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Product> products = body
            .map((dynamic item) => Product.fromJson(item))
            .toList();
        return products;
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      // print(e.toString());
      return [];
    }
  }

  Future<bool> createProduct(Product product, String token) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'isFeatured': product.isFeatured,
          'isBestSeller': product.isBestSeller,
          'gender': product.gender,
          'variants': product.variants.map((v) => v.toJson()).toList(),
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      // print(e);
      return false;
    }
  }

  Future<bool> deleteProduct(String id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Product>> getInventory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inventory'),
        headers: {'x-auth-token': token},
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load inventory');
      }
    } catch (e) {
      // print(e.toString());
      return [];
    }
  }

  Future<bool> updateProduct(Product product, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${product.id}'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'isFeatured': product.isFeatured,
          'isBestSeller': product.isBestSeller,
          'gender': product.gender,
          'variants': product.variants.map((v) => v.toJson()).toList(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      // print(e);
      return false;
    }
  }

  Future<List<Product>> getRecommendations(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recommendations/$productId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      // print(e.toString());
      return [];
    }
  }
}
