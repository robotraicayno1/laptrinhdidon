import 'package:clothesapp/services/auth_service.dart';
import 'package:intl/intl.dart';

class ProductVariant {
  final String color;
  final String size;
  final int stock;
  final double purchasePrice;
  final double sellingPrice;

  ProductVariant({
    required this.color,
    required this.size,
    required this.stock,
    required this.purchasePrice,
    required this.sellingPrice,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      color: json['color'] ?? '',
      size: json['size'] ?? '',
      stock: json['stock'] ?? 0,
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'color': color,
    'size': size,
    'stock': stock,
    'purchasePrice': purchasePrice,
    'sellingPrice': sellingPrice,
  };
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isFeatured;
  final bool isBestSeller;
  final String gender;
  final List<ProductVariant> variants;
  final double averageRating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isFeatured,
    required this.isBestSeller,
    required this.gender,
    required this.variants,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    }

    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] != null ? parsePrice(json['price']) : 0.0,
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
      isBestSeller: json['isBestSeller'] ?? false,
      gender: json['gender'] ?? 'Unisex',
      variants:
          (json['variants'] as List?)
              ?.map((v) => ProductVariant.fromJson(v))
              .toList() ??
          [],
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }

  String get fullImageUrl {
    if (imageUrl.startsWith('http')) return imageUrl;
    String serverBase = AuthService.baseUrl.replaceAll('/api', '');
    return "$serverBase/$imageUrl".replaceAll('//uploads', '/uploads');
  }

  String get priceRange {
    if (variants.isEmpty) {
      return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(price);
    }

    final prices = variants.map((v) => v.sellingPrice).toList();
    final minPrice = prices.reduce((curr, next) => curr < next ? curr : next);
    final maxPrice = prices.reduce((curr, next) => curr > next ? curr : next);

    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    if (minPrice == maxPrice) {
      return format.format(minPrice);
    }

    return "${format.format(minPrice)} - ${format.format(maxPrice)}";
  }
}
