import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repforge_mobile/data/auth_api.dart';

void main() {
  group('AuthApi workout sessions', () {
    test(
      'publishes title and independent set entries as multipart data',
      () async {
        late http.Request request;
        final api = AuthApi(
          client: MockClient((incoming) async {
            request = incoming;
            return http.Response(
              jsonEncode({
                'data': {
                  'id': 7,
                  'title': 'Leg day',
                  'photo_path': 'workout-sessions/photo.jpg',
                  'published_at': '2026-10-20T06:00:00.000000Z',
                  'entries': [
                    {
                      'id': 14,
                      'exercise_name': 'Squat',
                      'set_number': 1,
                      'reps': 8,
                      'weight_kg': '40.00',
                    },
                  ],
                },
              }),
              201,
            );
          }),
        );

        final session = await api.publishWorkoutSession(
          token: 'access-token',
          title: 'Leg day',
          entries: const [
            WorkoutSetPayload(
              exerciseName: 'Squat',
              setNumber: 1,
              reps: 8,
              weightKg: 40,
            ),
          ],
        );

        expect(request.method, 'POST');
        expect(request.url.path, '/api/workout-sessions');
        expect(request.headers['Authorization'], startsWith('Bearer '));
        expect(request.headers['Authorization'], endsWith('access-token'));
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        expect(request.body, contains('Leg day'));
        expect(
          request.body,
          contains(
            '[{"exercise_name":"Squat","set_number":1,"reps":8,"weight_kg":40.0}]',
          ),
        );
        expect(session.id, 7);
        expect(session.title, 'Leg day');
        expect(session.entries.single.reps, 8);
        expect(session.entries.single.weightKg, 40);
        expect(
          session.photoUrl,
          contains('/storage/workout-sessions/photo.jpg'),
        );
      },
    );

    test('loads workout history from the authenticated endpoint', () async {
      late http.Request request;
      final api = AuthApi(
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 9,
                  'title': 'Push day',
                  'photo_path': null,
                  'published_at': '2026-10-20T06:00:00.000000Z',
                  'entries': [
                    {
                      'id': 15,
                      'exercise_name': 'Bench Press',
                      'set_number': 1,
                      'reps': 10,
                      'weight_kg': null,
                    },
                  ],
                },
              ],
            }),
            200,
          );
        }),
      );

      final sessions = await api.getWorkoutSessions(token: 'access-token');

      expect(request.method, 'GET');
      expect(request.url.path, '/api/workout-sessions');
      expect(request.headers['Authorization'], startsWith('Bearer '));
      expect(request.headers['Authorization'], endsWith('access-token'));
      expect(sessions.single.title, 'Push day');
      expect(sessions.single.photoUrl, isNull);
      expect(sessions.single.entries.single.exerciseName, 'Bench Press');
    });
  });
}
