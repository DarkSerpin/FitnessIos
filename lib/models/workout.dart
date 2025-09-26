class Workout {
  final int? id;
  final DateTime date;
  final String duration;
  final int totalSets;

  Workout({
    this.id,
    required this.date,
    required this.duration,
    required this.totalSets,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'duration': duration,
      'totalSets': totalSets,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> m) => Workout(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        duration: m['duration'] as String,
        totalSets: m['totalSets'] as int,
      );
}
