import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_user.dart';

class AuthService {
  // Android Emulator -> your computer's localhost
  // static const String baseUrl = 'http://10.0.2.2:5000';
  // static const String baseUrl = 'http://10.0.2.2:5000';
  // static const String baseUrl = 'http://localhost:5000';
  static const String baseUrl = 'https://sihproj-backend.onrender.com';

  static AppUser? currentUser;
  static String? token;

  Future<AppUser> login({
    required String email,
    required String password,
    required String role,
  }) async {
    if (email.trim().isEmpty) {
      throw Exception('Email is required.');
    }

    if (password.isEmpty) {
      throw Exception('Password is required.');
    }

    if (role.trim().isEmpty) {
      throw Exception('Please select a role.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'role': role.trim().toLowerCase(),
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        token = data['token'] as String;

        currentUser = AppUser.fromJson(
          data['user'] as Map<String, dynamic>,
        );

        return currentUser!;
      }

      final message =
          data['message']?.toString() ?? 'Login failed.';

      throw Exception(message);
    } on FormatException {
      throw Exception('Invalid response received from server.');
    } on http.ClientException {
      throw Exception('Could not connect to the server.');
    }
  }

  Future<void> logout() async {
    currentUser = null;
    token = null;
  }

  bool get isLoggedIn {
    return currentUser != null && token != null;
  }
}