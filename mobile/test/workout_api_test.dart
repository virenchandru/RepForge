import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repforge_mobile/data/auth_api.dart';

void main() {
  group('AuthApi.createWorkoutEntry', () {
    test(
      'sends an authenticated entry and parses the saved response',
      () async {
        late http.Request request;
        final api = AuthApi(
          client: MockClient((incoming) async {
            request = incoming;
            return http.Response(
              jsonEncode({
                'message': 'Workout logged successfully',
                'data': {
                  'id': 9,
                  'user_id': 4,
                  'exercise_name': 'Squat',
                  'sets': 3,
                  'reps': 10,
                  'weight_kg': '42.50',
                  'created_at': '2026-10-14T09:40:00.000000Z',
                },
              }),
              201,
            );
          }),
        );

        final entry = await api.createWorkoutEntry(
          token: 'access-token',
          exerciseName: 'Squat',
          sets: 3,
          reps: 10,
          weightKg: 42.5,
        );

        expect(request.url.path, '/api/workouts');
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {
          'exercise_name': 'Squat',
          'sets': 3,
          'reps': 10,
          'weight_kg': 42.5,
        });
        expect(entry.id, 9);
        expect(entry.exerciseName, 'Squat');
        expect(entry.weightKg, 42.5);
        expect(entry.createdAt, DateTime.utc(2026, 10, 14, 9, 40));
      },
    );

    test('sends an unspecified weight as null', () async {
      late Map<String, dynamic> payload;
      final api = AuthApi(
        client: MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {
                'id': 10,
                'user_id': 4,
                'exercise_name': 'Push-up',
                'sets': 3,
                'reps': 12,
                'weight_kg': null,
                'created_at': '2026-10-14T09:40:00.000000Z',
              },
            }),
            201,
          );
        }),
      );

      final entry = await api.createWorkoutEntry(
        token: 'access-token',
        exerciseName: 'Push-up',
        sets: 3,
        reps: 12,
      );

      expect(payload['weight_kg'], isNull);
      expect(entry.weightKg, isNull);
    });
  });
}
