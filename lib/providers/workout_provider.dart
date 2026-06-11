import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../services/database_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final DatabaseService _db;
  WorkoutProvider(this._db);

  List<WorkoutPlan> _plans = [];
  WorkoutSession? _activeSession;
  bool _isLoading = false;

  List<WorkoutPlan> get plans => List.unmodifiable(_plans);
  WorkoutSession? get activeSession => _activeSession;
  bool get isLoading => _isLoading;

  Future<void> reorderPlans(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final plans = List<WorkoutPlan>.from(_plans);
    final item = plans.removeAt(oldIndex);
    plans.insert(newIndex, item);
    _plans = plans;
    notifyListeners();
    // Persisti l'ordine
    final prefs = await SharedPreferences.getInstance();
    final order = _plans.map((p) => p.id.toString()).toList();
    await prefs.setStringList('workout_order', order);
  }

  Future<void> loadPlans() async {
    _isLoading = true;
    notifyListeners();
    final plans = await _db.getAllWorkoutPlans();
    // Ripristina ordine salvato
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList('workout_order');
    if (order != null && order.isNotEmpty) {
      final idToplan = {for (final p in plans) p.id.toString(): p};
      final sorted = <WorkoutPlan>[];
      for (final id in order) {
        if (idToplan.containsKey(id)) sorted.add(idToplan[id]!);
      }
      // Aggiungi eventuali nuovi piani non ancora in lista
      for (final p in plans) {
        if (!sorted.any((s) => s.id == p.id)) sorted.add(p);
      }
      _plans = sorted;
    } else {
      _plans = plans;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<int> createPlan(String name) async {
    final id = await _db.createWorkoutPlan(name);
    await loadPlans();
    return id;
  }

  Future<void> deletePlan(int id) async {
    await _db.deleteWorkoutPlan(id);
    // Se la sessione attiva appartiene al piano eliminato, la azzera
    if (_activeSession?.workoutPlanId == id) {
      _activeSession = null;
    }
    await loadPlans();
  }

  Future<void> startSession(WorkoutPlan plan) async {
    final sessionId = await _db.startSession(plan);
    _activeSession = await _db.getSession(sessionId);
    notifyListeners();
  }

  Future<void> refreshSession() async {
    if (_activeSession?.id == null) return;
    _activeSession = await _db.getSession(_activeSession!.id!);
    notifyListeners();
  }

  Future<void> markExerciseCompleted(int sessionExerciseId) async {
    await _db.markExerciseCompleted(sessionExerciseId);
    await refreshSession();
  }

  Future<void> addSet(ExerciseSet set) async {
    await _db.addSet(set);
    await refreshSession();
  }

  Future<void> updateSet(ExerciseSet set) async {
    await _db.updateSet(set);
    await refreshSession();
  }

  Future<void> deleteSet(int id) async {
    await _db.deleteSet(id);
    await refreshSession();
  }

  void endSession() {
    _activeSession = null;
    notifyListeners();
  }
}
