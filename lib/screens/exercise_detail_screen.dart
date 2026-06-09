import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final SessionExercise sessionExercise;
  const ExerciseDetailScreen({super.key, required this.sessionExercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _notesController = TextEditingController();

  // Timer recupero
  Timer? _timer;
  Timer? _prTimer;
  int _seconds = 0;
  bool _timerRunning = false;
  bool _timerPaused = false;
  bool _timerFinished = false;

  // PR
  double? _historicPR;
  double? _pr;
  double _prBadgeOpacity = 0.0; // 0 = nascosto, 1 = visibile

  // Ultima sessione
  List<Map<String, dynamic>> _lastSession = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rest = context.read<ThemeProvider>().restSeconds;
      setState(() => _seconds = rest);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _prTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = context.read<DatabaseService>();
    final history = await db.getExerciseHistory(widget.sessionExercise.exerciseId);
    final currentSessionId = widget.sessionExercise.sessionId;
    final pastRows = history.where((r) => r['session_id'] != currentSessionId).toList();

    double? historicMax;
    if (pastRows.isNotEmpty) {
      historicMax = pastRows.map((r) => r['weight'] as double).reduce((a, b) => a > b ? a : b);
    }

    setState(() {
      _historicPR = historicMax;
      _pr = historicMax;
      _lastSession = _extractLastSession(pastRows);
    });
  }

  List<Map<String, dynamic>> _extractLastSession(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return [];
    final lastDate = rows.last['date'] as String;
    return rows.where((r) => r['date'] == lastDate).toList();
  }

  void _recalcPR(List<ExerciseSet> sets) {
    double? sessionMax;
    if (sets.isNotEmpty) {
      sessionMax = sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
    }
    final all = [_historicPR, sessionMax].whereType<double>();
    setState(() => _pr = all.isEmpty ? null : all.reduce((a, b) => a > b ? a : b));
  }

  // ─── PR badge con AnimatedOpacity ─────────────────────────────────────────

  void _showPRBadge() {
    _prTimer?.cancel();
    // Appare subito
    setState(() => _prBadgeOpacity = 1.0);
    // Dopo 4s inizia a scomparire
    _prTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _prBadgeOpacity = 0.0);
    });
  }

  // ─── Timer recupero ───────────────────────────────────────────────────────

  void _startTimer() {
    final rest = context.read<ThemeProvider>().restSeconds;
    if (!_timerRunning && !_timerPaused) _seconds = rest;
    setState(() { _timerRunning = true; _timerPaused = false; _timerFinished = false; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds <= 1) {
        _timer?.cancel();
        setState(() { _seconds = 0; _timerRunning = false; _timerFinished = true; });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            final r = context.read<ThemeProvider>().restSeconds;
            setState(() { _timerFinished = false; _seconds = r; });
          }
        });
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() { _timerRunning = false; _timerPaused = true; });
  }

  void _resetTimer() {
    _timer?.cancel();
    final rest = context.read<ThemeProvider>().restSeconds;
    setState(() { _seconds = rest; _timerRunning = false; _timerPaused = false; _timerFinished = false; });
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─── Serie ────────────────────────────────────────────────────────────────

  Future<void> _addSet() async {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    if (weight == null || reps == null || reps == 0) return;

    final provider = context.read<WorkoutProvider>();
    final se = widget.sessionExercise;
    final currentSets = provider.activeSession?.exercises
        .firstWhere((e) => e.id == se.id, orElse: () => se).sets ?? se.sets;

    await provider.addSet(ExerciseSet(
      sessionExerciseId: se.id!,
      setNumber: currentSets.length + 1,
      weight: weight,
      reps: reps,
      notes: _notesController.text.trim(),
    ));
    _notesController.clear();

    // Mostra badge solo se SUPERA il PR attuale (non uguale)
    if (_historicPR == null || weight > (_historicPR ?? 0)) {
      _historicPR = weight; // aggiorna subito così la prossima serie non riattiva
      _showPRBadge();
    }
    _recalcPR([...currentSets,
      ExerciseSet(sessionExerciseId: se.id!, setNumber: 0, weight: weight, reps: reps)]);

    _startTimer();
  }

  Future<void> _deleteSet(ExerciseSet set, List<ExerciseSet> allSets) async {
    await context.read<WorkoutProvider>().deleteSet(set.id!);
    // Ricarica tutto dal DB — unica fonte di verità
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final se = provider.activeSession?.exercises.firstWhere(
              (e) => e.id == widget.sessionExercise.id,
              orElse: () => widget.sessionExercise,
            ) ?? widget.sessionExercise;

        final restSeconds = context.watch<ThemeProvider>().restSeconds;
        final progress = restSeconds > 0 ? _seconds / restSeconds : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(se.exerciseName),
            actions: [
              // Badge PR con AnimatedOpacity — scompare fluidamente
              AnimatedOpacity(
                opacity: _prBadgeOpacity,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text('PR!', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // PR in tempo reale
              if (_pr != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text('PR: ${_pr!.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                ),

              // Input serie
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aggiungi serie',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Peso (kg)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _repsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Ripetizioni',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Note (opzionale)',
                          border: OutlineInputBorder(),
                          hintText: 'Es. sensazione, tecnica...',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _addSet,
                          icon: const Icon(Icons.add),
                          label: const Text('Aggiungi serie'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Serie sessione corrente
              if (se.sets.isNotEmpty) ...[
                const Text('Serie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ...se.sets.map((set) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text('${set.setNumber}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${set.weight} kg × ${set.reps} rip',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: set.notes.isNotEmpty ? Text(set.notes) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _deleteSet(set, se.sets),
                    ),
                  ),
                )),
                const SizedBox(height: 16),
              ],

              // Timer recupero
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _timerFinished
                      ? Colors.green.withOpacity(0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: _timerFinished ? Border.all(color: Colors.green, width: 2) : null,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined),
                        const SizedBox(width: 8),
                        const Text('Recupero', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_timerFinished)
                          const Text('Via!', style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _timerRunning
                            ? progress
                            : (_timerFinished ? 0 : (_timerPaused ? progress : 1)),
                        minHeight: 8,
                        color: _timerFinished ? Colors.green : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_timerLabel,
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        if (!_timerRunning)
                          FilledButton.icon(
                            onPressed: _startTimer,
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: Text(_timerPaused ? 'Riprendi' : 'Start'),
                          )
                        else ...[
                          IconButton(onPressed: _pauseTimer, icon: const Icon(Icons.pause), tooltip: 'Pausa'),
                          IconButton(onPressed: _resetTimer, icon: const Icon(Icons.replay), tooltip: 'Reset'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Ultima sessione
              if (_lastSession.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Ultima volta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_lastSession.first['date'] as String,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        ..._lastSession.map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'S${r['set_number']}: ${r['weight']} kg × ${r['reps']} rip',
                            style: const TextStyle(fontSize: 14),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
