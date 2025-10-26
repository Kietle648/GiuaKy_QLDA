import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  File? _image;
  bool _isLoading = false;

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    final scaffold = ScaffoldMessenger.of(context);

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    if (!mounted) return;
    setState(() {
      _image = File(pickedFile.path);
      _isLoading = true;
    });

    if (token == null) {
      scaffold.showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
      return;
    }

    try {
      final response = await ApiService.analyzeImage(_image!, token);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imagePath = data['duong_dan_anh_danh_dau'] as String?;

        if (imagePath == null || imagePath.isEmpty) {
          scaffold.showSnackBar(const SnackBar(content: Text('Không có ảnh kết quả')));
          return;
        }

        // Tạo URL với cache buster MẠNH + timestamp microsecond
        final uniqueUrl =
            '$baseUrl/media/$imagePath?v=${DateTime.now().microsecondsSinceEpoch}';

        _showResultDialog(uniqueUrl);
      } else {
        scaffold.showSnackBar(SnackBar(content: Text('Lỗi: ${response.body}')));
      }
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showResultDialog(String imageUrl) {
    // Đóng dialog cũ nếu có
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Kết quả phân tích"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Image.network(
            imageUrl,
            key: ValueKey(imageUrl), // Ép rebuild hoàn toàn
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const Text('Không tải được ảnh'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showResultDialog(imageUrl); // Thử lại
                    },
                    child: const Text("Thử lại"),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_image != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Chụp Ảnh'),
                onPressed: () => _pickAndAnalyzeImage(ImageSource.camera),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Chọn Từ Thư Viện'),
                onPressed: () => _pickAndAnalyzeImage(ImageSource.gallery),
              ),
            ],
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}