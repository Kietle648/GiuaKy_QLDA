import 'dart:convert';  // Thêm import này để sử dụng jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';  // Thêm import này để sử dụng ApiService

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  String? _email;

  String? get accessToken => _accessToken;
  String? get email => _email;

  Future<void> login(String access, String refresh, String email) async {
    _accessToken = access;
    _refreshToken = refresh;
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
    await prefs.setString('email', email);
    notifyListeners();
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    return _accessToken != null;
  }

 
  Future<void> refresh() async {
    if (_refreshToken == null) return;
    final response = await ApiService.refreshToken(_refreshToken!);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await login(data['access'], _refreshToken!, _email!);
    }
  }
}