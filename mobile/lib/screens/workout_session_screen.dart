import 'dart:async';

import 'package:flutter/cupertino.dart';
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
    required this.onLoadPreviousPerformance,
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
  final Future<PreviousPerformance?> Function({required String exerciseName})
  onLoadPreviousPerformance;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final Set<SessionExercise> _requestedPreviousPerformance = {};
  final Set<SessionExercise> _loadingPreviousPerformance = {};
  final Map<SessionExercise, PreviousPerformance?> _previousPerformance = {};
  final Map<SessionExercise, String> _previousPerformanceErrors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.session.addListener(_loadPreviousForNewExercises);
    _loadPreviousForNewExercises();
  }

  @override
  void didUpdateWidget(covariant WorkoutSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_loadPreviousForNewExercises);
      widget.session.addListener(_loadPreviousForNewExercises);
      _requestedPreviousPerformance.clear();
      _loadingPreviousPerformance.clear();
      _previousPerformance.clear();
      _previousPerformanceErrors.clear();
      _loadPreviousForNewExercises();
    }
  }

  void _loadPreviousForNewExercises() {
    final activeExercises = widget.session.exercises.toSet();
    _requestedPreviousPerformance.retainAll(activeExercises);
    _loadingPreviousPerformance.retainAll(activeExercises);
    _previousPerformance.removeWhere(
      (exercise, _) => !activeExercises.contains(exercise),
    );
    _previousPerformanceErrors.removeWhere(
      (exercise, _) => !activeExercises.contains(exercise),
    );
    for (final exercise in widget.session.exercises) {
      if (_requestedPreviousPerformance.add(exercise)) {
        unawaited(_loadPreviousPerformance(exercise));
      }
    }
  }

  Future<void> _loadPreviousPerformance(SessionExercise exercise) async {
    if (mounted) {
      setState(() {
        _loadingPreviousPerformance.add(exercise);
        _previousPerformanceErrors.remove(exercise);
      });
    }
    try {
      final performance = await widget.onLoadPreviousPerformance(
        exerciseName: exercise.name,
      );
      if (!mounted || !widget.session.exercises.contains(exercise)) return;
      setState(() {
        _previousPerformance[exercise] = performance;
        _loadingPreviousPerformance.remove(exercise);
      });
    } on AuthApiException catch (error) {
      if (!mounted || !widget.session.exercises.contains(exercise)) return;
      setState(() {
        _previousPerformanceErrors[exercise] = error.message;
        _loadingPreviousPerformance.remove(exercise);
      });
    }
  }

  void _retryPreviousPerformance(SessionExercise exercise) {
    _requestedPreviousPerformance.remove(exercise);
    _loadPreviousForNewExercises();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.session.refreshRestTimers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.session.removeListener(_loadPreviousForNewExercises);
    super.dispose();
  }

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
                          previousPerformance: _previousPerformance[exercise],
                          isLoadingPreviousPerformance:
                              _loadingPreviousPerformance.contains(exercise),
                          previousPerformanceError:
                              _previousPerformanceErrors[exercise],
                          onRetryPreviousPerformance: () =>
                              _retryPreviousPerformance(exercise),
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
    required this.previousPerformance,
    required this.isLoadingPreviousPerformance,
    required this.previousPerformanceError,
    required this.onRetryPreviousPerformance,
    super.key,
  });

  final WorkoutSession session;
  final SessionExercise exercise;
  final PreviousPerformance? previousPerformance;
  final bool isLoadingPreviousPerformance;
  final String? previousPerformanceError;
  final VoidCallback onRetryPreviousPerformance;

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
          _RestTimerControls(session: session, exercise: exercise),
          _PreviousPerformanceSummary(
            exerciseName: exercise.name,
            performance: previousPerformance,
            isLoading: isLoadingPreviousPerformance,
            error: previousPerformanceError,
            onRetry: onRetryPreviousPerformance,
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
          width: 32,
          child: Checkbox(
            key: ValueKey<String>('complete-set-${set.id}'),
            value: set.isCompleted,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) {
              if (value != null) {
                session.setCompleted(exercise, set, value);
              }
            },
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

class _RestTimerControls extends StatelessWidget {
  const _RestTimerControls({required this.session, required this.exercise});

  final WorkoutSession session;
  final SessionExercise exercise;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _selectDuration(BuildContext context) async {
    final duration = await showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _RestDurationPicker(initialDuration: exercise.restDuration),
    );
    if (duration != null) session.setRestDuration(exercise, duration);
  }

  @override
  Widget build(BuildContext context) {
    final status = exercise.restTimerStatus;
    final isRunning = status == RestTimerStatus.running;
    final isPaused = status == RestTimerStatus.paused;
    String statusText;
    if (isRunning || isPaused) {
      statusText = _formatDuration(exercise.restTimeRemaining);
    } else if (status == RestTimerStatus.completed) {
      statusText = 'Rest complete';
    } else if (status == RestTimerStatus.skipped &&
        exercise.restDuration == Duration.zero) {
      statusText = 'Rest timer disabled';
    } else if (status == RestTimerStatus.skipped) {
      statusText = 'Rest skipped';
    } else {
      statusText = 'Ready';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded, size: 18),
              SizedBox(width: 7),
              Text('Rest Timer', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: const Color(0xFFEAF3D7),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: ValueKey<String>('rest-duration-${exercise.id}'),
              onTap: () => _selectDuration(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDuration(exercise.restDuration),
                        style: const TextStyle(
                          color: Color(0xFF171A17),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF171A17),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  statusText,
                  key: ValueKey<String>('rest-status-${exercise.id}'),
                  style: TextStyle(
                    color: isRunning
                        ? const Color(0xFF171A17)
                        : const Color(0xFF777A73),
                    fontSize: isRunning || isPaused ? 22 : 13,
                    fontWeight: isRunning || isPaused
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (isRunning || isPaused) ...[
                TextButton(
                  key: ValueKey<String>(
                    isRunning
                        ? 'pause-rest-${exercise.id}'
                        : 'resume-rest-${exercise.id}',
                  ),
                  onPressed: () => isRunning
                      ? session.pauseRestTimer(exercise)
                      : session.resumeRestTimer(exercise),
                  child: Text(isRunning ? 'Pause' : 'Resume'),
                ),
                TextButton(
                  key: ValueKey<String>('skip-rest-${exercise.id}'),
                  onPressed: () => session.skipRestTimer(exercise),
                  child: const Text('Skip'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RestDurationPicker extends StatefulWidget {
  const _RestDurationPicker({required this.initialDuration});

  final Duration initialDuration;

  @override
  State<_RestDurationPicker> createState() => _RestDurationPickerState();
}

class _RestDurationPickerState extends State<_RestDurationPicker> {
  late int _minutes;
  late int _seconds;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _secondController;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialDuration.inMinutes;
    _seconds = widget.initialDuration.inSeconds % 60;
    _minuteController = FixedExtentScrollController(initialItem: _minutes);
    _secondController = FixedExtentScrollController(initialItem: _seconds);
  }

  @override
  void dispose() {
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: height < 500 ? height * 0.62 : 300,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Rest duration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey<String>('save-rest-duration'),
                    onPressed: () => Navigator.pop(
                      context,
                      Duration(minutes: _minutes, seconds: _seconds),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('MIN'),
                        Expanded(
                          child: CupertinoPicker(
                            key: const ValueKey<String>('rest-minutes-wheel'),
                            scrollController: _minuteController,
                            itemExtent: 42,
                            onSelectedItemChanged: (value) =>
                                setState(() => _minutes = value),
                            children: [
                              for (var value = 0; value < 60; value++)
                                Center(
                                  child: Text(
                                    value.toString().padLeft(2, '0'),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('SEC'),
                        Expanded(
                          child: CupertinoPicker(
                            key: const ValueKey<String>('rest-seconds-wheel'),
                            scrollController: _secondController,
                            itemExtent: 42,
                            onSelectedItemChanged: (value) =>
                                setState(() => _seconds = value),
                            children: [
                              for (var value = 0; value < 60; value++)
                                Center(
                                  child: Text(
                                    value.toString().padLeft(2, '0'),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

class _PreviousPerformanceSummary extends StatelessWidget {
  const _PreviousPerformanceSummary({
    required this.exerciseName,
    required this.performance,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final String exerciseName;
  final PreviousPerformance? performance;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  String _formatWeight(double? weightKg) {
    if (weightKg == null) return '— kg';
    final value = weightKg
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '$value kg';
  }

  @override
  Widget build(BuildContext context) {
    final entries =
        performance?.entries
            .where((entry) => entry.exerciseName == exerciseName)
            .toList(growable: false) ??
        const <WorkoutSessionEntry>[];

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Previous Performance',
            style: TextStyle(
              color: Color(0xFF171A17),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          if (isLoading)
            const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (error != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFF777A73),
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey<String>('retry-previous-performance'),
                  onPressed: onRetry,
                  tooltip: 'Retry',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            )
          else if (entries.isEmpty)
            const Text(
              'No previous performance',
              style: TextStyle(color: Color(0xFF777A73), fontSize: 12),
            )
          else ...[
            Text(
              MaterialLocalizations.of(
                context,
              ).formatMediumDate(performance!.publishedAt.toLocal()),
              style: const TextStyle(color: Color(0xFF777A73), fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        'Set ${entry.setNumber}',
                        style: const TextStyle(
                          color: Color(0xFF171A17),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.reps} reps',
                        style: const TextStyle(
                          color: Color(0xFF171A17),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      _formatWeight(entry.weightKg),
                      style: const TextStyle(
                        color: Color(0xFF171A17),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
