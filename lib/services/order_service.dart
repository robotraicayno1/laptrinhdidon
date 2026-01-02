import 'dart:convert';
import 'package:clothesapp/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:clothesapp/models/product.dart';

class Order {
  final String id;
  final List<Product> products;
  final List<int> quantities;
  final List<String> selectedColors;
  final List<String> selectedSizes;
  final String address;
  final String userId;
  final String userName;
  final String userEmail;
  final int orderedAt;
  final int status;
  final double totalPrice;
  final double shippingFee;
  final String appTransId;
  final String trackingNumber;

  Order({
    required this.id,
    required this.products,
    required this.quantities,
    required this.selectedColors,
    required this.selectedSizes,
    required this.address,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.orderedAt,
    required this.status,
    required this.totalPrice,
    required this.shippingFee,
    required this.appTransId,
    required this.trackingNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      List<Product> products = [];
      List<int> quantities = [];
      List<String> selectedColors = [];
      List<String> selectedSizes = [];

      if (json['products'] != null) {
        for (var item in json['products']) {
          if (item['product'] != null) {
            products.add(Product.fromJson(item['product']));
            quantities.add(item['quantity'] ?? 1);
            selectedColors.add(item['selectedColor'] ?? '');
            selectedSizes.add(item['selectedSize'] ?? '');
          }
        }
      }

      int parseTime(dynamic value) {
        if (value is int) return value;
        if (value is String) {
          final dt = DateTime.tryParse(value);
          return dt?.millisecondsSinceEpoch ?? 0;
        }
        return 0;
      }

      return Order(
        id: json['_id'] ?? '',
        products: products,
        quantities: quantities,
        selectedColors: selectedColors,
        selectedSizes: selectedSizes,
        address: json['address'] ?? '',
        userId: json['userId'] is Map
            ? (json['userId']['_id'] ?? '')
            : (json['userId'] ?? ''),
        userName: json['userId'] is Map
            ? (json['userId']['name'] ?? 'Guest')
            : 'Guest',
        userEmail: json['userId'] is Map ? (json['userId']['email'] ?? '') : '',
        orderedAt: parseTime(json['createdAt']),
        status: json['status'] ?? 0,
        totalPrice: (json['totalPrice'] ?? 0).toDouble(),
        shippingFee: (json['shippingFee'] ?? 0).toDouble(),
        appTransId: json['appTransId'] ?? '',
        trackingNumber: json['trackingNumber'] ?? '',
      );
    } catch (e) {
      // print('Error parsing Order: $e');
      rethrow;
    }
  }
}

class OrderService {
  final String baseUrl = ApiConstants.ordersSubRoute;

  Future<Map<String, dynamic>?> placeOrder({
    required double totalPrice,
    required String address,
    required List<dynamic> cart,
    required String token,
    String voucherCode = '',
    double discountAmount = 0.0,
    double shippingFee = 0.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({
          'totalPrice': totalPrice,
          'cart': cart,
          'voucherCode': voucherCode,
          'discountAmount': discountAmount,
          'shippingFee': shippingFee,
          'address': address,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Order>> getMyOrders(String token) async {
    List<Order> orderList = [];
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-orders'),
        headers: {'x-auth-token': token},
      );
      if (response.statusCode == 200) {
        for (var item in jsonDecode(response.body)) {
          orderList.add(Order.fromJson(item));
        }
      }
    } catch (e) {
      // print(e);
    }
    return orderList;
  }

  Future<List<Order>> getAllOrders(String token) async {
    List<Order> orderList = [];
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'x-auth-token': token},
      );
      if (response.statusCode == 200) {
        for (var item in jsonDecode(response.body)) {
          orderList.add(Order.fromJson(item));
        }
      }
    } catch (e) {
      // print(e);
    }
    return orderList;
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    String id,
    int status,
    String token, {
    String? trackingNumber,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id/status'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({
          'status': status,
          if (trackingNumber != null) 'trackingNumber': trackingNumber,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': body['msg'] ?? body['error'] ?? 'Đã có lỗi xảy ra',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String id, String token) async {
    return await updateOrderStatus(id, 4, token);
  }
}
