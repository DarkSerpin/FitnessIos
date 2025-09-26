import 'package:flutter/material.dart';
import 'constants.dart';
import 'uebungsgruppe_erstellen.dart';
import '../database/database_helper.dart';
import '../models/uebungsgruppe.dart';
import '../models/uebung.dart';

class UebungenSeite extends StatefulWidget {
  const UebungenSeite({super.key});

  @override
  State<UebungenSeite> createState() => _UebungenSeiteState();
}

class _UebungenSeiteState extends State<UebungenSeite> {
  bool _isMenuOpen = false;
  bool _isDeleteMode = false;
  bool _isEditMode = false;
  List<int> _selectedGroups = [];

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Uebungsgruppe> _uebungsgruppen = [];
  Map<int, List<Uebung>> _uebungenPerGruppe = {};

  @override
  void initState() {
    super.initState();
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

  Future<void> _deleteUebungsgruppe(int id) async {
    await _databaseHelper.deleteUebungsgruppeWithUebungen(id);
    _loadUebungsgruppen();
  }

  Future<void> _deleteSelectedGroups() async {
    if (_selectedGroups.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Löschen bestätigen'),
          content: Text(
            _selectedGroups.length == 1
                ? 'Möchten Sie diese Übungsgruppe wirklich löschen?'
                : 'Möchten Sie diese ${_selectedGroups.length} Übungsgruppen wirklich löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Löschen', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      for (final id in _selectedGroups) {
        await _deleteUebungsgruppe(id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedGroups.length == 1
                ? 'Übungsgruppe wurde gelöscht'
                : '${_selectedGroups.length} Übungsgruppen wurden gelöscht',
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isDeleteMode = false;
        _selectedGroups.clear();
      });
    }
  }

  void _toggleGroupSelection(int id) {
    setState(() {
      if (_selectedGroups.contains(id)) {
        _selectedGroups.remove(id);
      } else {
        _selectedGroups.add(id);
      }
    });
  }

  void _cancelDeleteMode() {
    setState(() {
      _isDeleteMode = false;
      _selectedGroups.clear();
    });
  }

  void _startEditMode() {
    setState(() {
      _isEditMode = true;
      _isMenuOpen = false;
    });
  }

  void _cancelEditMode() {
    setState(() {
      _isEditMode = false;
      _selectedGroups.clear();
    });
  }

  void _editUebungsgruppe(Uebungsgruppe gruppe) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => UebungsgruppeErstellen(gruppe: gruppe),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadUebungsgruppen();
          }
          _cancelEditMode();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isDeleteMode
            ? Text(
                '${_selectedGroups.length} ausgewählt',
                style: AppTextStyles.heading,
              )
            : _isEditMode
            ? const Text('Gruppe bearbeiten', style: AppTextStyles.heading)
            : const Text('Übungsgruppen', style: AppTextStyles.heading),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: _isDeleteMode || _isEditMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isDeleteMode ? _cancelDeleteMode : _cancelEditMode,
              )
            : null,
        actions: _isDeleteMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedGroups.isNotEmpty
                      ? _deleteSelectedGroups
                      : null,
                  tooltip: 'Ausgewählte löschen',
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: AppPaddings.screenPadding,
        child: ListView.builder(
          itemCount: _uebungsgruppen.length,
          itemBuilder: (context, index) {
            final gruppe = _uebungsgruppen[index];
            final uebungen = _uebungenPerGruppe[gruppe.id] ?? [];
            final isSelected = _selectedGroups.contains(gruppe.id);

            return GestureDetector(
              onTap: _isEditMode ? () => _editUebungsgruppe(gruppe) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isDeleteMode)
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) =>
                                _toggleGroupSelection(gruppe.id!),
                          )
                        else if (_isEditMode)
                          const Icon(
                            Icons.edit,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        Expanded(
                          child: Text(
                            gruppe.name,
                            style: AppTextStyles.subheading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...uebungen.map(
                      (uebung) => Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Text(
                          '• ${uebung.name}',
                          style: AppTextStyles.bodyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isMenuOpen && !_isDeleteMode && !_isEditMode) ...[
            FloatingActionButton.extended(
              icon: const Icon(Icons.delete, color: AppColors.primary),
              label: const Text(
                'Übungsgruppe löschen',
                style: TextStyle(color: AppColors.primary),
              ),
              heroTag: 'delete-group',
              backgroundColor: AppColors.primaryLight,
              onPressed: () {
                setState(() {
                  _isDeleteMode = true;
                  _isMenuOpen = false;
                });
              },
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              label: const Text(
                'Übungsgruppe bearbeiten',
                style: TextStyle(color: AppColors.primary),
              ),
              heroTag: 'edit-group',
              backgroundColor: AppColors.primaryLight,
              onPressed: _startEditMode,
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text(
                'Übungsgruppe hinzufügen',
                style: TextStyle(color: AppColors.primary),
              ),
              heroTag: 'add-group',
              backgroundColor: AppColors.primaryLight,
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UebungsgruppeErstellen(),
                  ),
                );
                if (result == true) {
                  _loadUebungsgruppen();
                }
                setState(() {
                  _isMenuOpen = false;
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          if (!_isDeleteMode && !_isEditMode) ...[
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isMenuOpen = !_isMenuOpen;
                });
              },
              child: Icon(_isMenuOpen ? Icons.close : Icons.menu),
              backgroundColor: AppColors.primaryLight,
              heroTag: 'main-fab-uebungen',
            ),
          ],
        ],
      ),
    );
  }
}
