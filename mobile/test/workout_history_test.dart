import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repforge_mobile/data/auth_api.dart';
import 'package:repforge_mobile/screens/app_shell.dart';
import 'package:repforge_mobile/screens/workout_history_detail_screen.dart';

void main() {
  final session = WorkoutSessionRecord(
    id: 1,
    title: 'Strength Day',
    photoUrl: null,
    publishedAt: DateTime(2026, 10, 20, 12),
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
      WorkoutSessionEntry(
        exerciseName: 'Bench Press',
        setNumber: 1,
        reps: 10,
        weightKg: 22.5,
      ),
    ],
  );

  Future<void> openHistory(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          user: const AppUser(name: 'Test Athlete', email: 'test@example.com'),
          onLogout: () async {},
          onPublishWorkout: ({required title, required entries, photo}) async {
            return session;
          },
          onLoadWorkoutHistory: () async => [session],
          onLoadPreviousPerformance: ({required exerciseName}) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
  }

  testWidgets('history cards show only title, date, and a tap indicator', (
    tester,
  ) async {
    await openHistory(tester);

    expect(find.text('Strength Day'), findsOneWidget);
    final localDate = MaterialLocalizations.of(
      tester.element(find.text('Strength Day')),
    ).formatMediumDate(session.publishedAt.toLocal());
    expect(find.text(localDate), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.text('Squat'), findsNothing);
    expect(find.text('Bench Press'), findsNothing);
    expect(find.text('8 reps · 40.0 kg'), findsNothing);
  });

  testWidgets('tapping a history card opens the recorded workout details', (
    tester,
  ) async {
    await openHistory(tester);

    await tester.tap(find.text('Strength Day'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutHistoryDetailScreen), findsOneWidget);
    expect(find.text('Workout Details'), findsOneWidget);
    expect(find.text('Strength Day'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Set 1'), findsNWidgets(2));
    expect(find.text('Set 2'), findsOneWidget);
    expect(find.text('8 reps · 40.0 kg'), findsOneWidget);
    expect(find.text('6 reps'), findsOneWidget);
    expect(find.text('10 reps · 22.5 kg'), findsOneWidget);
    expect(find.text('6 reps · null kg'), findsNothing);
  });
}
