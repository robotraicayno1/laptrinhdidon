import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/models/review.dart';
import 'package:clothesapp/services/product_service.dart';
import 'package:clothesapp/services/review_service.dart';
import 'package:clothesapp/services/user_service.dart';
import 'package:clothesapp/widgets/add_review_dialog.dart';
import 'package:clothesapp/widgets/review_card.dart';
import 'package:clothesapp/widgets/product_card.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String token;
  final Map<String, dynamic> user;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.token,
    required this.user,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final UserService _userService = UserService();
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService = ProductService();

  bool isFavorite = false;
  int quantity = 1;
  bool isAddingToCart = false;
  String? selectedSize;
  String? selectedColor;

  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  List<Product> _recommendations = [];
  bool _isLoadingRecommendations = true;
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _checkIsFavorite();
    _loadReviews();
    _loadRecommendations();
  }

  void _checkIsFavorite() {
    final favorites = widget.user['favorites'] as List?;
    if (favorites != null) {
      setState(() {
        isFavorite = favorites.contains(widget.product.id);
      });
    }
  }

  void _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    final reviews = await _reviewService.getReviews(widget.product.id);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    }
  }

  void _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    final recommendations = await _productService.getRecommendations(
      widget.product.id,
    );
    if (mounted) {
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    }
  }

  void _reloadProduct() async {
    final products = await _productService.getProducts();
    final updatedProduct = products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );
    if (mounted) {
      setState(() {
        _currentProduct = updatedProduct;
      });
    }
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        onSubmit: (rating, comment) async {
          final success = await _reviewService.addReview(
            widget.product.id,
            rating,
            comment,
            widget.token,
          );
          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đánh giá thành công!')),
            );
            _loadReviews();
            _reloadProduct();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lỗi khi gửi đánh giá')),
            );
          }
        },
      ),
    );
  }

  void _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _reviewService.deleteReview(
        review.id,
        widget.token,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa đánh giá')));
        _loadReviews();
        _reloadProduct();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa đánh giá này')),
        );
      }
    }
  }

  bool _hasReviewed() {
    return _reviews.any((review) => review.userId == widget.user['_id']);
  }

  void _addToCart() async {
    if (selectedColor == null || selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn màu sắc và kích thước")),
      );
      return;
    }

    setState(() => isAddingToCart = true);
    final success = await _userService.addToCart(
      widget.product.id,
      quantity,
      selectedColor!,
      selectedSize!,
      widget.token,
    );
    if (!mounted) return;
    setState(() => isAddingToCart = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã thêm vào giỏ hàng!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lỗi thêm vào giỏ hàng!")));
    }
  }

  void _toggleFavorite() async {
    setState(() => isFavorite = !isFavorite);
    await _userService.toggleFavorite(widget.product.id, widget.token);
  }

  String? _getSelectedVariantPrice() {
    if (selectedColor != null && selectedSize != null) {
      final variant = _currentProduct.variants.firstWhere(
        (v) => v.color == selectedColor && v.size == selectedSize,
        orElse: () => _currentProduct.variants.first,
      );
      return NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
      ).format(variant.sellingPrice);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${_currentProduct.id}',
                child: Image.network(
                  _currentProduct.fullImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[900],
                    child: const Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
              const SizedBox(width: 12),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentProduct.category.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary, // Gold
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentProduct.name,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      _getSelectedVariantPrice() ?? _currentProduct.priceRange,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentProduct.averageRating > 0
                                ? _currentProduct.averageRating.toStringAsFixed(
                                    1,
                                  )
                                : "N/A",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            " (${_currentProduct.reviewCount})",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text("Mô tả", style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  _currentProduct.description.isEmpty
                      ? "Không có mô tả cho sản phẩm này."
                      : _currentProduct.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                ...(_renderColorSection(theme)),
                ...(_renderSizeSection(theme)),
                const SizedBox(height: 48),
                _buildRecommendationsSection(theme),
                const Divider(height: 64),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đánh giá khách hàng',
                      style: theme.textTheme.headlineSmall,
                    ),
                    _isLoadingReviews
                        ? const SizedBox.shrink()
                        : TextButton(
                            onPressed: _hasReviewed()
                                ? null
                                : _showAddReviewDialog,
                            child: Text(
                              _hasReviewed() ? 'Đã đánh giá' : 'Viết đánh giá',
                              style: TextStyle(
                                color: _hasReviewed()
                                    ? Colors.grey
                                    : theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoadingReviews
                    ? const Center(child: CircularProgressIndicator())
                    : _reviews.isEmpty
                    ? _buildEmptyReviews(theme)
                    : Column(
                        children: _reviews
                            .map(
                              (review) => ReviewCard(
                                review: review,
                                showDeleteButton: true,
                                onDelete: () => _deleteReview(review),
                              ),
                            )
                            .toList(),
                      ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomPanel(currencyFormat, theme),
    );
  }

  List<Widget> _renderColorSection(ThemeData theme) {
    final availableColors = _currentProduct.variants
        .map((v) => v.color)
        .toSet()
        .toList();
    if (availableColors.isEmpty) return [];
    return [
      _buildSectionTitle("Màu sắc", theme),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        children: availableColors
            .map(
              (color) =>
                  _buildChoiceChip(color, selectedColor == color, theme, (s) {
                    setState(() {
                      selectedColor = s ? color : null;
                      if (selectedColor != null && selectedSize != null) {
                        final exists = _currentProduct.variants.any(
                          (v) =>
                              v.color == selectedColor &&
                              v.size == selectedSize &&
                              v.stock > 0,
                        );
                        if (!exists) selectedSize = null;
                      }
                    });
                  }),
            )
            .toList(),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _renderSizeSection(ThemeData theme) {
    final availableSizes = _currentProduct.variants
        .where((v) => selectedColor == null || v.color == selectedColor)
        .map((v) => v.size)
        .toSet()
        .toList();
    if (availableSizes.isEmpty) return [];
    return [
      _buildSectionTitle("Kích thước", theme),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        children: availableSizes
            .map(
              (size) => _buildChoiceChip(size, selectedSize == size, theme, (
                s,
              ) {
                final variant = _currentProduct.variants.firstWhere(
                  (v) =>
                      (selectedColor == null || v.color == selectedColor) &&
                      v.size == size,
                  orElse: () => _currentProduct.variants.first,
                );
                if (variant.stock > 0) {
                  setState(() => selectedSize = s ? size : null);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sản phẩm này đã hết hàng")),
                  );
                }
              }),
            )
            .toList(),
      ),
    ];
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChoiceChip(
    String label,
    bool isSelected,
    ThemeData theme,
    Function(bool) onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: theme.cardColor,
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.transparent : theme.dividerColor,
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    if (!_isLoadingRecommendations && _recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Sản phẩm tương tự", style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        _isLoadingRecommendations
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final product = _recommendations[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ProductCard(
                        product: product,
                        width: 180,
                        token: widget.token,
                        user: widget.user,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyReviews(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đánh giá nào. Hãy là người đầu tiên!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(NumberFormat currencyFormat, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    size: 20,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () =>
                      quantity > 1 ? setState(() => quantity--) : null,
                ),
                Text(
                  "$quantity",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 20, color: theme.iconTheme.color),
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: isAddingToCart ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isAddingToCart
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Thêm vào giỏ hàng",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
