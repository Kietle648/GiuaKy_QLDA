// screens/change_password_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ChangePasswordScreenState createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
        }
        return;
      }

      final response = await ApiService.changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
        _confirmNewPasswordController.text,
        token,  // Thêm token nếu ApiService cần (chỉnh ApiService nếu chưa có)
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));
          Navigator.pop(context);
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['detail'] ?? 'Lỗi đổi mật khẩu')));
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
      appBar: AppBar(title: const Text('Đổi Mật Khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _oldPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật Khẩu Cũ')),
            TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật Khẩu Mới')),
            TextField(controller: _confirmNewPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Xác Nhận Mật Khẩu Mới')),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _changePassword, child: const Text('Đổi Mật Khẩu')),
          ],
        ),
      ),
    );
  }
}