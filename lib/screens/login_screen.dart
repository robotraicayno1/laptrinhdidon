import 'package:clothesapp/screens/forgot_password_screen.dart';
import 'package:clothesapp/screens/home_screen.dart';
import 'package:clothesapp/screens/signup_screen.dart';
import 'package:clothesapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ email và mật khẩu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await _authService.login(email, password);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công!')));

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              user: res['data']['user'],
              token: res['data']['token'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // backgroundColor: theme.scaffoldBackgroundColor, // Handled by theme
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                        "Chào mừng\ntrở lại.",
                        style: theme.textTheme.displayLarge,
                      )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  Text(
                    "Đăng nhập để cập nhật những\nbộ sưu tập mới nhất của chúng tôi.",
                    style: theme.textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
              const SizedBox(height: 56),

              Text(
                "ĐỊA CHỈ EMAIL",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: "example@email.com",
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              Text(
                "MẬT KHẨU",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: "••••••••",
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                ),
              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Quên mật khẩu?",
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.primary, // Gold
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 40),

              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _login,
                      // Style handled by theme
                      child: const Text("Đăng nhập"),
                    ).animate().fadeIn(delay: 800.ms).scale(),

              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(child: Divider(color: theme.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Hoặc tiếp tục với",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(child: Divider(color: theme.dividerColor)),
                ],
              ).animate().fadeIn(delay: 1000.ms),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(Icons.g_mobiledata, Colors.red, theme),
                  const SizedBox(width: 24),
                  _buildSocialIcon(Icons.apple, Colors.white, theme),
                  const SizedBox(width: 24),
                  _buildSocialIcon(
                    Icons.facebook,
                    const Color(0xFF1877F2),
                    theme,
                  ),
                ],
              ).animate().fadeIn(delay: 1200.ms).moveY(begin: 20, end: 0),

              const Spacer(flex: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Chưa có tài khoản? ",
                    style: theme.textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Đăng ký ngay",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1400.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
