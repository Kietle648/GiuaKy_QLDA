// screens/history_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
      if (token == null) return;

      final response = await ApiService.getHistory(token);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        setState(() {
          _history = jsonList.map((item) => item as Map<String, dynamic>).toList();
        });
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

  Future<void> _deleteItem(int id) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
      if (token == null) return;

      final response = await ApiService.deleteHistory(id, token);
      if (response.statusCode == 200) {
        _fetchHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.black, // Khung màu đen cho tiêu đề như bottom bar
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Lịch Sử Phân Tích',
            style: TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
                  ? const Center(child: Text('Chưa có lịch sử', style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            title: Text(item['date'] ?? 'Ngày không xác định', style: const TextStyle(color: Colors.white)),
                            subtitle: Text(item['result'] ?? '', style: const TextStyle(color: Colors.grey)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: const Text('Bạn có chắc muốn xóa mục này?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                                      TextButton(onPressed: () {
                                        Navigator.pop(context);
                                        _deleteItem(item['id']);
                                      }, child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}