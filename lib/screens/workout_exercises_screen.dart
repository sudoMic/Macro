import 'package:flutter/material.dart';
import '../models/workout.dart';
import 'workout_history_screen.dart';

/// Mostra gli esercizi di un piano in sola lettura + accesso allo storico.
class WorkoutExercisesScreen extends StatelessWidget {
  final WorkoutPlan plan;
  const WorkoutExercisesScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        actions: [
          IconButton(
            icon: Image.asset('assets/statistic.png', width: 24),
            tooltip: 'Storico',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutHistoryScreen(
                  planId: plan.id!,
                  planName: plan.name,
                ),
              ),
            ),
          ),
        ],
      ),
      body: plan.exercises.isEmpty
          ? const Center(
              child: Text(
                'Nessun esercizio in questo workout.\nModificalo per aggiungerne.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plan.exercises.length,
              itemBuilder: (context, i) {
                final ex = plan.exercises[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(ex.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: ex.category.isNotEmpty ? Text(ex.category) : null,
                  ),
                );
              },
            ),
    );
  }
}
