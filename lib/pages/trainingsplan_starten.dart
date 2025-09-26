import 'package:flutter/material.dart';
import 'dart:async';
import 'constants.dart';
import '../models/trainingsplan.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../database/database_helper.dart';

class TrainingsplanStartenScreen extends StatefulWidget {
  final String trainingName;
  final List<TrainingsplanUebung> uebungen;

  const TrainingsplanStartenScreen({
    Key? key,
    required this.trainingName,
    required this.uebungen,
  }) : super(key: key);

  @override
  TrainingsplanStartenScreenState createState() =>
      TrainingsplanStartenScreenState();
}

class TrainingsplanStartenScreenState
    extends State<TrainingsplanStartenScreen> {
  late List<List<Map<String, dynamic>>> uebungsSaetze;
  late Stopwatch workoutStopwatch;
  Timer? displayTimer;
  String elapsedTime = '00:00:00';

  @override
  void initState() {
    super.initState();
    workoutStopwatch = Stopwatch()..start();
    displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsedTime = _formatDuration(workoutStopwatch.elapsed);
      });
    });
    

    uebungsSaetze = List.generate(widget.uebungen.length, (i) {
      final u = widget.uebungen[i];
      return List.generate(u.saetze, (j) {
        return {
          'gewichtController': TextEditingController(text: u.gewicht.toString()),
          'wdhController': TextEditingController(text: u.wiederholungen.toString()),
        };
      });
    });
  }

  @override
  void dispose() {
    workoutStopwatch.stop();
    displayTimer?.cancel();
    for (var saetze in uebungsSaetze) {
      for (var f in saetze) {
        (f['gewichtController'] as TextEditingController).dispose();
        (f['wdhController'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }


  void _addSatz(int uebungIndex) {
    setState(() {
      final u = widget.uebungen[uebungIndex];
      uebungsSaetze[uebungIndex].add({
        'gewichtController': TextEditingController(text: u.gewicht.toString()),
        'wdhController': TextEditingController(text: u.wiederholungen.toString()),
      });
    });
  }


  void _removeSatz(int uebungIndex, int satzIndex) {
    setState(() {
      if (uebungsSaetze[uebungIndex].length > 1) {

        uebungsSaetze[uebungIndex][satzIndex]['gewichtController'].dispose();
        uebungsSaetze[uebungIndex][satzIndex]['wdhController'].dispose();
        uebungsSaetze[uebungIndex].removeAt(satzIndex);
      }
    });
  }

  Future<void> _saveWorkout() async {
    final db = DatabaseHelper();
    final duration = _formatDuration(workoutStopwatch.elapsed);
    final date = DateTime.now();
    final totalSets = uebungsSaetze.fold<int>(0, (sum, list) => sum + list.length);
    final workout = Workout(date: date, duration: duration, totalSets: totalSets);
    final workoutId = await db.insertWorkout(workout);

    for (var i = 0; i < widget.uebungen.length; i++) {
      final exerciseName = widget.uebungen[i].name;
      final sets = uebungsSaetze[i];
      for (var j = 0; j < sets.length; j++) {
        final reps = int.tryParse(
              (sets[j]['wdhController'] as TextEditingController).text,
            ) ??
            0;
        final weight = double.tryParse(
              (sets[j]['gewichtController'] as TextEditingController).text,
            ) ??
            0.0;
        final ws = WorkoutSet(
          workoutId: workoutId,
          exerciseName: exerciseName,
          setIndex: j + 1,
          reps: reps,
          weight: weight,
        );
        await db.insertWorkoutSet(ws);
      }
    }
  }

  void onTrainingBeenden() async {
    workoutStopwatch.stop();
    displayTimer?.cancel();
    await _saveWorkout();
    final total = elapsedTime;
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Training beendet'),
          content: Text('Training wurde gespeichert: $total'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget buildExerciseBlock(int idx) {
    final u = widget.uebungen[idx];
    final saetze = uebungsSaetze[idx];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(u.name, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: () => _addSatz(idx),
                  tooltip: 'Satz hinzufügen',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: List.generate(saetze.length, (j) {
                final f = saetze[j];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text('Satz ${j + 1}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.red, size: 18),
                            onPressed: () => _removeSatz(idx, j),
                            tooltip: 'Satz entfernen',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      
                      Expanded(
                        child: TextField(
                          controller: f['wdhController'] as TextEditingController,
                          decoration: const InputDecoration(
                            labelText: 'Wdh.',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      Expanded(
                        child: TextField(
                          controller: f['gewichtController'] as TextEditingController,
                          decoration: const InputDecoration(
                            labelText: 'Kg',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Training: ${widget.trainingName}', style: AppTextStyles.heading),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Zeit: $elapsedTime', 
                         style: AppTextStyles.subheading.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: widget.uebungen.length,
                itemBuilder: (_, i) => buildExerciseBlock(i),
              ),
            ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTrainingBeenden,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Training beenden', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}