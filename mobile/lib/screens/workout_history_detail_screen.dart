import 'package:flutter/material.dart';

import '../data/auth_api.dart';

class WorkoutHistoryDetailScreen extends StatelessWidget {
  const WorkoutHistoryDetailScreen({required this.session, super.key});

  final WorkoutSessionRecord session;

  @override
  Widget build(BuildContext context) {
    final exercises = <String, List<WorkoutSessionEntry>>{};
    for (final entry in session.entries) {
      exercises.putIfAbsent(entry.exerciseName, () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            session.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            MaterialLocalizations.of(
              context,
            ).formatMediumDate(session.publishedAt.toLocal()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          for (final exercise in exercises.entries) ...[
            _ExerciseHistoryCard(
              exerciseName: exercise.key,
              entries: exercise.value,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ExerciseHistoryCard extends StatelessWidget {
  const _ExerciseHistoryCard({
    required this.exerciseName,
    required this.entries,
  });

  final String exerciseName;
  final List<WorkoutSessionEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        'Set ${entry.setNumber}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.reps} reps'
                        '${entry.weightKg == null ? '' : ' · ${entry.weightKg} kg'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
