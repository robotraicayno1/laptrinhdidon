import 'package:clothesapp/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrderScreen extends StatefulWidget {
  final String token;
  const AdminOrderScreen({super.key, required this.token});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
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
    final orders = await _orderService.getAllOrders(widget.token);
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  void _updateStatus(
    String orderId,
    int status, {
    String? trackingNumber,
  }) async {
    final res = await _orderService.updateOrderStatus(
      orderId,
      status,
      widget.token,
      trackingNumber: trackingNumber,
    );
    if (res['success']) {
      _loadOrders();
    }
  }

  void _showTrackingDialog(String orderId) {
    final TextEditingController trackingController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nhập mã vận đơn"),
        content: TextField(
          controller: trackingController,
          decoration: const InputDecoration(
            hintText: "VD: VN123456789",
            labelText: "Mã vận đơn (Tracking ID)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              final tid = trackingController.text.trim();
              if (tid.isNotEmpty) {
                Navigator.pop(context);
                _updateStatus(orderId, 2, trackingNumber: tid);
              }
            },
            child: const Text("Xác nhận & Giao hàng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Quản Lý Đơn Hàng',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text("Chưa có đơn hàng nào"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return OrderCard(
                  order: order,
                  onStatusUpdate: _updateStatus,
                  onShip: _showTrackingDialog,
                );
              },
            ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final Function(String, int, {String? trackingNumber}) onStatusUpdate;
  final Function(String) onShip;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
    required this.onShip,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final date = DateTime.fromMillisecondsSinceEpoch(order.orderedAt);
    final dateString = DateFormat('dd/MM/yyyy HH:mm').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Đơn: #${order.id.substring(order.id.length - 8)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateString,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo[50],
                  child: const Icon(Icons.person_outline, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        order.userEmail,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "SẢN PHẨM",
              style: TextStyle(
                letterSpacing: 1.2,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...order.products.asMap().entries.map((entry) {
              final idx = entry.key;
              final product = entry.value;
              final quantity = order.quantities.length > idx
                  ? order.quantities[idx]
                  : 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${product.name} x $quantity",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 32),
            if (order.trackingNumber.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.indigo,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Mã vận đơn: ",
                      style: TextStyle(
                        color: Colors.indigo[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.trackingNumber,
                      style: TextStyle(color: Colors.indigo[900]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(order.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Colors.red,
                  ),
                ),
                _buildActionButton(order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(int status) {
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
        text = "K.Xác định";
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(int status) {
    if (status == 0) {
      return ElevatedButton(
        onPressed: () => onShip(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text("Duyệt & Giao hàng"),
      );
    }
    if (status == 2) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text("Đang vận chuyển"),
      );
    }
    return const SizedBox.shrink();
  }
}
