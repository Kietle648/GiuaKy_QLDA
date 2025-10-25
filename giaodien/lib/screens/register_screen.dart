// screens/register_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.register(
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text,
      );
      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pushNamed(context, '/otp', arguments: _emailController.text);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi OTP')));
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['detail'] ?? 'Lỗi đăng ký')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật Khẩu')),
            TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Xác Nhận Mật Khẩu')),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _register, child: const Text('Đăng Ký')),
          ],
        ),
      ),
    );
  }
}