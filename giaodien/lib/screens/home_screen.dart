// screens/home_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart'; // Giả sử bạn có model này

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  File? _image;
  List<AnalysisResult> _results = [];
  bool _isLoading = false;

  Future<void> _pickAndAnalyzeImage() async {
    // Lấy những object phụ thuộc vào context trước khi chạy các await
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    final scaffold = ScaffoldMessenger.of(context);

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (!mounted) return;
    setState(() {
      _image = File(pickedFile.path);
      _isLoading = true;
    });

    try {
      if (token == null) {
        // kiểm tra mounted trước khi thao tác UI
        if (!mounted) return;
        scaffold.showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập')),
        );
        return;
      }

      final response = await ApiService.analyzeImage(_image!, token);

      // kiểm tra mounted ngay sau async work trước khi dùng UI
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // cập nhật state an toàn
        setState(() {
          _results = (data['results'] as List)
              .map((e) => AnalysisResult.fromJson(e))
              .toList();
        });
        scaffold.showSnackBar(
          const SnackBar(content: Text('Phân tích thành công')),
        );
      } else {
        scaffold.showSnackBar(SnackBar(content: Text('Lỗi: ${response.body}')));
      }
    } catch (e) {
      if (!mounted) return;
      scaffold.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () => Navigator.pushNamed(context, '/change-password'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Lấy trước navigator và authProvider để tránh dùng context sau await
              final navigator = Navigator.of(context);
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );

              await authProvider.logout();

              if (!mounted) return;
              navigator.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null) Image.file(_image!, height: 200),
            ElevatedButton(
              onPressed: _pickAndAnalyzeImage,
              child: const Text('Chọn và Phân Tích Ảnh'),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: CircularProgressIndicator(),
              ),
            // Nếu muốn tránh layout issues: đặt Expanded bên ngoài Column khi cần
            if (_results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return ListTile(
                      title: Text(result.objectName),
                      subtitle: Text('Confidence: ${result.confidence}'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
