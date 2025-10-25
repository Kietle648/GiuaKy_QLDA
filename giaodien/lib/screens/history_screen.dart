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
  List<dynamic> _history = [];
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
        setState(() {
          _history = jsonDecode(response.body);  // Giả sử backend trả list JSON
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
        _fetchHistory();  // Refresh list
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
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Phân Tích')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return ListTile(
                  title: Text(item['date'] ?? 'Ngày không xác định'),  // Giả sử fields từ backend
                  subtitle: Text(item['result'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteItem(item['id']),
                  ),
                );
              },
            ),
    );
  }
}