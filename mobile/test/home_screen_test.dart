import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repforge_mobile/data/auth_api.dart';
import 'package:repforge_mobile/screens/home_screen.dart';
import 'package:repforge_mobile/screens/workout_history_detail_screen.dart';

void main() {
  testWidgets(
    'dashboard displays real workout stats and opens workout detail',
    (tester) async {
      final now = DateTime.now();
      final session = WorkoutSessionRecord(
        id: 1,
        title: 'Upper body',
        photoUrl: null,
        publishedAt: now,
        entries: const [
          WorkoutSessionEntry(
            exerciseName: 'Bench Press',
            setNumber: 1,
            reps: 4,
            weightKg: 40,
          ),
          WorkoutSessionEntry(
            exerciseName: 'Bench Press',
            setNumber: 2,
            reps: 4,
            weightKg: 40,
          ),
        ],
      );
      var startedWorkout = false;
      var openedProfile = false;
      var openedHistory = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              user: const AppUser(
                name: 'Test Athlete',
                email: 'test@example.com',
              ),
              onAddWorkout: () => startedWorkout = true,
              onOpenProfile: () => openedProfile = true,
              onSeeAll: () => openedHistory = true,
              loadWorkoutHistory: () async => [session],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test.'), findsOneWidget);
      expect(find.text('Weekly activity'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.person_rounded));
      expect(openedProfile, isTrue);
      await tester.tap(find.text('Start workout'));
      expect(startedWorkout, isTrue);

      await tester.scrollUntilVisible(find.text('320 kg'), 300);
      expect(find.text('320 kg'), findsWidgets);
      await tester.scrollUntilVisible(find.text('Upper body'), 300);
      expect(find.text('Upper body'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Heaviest lift'), 300);
      expect(find.text('Heaviest lift'), findsOneWidget);

      await tester.ensureVisible(find.text('See all'));
      await tester.tap(find.text('See all'));
      expect(openedHistory, isTrue);

      await tester.scrollUntilVisible(find.text('Upper body'), 300);
      await tester.tap(find.text('Upper body'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutHistoryDetailScreen), findsOneWidget);
    },
  );

  testWidgets('new users see a useful empty state and start action', (
    tester,
  ) async {
    var startedWorkout = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            user: const AppUser(name: 'New Athlete', email: 'new@example.com'),
            onAddWorkout: () => startedWorkout = true,
            onOpenProfile: () {},
            onSeeAll: () {},
            loadWorkoutHistory: () async => [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Your training story starts here'),
      300,
    );
    expect(find.text('Your training story starts here'), findsOneWidget);
    expect(
      find.text(
        'Log weights in your workouts to see your personal records here.',
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(find.text('Start your first workout'), 300);
    await tester.tap(find.text('Start your first workout'));
    expect(startedWorkout, isTrue);
  });
}
