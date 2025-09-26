// pages/uebungsgruppe_erstellen.dart - Überarbeitet
import 'package:flutter/material.dart';
import 'constants.dart';
import '../database/database_helper.dart';
import '../models/uebungsgruppe.dart';
import '../models/uebung.dart';

class UebungsgruppeErstellen extends StatefulWidget {
  final Uebungsgruppe? gruppe;

  const UebungsgruppeErstellen({super.key, this.gruppe});

  @override
  State<UebungsgruppeErstellen> createState() => _UebungsgruppeErstellenState();
}

class _UebungsgruppeErstellenState extends State<UebungsgruppeErstellen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Uebung> _selectedUebungen = [];
  List<Uebung> _availableUebungen = [];

  @override
  void initState() {
    super.initState();
    _loadUebungen();
    if (widget.gruppe != null) {
      _nameController.text = widget.gruppe!.name;
      _loadGroupUebungen();
    }
  }

  Future<void> _loadUebungen() async {
    final uebungen = await _databaseHelper.getAllUebungen();
    setState(() {
      _availableUebungen = uebungen;
    });
  }

  Future<void> _loadGroupUebungen() async {
    if (widget.gruppe != null) {
      final gruppenUebungen = await _databaseHelper.getUebungenForGruppe(
        widget.gruppe!.id!,
      );
      setState(() {
        _selectedUebungen = gruppenUebungen;
      });
    }
  }

  void _uebungHinzufuegen() async {
    String? neueUebung = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Neue Übung erstellen'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name der Übung'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );

    if (neueUebung != null && neueUebung.isNotEmpty) {
      try {
        final neueUebungObj = Uebung(name: neueUebung);
        final uebungId = await _databaseHelper.insertUebung(neueUebungObj);
        neueUebungObj.id = uebungId;

        setState(() {
          _availableUebungen.add(neueUebungObj);
          _selectedUebungen.add(neueUebungObj);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Erstellen der Übung: $e')),
        );
      }
    }
  }

  void _uebungAusListeHinzufuegen() async {
    final availableUebungen = _availableUebungen
        .where(
          (ueb) => !_selectedUebungen.any((selected) => selected.id == ueb.id),
        )
        .toList();

    if (availableUebungen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine weiteren Übungen verfügbar')),
      );
      return;
    }

    Uebung? auswahl = await showDialog<Uebung>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Übung auswählen'),
          children: availableUebungen.map((uebung) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, uebung),
              child: Text(uebung.name),
            );
          }).toList(),
        );
      },
    );

    if (auswahl != null) {
      setState(() {
        _selectedUebungen.add(auswahl);
      });
    }
  }

  void _removeUebung(int index) {
    setState(() {
      _selectedUebungen.removeAt(index);
    });
  }

  void _editUebung(Uebung uebung) async {
    String? neuerName = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController(
          text: uebung.name,
        );
        return AlertDialog(
          title: const Text('Übung bearbeiten'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Neuer Name der Übung',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    if (neuerName != null && neuerName.isNotEmpty && neuerName != uebung.name) {
      try {
        final updatedUebung = Uebung(
          id: uebung.id,
          name: neuerName,
          beschreibung: uebung.beschreibung,
        );
        await _databaseHelper.updateUebung(updatedUebung);

        setState(() {
          final index = _selectedUebungen.indexWhere((u) => u.id == uebung.id);
          if (index != -1) {
            _selectedUebungen[index] = updatedUebung;
          }

          final availableIndex = _availableUebungen.indexWhere(
            (u) => u.id == uebung.id,
          );
          if (availableIndex != -1) {
            _availableUebungen[availableIndex] = updatedUebung;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Übung erfolgreich bearbeitet')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Bearbeiten: $e')));
      }
    }
  }

  void _saveUebungsgruppe() async {
    if (_formKey.currentState!.validate() && _selectedUebungen.isNotEmpty) {
      try {
        final name = _nameController.text.trim();

        if (widget.gruppe == null) {
          // Neue Gruppe erstellen
          final neueGruppe = Uebungsgruppe(name: name);
          final gruppenId = await _databaseHelper.insertUebungsgruppe(
            neueGruppe,
          );

          // Übungen zur Gruppe hinzufügen
          for (final uebung in _selectedUebungen) {
            await _databaseHelper.addUebungToGruppe(gruppenId, uebung.id!);
          }
        } else {
          // Bestehende Gruppe aktualisieren
          final updatedGruppe = Uebungsgruppe(
            id: widget.gruppe!.id,
            name: name,
          );
          await _databaseHelper.updateUebungsgruppe(updatedGruppe);

          // Übungen aktualisieren
          final currentUebungen = await _databaseHelper.getUebungenForGruppe(
            widget.gruppe!.id!,
          );

          // Übungen entfernen, die nicht mehr ausgewählt sind
          for (final uebung in currentUebungen) {
            if (!_selectedUebungen.any(
              (selected) => selected.id == uebung.id,
            )) {
              await _databaseHelper.removeUebungFromGruppe(
                widget.gruppe!.id!,
                uebung.id!,
              );
            }
          }

          // Neue Übungen hinzufügen
          for (final uebung in _selectedUebungen) {
            if (!currentUebungen.any((current) => current.id == uebung.id)) {
              await _databaseHelper.addUebungToGruppe(
                widget.gruppe!.id!,
                uebung.id!,
              );
            }
          }
        }

        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte Namen eingeben und mindestens eine Übung hinzufügen',
          ),
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
        title: Text(
          widget.gruppe == null
              ? 'Übungsgruppe erstellen'
              : 'Übungsgruppe bearbeiten',
          style: AppTextStyles.heading,
        ),
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
                decoration: const InputDecoration(
                  labelText: 'Name der Übungsgruppe',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Bitte Namen eingeben';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Übung aus Liste hinzufügen'),
                    onPressed: _uebungAusListeHinzufuegen,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.create),
                    label: const Text('Neue Übung erstellen'),
                    onPressed: _uebungHinzufuegen,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedUebungen.length,
                  itemBuilder: (context, index) {
                    final uebung = _selectedUebungen[index];
                    return ListTile(
                      title: Text(uebung.name, style: AppTextStyles.bodyText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editUebung(uebung),
                            tooltip: 'Übung bearbeiten',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeUebung(index),
                            tooltip: 'Übung entfernen',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _saveUebungsgruppe,
                child: Text(
                  widget.gruppe == null ? 'Speichern' : 'Änderungen speichern',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
