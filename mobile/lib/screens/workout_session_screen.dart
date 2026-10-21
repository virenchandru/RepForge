import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/auth_api.dart';
import '../models/workout_session.dart';
import 'exercise_selection_screen.dart';
import 'publish_workout_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    required this.session,
    required this.onPublish,
    required this.onWorkoutPublished,
    super.key,
  });

  final WorkoutSession session;
  final Future<WorkoutSessionRecord> Function({
    required String title,
    required List<WorkoutSetPayload> entries,
    XFile? photo,
  })
  onPublish;
  final VoidCallback onWorkoutPublished;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _addExercise() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseSelectionScreen(session: widget.session),
      ),
    );
  }

  Future<void> _endWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PublishWorkoutScreen(
          session: widget.session,
          onPublish: widget.onPublish,
        ),
      ),
    );
    if (published == true && mounted) {
      widget.session.reset();
      widget.onWorkoutPublished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: CustomScrollView(
              key: const PageStorageKey<String>('workout-session-scroll'),
              slivers: [
                SliverAppBar(pinned: true, title: const Text('Workout')),
                if (widget.session.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySession(onAddExercise: _addExercise),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: _SessionSummary(session: widget.session),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    sliver: SliverList.separated(
                      itemCount: widget.session.exercises.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final exercise = widget.session.exercises[index];
                        return _ExerciseCard(
                          key: ValueKey<int>(exercise.id),
                          session: widget.session,
                          exercise: exercise,
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _addExercise,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Exercise'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              foregroundColor: const Color(0xFF171A17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _endWorkout,
                            icon: const Icon(Icons.flag_rounded),
                            label: const Text('End Workout'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: const Color(0xFF171A17),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptySession extends StatelessWidget {
  const _EmptySession({required this.onAddExercise});

  final VoidCallback onAddExercise;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3D7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 34,
                color: Color(0xFF171A17),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your workout starts here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171A17),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add an exercise to begin your session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF777A73), height: 1.45),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Exercise'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(190, 52),
                backgroundColor: const Color(0xFF171A17),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final exerciseCount = session.exercises.length;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3D7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFF171A17)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}'
              '  ·  ${session.setCount} sets',
              style: const TextStyle(
                color: Color(0xFF171A17),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.session,
    required this.exercise,
    super.key,
  });

  final WorkoutSession session;
  final SessionExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBEBE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            exercise.name,
            style: const TextStyle(
              color: Color(0xFF171A17),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              SizedBox(width: 50, child: Text('SET')),
              Expanded(child: Text('REPS')),
              SizedBox(width: 12),
              Expanded(child: Text('WEIGHT (KG)')),
              SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 8),
          for (final set in exercise.sets) ...[
            _SetRow(
              key: ValueKey<String>('set-${set.id}'),
              session: session,
              exercise: exercise,
              set: set,
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => session.addSet(exercise),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add set'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.session,
    required this.exercise,
    required this.set,
    super.key,
  });

  final WorkoutSession session;
  final SessionExercise exercise;
  final WorkoutSet set;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '${set.number}',
            style: const TextStyle(
              color: Color(0xFF171A17),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            key: ValueKey<String>('reps-${set.id}'),
            initialValue: set.reps,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            validator: (value) {
              final reps = int.tryParse(value?.trim() ?? '');
              if (reps == null || reps < 1 || reps > 1000) {
                return 'Enter 1–1000 reps';
              }
              return null;
            },
            onChanged: (value) => session.updateSet(set, reps: value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            key: ValueKey<String>('weight-${set.id}'),
            initialValue: set.weightKg,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '—',
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return null;
              final weight = double.tryParse(text);
              if (weight == null || weight < 0 || weight > 999999.99) {
                return 'Enter valid kg';
              }
              return null;
            },
            onChanged: (value) => session.updateSet(set, weightKg: value),
          ),
        ),
        SizedBox(
          width: 44,
          child: IconButton(
            tooltip: 'Hapus set ${set.number}',
            onPressed: exercise.sets.length == 1
                ? null
                : () => session.removeSet(exercise, set),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ),
      ],
    );
  }
}
