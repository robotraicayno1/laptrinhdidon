import 'package:clothesapp/services/order_service.dart';
import 'package:clothesapp/widgets/order_review_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatefulWidget {
  final String token;
  const MyOrdersScreen({super.key, required this.token});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await _orderService.getMyOrders(widget.token);
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  void _confirmReceipt(Order order) async {
    final res = await _orderService.updateOrderStatus(
      order.id,
      3,
      widget.token,
    );
    if (res['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xác nhận đã nhận hàng thành công!")),
        );
        _loadOrders();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Lỗi xác nhận nhận hàng!")),
        );
      }
    }
  }

  void _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận hủy"),
        content: const Text("Bạn có chắc chắn muốn hủy đơn hàng này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy bỏ"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xác nhận hủy"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await _orderService.cancelOrder(order.id, widget.token);
      if (res['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã hủy đơn hàng thành công!")),
          );
          _loadOrders();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? "Lỗi khi hủy đơn hàng!")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Đơn Hàng Của Tôi", style: theme.textTheme.headlineMedium),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? Center(
              child: Text(
                "Bạn chưa có đơn hàng nào",
                style: theme.textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final date = DateTime.fromMillisecondsSinceEpoch(
                  order.orderedAt,
                );
                final dateString = DateFormat('dd/MM/yyyy HH:mm').format(date);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Mã đơn: ${order.id.substring(order.id.length - 8)}",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildStatusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateString,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        if (order.trackingNumber.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Mã vận đơn: ${order.trackingNumber}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const Divider(),
                        ...order.products.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final product = entry.value;
                          final quantity = order.quantities.length > idx
                              ? order.quantities[idx]
                              : 1;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  product.name,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  "x$quantity",
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tổng cộng:",
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currencyFormat.format(order.totalPrice),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (order.status == 0 || order.status == 1) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _cancelOrder(order),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              child: const Text("Hủy đơn hàng"),
                            ),
                          ),
                        ],
                        if (order.status == 2) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _confirmReceipt(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Đã nhận được hàng"),
                            ),
                          ),
                        ],
                        if (order.status == 3) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => OrderReviewListDialog(
                                    order: order,
                                    token: widget.token,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.rate_review_outlined,
                                color: theme.colorScheme.onSurface,
                              ),
                              label: Text(
                                "Đánh giá sản phẩm",
                                style: theme.textTheme.bodyMedium,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme.dividerColor),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(int status) {
    String text;
    Color color;
    switch (status) {
      case 0:
        text = "Chờ duyệt";
        color = Colors.orange;
        break;
      case 1:
        text = "Đã duyệt";
        color = Colors.blue;
        break;
      case 2:
        text = "Đang giao";
        color = Colors.indigo;
        break;
      case 3:
        text = "Hoàn thành";
        color = Colors.green;
        break;
      case 4:
        text = "Đã hủy";
        color = Colors.red;
        break;
      default:
        text = "Không xác định";
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
