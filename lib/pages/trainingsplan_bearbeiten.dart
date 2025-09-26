import 'package:flutter/material.dart';
import 'constants.dart';
import '../database/database_helper.dart';
import '../models/trainingsplan.dart';
import '../models/uebungsgruppe.dart';
import '../models/uebung.dart';

class TrainingsplanBearbeiten extends StatefulWidget {
  final Trainingsplan trainingsplan;

  const TrainingsplanBearbeiten({super.key, required this.trainingsplan});

  @override
  State<TrainingsplanBearbeiten> createState() => _TrainingsplanBearbeitenState();
}

class _TrainingsplanBearbeitenState extends State<TrainingsplanBearbeiten> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Uebungsgruppe> _uebungsgruppen = [];
  Map<int, List<Uebung>> _uebungenPerGruppe = {};
  late List<TrainingsplanUebung> _selectedUebungen;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trainingsplan.name);
    _selectedUebungen = List.from(widget.trainingsplan.uebungen);
    _loadUebungsgruppen();
  }

  Future<void> _loadUebungsgruppen() async {
    final gruppen = await _databaseHelper.getAllUebungsgruppen();
    Map<int, List<Uebung>> uebungenMap = {};
    
    for (var gruppe in gruppen) {
      final uebungen = await _databaseHelper.getUebungenForGruppe(gruppe.id!);
      uebungenMap[gruppe.id!] = uebungen;
    }

    setState(() {
      _uebungsgruppen = gruppen;
      _uebungenPerGruppe = uebungenMap;
    });
  }

  Future<void> _showGruppenDialog() async {
    if (_uebungsgruppen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Übungsgruppen verfügbar')),
      );
      return;
    }

    Uebungsgruppe? selectedGroup = await showDialog<Uebungsgruppe>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Übungsgruppe wählen'),
          children: _uebungsgruppen.map((gruppe) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, gruppe),
              child: Text(gruppe.name),
            );
          }).toList(),
        );
      },
    );

    if (selectedGroup != null) {
      _showUebungenDialog(selectedGroup);
    }
  }

  Future<void> _showUebungenDialog(Uebungsgruppe gruppe) async {
    final uebungen = _uebungenPerGruppe[gruppe.id] ?? [];
    
    if (uebungen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keine Übungen in ${gruppe.name}')),
      );
      return;
    }

    Uebung? selectedUebung = await showDialog<Uebung>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Übung aus ${gruppe.name} wählen'),
          children: uebungen.map((uebung) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, uebung),
              child: Text(uebung.name),
            );
          }).toList(),
        );
      },
    );

    if (selectedUebung != null) {
      _showUebungsDetailsDialog(selectedUebung);
    }
  }

  Future<void> _showUebungsDetailsDialog(Uebung uebung) async {
    final TextEditingController saetzeController = TextEditingController(text: '3');
    final TextEditingController wdhController = TextEditingController(text: '10');
    final TextEditingController gewichtController = TextEditingController(text: '0');

    final result = await showDialog<TrainingsplanUebung>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Details für ${uebung.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: saetzeController,
                decoration: const InputDecoration(labelText: 'Anzahl Sätze'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: wdhController,
                decoration: const InputDecoration(labelText: 'Wiederholungen pro Satz'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gewichtController,
                decoration: const InputDecoration(labelText: 'Gewicht (kg)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final saetze = int.tryParse(saetzeController.text) ?? 1;
                final wiederholungen = int.tryParse(wdhController.text) ?? 1;
                final gewicht = double.tryParse(gewichtController.text) ?? 0.0;

                final trainingsplanUebung = TrainingsplanUebung(
                  name: uebung.name,
                  saetze: saetze,
                  wiederholungen: wiederholungen,
                  gewicht: gewicht,
                );

                Navigator.pop(context, trainingsplanUebung);
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedUebungen.add(result);
      });
    }
  }

  Future<void> _showEditUebungsDetailsDialog(int index) async {
    final uebung = _selectedUebungen[index];
    final TextEditingController saetzeController = TextEditingController(text: uebung.saetze.toString());
    final TextEditingController wdhController = TextEditingController(text: uebung.wiederholungen.toString());
    final TextEditingController gewichtController = TextEditingController(text: uebung.gewicht.toString());

    final result = await showDialog<TrainingsplanUebung>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${uebung.name} bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: saetzeController,
                decoration: const InputDecoration(labelText: 'Anzahl Sätze'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: wdhController,
                decoration: const InputDecoration(labelText: 'Wiederholungen pro Satz'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gewichtController,
                decoration: const InputDecoration(labelText: 'Gewicht (kg)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final saetze = int.tryParse(saetzeController.text) ?? 1;
                final wiederholungen = int.tryParse(wdhController.text) ?? 1;
                final gewicht = double.tryParse(gewichtController.text) ?? 0.0;

                final updatedUebung = TrainingsplanUebung(
                  name: uebung.name,
                  saetze: saetze,
                  wiederholungen: wiederholungen,
                  gewicht: gewicht,
                );

                Navigator.pop(context, updatedUebung);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedUebungen[index] = result;
      });
    }
  }

  void _removeUebung(int index) {
    setState(() {
      _selectedUebungen.removeAt(index);
    });
  }

  void _savePlan() async {
    if (_formKey.currentState!.validate() && _selectedUebungen.isNotEmpty) {
      final name = _nameController.text.trim();
      
      try {
        final updatedPlan = Trainingsplan(
          id: widget.trainingsplan.id,
          name: name,
          uebungen: _selectedUebungen,
          erstellungsdatum: widget.trainingsplan.erstellungsdatum,
        );
        
        await _databaseHelper.updateTrainingsplan(updatedPlan);
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Namen eingeben und mindestens eine Übung auswählen'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainingsplan bearbeiten', style: AppTextStyles.heading),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
      ),
      body: Padding(
        padding: AppPaddings.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Trainingsplan Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte Namen eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _showGruppenDialog,
                icon: const Icon(Icons.add),
                label: const Text('Übung hinzufügen'),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedUebungen.length,
                  itemBuilder: (context, index) {
                    final uebung = _selectedUebungen[index];
                    return Card(
                      child: ListTile(
                        title: Text(uebung.name, style: AppTextStyles.bodyText),
                        subtitle: Text(
                          '${uebung.saetze} Sätze × ${uebung.wiederholungen} Wdh. @ ${uebung.gewicht}kg',
                          style: AppTextStyles.captionText,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditUebungsDetailsDialog(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeUebung(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _savePlan,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Änderungen speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
