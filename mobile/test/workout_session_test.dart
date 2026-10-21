import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repforge_mobile/data/auth_api.dart';
import 'package:repforge_mobile/models/workout_session.dart';
import 'package:repforge_mobile/screens/app_shell.dart';

void main() {
  group('WorkoutSession', () {
    test('keeps values independent and deletes only added sets', () {
      final session = WorkoutSession();
      final squat = session.addExercise('Squat')!;
      final bench = session.addExercise('Bench Press')!;
      final extraSet = session.addSet(squat);

      session.updateSet(squat.sets.first, reps: '8', weightKg: '40');
      session.updateSet(bench.sets.first, reps: '10', weightKg: '20');
      session.updateSet(extraSet, reps: '6', weightKg: '45');

      expect(session.addExercise(' squat '), isNull);
      expect(session.removeSet(squat, extraSet), isTrue);
      expect(session.removeSet(squat, squat.sets.first), isFalse);
      expect(squat.sets.map((set) => set.number), [1]);
      expect(squat.sets.single.reps, '8');
      expect(squat.sets.single.weightKg, '40');
      expect(bench.sets.single.reps, '10');
      expect(bench.sets.single.weightKg, '20');
      session.dispose();
    });
  });

  testWidgets('deletes sets and publishes the completed workout to history', (
    tester,
  ) async {
    final publishCalls = <String>[];
    WorkoutSessionRecord? publishedSession;
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          user: const AppUser(name: 'Test Athlete', email: 'test@example.com'),
          onLogout: () async {},
          onPublishWorkout: ({required title, required entries, photo}) async {
            publishCalls.add('$title:${entries.length}');
            publishedSession = WorkoutSessionRecord(
              id: 1,
              title: title,
              photoUrl: null,
              publishedAt: DateTime(2026),
              entries: entries
                  .map(
                    (entry) => WorkoutSessionEntry(
                      exerciseName: entry.exerciseName,
                      setNumber: entry.setNumber,
                      reps: entry.reps,
                      weightKg: entry.weightKg,
                    ),
                  )
                  .toList(),
            );
            return publishedSession!;
          },
          onLoadWorkoutHistory: () async =>
              publishedSession == null ? [] : [publishedSession!],
        ),
      ),
    );

    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Squat'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey<String>('reps-0')), '8');
    await tester.enterText(
      find.byKey(const ValueKey<String>('weight-0')),
      '40',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey<String>('reps-1')), '6');
    await tester.enterText(
      find.byKey(const ValueKey<String>('weight-1')),
      '45',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus set 2'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('reps-1')), findsNothing);

    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey<String>('reps-2')), '6');
    await tester.enterText(
      find.byKey(const ValueKey<String>('weight-2')),
      '45',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bench');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey<String>('reps-3')));
    await tester.enterText(find.byKey(const ValueKey<String>('reps-3')), '10');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('reps-0')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      '8',
    );

    await tester.ensureVisible(find.text('End Workout'));
    await tester.tap(find.text('End Workout'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('workout-title')),
      'Leg Day',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish workout'));
    await tester.pumpAndSettle();

    expect(publishCalls, ['Leg Day:3']);
    expect(find.text('Leg Day'), findsOneWidget);
  });
}
