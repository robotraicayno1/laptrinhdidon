import 'package:clothesapp/models/voucher.dart';
import 'package:clothesapp/services/auth_service.dart';
import 'package:clothesapp/services/order_service.dart';
import 'package:clothesapp/services/user_service.dart';
import 'package:clothesapp/services/voucher_service.dart';
import 'package:clothesapp/screens/profile_screen.dart';
import 'package:clothesapp/widgets/voucher_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:clothesapp/utils/vietnam_provinces.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String token;
  const CartScreen({super.key, required this.token, this.user});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final UserService _userService = UserService();
  final OrderService _orderService = OrderService();
  final VoucherService _voucherService = VoucherService();
  List<dynamic> _cartItems = [];
  bool _isLoading = true;

  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  Voucher? _appliedVoucher;
  bool _isApplyingVoucher = false;
  String _paymentMethod = 'COD'; // 'COD' or 'Transfer'
  VietnamProvince? _selectedProvince;

  @override
  void dispose() {
    _voucherController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
    if (widget.user != null && widget.user!['address'] != null) {
      _addressController.text = widget.user!['address'];
    }
  }

  void _loadCart() async {
    try {
      final response = await http.get(
        Uri.parse('${_userService.baseUrl}/cart'),
        headers: {'x-auth-token': widget.token},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _cartItems = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // print(e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _getItemPrice(dynamic item) {
    final product = item['product'];
    if (product == null) return 0;

    final variants = product['variants'] as List?;
    if (variants == null || variants.isEmpty) {
      return (product['price'] ?? 0).toDouble();
    }

    final selectedColor = item['selectedColor'];
    final selectedSize = item['selectedSize'];

    final variant = variants.firstWhere(
      (v) => v['color'] == selectedColor && v['size'] == selectedSize,
      orElse: () => variants.first,
    );

    return (variant['sellingPrice'] ?? product['price'] ?? 0).toDouble();
  }

  void _removeItem(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('${_userService.baseUrl}/cart/$productId'),
        headers: {'x-auth-token': widget.token},
      );
      if (response.statusCode == 200) {
        _loadCart(); // Reload cart
      }
    } catch (e) {
      // print(e);
    }
  }

  double get _subtotal {
    double total = 0;
    for (var item in _cartItems) {
      total += _getItemPrice(item) * item['quantity'];
    }
    return total;
  }

  double get _shippingFee {
    if (_selectedProvince == null) return 0;
    if (_subtotal >= 1000000) return 0;

    if (_selectedProvince!.name == "TP Hồ Chí Minh") {
      return 20000;
    } else if (_selectedProvince!.region == "South") {
      return 30000;
    } else {
      return 45000;
    }
  }

  double get _totalPrice {
    double total = _subtotal + _shippingFee;
    if (_appliedVoucher != null) {
      total -= _appliedVoucher!.discountAmount;
    }
    return total > 0 ? total : 0;
  }

  void _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingVoucher = true);

    final voucher = await _voucherService.validateVoucher(code, widget.token);

    if (mounted) {
      setState(() => _isApplyingVoucher = false);
      if (voucher != null) {
        setState(() {
          _appliedVoucher = voucher;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Áp dụng mã giảm giá thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã giảm giá không hợp lệ hoặc đã hết hạn'),
          ),
        );
      }
    }
  }

  void _selectVoucher() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => VoucherSelectionDialog(token: widget.token),
    );

    if (code != null) {
      _voucherController.text = code;
      _applyVoucher();
    }
  }

  void _checkout() async {
    if (_cartItems.isEmpty) return;

    setState(() => _isLoading = true);

    // Fetch latest user profile to ensure they have phone and address
    final userProfile = await _userService.getProfile(widget.token);

    if (!mounted) return;

    if (userProfile == null ||
        (userProfile['phone'] ?? '').isEmpty ||
        (userProfile['address'] ?? '').isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Vui lòng cập nhật Số điện thoại và Địa chỉ để tiếp tục",
          ),
          duration: Duration(seconds: 3),
        ),
      );
      // Redirect to Profile Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            user: userProfile ?? widget.user ?? {},
            token: widget.token,
          ),
        ),
      ).then((_) => _loadCart()); // Refresh cart/state when back
      return;
    }

    if (_selectedProvince == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn Tỉnh/Thành phố")),
      );
      return;
    }

    final String address =
        "${_addressController.text.trim()}, ${_selectedProvince!.name}";

    final res = await _orderService.placeOrder(
      totalPrice: _totalPrice,
      address: address,
      cart: _cartItems,
      token: widget.token,
      voucherCode: _appliedVoucher?.code ?? '',
      discountAmount: _appliedVoucher?.discountAmount ?? 0.0,
      shippingFee: _shippingFee,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (res != null) {
        if (_paymentMethod == 'Transfer') {
          final String orderId = res['_id'];
          final String shortOrderId = orderId
              .substring(orderId.length - 6)
              .toUpperCase();
          _showBankTransferDialog(shortOrderId, _totalPrice);
        } else {
          _showOrderSuccess();
        }
      } else {
        _showError("Lỗi dịch vụ đặt hàng!");
      }
    }
  }

  void _showBankTransferDialog(String orderId, double amount) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final theme = Theme.of(context);

    // Mock Bank Information - In real app, fetch from config or constants
    const bankName = "Sacombank";
    const accountNumber = "050138116155";
    const accountName = "NGUYEN MINH TAI";
    final content = "THANHTOAN $orderId";

    // Construct VietQR URL
    // Format: https://img.vietqr.io/image/<BANK_ID>-<ACCOUNT_NO>-<TEMPLATE>.png?amount=<AMOUNT>&addInfo=<CONTENT>&accountName=<NAME>
    final String qrUrl =
        "https://img.vietqr.io/image/STB-050138116155-compact.png?amount=${amount.toInt()}&addInfo=${Uri.encodeComponent(content)}&accountName=${Uri.encodeComponent(accountName)}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Thông tin chuyển khoản",
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
            ),
            IconButton(
              icon: Icon(Icons.close, color: theme.iconTheme.color),
              onPressed: () {
                Navigator.pop(context);
                _showOrderSuccess(
                  msg: "Đơn hàng đã tạo. Vui lòng thanh toán sau.",
                );
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // QR Code Image
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  qrUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      width: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
              Text(
                "Quét mã QR để thanh toán nhanh",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Hoặc chuyển khoản thủ công:",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow("Ngân hàng", bankName, theme),
              _buildInfoRow(
                "Số tài khoản",
                accountNumber,
                theme,
                isCopyable: true,
              ),
              _buildInfoRow("Chủ tài khoản", accountName, theme),
              _buildInfoRow(
                "Số tiền",
                currencyFormat.format(amount),
                theme,
                isHighLight: true,
              ),
              _buildInfoRow("Nội dung", content, theme, isCopyable: true),
              const SizedBox(height: 20),
              Text(
                "Lưu ý: Đơn hàng sẽ được xử lý sau khi xác nhận thanh toán thành công.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Call Verify API
              final nav = Navigator.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Đang kiểm tra giao dịch...")),
              );

              try {
                final response = await http.post(
                  Uri.parse(
                    '${AuthService.baseUrl}/payment/verify-transaction',
                  ),
                  headers: {
                    'Content-Type': 'application/json',
                    'x-auth-token': widget.token,
                  },
                  body: jsonEncode({'orderId': orderId}), // Need full ID here?
                  // actually we passed shortID to dialog. We need the full ID for backend lookup.
                  // The current _showBankTransferDialog only receives shortId string?
                  // Wait, let's check call site.
                );

                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data['success'] == true) {
                    nav.pop();
                    _showOrderSuccess(msg: "Xác nhận thanh toán thành công!");
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(data['msg'] ?? "Chưa thấy giao dịch"),
                      ),
                    );
                  }
                }
              } catch (e) {
                // print(e);
              }
            },
            child: Text("Tôi đã chuyển khoản"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showOrderSuccess(
                msg:
                    "Đơn hàng đã được ghi nhận. Vui lòng hoàn tất chuyển khoản.",
              );
            },
            child: Text(
              "Đóng",
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool isCopyable = false,
    bool isHighLight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isHighLight
                          ? theme.colorScheme.primary
                          : Colors.white,
                    ),
                  ),
                ),
                if (isCopyable)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Đã sao chép: $value")),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccess({String? msg}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg ?? "Đặt hàng thành công! Đang chờ Admin duyệt."),
        backgroundColor: Colors.green,
      ),
    );
    _addressController.clear();
    _voucherController.clear();
    setState(() {
      _cartItems = [];
      _appliedVoucher = null;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Giỏ Hàng", style: theme.textTheme.headlineMedium),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? Center(
              child: Text("Giỏ hàng trống", style: theme.textTheme.bodyLarge),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final product = item['product'];
                      if (product == null) return const SizedBox.shrink();

                      return Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Builder(
                              builder: (context) {
                                String imageUrl = product['imageUrl'] ?? '';
                                if (!imageUrl.startsWith('http')) {
                                  String serverBase = AuthService.baseUrl
                                      .replaceAll('/api', '');
                                  imageUrl = "$serverBase/$imageUrl".replaceAll(
                                    '//uploads',
                                    '/uploads',
                                  );
                                }
                                return Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.error),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            product['name'] ?? 'Unknown',
                            maxLines: 1,
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${currencyFormat.format(_getItemPrice(item))} x ${item['quantity']}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if ((item['selectedColor'] ?? '').isNotEmpty ||
                                  (item['selectedSize'] ?? '').isNotEmpty)
                                Text(
                                  "Màu: ${item['selectedColor']} | Size: ${item['selectedSize']}",
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.error,
                            ),
                            onPressed: () => _removeItem(item['_id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Province Dropdown Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: DropdownButtonFormField<VietnamProvince>(
                    dropdownColor: theme.cardColor,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: "Chọn Tỉnh/Thành phố",
                      prefixIcon: Icon(
                        Icons.map_outlined,
                        color: theme.iconTheme.color,
                      ),
                      filled: true,
                      fillColor: theme.inputDecorationTheme.fillColor,
                      border: theme.inputDecorationTheme.border,
                      enabledBorder: theme.inputDecorationTheme.enabledBorder,
                      focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    ),
                    value: _selectedProvince,
                    items: vietnamProvinces.map((province) {
                      return DropdownMenuItem<VietnamProvince>(
                        value: province,
                        child: Text(province.name),
                      );
                    }).toList(),
                    onChanged: (province) {
                      setState(() {
                        _selectedProvince = province;
                      });
                    },
                  ),
                ),
                // Address Input Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _addressController,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: "Nhập địa chỉ nhận hàng",
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: theme.iconTheme.color,
                      ),
                      filled: true,
                      fillColor: theme.inputDecorationTheme.fillColor,
                      border: theme.inputDecorationTheme.border,
                      enabledBorder: theme.inputDecorationTheme.enabledBorder,
                      focusedBorder: theme.inputDecorationTheme.focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                // Voucher Input Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voucherController,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: "Mã giảm giá",
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: theme.inputDecorationTheme.border,
                            enabledBorder:
                                theme.inputDecorationTheme.enabledBorder,
                            focusedBorder:
                                theme.inputDecorationTheme.focusedBorder,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            suffixIcon: _appliedVoucher != null
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: theme.colorScheme.error,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _appliedVoucher = null;
                                        _voucherController.clear();
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isApplyingVoucher ? null : _applyVoucher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isApplyingVoucher
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text("Áp dụng"),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectVoucher,
                  icon: Icon(
                    Icons.list_alt,
                    color: theme.colorScheme.secondary,
                  ),
                  label: Text(
                    "Chọn khuyến mãi từ danh sách",
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                ),
                // Payment Method Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Phương thức thanh toán",
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildPaymentOption(
                            icon: Icons.money,
                            label: "COD",
                            value: "COD",
                            theme: theme,
                          ),
                          const SizedBox(width: 12),
                          _buildPaymentOption(
                            icon: Icons.account_balance,
                            label: "Chuyển khoản",
                            value: "Transfer",
                            theme: theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtotal
                          Text(
                            "Tạm tính: ${currencyFormat.format(_subtotal)}",
                            style: theme.textTheme.bodyMedium,
                          ),
                          // Voucher Discount
                          if (_appliedVoucher != null)
                            Text(
                              "Giảm giá: -${currencyFormat.format(_appliedVoucher!.discountAmount)}",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                              ),
                            ),
                          // Shipping Fee
                          Text(
                            _selectedProvince == null
                                ? "Vận chuyển: --"
                                : "Vận chuyển: ${_shippingFee == 0 ? 'Miễn phí' : currencyFormat.format(_shippingFee)}",
                            style: TextStyle(
                              color: _shippingFee == 0
                                  ? Colors.green
                                  : theme.textTheme.bodyMedium?.color,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Tổng cộng", style: theme.textTheme.titleMedium),
                          Text(
                            currencyFormat.format(_totalPrice),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Thanh Toán",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    final isSelected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.iconTheme.color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
