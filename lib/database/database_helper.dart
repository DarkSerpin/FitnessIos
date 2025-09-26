import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/uebung.dart';
import '../models/uebungsgruppe.dart';
import '../models/trainingsplan.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'training.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Aktivieren von Foreign Keys
    await db.execute('PRAGMA foreign_keys = ON');
    
    // Tabelle für Workouts
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        duration TEXT NOT NULL,
        totalSets INTEGER NOT NULL
      )
    ''');

    // Tabelle für Workout Sets
    await db.execute('''
      CREATE TABLE workout_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutId INTEGER NOT NULL,
        exerciseName TEXT NOT NULL,
        setIndex INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        FOREIGN KEY(workoutId) REFERENCES workouts(id) ON DELETE CASCADE
      )
    ''');

    // Tabelle für Übungen
    await db.execute('''
      CREATE TABLE uebungen(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        beschreibung TEXT
      )
    ''');

    // Tabelle für Übungsgruppen
    await db.execute('''
      CREATE TABLE uebungsgruppen(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Tabelle für Trainingspläne
    await db.execute('''
      CREATE TABLE trainingsplaene(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        erstellungsdatum INTEGER NOT NULL,
        uebungen TEXT NOT NULL
      )
    ''');

    // Verknüpfungstabelle: Übungen zu Übungsgruppen
    await db.execute('''
      CREATE TABLE uebungsgruppe_uebungen(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uebungsgruppe_id INTEGER NOT NULL,
        uebung_id INTEGER NOT NULL,
        FOREIGN KEY (uebungsgruppe_id) REFERENCES uebungsgruppen (id) ON DELETE CASCADE,
        FOREIGN KEY (uebung_id) REFERENCES uebungen (id) ON DELETE CASCADE
      )
    ''');

    // Verknüpfungstabelle: Übungsgruppen zu Trainingsplänen
    await db.execute('''
      CREATE TABLE trainingsplan_uebungsgruppen(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trainingsplan_id INTEGER NOT NULL,
        uebungsgruppe_id INTEGER NOT NULL,
        FOREIGN KEY (trainingsplan_id) REFERENCES trainingsplaene (id) ON DELETE CASCADE,
        FOREIGN KEY (uebungsgruppe_id) REFERENCES uebungsgruppen (id) ON DELETE CASCADE
      )
    ''');
  }

  // Workout-related methods
  Future<int> insertWorkout(Workout w) async {
    final dbClient = await database;
    return await dbClient.insert('workouts', w.toMap());
  }

  Future<int> insertWorkoutSet(WorkoutSet ws) async {
    final dbClient = await database;
    return await dbClient.insert('workout_sets', ws.toMap());
  }

  Future<List<Workout>> getAllWorkouts() async {
    final dbClient = await database;
    final maps = await dbClient.query('workouts', orderBy: 'date DESC');
    return maps.map((m) => Workout.fromMap(m)).toList();
  }

  Future<List<WorkoutSet>> getSetsForWorkout(int workoutId) async {
    final dbClient = await database;
    final maps = await dbClient.query(
      'workout_sets',
      where: 'workoutId = ?',
      whereArgs: [workoutId],
      orderBy: 'exerciseName, setIndex',
    );
    return maps.map((m) => WorkoutSet.fromMap(m)).toList();
  }

  // Übungsgruppen-related methods
  Future<void> addUebungToGruppe(int gruppeId, int uebungId) async {
    final db = await database;
    await db.insert('uebungsgruppe_uebungen', {
      'uebungsgruppe_id': gruppeId,
      'uebung_id': uebungId,
    });
  }

  Future<List<Uebung>> getUebungenForGruppe(int gruppeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT u.* FROM uebungen u
      INNER JOIN uebungsgruppe_uebungen ugu ON u.id = ugu.uebung_id
      WHERE ugu.uebungsgruppe_id = ?
      ''',
      [gruppeId],
    );
    return List.generate(maps.length, (i) => Uebung.fromMap(maps[i]));
  }

  Future<void> removeUebungFromGruppe(int gruppeId, int uebungId) async {
    final db = await database;
    await db.delete(
      'uebungsgruppe_uebungen',
      where: 'uebungsgruppe_id = ? AND uebung_id = ?',
      whereArgs: [gruppeId, uebungId],
    );
  }

  Future<void> deleteUebungsgruppeWithUebungen(int id) async {
    final db = await database;
    await db.delete(
      'uebungsgruppe_uebungen',
      where: 'uebungsgruppe_id = ?',
      whereArgs: [id],
    );
    await db.delete('uebungsgruppen', where: 'id = ?', whereArgs: [id]);
  }

  // Übungen CRUD
  Future<int> insertUebung(Uebung uebung) async {
    final db = await database;
    return await db.insert('uebungen', uebung.toMap());
  }

  Future<List<Uebung>> getAllUebungen() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('uebungen');
    return List.generate(maps.length, (i) => Uebung.fromMap(maps[i]));
  }

  Future<void> updateUebung(Uebung uebung) async {
    final db = await database;
    await db.update(
      'uebungen',
      uebung.toMap(),
      where: 'id = ?',
      whereArgs: [uebung.id],
    );
  }

  Future<void> deleteUebung(int id) async {
    final db = await database;
    await db.delete('uebungen', where: 'id = ?', whereArgs: [id]);
  }

  // Übungsgruppen CRUD
  Future<int> insertUebungsgruppe(Uebungsgruppe gruppe) async {
    final db = await database;
    return await db.insert('uebungsgruppen', gruppe.toMap());
  }

  Future<List<Uebungsgruppe>> getAllUebungsgruppen() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('uebungsgruppen');
    return List.generate(maps.length, (i) => Uebungsgruppe.fromMap(maps[i]));
  }

  Future<void> updateUebungsgruppe(Uebungsgruppe gruppe) async {
    final db = await database;
    await db.update(
      'uebungsgruppen',
      gruppe.toMap(),
      where: 'id = ?',
      whereArgs: [gruppe.id],
    );
  }

  Future<void> deleteUebungsgruppe(int id) async {
    final db = await database;
    await db.delete('uebungsgruppen', where: 'id = ?', whereArgs: [id]);
  }

  // Trainingspläne CRUD
  Future<int> insertTrainingsplan(Trainingsplan plan) async {
    final db = await database;
    return await db.insert('trainingsplaene', plan.toMap());
  }

  Future<List<Trainingsplan>> getAllTrainingsplaene() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('trainingsplaene');
    return List.generate(maps.length, (i) => Trainingsplan.fromMap(maps[i]));
  }

  Future<void> updateTrainingsplan(Trainingsplan plan) async {
    final db = await database;
    await db.update(
      'trainingsplaene',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<void> deleteTrainingsplan(int id) async {
    final db = await database;
    await db.delete('trainingsplaene', where: 'id = ?', whereArgs: [id]);
  }

  // Übungsgruppe zu Trainingsplan hinzufügen
  Future<void> addUebungsgruppeToTrainingsplan(int trainingsplanId, int gruppeId) async {
    final db = await database;
    await db.insert('trainingsplan_uebungsgruppen', {
      'trainingsplan_id': trainingsplanId,
      'uebungsgruppe_id': gruppeId,
    });
  }

  // Übungsgruppen eines Trainingsplans abrufen
  Future<List<Uebungsgruppe>> getUebungsgruppenForTrainingsplan(int trainingsplanId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT ug.* FROM uebungsgruppen ug
      INNER JOIN trainingsplan_uebungsgruppen tug ON ug.id = tug.uebungsgruppe_id
      WHERE tug.trainingsplan_id = ?
      ''',
      [trainingsplanId],
    );
    return List.generate(maps.length, (i) => Uebungsgruppe.fromMap(maps[i]));
  }

// Gesamtstatistiken für alle Workouts
Future<Map<String, dynamic>> getWorkoutStatistics() async {
  final db = await database;
  
  // Gesamtanzahl der Workouts
  final totalWorkoutsResult = await db.rawQuery(
    'SELECT COUNT(*) as count FROM workouts'
  );
  final totalWorkouts = totalWorkoutsResult.first['count'] as int;
  
  // Gesamttrainingszeit
  final totalDurationResult = await db.rawQuery(
    'SELECT duration FROM workouts'
  );
  
  int totalSeconds = 0;
  for (final row in totalDurationResult) {
    final duration = row['duration'] as String;
    totalSeconds += _durationToSeconds(duration);
  }
  
  // Gesamtes bewegtes Gewicht (Volumen)
  final volumeResult = await db.rawQuery('''
    SELECT SUM(reps * weight) as totalVolume 
    FROM workout_sets
  ''');
  final totalVolume = volumeResult.first['totalVolume'] as double? ?? 0.0;
  
  // Durchschnittliche Sätze pro Workout
  final avgSetsResult = await db.rawQuery(
    'SELECT AVG(totalSets) as avgSets FROM workouts'
  );
  final avgSets = avgSetsResult.first['avgSets'] as double? ?? 0.0;
  
  // Letztes Workout Datum
  final lastWorkoutResult = await db.rawQuery(
    'SELECT date FROM workouts ORDER BY date DESC LIMIT 1'
  );
  DateTime? lastWorkoutDate;
  if (lastWorkoutResult.isNotEmpty) {
    lastWorkoutDate = DateTime.parse(lastWorkoutResult.first['date'] as String);
  }
  
  return {
    'totalWorkouts': totalWorkouts,
    'totalDuration': _secondsToDurationString(totalSeconds),
    'totalVolume': totalVolume,
    'avgSetsPerWorkout': avgSets.round(),
    'lastWorkoutDate': lastWorkoutDate,
    'totalTrainingSeconds': totalSeconds,
  };
}

// Workout-Statistiken über Zeit (für Charts)
Future<List<Map<String, dynamic>>> getWorkoutProgress() async {
  final db = await database;
  
  final result = await db.rawQuery('''
    SELECT 
      date,
      totalSets,
      duration,
      (SELECT SUM(reps * weight) FROM workout_sets WHERE workoutId = workouts.id) as volume
    FROM workouts 
    ORDER BY date ASC
  ''');
  
  return result.map((row) {
    final date = DateTime.parse(row['date'] as String);
    return {
      'date': date,
      'totalSets': row['totalSets'] as int,
      'duration': row['duration'] as String,
      'volume': row['volume'] as double? ?? 0.0,
      'formattedDate': '${date.day}.${date.month}.${date.year}',
    };
  }).toList();
}

// Hilfsfunktion: Duration-String zu Sekunden
int _durationToSeconds(String duration) {
  try {
    final parts = duration.split(':');
    if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return hours * 3600 + minutes * 60 + seconds;
    }
  } catch (e) {
    print('Fehler beim Parsen der Dauer: $duration');
  }
  return 0;
}

// Hilfsfunktion: Sekunden zu Duration-String
String _secondsToDurationString(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
}