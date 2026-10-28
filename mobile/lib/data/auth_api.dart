import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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

class WorkoutEntry {
  const WorkoutEntry({
    required this.id,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.createdAt,
  });

  final int id;
  final String exerciseName;
  final int sets;
  final int reps;
  final double? weightKg;
  final DateTime createdAt;

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) {
    final rawWeight = json['weight_kg'];
    final weight = rawWeight == null
        ? null
        : rawWeight is num
        ? rawWeight.toDouble()
        : double.parse(rawWeight as String);

    return WorkoutEntry(
      id: json['id'] as int,
      exerciseName: json['exercise_name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weightKg: weight,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class WorkoutSetPayload {
  const WorkoutSetPayload({
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    this.weightKg,
  });

  final String exerciseName;
  final int setNumber;
  final int reps;
  final double? weightKg;

  Map<String, dynamic> toJson() => {
    'exercise_name': exerciseName,
    'set_number': setNumber,
    'reps': reps,
    'weight_kg': weightKg,
  };
}

class WorkoutSessionEntry {
  const WorkoutSessionEntry({
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
  });

  final String exerciseName;
  final int setNumber;
  final int reps;
  final double? weightKg;

  factory WorkoutSessionEntry.fromJson(Map<String, dynamic> json) {
    final rawWeight = json['weight_kg'];
    return WorkoutSessionEntry(
      exerciseName: json['exercise_name'] as String,
      setNumber: json['set_number'] as int,
      reps: json['reps'] as int,
      weightKg: rawWeight == null
          ? null
          : rawWeight is num
          ? rawWeight.toDouble()
          : double.parse(rawWeight as String),
    );
  }
}

class WorkoutSessionRecord {
  const WorkoutSessionRecord({
    required this.id,
    required this.title,
    required this.photoUrl,
    required this.publishedAt,
    required this.entries,
  });

  final int id;
  final String title;
  final String? photoUrl;
  final DateTime publishedAt;
  final List<WorkoutSessionEntry> entries;

  factory WorkoutSessionRecord.fromJson(
    Map<String, dynamic> json, {
    required String? photoUrl,
  }) {
    final entries = json['entries'] as List<dynamic>? ?? const [];
    return WorkoutSessionRecord(
      id: json['id'] as int,
      title: json['title'] as String,
      photoUrl: photoUrl,
      publishedAt: DateTime.parse(json['published_at'] as String),
      entries: entries
          .map(
            (entry) =>
                WorkoutSessionEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

class PreviousPerformance {
  const PreviousPerformance({
    required this.title,
    required this.publishedAt,
    required this.entries,
  });

  final String title;
  final DateTime publishedAt;
  final List<WorkoutSessionEntry> entries;

  factory PreviousPerformance.fromJson(Map<String, dynamic> json) {
    final entries = json['entries'] as List<dynamic>? ?? const [];
    return PreviousPerformance(
      title: json['title'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      entries: entries
          .map(
            (entry) =>
                WorkoutSessionEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
  bool get isUnauthenticated => statusCode == 401;

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
        ? 'http://127.0.2.1:8000/api'
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
      throw AuthApiException(
        _errorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
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

  Future<AppUser> getCurrentUser({required String token}) async {
    final response = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Accept': 'application/json',
          'Authorization': _bearerToken(token),
        },
      ),
    );
    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _errorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    return AppUser.fromJson(body);
  }

  Future<void> logout(String token) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': _bearerToken(token),
        },
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _errorMessage(_decodeBody(response), response.statusCode),
        statusCode: response.statusCode,
      );
    }
  }

  Future<WorkoutEntry> createWorkoutEntry({
    required String token,
    required String exerciseName,
    required int sets,
    required int reps,
    double? weightKg,
  }) async {
    final payload = <String, dynamic>{
      'exercise_name': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight_kg': weightKg,
    };
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/workouts'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': _bearerToken(token),
        },
        body: jsonEncode(payload),
      ),
    );
    final body = _decodeBody(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _errorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final entry = body['data'];
    if (entry is! Map<String, dynamic>) {
      throw const AuthApiException(
        'Respons server tidak sesuai. Periksa endpoint latihan.',
      );
    }

    return WorkoutEntry.fromJson(entry);
  }

  Future<WorkoutSessionRecord> publishWorkoutSession({
    required String token,
    required String title,
    required List<WorkoutSetPayload> entries,
    XFile? photo,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/workout-sessions'))
          ..headers['Accept'] = 'application/json'
          ..headers['Authorization'] = _bearerToken(token)
          ..fields['title'] = title
          ..fields['entries'] = jsonEncode(
            entries.map((entry) => entry.toJson()).toList(),
          );

    if (photo != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          await photo.readAsBytes(),
          filename: photo.name,
        ),
      );
    }

    final response = await _send(
      () async => http.Response.fromStream(await _client.send(request)),
    );
    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _errorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthApiException(
        'Respons server tidak sesuai. Periksa endpoint workout.',
      );
    }
    return WorkoutSessionRecord.fromJson(
      data,
      photoUrl: _photoUrl(data['photo_path'] as String?),
    );
  }

  Future<List<WorkoutSessionRecord>> getWorkoutSessions({
    required String token,
  }) async {
    final response = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/workout-sessions'),
        headers: {
          'Accept': 'application/json',
          'Authorization': _bearerToken(token),
        },
      ),
    );
    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _errorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final data = body['data'];
    if (data is! List<dynamic>) {
      throw const AuthApiException(
        'Respons server tidak sesuai. Periksa riwayat workout.',
      );
    }
    return data
        .map(
          (session) => WorkoutSessionRecord.fromJson(
            session as Map<String, dynamic>,
            photoUrl: _photoUrl(session['photo_path'] as String?),
          ),
        )
        .toList(growable: false);
  }

  Future<PreviousPerformance?> getPreviousPerformance({
    required String token,
    required String exerciseName,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/workout-sessions/previous-performance',
    ).replace(queryParameters: {'exercise_name': exerciseName});
    final response = await _send(
      () => _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': _bearerToken(token),
        },
      ),
    );
    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _errorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final data = body['data'];
    if (data == null) return null;
    if (data is! Map<String, dynamic>) {
      throw const AuthApiException(
        'Respons server tidak sesuai. Periksa performa sebelumnya.',
      );
    }
    return PreviousPerformance.fromJson(data);
  }

  String? _photoUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) return path;

    final segments = path.split('/').map(Uri.encodeComponent).join('/');
    return Uri.parse(_baseUrl).replace(path: '/storage/$segments').toString();
  }

  String _bearerToken(String token) => 'Bearer $token';

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
