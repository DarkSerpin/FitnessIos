import 'package:flutter/material.dart';
import 'constants.dart';
import 'trainingsplan_starten.dart';
import '../models/trainingsplan.dart';

class TrainingsplanDetails extends StatelessWidget {
  final String name;
  final List<TrainingsplanUebung> uebungen;

  const TrainingsplanDetails({
    super.key, 
    required this.name, 
    required this.uebungen
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: AppTextStyles.heading),
        backgroundColor: AppColors.background,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: AppPaddings.screenPadding,
        child: ListView.builder(
          itemCount: uebungen.length,
          itemBuilder: (context, index) {
            final uebung = uebungen[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(uebung.name, style: AppTextStyles.bodyText),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Sätze: ${uebung.saetze}',
                      style: AppTextStyles.captionText,
                    ),
                    Text(
                      'Wiederholungen: ${uebung.wiederholungen}',
                      style: AppTextStyles.captionText,
                    ),
                    Text(
                      'Gewicht: ${uebung.gewicht} kg',
                      style: AppTextStyles.captionText,
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text("Training starten"),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrainingsplanStartenScreen(
                  trainingName: name, 
                  uebungen: uebungen,
                ),
                ),
              
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            textStyle: AppTextStyles.heading,
            backgroundColor: AppColors.primaryLight,
          ),
        ),
      ),
    );
  }
}