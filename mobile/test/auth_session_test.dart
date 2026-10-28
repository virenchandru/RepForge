import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repforge_mobile/data/auth_api.dart';
import 'package:repforge_mobile/data/auth_token_store.dart';
import 'package:repforge_mobile/main.dart';
import 'package:repforge_mobile/screens/app_shell.dart';
import 'package:repforge_mobile/screens/auth_screen.dart';

class _MemoryAuthTokenStore implements AuthTokenStore {
  _MemoryAuthTokenStore([this.token]);

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login survives app restart and logout clears the saved token', (
    tester,
  ) async {
    final tokenStore = _MemoryAuthTokenStore();
    final requests = <http.Request>[];
    final api = AuthApi(
      client: MockClient((request) async {
        requests.add(request);
        switch (request.url.path) {
          case '/api/login':
            return http.Response(
              jsonEncode({
                'data': {
                  'user': {'name': 'Test Athlete', 'email': 'test@example.com'},
                  'token': 'saved-access-token',
                },
              }),
              200,
            );
          case '/api/user':
            return http.Response(
              jsonEncode({'name': 'Test Athlete', 'email': 'test@example.com'}),
              200,
            );
          case '/api/workout-sessions':
            return http.Response(jsonEncode({'data': []}), 200);
          case '/api/logout':
            return http.Response(jsonEncode({'message': 'Logged out'}), 200);
          default:
            return http.Response('', 404);
        }
      }),
    );

    await tester.pumpWidget(RepForgeApp(authApi: api, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    final signInButton = find.widgetWithText(FilledButton, 'Masuk');
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();
    expect(tokenStore.token, 'saved-access-token');
    expect(find.byType(AppShell), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(RepForgeApp(authApi: api, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(
      requests.any(
        (request) =>
            request.url.path == '/api/user' &&
            request.headers['Authorization'] == 'Bearer saved-access-token',
      ),
      isTrue,
    );

    await tester.tap(find.text('Workout').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tokenStore.token, 'saved-access-token');

    await tester.tap(find.text('Keluar dari akun'));
    await tester.pumpAndSettle();
    expect(tokenStore.token, isNull);
    expect(find.byType(AuthScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(RepForgeApp(authApi: api, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('an invalid saved token is deleted and returns to login', (
    tester,
  ) async {
    final tokenStore = _MemoryAuthTokenStore('expired-token');
    final api = AuthApi(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401),
      ),
    );

    await tester.pumpWidget(RepForgeApp(authApi: api, tokenStore: tokenStore));
    await tester.pumpAndSettle();

    expect(tokenStore.token, isNull);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });
}
