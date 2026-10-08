import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppUser {
  const AppUser({required this.name, required this.email});

  final String name;
  final String email;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: json['name'] as String? ?? 'Atlet RepForge',
      email: json['email'] as String? ?? '',
    );
  }
}

class AuthResult {
  const AuthResult({required this.user, required this.token});

  final AppUser user;
  final String token;
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static String get _baseUrl {
    final configuredUrl = _configuredUrl.trim();
    if (configuredUrl.isNotEmpty) {
      return configuredUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000/api'
        : 'http://127.0.0.1:8000/api';
  }

  Future<AuthResult> login({required String email, required String password}) {
    return _authenticate('/login', {'email': email, 'password': password});
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _authenticate('/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
    });
  }

  Future<AuthResult> _authenticate(
    String path,
    Map<String, String> payload,
  ) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ),
    );
    final body = _decodeBody(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_errorMessage(body, response.statusCode));
    }

    final data = body['data'] as Map<String, dynamic>?;
    final user = data?['user'] as Map<String, dynamic>?;
    final token = data?['token'] as String?;
    if (user == null || token == null) {
      throw const AuthApiException(
        'Respons server tidak sesuai. Periksa endpoint autentikasi.',
      );
    }

    return AuthResult(user: AppUser.fromJson(user), token: token);
  }

  Future<void> logout(String token) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _errorMessage(_decodeBody(response), response.statusCode),
      );
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw AuthApiException(
        'Tidak dapat terhubung ke server. Pastikan backend aktif dan alamat API benar.',
      );
    } on TimeoutException {
      throw const AuthApiException(
        'Server terlalu lama merespons. Coba lagi sebentar.',
      );
    } on FormatException {
      throw const AuthApiException('Alamat API tidak valid.');
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // The server can return non-JSON error pages; show a concise status instead.
    }
    return {};
  }

  String _errorMessage(Map<String, dynamic> body, int statusCode) {
    final errors = body['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
      }
    }
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    return 'Permintaan gagal (HTTP $statusCode). Coba lagi.';
  }
}
