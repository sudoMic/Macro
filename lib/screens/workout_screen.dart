import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';
import 'workout_plan_screen.dart';
import 'active_session_screen.dart';
import 'workout_history_screen.dart';
import 'workout_exercises_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadPlans();
    });
  }

  Future<void> _createPlan() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuovo workout'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Es. Gambe, Upper, Full Body...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Crea'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await context.read<WorkoutProvider>().createPlan(name);
    }
  }

  Future<void> _confirmDelete(WorkoutPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina workout'),
        content: Text('Vuoi eliminare "${plan.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && plan.id != null) {
      await context.read<WorkoutProvider>().deletePlan(plan.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 22,
          ),
        ),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          final activeSession = provider.activeSession;

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Banner sessione attiva
              if (activeSession != null)
                GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ActiveSessionScreen(session: activeSession))),
                  child: Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sessione in corso: ${activeSession.workoutName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: provider.plans.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessun workout.\nPremi + per crearne uno.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        buildDefaultDragHandles: false,
                        itemCount: provider.plans.length,
                        onReorder: (oldIndex, newIndex) {
                          provider.reorderPlans(oldIndex, newIndex);
                        },
                        itemBuilder: (context, i) {
                          final plan = provider.plans[i];
                          return Card(
                            key: ValueKey(plan.id),
                            child: ListTile(
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutExercisesScreen(plan: plan))),
                              onLongPress: () => _confirmDelete(plan),
                              leading: ReorderableDragStartListener(
                                index: i,
                                child: const Icon(Icons.drag_handle, color: Colors.grey),
                              ),
                              title: Text(plan.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${plan.exercises.length} esercizi'),
                              trailing: Transform.translate(
                                offset: const Offset(16, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                                      tooltip: 'Avvia',
                                      onPressed: () async {
                                        await provider.startSession(plan);
                                        if (context.mounted) {
                                          Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => ActiveSessionScreen(
                                              session: provider.activeSession!),
                                          ));
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Modifica',
                                      onPressed: () => Navigator.push(context,
                                        MaterialPageRoute(
                                          builder: (_) => WorkoutPlanScreen(plan: plan))),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlan,
        child: const Icon(Icons.add),
      ),
    );
  }
}
