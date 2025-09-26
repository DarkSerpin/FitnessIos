import 'dart:convert';

class TrainingsplanUebung {
  final String name;
  final int saetze;
  final int wiederholungen;
  final double gewicht;

  TrainingsplanUebung({
    required this.name,
    required this.saetze,
    required this.wiederholungen,
    required this.gewicht,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'saetze': saetze,
      'wiederholungen': wiederholungen,
      'gewicht': gewicht,
    };
  }

  static TrainingsplanUebung fromMap(Map<String, dynamic> map) {
    return TrainingsplanUebung(
      name: map['name'],
      saetze: map['saetze'],
      wiederholungen: map['wiederholungen'],
      gewicht: map['gewicht']?.toDouble() ?? 0.0,
    );
  }
}

class Trainingsplan {
  int? id;
  String name;
  List<TrainingsplanUebung> uebungen;
  DateTime erstellungsdatum;

  Trainingsplan({
    this.id,
    required this.name,
    required this.uebungen,
    required this.erstellungsdatum,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'uebungen': jsonEncode(uebungen.map((u) => u.toMap()).toList()),
      'erstellungsdatum': erstellungsdatum.millisecondsSinceEpoch,
    };
  }

  static Trainingsplan fromMap(Map<String, dynamic> map) {
    List<TrainingsplanUebung> uebungen = [];
    
    if (map['uebungen'] != null && map['uebungen'].isNotEmpty) {
      try {
        final List<dynamic> uebungenList = jsonDecode(map['uebungen']);
        uebungen = uebungenList.map((u) => TrainingsplanUebung.fromMap(u)).toList();
      } catch (e) {
        print('Fehler beim Parsen der Übungen: $e');
        uebungen = [];
      }
    }

    return Trainingsplan(
      id: map['id'],
      name: map['name'],
      uebungen: uebungen,
      erstellungsdatum: DateTime.fromMillisecondsSinceEpoch(map['erstellungsdatum']),
    );
  }
}