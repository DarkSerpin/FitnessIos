import 'package:flutter/material.dart';
import 'constants.dart';
import '../database/database_helper.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';

class WorkoutHistorie extends StatefulWidget {
  const WorkoutHistorie({super.key});

  @override
  State<WorkoutHistorie> createState() => _WorkoutHistorieState();
}

class _WorkoutHistorieState extends State<WorkoutHistorie> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Workout> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final workouts = await _databaseHelper.getAllWorkouts();
    setState(() {
      _workouts = workouts;
    });
  }

  Future<List<WorkoutSet>> _getWorkoutSets(int workoutId) async {
    return await _databaseHelper.getSetsForWorkout(workoutId);
  }

  void _showWorkoutDetails(Workout workout) async {
    final sets = await _getWorkoutSets(workout.id!);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workout Details',
                  style: AppTextStyles.heading,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Datum: ${_formatDate(workout.date)}'),
            Text('Dauer: ${workout.duration}'),
            Text('Gesamte Sätze: ${workout.totalSets}'),
            const SizedBox(height: 16),
            const Text('Übungen:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sets.length,
                itemBuilder: (context, index) {
                  final set = sets[index];
                  return ListTile(
                    title: Text(set.exerciseName),
                    subtitle: Text('Satz ${set.setIndex}: ${set.reps} Wdh. × ${set.weight}kg'),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Historie', style: AppTextStyles.heading),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: AppPaddings.screenPadding,
        child: _workouts.isEmpty
            ? const Center(
                child: Text(
                  'Noch keine Workouts aufgezeichnet.\nStarte dein erstes Training!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyText,
                ),
              )
            : ListView.builder(
                itemCount: _workouts.length,
                itemBuilder: (context, index) {
                  final workout = _workouts[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(_formatDate(workout.date), style: AppTextStyles.bodyText),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dauer: ${workout.duration}'),
                          Text('Sätze: ${workout.totalSets}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showWorkoutDetails(workout),
                    ),
                  );
                },
              ),
      ),
    );
  }
}