/// Singola serie di un esercizio: peso, ripetizioni, note opzionali.
class ExerciseSet {
  final int? id;
  final int sessionExerciseId;
  final int setNumber;
  final double weight; // kg
  final int reps;
  final String notes;

  const ExerciseSet({
    this.id,
    required this.sessionExerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.notes = '',
  });

  factory ExerciseSet.fromDb(Map<String, dynamic> row) => ExerciseSet(
        id: row['id'] as int?,
        sessionExerciseId: row['session_exercise_id'] as int,
        setNumber: row['set_number'] as int,
        weight: (row['weight'] as num).toDouble(),
        reps: row['reps'] as int,
        notes: row['notes'] as String? ?? '',
      );

  Map<String, dynamic> toDb() => {
        if (id != null) 'id': id,
        'session_exercise_id': sessionExerciseId,
        'set_number': setNumber,
        'weight': weight,
        'reps': reps,
        'notes': notes,
      };

  ExerciseSet copyWith({double? weight, int? reps, String? notes}) => ExerciseSet(
        id: id,
        sessionExerciseId: sessionExerciseId,
        setNumber: setNumber,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        notes: notes ?? this.notes,
      );
}

/// Esercizio all'interno di una sessione con tutte le sue serie.
class SessionExercise {
  final int? id;
  final int sessionId;
  final int exerciseId;
  final String exerciseName;
  final bool completed;
  final List<ExerciseSet> sets;

  const SessionExercise({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.exerciseName,
    this.completed = false,
    this.sets = const [],
  });

  factory SessionExercise.fromDb(Map<String, dynamic> row,
      {List<ExerciseSet> sets = const []}) =>
      SessionExercise(
        id: row['id'] as int?,
        sessionId: row['session_id'] as int,
        exerciseId: row['exercise_id'] as int,
        exerciseName: row['exercise_name'] as String,
        completed: (row['completed'] as int) == 1,
        sets: sets,
      );

  Map<String, dynamic> toDb() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'completed': completed ? 1 : 0,
      };

  SessionExercise copyWith({bool? completed, List<ExerciseSet>? sets}) =>
      SessionExercise(
        id: id,
        sessionId: sessionId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        completed: completed ?? this.completed,
        sets: sets ?? this.sets,
      );
}

/// Una sessione di allenamento eseguita (corrisponde a un WorkoutPlan eseguito in una data).
class WorkoutSession {
  final int? id;
  final int workoutPlanId;
  final String workoutName;
  final DateTime date;
  final List<SessionExercise> exercises;

  const WorkoutSession({
    this.id,
    required this.workoutPlanId,
    required this.workoutName,
    required this.date,
    this.exercises = const [],
  });

  factory WorkoutSession.fromDb(Map<String, dynamic> row,
      {List<SessionExercise> exercises = const []}) =>
      WorkoutSession(
        id: row['id'] as int?,
        workoutPlanId: row['workout_plan_id'] as int,
        workoutName: row['workout_name'] as String,
        date: DateTime.parse(row['date'] as String),
        exercises: exercises,
      );

  Map<String, dynamic> toDb() => {
        if (id != null) 'id': id,
        'workout_plan_id': workoutPlanId,
        'workout_name': workoutName,
        'date': date.toIso8601String().substring(0, 10),
      };
}

/// Esercizio nella lista predefinita/custom.
class Exercise {
  final int? id;
  final String name;
  final String category; // es. "Petto", "Gambe", "Schiena", ecc.
  final bool isCustom;

  const Exercise({
    this.id,
    required this.name,
    required this.category,
    this.isCustom = false,
  });

  factory Exercise.fromDb(Map<String, dynamic> row) => Exercise(
        id: row['id'] as int?,
        name: row['name'] as String,
        category: row['category'] as String,
        isCustom: (row['is_custom'] as int) == 1,
      );

  Map<String, dynamic> toDb() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'is_custom': isCustom ? 1 : 0,
      };
}

/// Piano di allenamento (es. "Gambe", "Upper").
class WorkoutPlan {
  final int? id;
  final String name;
  final List<Exercise> exercises;

  const WorkoutPlan({
    this.id,
    required this.name,
    this.exercises = const [],
  });

  factory WorkoutPlan.fromDb(Map<String, dynamic> row,
      {List<Exercise> exercises = const []}) =>
      WorkoutPlan(
        id: row['id'] as int?,
        name: row['name'] as String,
        exercises: exercises,
      );

  Map<String, dynamic> toDb() => {
        if (id != null) 'id': id,
        'name': name,
      };
}
