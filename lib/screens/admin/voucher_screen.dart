import 'package:clothesapp/models/voucher.dart';
import 'package:clothesapp/services/voucher_service.dart';
import 'package:clothesapp/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VoucherScreen extends StatefulWidget {
  final String token;
  const VoucherScreen({super.key, required this.token});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final VoucherService _voucherService = VoucherService();
  late Future<List<Voucher>> _vouchers;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  void _loadVouchers() {
    setState(() {
      _vouchers = _voucherService.getVouchers();
    });
  }

  void _showAddVoucherDialog() {
    final codeController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Tạo Voucher Mới"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: codeController,
              hintText: "Mã Voucher (VD: SALE50)",
              prefixIcon: Icons.qr_code,
            ),
            SizedBox(height: 10),
            CustomTextField(
              controller: amountController,
              hintText: "Số tiền giảm (VD: 50000)",
              prefixIcon: Icons.money,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ListTile(
              title: Text(
                "Hết hạn: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) selectedDate = picked;
              },
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
              if (codeController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                final success = await _voucherService.createVoucher(
                  codeController.text,
                  double.tryParse(amountController.text) ?? 0,
                  selectedDate,
                  widget.token, // PASS TOKEN HERE
                );
                Navigator.pop(context);
                if (success) _loadVouchers();
              }
            },
            child: Text("Tạo"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản Lý Voucher"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVoucherDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<List<Voucher>>(
        future: _vouchers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Chưa có voucher nào"));
          }

          return ListView.separated(
            padding: EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => SizedBox(height: 10),
            itemBuilder: (context, index) {
              final voucher = snapshot.data![index];
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.orange, size: 30),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voucher.code,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "Giảm: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(voucher.discountAmount)}",
                          ),
                          Text(
                            "Hết hạn: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: voucher.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        voucher.isActive ? "Đang chạy" : "Ngưng",
                        style: TextStyle(
                          color: voucher.isActive ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey),
                      onPressed: () async {
                        final success = await _voucherService.deleteVoucher(
                          voucher.id,
                          widget.token,
                        );
                        if (!mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Xóa voucher thành công!"),
                            ),
                          );
                          _loadVouchers();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
