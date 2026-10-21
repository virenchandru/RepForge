import 'package:flutter/foundation.dart';

class WorkoutSet {
  WorkoutSet({required this.id, required this.number});

  final int id;
  int number;
  String reps = '';
  String weightKg = '';
}

class SessionExercise {
  SessionExercise({required this.id, required this.name, required int setId})
    : sets = [WorkoutSet(id: setId, number: 1)];

  final int id;
  final String name;
  final List<WorkoutSet> sets;

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

  void reset() {
    exercises.clear();
    _nextExerciseId = 0;
    _nextSetId = 0;
    notifyListeners();
  }
}
