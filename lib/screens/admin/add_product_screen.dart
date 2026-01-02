import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/services/product_service.dart';
import 'package:clothesapp/services/upload_service.dart';
import 'package:clothesapp/widgets/custom_button.dart';
import 'package:clothesapp/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProductScreen extends StatefulWidget {
  final String token;
  final Product? product;
  const AddProductScreen({super.key, required this.token, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();

  final List<Map<String, String>> categoryOptions = [
    {'id': 'Men', 'name': 'Nam'},
    {'id': 'Women', 'name': 'Nữ'},
    {'id': 'Pants', 'name': 'Quần'},
    {'id': 'Shirts', 'name': 'Áo'},
    {'id': 'Accessories', 'name': 'Phụ kiện'},
  ];
  String selectedCategory = 'Men';

  final List<Map<String, String>> genderOptions = [
    {'id': 'Men', 'name': 'Nam'},
    {'id': 'Women', 'name': 'Nữ'},
    {'id': 'Unisex', 'name': 'Unisex (Cả hai)'},
    {'id': 'Kids', 'name': 'Trẻ em'},
  ];
  String selectedGender = 'Unisex';
  final List<String> availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  List<String> selectedSizes = [];
  bool isFeatured = false;
  bool isBestSeller = false;
  List<ProductVariant> variants = [];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descController.text = widget.product!.description;
      _imageController.text = widget.product!.imageUrl;
      selectedCategory = widget.product!.category;
      selectedGender = widget.product!.gender;
      isFeatured = widget.product!.isFeatured;
      isBestSeller = widget.product!.isBestSeller;
      variants = List.from(widget.product!.variants);
    }
  }

  final ProductService _productService = ProductService();
  final UploadService _uploadService = UploadService();
  bool _isLoading = false;
  File? _pickedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
        _imageController.text = image.path; // Just for display or fallback
      });
    }
  }

  void _submit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Vui lòng nhập tên sản phẩm")));
      return;
    }

    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng thêm ít nhất một biến thể")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String finalImageUrl = _imageController.text;

    if (_pickedImage != null) {
      String? uploadUrl = await _uploadService.uploadImage(_pickedImage!);
      if (!mounted) return;
      if (uploadUrl != null) {
        finalImageUrl = uploadUrl;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload ảnh thất bại, dùng Link mặc định")),
        );
      }
    }

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text,
      description: _descController.text,
      price: 0, // No longer used globally, but keep for model compat
      imageUrl: finalImageUrl.isEmpty
          ? 'https://via.placeholder.com/150'
          : finalImageUrl,
      category: selectedCategory,
      isFeatured: isFeatured,
      isBestSeller: isBestSeller,
      gender: selectedGender,
      variants: variants,
    );

    bool success;
    if (widget.product == null) {
      success = await _productService.createProduct(product, widget.token);
    } else {
      success = await _productService.updateProduct(product, widget.token);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? "Thêm sản phẩm thành công!"
                : "Cập nhật sản phẩm thành công!",
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi xử lý sản phẩm")));
    }
  }

  void _showAddVariantDialog() {
    String color = "";
    String size = "M";
    int stock = 0;
    double pPrice = 0;
    double sPrice = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Thêm Biến Thể"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Màu sắc (vd: Đỏ)"),
                onChanged: (v) => color = v,
              ),
              DropdownButtonFormField<String>(
                value: size,
                items: availableSizes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => size = v!,
                decoration: InputDecoration(labelText: "Size"),
              ),
              TextField(
                decoration: InputDecoration(labelText: "Số lượng tồn kho"),
                keyboardType: TextInputType.number,
                onChanged: (v) => stock = int.tryParse(v) ?? 0,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Giá nhập (VNĐ)"),
                keyboardType: TextInputType.number,
                onChanged: (v) => pPrice = double.tryParse(v) ?? 0,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Giá bán (VNĐ)"),
                keyboardType: TextInputType.number,
                onChanged: (v) => sPrice = double.tryParse(v) ?? 0,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              if (color.isNotEmpty) {
                setState(() {
                  variants.add(
                    ProductVariant(
                      color: color,
                      size: size,
                      stock: stock,
                      purchasePrice: pPrice,
                      sellingPrice: sPrice,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: Text("Thêm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? "Thêm Sản Phẩm" : "Sửa Sản Phẩm"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _nameController,
              hintText: "Tên sản phẩm",
              prefixIcon: Icons.label,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _descController,
              hintText: "Mô tả sản phẩm",
              prefixIcon: Icons.description,
            ),
            SizedBox(height: 16),
            SizedBox(height: 16),

            // Image Picker UI
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_pickedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey,
                          ),
                          Text(
                            "Chọn ảnh từ thư viện",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Hoặc nhập Link ảnh (Optional):",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            CustomTextField(
              controller: _imageController,
              hintText: "Link ảnh (URL)",
              prefixIcon: Icons.link,
            ),
            SizedBox(height: 20),

            Text("Danh mục:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              items: categoryOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e['id'],
                      child: Text(e['name']!),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),
            SizedBox(height: 16),

            Text("Giới tính:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedGender,
              isExpanded: true,
              items: genderOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e['id'],
                      child: Text(e['name']!),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedGender = v!),
            ),
            SizedBox(height: 16),

            Text(
              "Biến thể (Variants):",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: variants.length,
              itemBuilder: (context, index) {
                final v = variants[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text("${v.color} - ${v.size}"),
                    subtitle: Text(
                      "Kho: ${v.stock} | Nhập: ${v.purchasePrice} | Bán: ${v.sellingPrice}",
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => variants.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
            CustomButton(
              text: "Thêm Biến Thể",
              onPressed: _showAddVariantDialog,
            ),
            SizedBox(height: 24),

            SwitchListTile(
              title: Text("Nổi bật (Featured)"),
              value: isFeatured,
              onChanged: (v) => setState(() => isFeatured = v),
            ),
            SwitchListTile(
              title: Text("Bán chạy (Best Seller)"),
              value: isBestSeller,
              onChanged: (v) => setState(() => isBestSeller = v),
            ),

            SizedBox(height: 30),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : CustomButton(text: "Lưu Sản Phẩm", onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
