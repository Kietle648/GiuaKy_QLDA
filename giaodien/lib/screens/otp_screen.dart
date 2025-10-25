// screens/otp_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  OtpScreenState createState() => OtpScreenState();
}

class OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  late String _email; // Nhận từ arguments

  @override
  void initState() {
    super.initState();
    _email = ''; // Sẽ nhận từ ModalRoute
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ModalRoute.of(context)!.settings.arguments as String;
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.verifyOtp(_email, _otpController.text);
      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xác thực OTP thành công')),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['detail'] ?? 'Lỗi xác thực')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
      appBar: AppBar(title: const Text('Xác Thực OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Nhập OTP gửi đến $_email'),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text('Xác Thực'),
                  ),
          ],
        ),
      ),
    );
  }
}
