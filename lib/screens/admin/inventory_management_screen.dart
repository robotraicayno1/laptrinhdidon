import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InventoryManagementScreen extends StatefulWidget {
  final String token;
  const InventoryManagementScreen({super.key, required this.token});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    final products = await _productService.getInventory(widget.token);
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  void _editVariant(Product product, int variantIndex) {
    final variant = product.variants[variantIndex];
    final stockController = TextEditingController(
      text: variant.stock.toString(),
    );
    final purchaseController = TextEditingController(
      text: variant.purchasePrice.toString(),
    );
    final sellingController = TextEditingController(
      text: variant.sellingPrice.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Cập nhật Biến thể\n${product.name} (${variant.color} - ${variant.size})",
          style: TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              decoration: InputDecoration(labelText: "Số lượng tồn kho"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: purchaseController,
              decoration: InputDecoration(labelText: "Giá nhập (VNĐ)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: sellingController,
              decoration: InputDecoration(labelText: "Giá bán (VNĐ)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedVariant = ProductVariant(
                color: variant.color,
                size: variant.size,
                stock: int.tryParse(stockController.text) ?? 0,
                purchasePrice: double.tryParse(purchaseController.text) ?? 0,
                sellingPrice: double.tryParse(sellingController.text) ?? 0,
              );

              final updatedVariants = List<ProductVariant>.from(
                product.variants,
              );
              updatedVariants[variantIndex] = updatedVariant;

              final updatedProduct = Product(
                id: product.id,
                name: product.name,
                description: product.description,
                price: product.price,
                imageUrl: product.imageUrl,
                category: product.category,
                isFeatured: product.isFeatured,
                isBestSeller: product.isBestSeller,
                gender: product.gender,
                variants: updatedVariants,
                averageRating: product.averageRating,
                reviewCount: product.reviewCount,
              );

              final success = await _productService.updateProduct(
                updatedProduct,
                widget.token,
              );
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cập nhật kho thành công!")),
                );
              }
              Navigator.pop(context);
              _loadInventory();
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Quản Lý Kho Hàng",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadInventory, icon: Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.fullImageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${product.variants.length} biến thể"),
                    children: product.variants.asMap().entries.map((entry) {
                      final vIndex = entry.key;
                      final v = entry.value;
                      return ListTile(
                        title: Text("${v.color} - Size ${v.size}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tồn kho: ${v.stock}",
                              style: TextStyle(
                                color: v.stock < 5 ? Colors.red : Colors.green,
                              ),
                            ),
                            Text(
                              "Nhập: ${currencyFormat.format(v.purchasePrice)} | Bán: ${currencyFormat.format(v.sellingPrice)}",
                            ),
                            if (v.sellingPrice > v.purchasePrice)
                              Text(
                                "Lợi nhuận: ${currencyFormat.format(v.sellingPrice - v.purchasePrice)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(Icons.edit_note, color: Colors.blue),
                        onTap: () => _editVariant(product, vIndex),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
