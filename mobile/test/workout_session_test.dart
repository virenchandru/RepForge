import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repforge_mobile/data/auth_api.dart';
import 'package:repforge_mobile/models/workout_session.dart';
import 'package:repforge_mobile/screens/app_shell.dart';
import 'package:repforge_mobile/screens/workout_session_screen.dart';

void main() {
  group('WorkoutSession', () {
    test('manages independent rest timers from set completion transitions', () {
      final session = WorkoutSession();
      final squat = session.addExercise('Squat')!;
      final bench = session.addExercise('Bench Press')!;
      final squatSet = squat.sets.single;

      session.setRestDuration(squat, const Duration(minutes: 2, seconds: 15));
      session.setRestDuration(bench, Duration.zero);
      expect(squat.restDuration, const Duration(minutes: 2, seconds: 15));
      expect(bench.restDuration, Duration.zero);

      expect(session.setCompleted(squat, squatSet, true), isTrue);
      expect(squat.restTimerStatus, RestTimerStatus.running);
      expect(session.setCompleted(squat, squatSet, true), isFalse);
      expect(session.setCompleted(bench, bench.sets.single, true), isTrue);
      expect(bench.restTimerStatus, RestTimerStatus.skipped);

      session.pauseRestTimer(squat);
      expect(squat.restTimerStatus, RestTimerStatus.paused);
      session.resumeRestTimer(squat);
      expect(squat.restTimerStatus, RestTimerStatus.running);
      session.skipRestTimer(squat);
      expect(squat.restTimerStatus, RestTimerStatus.skipped);

      expect(session.setCompleted(squat, squatSet, false), isTrue);
      expect(session.setCompleted(squat, squatSet, true), isTrue);
      expect(squat.restTimerStatus, RestTimerStatus.running);
      expect(squat.sets.single.isCompleted, isTrue);

      session.dispose();
    });

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

  testWidgets('rest timer picker and controls work per exercise', (
    tester,
  ) async {
    final session = WorkoutSession();
    final squat = session.addExercise('Squat')!;
    final bench = session.addExercise('Bench Press')!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutSessionScreen(
            session: session,
            onPublish: ({required title, required entries, photo}) async {
              throw UnimplementedError();
            },
            onWorkoutPublished: () {},
            onLoadPreviousPerformance: ({required exerciseName}) async => null,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('rest-duration-0')));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsNWidgets(2));
    await tester.drag(
      find.byKey(const ValueKey<String>('rest-seconds-wheel')),
      const Offset(0, -84),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-rest-duration')));
    await tester.pumpAndSettle();
    expect(squat.restDuration, isNot(const Duration(seconds: 90)));
    expect(bench.restDuration, const Duration(seconds: 90));
    final selectedDurationText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('rest-duration-0')),
        matching: find.byType(Text),
      ),
    );
    final minutes = squat.restDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = squat.restDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    expect(selectedDurationText.data, '$minutes:$seconds');
    expect(
      find.text('Completing another set restarts this exercise timer.'),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('complete-set-0')));
    await tester.pump();
    expect(squat.restTimerStatus, RestTimerStatus.running);
    await tester.tap(find.byKey(const ValueKey<String>('pause-rest-0')));
    await tester.pump();
    expect(squat.restTimerStatus, RestTimerStatus.paused);
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const ValueKey<String>('resume-rest-0')));
    await tester.pump();
    expect(squat.restTimerStatus, RestTimerStatus.running);
    await tester.tap(find.byKey(const ValueKey<String>('skip-rest-0')));
    await tester.pump();
    expect(squat.restTimerStatus, RestTimerStatus.skipped);
    expect(bench.restTimerStatus, RestTimerStatus.idle);

    session.setRestDuration(bench, Duration.zero);
    session.setCompleted(bench, bench.sets.single, true);
    await tester.pump();
    expect(bench.restTimerStatus, RestTimerStatus.skipped);
    expect(find.text('Rest timer disabled'), findsOneWidget);
    session.setCompleted(bench, bench.sets.single, false);

    session.setRestDuration(bench, const Duration(seconds: 2));
    session.setCompleted(bench, bench.sets.single, true);
    await tester.pump();
    expect(bench.restTimerStatus, RestTimerStatus.running);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(bench.restTimerStatus, RestTimerStatus.completed);
    expect(find.text('Rest complete'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('previous performance is read-only and isolated per exercise', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = WorkoutSession();
    final loadedExercises = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutSessionScreen(
            session: session,
            onPublish: ({required title, required entries, photo}) async {
              throw UnimplementedError();
            },
            onWorkoutPublished: () {},
            onLoadPreviousPerformance: ({required exerciseName}) async {
              loadedExercises.add(exerciseName);
              if (exerciseName == 'Squat') {
                return PreviousPerformance(
                  title: 'Previous leg day',
                  publishedAt: DateTime(2026, 10, 20),
                  entries: const [
                    WorkoutSessionEntry(
                      exerciseName: 'Squat',
                      setNumber: 1,
                      reps: 8,
                      weightKg: 40,
                    ),
                    WorkoutSessionEntry(
                      exerciseName: 'Squat',
                      setNumber: 2,
                      reps: 6,
                      weightKg: null,
                    ),
                  ],
                );
              }
              if (exerciseName == 'Bench Press') {
                return PreviousPerformance(
                  title: 'Previous push day',
                  publishedAt: DateTime(2026, 10, 21),
                  entries: const [
                    WorkoutSessionEntry(
                      exerciseName: 'Bench Press',
                      setNumber: 1,
                      reps: 10,
                      weightKg: 22.5,
                    ),
                  ],
                );
              }
              return null;
            },
          ),
        ),
      ),
    );

    final squat = session.addExercise('Squat')!;
    final bench = session.addExercise('Bench Press')!;
    final plank = session.addExercise('Plank')!;
    await tester.pumpAndSettle();

    expect(loadedExercises, ['Squat', 'Bench Press', 'Plank']);
    expect(find.text('8 reps'), findsOneWidget);
    expect(find.text('6 reps'), findsOneWidget);
    expect(find.text('10 reps'), findsOneWidget);
    expect(find.text('40 kg'), findsOneWidget);
    expect(find.text('22.5 kg'), findsOneWidget);
    expect(find.text('No previous performance'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey<String>('reps-0')));
    await tester.enterText(find.byKey(const ValueKey<String>('reps-0')), '12');
    await tester.pump();
    expect(squat.sets.single.reps, '12');
    expect(find.text('8 reps'), findsOneWidget);
    expect(bench.sets.single.reps, '');
    expect(plank.sets.single.reps, '');

    await tester.pumpWidget(const SizedBox());
    session.dispose();
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
          onLoadPreviousPerformance: ({required exerciseName}) async => null,
        ),
      ),
    );

    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add Exercise'));
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

    await tester.drag(
      find.byKey(const PageStorageKey<String>('workout-session-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add Exercise'));
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
    await tester.drag(
      find.byKey(const PageStorageKey<String>('workout-session-scroll')),
      const Offset(0, 1000),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey<String>('reps-0')));
    expect(find.text('Squat'), findsOneWidget);
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
    await tester.drag(
      find.byKey(const PageStorageKey<String>('workout-session-scroll')),
      const Offset(0, -1500),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey<String>('reps-3')));
    expect(find.text('Bench Press'), findsOneWidget);

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
