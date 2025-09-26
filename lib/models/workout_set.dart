class WorkoutSet {
  final int? id;
  final int workoutId;
  final String exerciseName;
  final int setIndex;
  final int reps;
  final double weight;

  WorkoutSet({
    this.id,
    required this.workoutId,
    required this.exerciseName,
    required this.setIndex,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseName': exerciseName,
      'setIndex': setIndex,
      'reps': reps,
      'weight': weight,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> m) => WorkoutSet(
        id: m['id'] as int?,
        workoutId: m['workoutId'] as int,
        exerciseName: m['exerciseName'] as String,
        setIndex: m['setIndex'] as int,
        reps: m['reps'] as int,
        weight: m['weight'] as double,
      );
}
