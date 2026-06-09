import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../services/database_service.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  final int planId;
  final String planName;
  const WorkoutHistoryScreen({super.key, required this.planId, required this.planName});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<WorkoutSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await context.read<DatabaseService>().getSessionsForPlan(widget.planId);
    // Carica anche i dettagli di ogni sessione
    final detailed = <WorkoutSession>[];
    for (final s in sessions) {
      final full = await context.read<DatabaseService>().getSession(s.id!);
      if (full != null) detailed.add(full);
    }
    setState(() { _sessions = detailed; _isLoading = false; });
  }

  Future<void> _confirmDeleteSession(WorkoutSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina sessione'),
        content: Text('Vuoi eliminare l\'allenamento del ${_formatDate(session.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<DatabaseService>().deleteSession(session.id!);
      await _load();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Oggi';
    if (d == today.subtract(const Duration(days: 1))) return 'Ieri';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Storico — ${widget.planName}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(
                  child: Text('Nessuna sessione registrata.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, i) {
                    final session = _sessions[i];
                    final done = session.exercises.where((e) => e.completed).length;
                    return Card(
                      child: InkWell(
                        onLongPress: () => _confirmDeleteSession(session),
                        borderRadius: BorderRadius.circular(12),
                        child: ExpansionTile(
                        title: Text(_formatDate(session.date),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$done / ${session.exercises.length} esercizi'),
                        children: session.exercises
                            .where((e) => e.sets.isNotEmpty)
                            .map((se) {
                          final maxWeight = se.sets
                              .map((s) => s.weight)
                              .reduce((a, b) => a > b ? a : b);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(se.exerciseName,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Text('max ${maxWeight.toStringAsFixed(1)} kg',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Grafico barre peso per set
                                _SetBarChart(sets: se.sets),
                                const SizedBox(height: 8),
                                Text(
                                  se.sets.map((s) =>
                                    'S${s.setNumber}: ${s.weight}kg×${s.reps}').join(' · '),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                                const Divider(),
                              ],
                            ),
                          );
                        }).toList(),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _SetBarChart extends StatelessWidget {
  final List<ExerciseSet> sets;
  const _SetBarChart({required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const SizedBox.shrink();
    final maxW = sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
    if (maxW == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sets.map((set) {
          final ratio = set.weight / maxW;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 8 + (ratio * 28),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
