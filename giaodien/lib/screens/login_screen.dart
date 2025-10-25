import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

 Future<void> _login() async {
  setState(() => _isLoading = true);

  try {
    final response = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    final statusCode = response.statusCode;
    final body = response.body;

    // Dùng try-catch cho decode JSON an toàn
    dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      data = null;
    }

    if (statusCode == 200 && data != null && data['access'] != null) {
      if (!mounted) return;

      final provider = Provider.of<AuthProvider>(context, listen: false);
      await provider.login(
        data['access'],
        data['refresh'],
        data['user']?['email'] ?? '', // tránh lỗi null
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thành công')),
      );
    } else {
      final message = data != null
          ? (data['detail'] ?? 'Email hoặc mật khẩu không đúng')
          : 'Không thể kết nối đến máy chủ';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Đăng Nhập'),
                  ),
          ],
        ),
      ),
    );
  }
}
