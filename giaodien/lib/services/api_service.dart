import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  // ======== NGƯỜI DÙNG ========

  /// Đăng ký tài khoản
  static Future<http.Response> register(
      String email, String password, String confirmPassword) async {
    return await http.post(
      Uri.parse('$baseUrl/api/nguoi-dung/dang-ky/'),
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
    return await http.post(
      Uri.parse('$baseUrl/api/nguoi-dung/xac-thuc-otp/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );
  }

  /// Đăng nhập
  static Future<http.Response> login(String email, String password) async {
    return await http.post(
      Uri.parse('$baseUrl/api/nguoi-dung/dang-nhap/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
  }

  /// Làm mới token
  static Future<http.Response> refreshToken(String refreshToken) async {
    return await http.post(
      Uri.parse('$baseUrl/api/nguoi-dung/refresh/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refreshToken}),
    );
  }

  /// Gửi ảnh để phân tích
  static Future<http.Response> analyzeImage(File imageFile, String token) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/phan-tich-anh/phan-tich/'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));  // 'file' là key backend mong đợi

    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // ======== LỊCH SỬ ========

  /// Lấy lịch sử phân tích
  static Future<http.Response> getHistory(String token) async {
    return await http.get(
      Uri.parse('$baseUrl/api/lich-su/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
  }

  /// Xoá 1 mục lịch sử
  static Future<http.Response> deleteHistory(int id, String token) async {
    return await http.delete(
      Uri.parse('$baseUrl/api/lich-su/xoa/$id/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
  }

    /// Đổi mật khẩu
  static Future<http.Response> changePassword(
      String oldPassword, String newPassword, String confirmPassword, String token) async {
    return await http.post(
      Uri.parse('$baseUrl/api/nguoi-dung/doi-mat-khau/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "old_password": oldPassword,
        "new_password": newPassword,
        "confirm_password": confirmPassword,
      }),
    );
  }

}

