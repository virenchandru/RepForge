import 'dart:async';

import 'package:flutter/foundation.dart';

class WorkoutSet {
  WorkoutSet({required this.id, required this.number});

  final int id;
  int number;
  String reps = '';
  String weightKg = '';
  bool isCompleted = false;
}

enum RestTimerStatus { idle, running, paused, completed, skipped }

class SessionExercise {
  SessionExercise({required this.id, required this.name, required int setId})
    : sets = [WorkoutSet(id: setId, number: 1)];

  final int id;
  final String name;
  final List<WorkoutSet> sets;
  Duration restDuration = const Duration(seconds: 90);
  VoidCallback? onRestTimerChanged;

  Timer? _restTimer;
  DateTime? _restDeadline;
  Duration? _pausedRemaining;
  RestTimerStatus _restTimerStatus = RestTimerStatus.idle;

  RestTimerStatus get restTimerStatus => _restTimerStatus;

  Duration get restTimeRemaining {
    if (_restTimerStatus == RestTimerStatus.paused) {
      return _pausedRemaining ?? Duration.zero;
    }
    if (_restTimerStatus != RestTimerStatus.running) return Duration.zero;
    final remaining = _restDeadline!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _startRestTimer() {
    _cancelRestTimer();
    if (restDuration <= Duration.zero) {
      _restTimerStatus = RestTimerStatus.skipped;
      return;
    }
    _restTimerStatus = RestTimerStatus.running;
    _restDeadline = DateTime.now().add(restDuration);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      refreshRestTimer();
      onRestTimerChanged?.call();
    });
  }

  void pauseRestTimer() {
    if (_restTimerStatus != RestTimerStatus.running) return;
    _pausedRemaining = restTimeRemaining;
    _cancelRestTimer();
    _restDeadline = null;
    _restTimerStatus = _pausedRemaining == Duration.zero
        ? RestTimerStatus.completed
        : RestTimerStatus.paused;
  }

  void resumeRestTimer() {
    if (_restTimerStatus != RestTimerStatus.paused) return;
    final remaining = _pausedRemaining ?? Duration.zero;
    if (remaining == Duration.zero) {
      _restTimerStatus = RestTimerStatus.completed;
      return;
    }
    _restDeadline = DateTime.now().add(remaining);
    _pausedRemaining = null;
    _restTimerStatus = RestTimerStatus.running;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      refreshRestTimer();
      onRestTimerChanged?.call();
    });
  }

  void skipRestTimer() {
    if (_restTimerStatus != RestTimerStatus.running &&
        _restTimerStatus != RestTimerStatus.paused) {
      return;
    }
    _cancelRestTimer();
    _restDeadline = null;
    _pausedRemaining = null;
    _restTimerStatus = RestTimerStatus.skipped;
  }

  void refreshRestTimer() {
    if (_restTimerStatus != RestTimerStatus.running ||
        restTimeRemaining > Duration.zero) {
      return;
    }
    _cancelRestTimer();
    _restDeadline = null;
    _restTimerStatus = RestTimerStatus.completed;
  }

  void _cancelRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
  }

  void dispose() {
    _cancelRestTimer();
    onRestTimerChanged = null;
  }

  WorkoutSet addSet(int id) {
    final set = WorkoutSet(id: id, number: sets.length + 1);
    sets.add(set);
    return set;
  }

  bool removeSet(WorkoutSet set) {
    if (sets.length == 1 || !sets.remove(set)) return false;
    for (var index = 0; index < sets.length; index++) {
      sets[index].number = index + 1;
    }
    return true;
  }
}

class WorkoutSession extends ChangeNotifier {
  final List<SessionExercise> exercises = [];
  int _nextExerciseId = 0;
  int _nextSetId = 0;

  bool get isEmpty => exercises.isEmpty;
  int get setCount =>
      exercises.fold(0, (count, exercise) => count + exercise.sets.length);

  bool containsExercise(String name) {
    return exercises.any(
      (exercise) => exercise.name.toLowerCase() == name.toLowerCase(),
    );
  }

  SessionExercise? addExercise(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || containsExercise(normalizedName)) return null;

    final exercise = SessionExercise(
      id: _nextExerciseId++,
      name: normalizedName,
      setId: _nextSetId++,
    );
    exercise.onRestTimerChanged = notifyListeners;
    exercises.add(exercise);
    notifyListeners();
    return exercise;
  }

  WorkoutSet addSet(SessionExercise exercise) {
    final set = exercise.addSet(_nextSetId++);
    notifyListeners();
    return set;
  }

  void updateSet(WorkoutSet set, {String? reps, String? weightKg}) {
    if (reps != null) set.reps = reps;
    if (weightKg != null) set.weightKg = weightKg;
    notifyListeners();
  }

  bool removeSet(SessionExercise exercise, WorkoutSet set) {
    if (!exercise.removeSet(set)) return false;
    notifyListeners();
    return true;
  }

  bool get hasUnsavedSets => !isEmpty;

  bool setCompleted(
    SessionExercise exercise,
    WorkoutSet set,
    bool isCompleted,
  ) {
    if (!exercises.contains(exercise) ||
        !exercise.sets.contains(set) ||
        set.isCompleted == isCompleted) {
      return false;
    }
    set.isCompleted = isCompleted;
    if (isCompleted) exercise._startRestTimer();
    notifyListeners();
    return true;
  }

  void setRestDuration(SessionExercise exercise, Duration duration) {
    if (!exercises.contains(exercise) ||
        duration.isNegative ||
        duration > const Duration(minutes: 59, seconds: 59)) {
      return;
    }
    exercise.restDuration = duration;
    notifyListeners();
  }

  void pauseRestTimer(SessionExercise exercise) {
    exercise.pauseRestTimer();
    notifyListeners();
  }

  void resumeRestTimer(SessionExercise exercise) {
    exercise.resumeRestTimer();
    notifyListeners();
  }

  void skipRestTimer(SessionExercise exercise) {
    exercise.skipRestTimer();
    notifyListeners();
  }

  void refreshRestTimers() {
    for (final exercise in exercises) {
      exercise.refreshRestTimer();
    }
    notifyListeners();
  }

  void reset() {
    for (final exercise in exercises) {
      exercise.dispose();
    }
    exercises.clear();
    _nextExerciseId = 0;
    _nextSetId = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final exercise in exercises) {
      exercise.dispose();
    }
    super.dispose();
  }
}
