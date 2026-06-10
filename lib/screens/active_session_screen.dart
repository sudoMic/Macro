import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import 'exercise_detail_screen.dart';
import 'workout_history_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final WorkoutSession session;
  const ActiveSessionScreen({super.key, required this.session});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {

  Future<void> _openExercise(SessionExercise se, List<SessionExercise> exercises) async {
    final index = exercises.indexWhere((e) => e.id == se.id);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          sessionExercise: se,
          allExercises: exercises,
          currentIndex: index,
        ),
      ),
    );
    final provider = context.read<WorkoutProvider>();
    final updated = provider.activeSession?.exercises
        .firstWhere((e) => e.id == se.id, orElse: () => se);
    if (updated != null && updated.sets.isNotEmpty && !updated.completed) {
      await provider.markExerciseCompleted(se.id!);
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Termina sessione'),
        content: const Text('Vuoi terminare l\'allenamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continua')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Termina')),
        ],
      ),
    );
    if (confirm == true) {
      context.read<WorkoutProvider>().endSession();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final session = provider.activeSession ?? widget.session;
        final exercises = session.exercises;
        final done = exercises.where((e) => e.completed).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(session.workoutName),
            actions: [
              IconButton(
                icon: Image.asset('assets/statistic.png', width: 24),
                tooltip: 'Storico',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutHistoryScreen(
                      planId: session.workoutPlanId,
                      planName: session.workoutName,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _endSession,
                child: const Text('Termina', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: exercises.isEmpty ? 0 : done / exercises.length,
                minHeight: 6,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('$done / ${exercises.length} esercizi completati',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, i) {
                    final se = exercises[i];
                    final maxWeight = se.sets.isEmpty
                        ? null
                        : se.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: se.completed
                            ? Colors.green
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: se.completed
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Text('${i + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      title: Text(se.exerciseName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: se.completed ? TextDecoration.lineThrough : null,
                            color: se.completed ? Colors.grey : null,
                          )),
                      subtitle: maxWeight != null
                          ? Text('max ${maxWeight.toStringAsFixed(1)} kg')
                          : const Text('Nessuna serie'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openExercise(se, exercises),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
