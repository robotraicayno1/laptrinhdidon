import 'dart:convert';
import 'package:clothesapp/core/constants/api_constants.dart';
import 'package:clothesapp/models/voucher.dart';
import 'package:http/http.dart' as http;

class VoucherService {
  final String baseUrl = ApiConstants.vouchersSubRoute;

  Future<List<Voucher>> getVouchers() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Voucher.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load vouchers");
      }
    } catch (e) {
      // print(e);
      return [];
    }
  }

  Future<bool> createVoucher(
    String code,
    double amount,
    DateTime expiry,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({
          'code': code.toUpperCase(),
          'discountAmount': amount,
          'expiryDate': expiry.toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      // print(e);
      return false;
    }
  }

  Future<bool> deleteVoucher(String id, String token) async {
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

  Future<Voucher?> validateVoucher(String code, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({'code': code.toUpperCase()}),
      );
      if (response.statusCode == 200) {
        return Voucher.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      // print(e);
      return null;
    }
  }
}
