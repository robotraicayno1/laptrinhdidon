import 'package:clothesapp/screens/admin/admin_chat_list_screen.dart';
import 'package:clothesapp/screens/admin/admin_order_screen.dart';
import 'package:clothesapp/screens/admin/inventory_management_screen.dart';
import 'package:clothesapp/screens/admin/manage_products_screen.dart';
import 'package:clothesapp/screens/admin/voucher_screen.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final String token;
  const AdminDashboard({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trang Quản Trị"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildAdminCard(
              context,
              icon: Icons.storefront,
              title: "Quản Lý Sản Phẩm",
              subtitle: "Xem, thêm và xóa sản phẩm",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageProductsScreen(token: token),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            _buildAdminCard(
              context,
              icon: Icons.inventory,
              title: "Quản Lý Kho Hàng",
              subtitle: "Kiểm soát tồn kho & Giá nhập/bán",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventoryManagementScreen(token: token),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            _buildAdminCard(
              context,
              icon: Icons.discount,
              title: "Quản Lý Voucher",
              subtitle: "Tạo mã giảm giá cho khách",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoucherScreen(token: token),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            _buildAdminCard(
              context,
              icon: Icons.assignment_turned_in,
              title: "Duyệt Đơn Hàng",
              subtitle: "Xử lý các đơn hàng đang chờ",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminOrderScreen(token: token),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            _buildAdminCard(
              context,
              icon: Icons.chat,
              title: "Quản Lý Chat",
              subtitle: "Hỗ trợ khách hàng trực tuyến",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminChatListScreen(token: token),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 30,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
