import 'package:clothesapp/screens/chat_screen.dart';
import 'package:clothesapp/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;
  const ProfileScreen({super.key, required this.user, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _fetchUserData();
  }

  void _fetchUserData() async {
    final user = await _userService.getProfile(widget.token);
    if (mounted && user != null) {
      setState(() {
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _addressController.text = user['address'] ?? '';
        _isLoadingUserData = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingUserData = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    setState(() => _isLoading = true);

    Map<String, dynamic> updateData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    if (_passwordController.text.isNotEmpty) {
      updateData['password'] = _passwordController.text;
    }

    final result = await _userService.updateProfile(updateData, widget.token);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật hồ sơ thành công!")),
      );
      _passwordController.clear();
      // Update local data with result
      setState(() {
        _nameController.text = result['name'] ?? '';
        _phoneController.text = result['phone'] ?? '';
        _addressController.text = result['address'] ?? '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thất bại. Vui lòng thử lại.")),
      );
    }
  }

  void _makeCall() async {
    final Uri url = Uri.parse('tel:0966209249');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể thực hiện cuộc gọi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Hồ Sơ Của Tôi", style: theme.textTheme.headlineMedium),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary, // Gold
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user['email'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildTextField(
                    "Họ và Tên",
                    _nameController,
                    Icons.person_outline,
                    theme,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Số điện thoại",
                    _phoneController,
                    Icons.phone_android_outlined,
                    theme,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Địa chỉ",
                    _addressController,
                    Icons.location_on_outlined,
                    theme,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Đổi mật khẩu (Để trống nếu không đổi)",
                    _passwordController,
                    Icons.lock_outline,
                    theme,
                    isPassword: true,
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                            )
                          : const Text(
                              "LƯU THAY ĐỔI",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 16),
                  Text(
                    "Hỗ trợ khách hàng",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _makeCall,
                          icon: const Icon(Icons.call, color: Colors.green),
                          label: Text(
                            "Gọi",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  user: widget.user,
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.commentDots,
                            color: Colors.orange,
                          ),
                          label: Text(
                            "Chat",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    ThemeData theme, {
    bool isPassword = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      maxLines: maxLines,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
        prefixIcon: Icon(icon, color: theme.iconTheme.color),
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
    );
  }
}
