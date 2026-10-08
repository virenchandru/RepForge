import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repforge_mobile/data/auth_api.dart';

void main() {
  group('AuthApi', () {
    test('logs in and parses the authenticated user and token', () async {
      late http.Request request;
      final api = AuthApi(
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'message': 'Login successful',
              'data': {
                'user': {'name': 'Viren', 'email': 'viren@example.com'},
                'token': 'access-token',
                'token_type': 'Bearer',
              },
            }),
            200,
          );
        }),
      );

      final result = await api.login(
        email: 'viren@example.com',
        password: 'password123',
      );

      expect(request.url.path, '/api/login');
      expect(jsonDecode(request.body), {
        'email': 'viren@example.com',
        'password': 'password123',
      });
      expect(result.user.name, 'Viren');
      expect(result.user.email, 'viren@example.com');
      expect(result.token, 'access-token');
    });

    test('registers with the confirmation field required by Laravel', () async {
      late Map<String, dynamic> payload;
      final api = AuthApi(
        client: MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {
                'user': {'name': 'Viren', 'email': 'viren@example.com'},
                'token': 'access-token',
              },
            }),
            201,
          );
        }),
      );

      await api.register(
        name: 'Viren',
        email: 'viren@example.com',
        password: 'password123',
      );

      expect(payload['password_confirmation'], 'password123');
    });

    test('shows Laravel validation errors to the user', () async {
      final api = AuthApi(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'email': ['The provided credentials are incorrect.'],
              },
            }),
            422,
          ),
        ),
      );

      expect(
        () => api.login(email: 'wrong@example.com', password: 'wrong'),
        throwsA(
          isA<AuthApiException>().having(
            (error) => error.message,
            'message',
            'The provided credentials are incorrect.',
          ),
        ),
      );
    });

    test('sends the bearer token when logging out', () async {
      late http.Request request;
      final api = AuthApi(
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({'message': 'Logout successful'}),
            200,
          );
        }),
      );

      await api.logout('access-token');

      expect(request.url.path, '/api/logout');
      expect(request.headers['Authorization'], 'Bearer access-token');
    });
  });
}
