class Uebung {
  int? id;
  final String name;
  final String? beschreibung;

  Uebung({this.id, required this.name, this.beschreibung});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'beschreibung': beschreibung};
  }

  factory Uebung.fromMap(Map<String, dynamic> map) {
    return Uebung(
      id: map['id'],
      name: map['name'],
      beschreibung: map['beschreibung'],
    );
  }
}
