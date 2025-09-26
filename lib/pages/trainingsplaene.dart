import 'package:flutter/material.dart';
import 'constants.dart';
import 'trainingsplan_erstellen.dart';
import 'trainingsplan_bearbeiten.dart';
import 'trainingsplandetails.dart';
import '../models/trainingsplan.dart';
import '../database/database_helper.dart';

class Trainingsplaene extends StatefulWidget {
  const Trainingsplaene({super.key});

  @override
  State<Trainingsplaene> createState() => _TrainingsplaeneState();
}

class _TrainingsplaeneState extends State<Trainingsplaene> {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  List<Trainingsplan> trainingsplaene = [];
  bool _isMenuOpen = false;
  bool _isDeleteMode = false;
  bool _isEditMode = false;
  List<int> selectedPlans = [];

  @override
  void initState() {
    super.initState();
    loadTrainingsplaene();
  }

  Future<void> loadTrainingsplaene() async {
    final plaene = await databaseHelper.getAllTrainingsplaene();
    setState(() {
      trainingsplaene = plaene;
    });
  }

  Future<void> deleteTrainingsplan(int id) async {
    await databaseHelper.deleteTrainingsplan(id);
    loadTrainingsplaene();
  }

  Future<void> deleteSelectedPlans() async {
    for (int id in selectedPlans) {
      await databaseHelper.deleteTrainingsplan(id);
    }
    setState(() {
      selectedPlans.clear();
    });
    loadTrainingsplaene();
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      if (!_isDeleteMode) {
        selectedPlans.clear();
      }
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        selectedPlans.clear();
      }
    });
  }

  void _navigateToCreatePlan() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TrainingsplanErstellen()),
    );
    if (result == true) {
      loadTrainingsplaene();
    }
  }

  void _navigateToEditPlan() async {
    if (selectedPlans.length == 1) {
      final planToEdit = trainingsplaene.firstWhere((p) => p.id == selectedPlans.first);
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrainingsplanBearbeiten(trainingsplan: planToEdit),
        ),
      );
      if (result == true) {
        loadTrainingsplaene();
        setState(() {
          _isEditMode = false;
          selectedPlans.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isDeleteMode
              ? 'Löschen (${selectedPlans.length})'
              : _isEditMode
                  ? 'Bearbeiten (${selectedPlans.length})'
                  : 'Trainingspläne',
          style: AppTextStyles.heading,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: AppPaddings.screenPadding,
        child: trainingsplaene.isEmpty
            ? const Center(
                child: Text(
                  'Keine Trainingspläne vorhanden.\nErstelle deinen ersten Plan!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyText,
                ),
              )
            : ListView.builder(
                itemCount: trainingsplaene.length,
                itemBuilder: (context, index) {
                  final plan = trainingsplaene[index];
                  final isSelected = selectedPlans.contains(plan.id);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isSelected ? AppColors.primaryLight : null,
                    child: ListTile(
                      title: Text(plan.name, style: AppTextStyles.bodyText),
                      subtitle: Text(
                        '${plan.uebungen.length} Übungen',
                        style: AppTextStyles.captionText,
                      ),
                      leading: _isDeleteMode || _isEditMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedPlans.add(plan.id!);
                                  } else {
                                    selectedPlans.remove(plan.id);
                                  }
                                });
                              },
                            )
                          : null,
                      trailing: !_isDeleteMode && !_isEditMode
                          ? const Icon(Icons.arrow_forward_ios, size: 16)
                          : null,
                      onTap: () {
                        if (_isDeleteMode || _isEditMode) {
                          setState(() {
                            if (selectedPlans.contains(plan.id)) {
                              selectedPlans.remove(plan.id);
                            } else {
                              selectedPlans.add(plan.id!);
                            }
                          });
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TrainingsplanDetails(
                                name: plan.name,
                                uebungen: plan.uebungen,
                              ),
                              ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isMenuOpen) ...[
            if (_isDeleteMode && selectedPlans.isNotEmpty) ...[
              FloatingActionButton.extended(
                heroTag: 'confirmDelete',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Bestätigen'),
                      content: Text(
                        'Möchtest du ${selectedPlans.length} Trainingsplan(e) löschen?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Abbrechen'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Löschen'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await deleteSelectedPlans();
                    _toggleDeleteMode();
                  }
                },
                icon: const Icon(Icons.delete_forever, color: AppColors.primary),
                label: const Text('Löschen bestätigen', style: TextStyle(color: AppColors.primary)),
                backgroundColor: AppColors.primaryLight,
              ),
              const SizedBox(height: 8),
            ] else if (_isEditMode && selectedPlans.length == 1) ...[
              FloatingActionButton.extended(
                heroTag: 'confirmEdit',
                onPressed: _navigateToEditPlan,
                icon: const Icon(Icons.edit, color: AppColors.primary),
                label: const Text('Bearbeiten', style: TextStyle(color: AppColors.primary)),
                backgroundColor: AppColors.primaryLight,
              ),
              const SizedBox(height: 8),
            ] else if (!_isDeleteMode && !_isEditMode) ...[
              FloatingActionButton.extended(
                heroTag: 'add',
                onPressed: _navigateToCreatePlan,
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('Trainingsplan hinzufügen', style: TextStyle(color: AppColors.primary)),
                backgroundColor: AppColors.primaryLight,
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'edit',
                onPressed: _toggleEditMode,
                icon: const Icon(Icons.edit, color: AppColors.primary),
                label: const Text('Trainingsplan bearbeiten', style: TextStyle(color: AppColors.primary)),
                backgroundColor: AppColors.primaryLight,
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'delete',
                onPressed: _toggleDeleteMode,
                icon: const Icon(Icons.delete, color: AppColors.primary),
                label: const Text('Trainingsplan löschen', style: TextStyle(color: AppColors.primary)),
                backgroundColor: AppColors.primaryLight,
              ),
              const SizedBox(height: 8),
            ],
          ],
          FloatingActionButton(
            heroTag: 'toggle',
            onPressed: () {
              setState(() {
                _isMenuOpen = !_isMenuOpen;
                if (!_isMenuOpen) {
                  _isDeleteMode = false;
                  _isEditMode = false;
                  selectedPlans.clear();
                }
              });
            },
            child: Icon(_isMenuOpen ? Icons.close : Icons.menu),
            backgroundColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}
