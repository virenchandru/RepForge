import 'package:flutter/material.dart';

import '../models/workout_session.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({required this.session, super.key});

  final WorkoutSession session;

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  static const _exercises = [
    'Bench Press',
    'Deadlift',
    'Overhead Press',
    'Pull-up',
    'Push-up',
    'Barbell Row',
    'Squat',
    'Lunge',
    'Leg Press',
    'Lat Pulldown',
    'Bicep Curl',
    'Triceps Pushdown',
    'Plank',
  ];

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _exercises
        .where((name) => name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Exercise')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search exercises',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            Expanded(
              child: filteredExercises.isEmpty
                  ? const Center(child: Text('No exercises found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filteredExercises.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final name = filteredExercises[index];
                        final alreadyAdded = widget.session.containsExercise(
                          name,
                        );
                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEAF3D7),
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: Color(0xFF171A17),
                              ),
                            ),
                            title: Text(name),
                            trailing: alreadyAdded
                                ? const Chip(label: Text('Added'))
                                : const Icon(Icons.add_circle_outline_rounded),
                            enabled: !alreadyAdded,
                            onTap: alreadyAdded
                                ? null
                                : () {
                                    widget.session.addExercise(name);
                                    Navigator.pop(context);
                                  },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
