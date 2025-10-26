import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // ĐÃ CÓ, KHÔNG CẦN INSTALL
import '../utils/constants.dart';

class ApiService {
  // ======== NGƯỜI DÙNG ========

  /// Đăng ký tài khoản
  static Future<http.Response> register(
      String email, String password, String confirmPassword) async {
    final url = '$baseUrl/api/nguoi-dung/dang-ky/';
    debugPrint('API POST: $url'); // Chỉ in khi debug

    return await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "confirm_password": confirmPassword,
      }),
    );
  }

  /// Xác thực OTP
  static Future<http.Response> verifyOtp(String email, String otp) async {
    final url = '$baseUrl/api/nguoi-dung/xac-thuc-otp/';
    debugPrint('API POST: $url');

    return await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );
  }

  /// Đăng nhập
  static Future<http.Response> login(String email, String password) async {
    final url = '$baseUrl/api/nguoi-dung/dang-nhap/';
    debugPrint('API POST: $url');

    return await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
  }

  /// Làm mới token
  static Future<http.Response> refreshToken(String refreshToken) async {
    final url = '$baseUrl/api/nguoi-dung/refresh/';
    debugPrint('API POST: $url');

    return await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refreshToken}),
    );
  }

  /// Gửi ảnh để phân tích  
  static Future<http.Response> analyzeImage(File imageFile, String token) async {
    final url = '$baseUrl/api/phan-tich-anh/phan-tich/';
    debugPrint('API POST: $url | File: ${imageFile.path.split('/').last}');

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      filename: imageFile.path.split('/').last,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('API Response: ${response.statusCode}');
    if (response.statusCode >= 400) {
      debugPrint('Error Body: ${response.body}');
    }

    return response;
  }

  // ======== LỊCH SỬ ========

  /// Lấy lịch sử phân tích
  static Future<http.Response> getHistory(String token) async {
    final url = '$baseUrl/api/lich-su/';
    debugPrint('API GET: $url');

    return await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
  }

  /// Xoá 1 mục lịch sử
  static Future<http.Response> deleteHistory(int id, String token) async {
    final url = '$baseUrl/api/lich-su/xoa/$id/';
    debugPrint('API DELETE: $url');

    return await http.delete(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
  }

  /// Đổi mật khẩu
  static Future<http.Response> changePassword(
      String oldPassword, String newPassword, String confirmPassword, String token) async {
    final url = '$baseUrl/api/nguoi-dung/doi-mat-khau/';
    debugPrint('API POST: $url');

    return await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "old_password": oldPassword,
        "new_password": newPassword,
        "confirm_new_password": confirmPassword,
      }),
    );
  }
}