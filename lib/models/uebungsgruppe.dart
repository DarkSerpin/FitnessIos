class Uebungsgruppe {
  final int? id;
  final String name;

  Uebungsgruppe({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Uebungsgruppe.fromMap(Map<String, dynamic> map) {
    return Uebungsgruppe(id: map['id'], name: map['name']);
  }
}
