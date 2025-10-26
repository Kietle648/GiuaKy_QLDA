import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  File? _image;
  List<AnalysisResult> _results = [];
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

    try {
      if (token == null) {
        if (!mounted) return;
        scaffold.showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập')),
        );
        return;
      }

      final response = await ApiService.analyzeImage(_image!, token);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_image != null) Image.file(_image!, height: 200),
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
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
          if (_results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return Card(
                    color: Colors.grey[900],
                    child: ListTile(
                      title: Text(result.objectName),
                      subtitle: Text('Confidence: ${result.confidence}'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}