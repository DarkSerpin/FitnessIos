import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'constants.dart';
import '../database/database_helper.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';

class Statistiken extends StatefulWidget {
  const Statistiken({super.key});

  @override
  State<Statistiken> createState() => _StatistikenState();
}

class _StatistikenState extends State<Statistiken> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Workout> _workouts = [];
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _progressData = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final workouts = await _databaseHelper.getAllWorkouts();
    final statistics = await _databaseHelper.getWorkoutStatistics();
    final progressData = await _databaseHelper.getWorkoutProgress();
    
    setState(() {
      _workouts = workouts;
      _statistics = statistics;
      _progressData = progressData;
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
            Text('Datum: ${_formatDate(workout.date)}', style: AppTextStyles.bodyText),
            Text('Dauer: ${workout.duration}', style: AppTextStyles.bodyText),
            Text('Gesamte Sätze: ${workout.totalSets}', style: AppTextStyles.bodyText),
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
                    title: Text(set.exerciseName, style: AppTextStyles.bodyText),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.captionText),
            Text(value, style: AppTextStyles.heading.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_progressData.length < 2) {
      return const Center(
        child: Text('Nicht genug Daten für Fortschrittsansicht'),
      );
    }

    final monthlyData = _progressData.groupListsBy((data) {
      final date = data['date'] as DateTime;
      return '${date.year}-${date.month}';
    }).entries.map((entry) {
      final monthData = entry.value;
      final totalVolume = monthData.map((d) => d['volume'] as double).sum;
      final totalSets = monthData.map((d) => d['totalSets'] as int).sum;
      final totalWorkouts = monthData.length;
      
      int totalSeconds = 0;
      for (final data in monthData) {
        final duration = data['duration'] as String;
        final parts = duration.split(':');
        if (parts.length == 3) {
          totalSeconds += int.parse(parts[0]) * 3600 + 
                         int.parse(parts[1]) * 60 + 
                         int.parse(parts[2]);
        }
      }
      
      final date = monthData.first['date'] as DateTime;
      return {
        'month': '${date.month}/${date.year}',
        'volume': totalVolume,
        'sets': totalSets,
        'workouts': totalWorkouts,
        'duration': totalSeconds,
      };
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: monthlyData.length,
      itemBuilder: (context, index) {
        final data = monthlyData[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['month'] as String, 
                    style: AppTextStyles.subheading),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Workouts: ${data['workouts']}'),
                    Text('Sätze: ${data['sets']}'),
                    Text('Volumen: ${(data['volume'] as double).toStringAsFixed(0)}kg'),
                  ],
                ),
                LinearProgressIndicator(
                  value: (data['volume'] as double) / 
                         (monthlyData.map((d) => d['volume'] as double).max * 1.1),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken', style: AppTextStyles.heading),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Übersicht', icon: Icon(Icons.dashboard)),
            Tab(text: 'Historie', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: AppPaddings.screenPadding,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildStatCard(
                        'Workouts',
                        _statistics['totalWorkouts']?.toString() ?? '0',
                        Icons.fitness_center,
                        AppColors.primary,
                      ),
                      _buildStatCard(
                        'Trainingszeit',
                        _statistics['totalDuration']?.toString() ?? '00:00:00',
                        Icons.timer,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Bewegtes Gewicht',
                        '${((_statistics['totalVolume'] as double?) ?? 0.0).toStringAsFixed(0)}kg',
                        Icons.line_weight,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Ø Sätze/Workout',
                        _statistics['avgSetsPerWorkout']?.toString() ?? '0',
                        Icons.format_list_numbered,
                        Colors.purple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monatlicher Fortschritt', 
                              style: AppTextStyles.subheading),
                          const SizedBox(height: 12),
                          _buildProgressChart(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
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
                          title: Text(_formatDate(workout.date), 
                                    style: AppTextStyles.bodyText),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}