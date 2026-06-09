import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../services/database_service.dart';

class WorkoutPlanScreen extends StatefulWidget {
  final WorkoutPlan plan;
  const WorkoutPlanScreen({super.key, required this.plan});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  List<Exercise> _allExercises = [];
  List<Exercise> _filtered = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(() {
      final q = _searchController.text.toLowerCase();
      setState(() => _filtered = q.isEmpty
          ? _allExercises
          : _allExercises.where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q)).toList());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    final exercises = await context.read<DatabaseService>().getAllExercises();
    setState(() {
      _allExercises = exercises;
      _filtered = exercises;
    });
  }

  bool _isInPlan(Exercise ex) =>
      widget.plan.exercises.any((e) => e.id == ex.id);

  Future<void> _toggleExercise(Exercise ex) async {
    final db = context.read<DatabaseService>();
    final provider = context.read<WorkoutProvider>();
    if (_isInPlan(ex)) {
      await db.removeExerciseFromPlan(widget.plan.id!, ex.id!);
    } else {
      await db.addExerciseToPlan(
          widget.plan.id!, ex, widget.plan.exercises.length);
    }
    await provider.loadPlans();
    // Aggiorna il piano locale
    final updated = provider.plans.firstWhere((p) => p.id == widget.plan.id);
    setState(() => widget.plan.exercises
      ..clear()
      ..addAll(updated.exercises));
  }

  Future<void> _addCustomExercise() async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Esercizio custom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome esercizio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Categoria (es. Petto, Gambe...)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    if (result == true &&
        nameController.text.isNotEmpty &&
        categoryController.text.isNotEmpty) {
      final db = context.read<DatabaseService>();
      await db.addCustomExercise(
          nameController.text.trim(), categoryController.text.trim());
      await _loadExercises();
    }
  }

  // Raggruppa per categoria
  Map<String, List<Exercise>> get _grouped {
    final map = <String, List<Exercise>>{};
    for (final ex in _filtered) {
      map.putIfAbsent(ex.category, () => []).add(ex);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final inPlan = widget.plan.exercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Esercizio custom',
            onPressed: _addCustomExercise,
          ),
        ],
      ),
      body: Column(
        children: [
          // Esercizi già nel piano
          if (inPlan.isNotEmpty)
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nel piano (${inPlan.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: inPlan.map((ex) => Chip(
                      label: Text(ex.name, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _toggleExercise(ex),
                    )).toList(),
                  ),
                ],
              ),
            ),

          // Ricerca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca esercizio...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: _searchController.clear)
                    : null,
              ),
            ),
          ),

          // Lista esercizi per categoria
          Expanded(
            child: _allExercises.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: _grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                )),
                          ),
                          ...entry.value.map((ex) {
                            final inList = _isInPlan(ex);
                            return ListTile(
                              dense: true,
                              title: Text(ex.name),
                              subtitle: ex.isCustom
                                  ? const Text('Custom',
                                      style: TextStyle(fontSize: 11, color: Colors.grey))
                                  : null,
                              trailing: inList
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.add_circle_outline),
                              onTap: () => _toggleExercise(ex),
                              onLongPress: ex.isCustom
                                  ? () => _confirmDeleteCustomExercise(ex)
                                  : null,
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCustomExercise(Exercise ex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vuoi eliminare "${ex.name}"?'),
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
    if (confirm != true) return;
    final db = context.read<DatabaseService>();
    await db.deleteExerciseHistory(ex.id!);
    await db.deleteExercise(ex.id!);
    await _loadExercises();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${ex.name}" eliminato')));
    }
  }
}
