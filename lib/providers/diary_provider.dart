import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../models/product.dart';
import '../services/database_service.dart';

/// Gestisce lo stato del diario giornaliero.
/// Tutti i widget leggono da qui — nessuno accede al DB direttamente.
class DiaryProvider extends ChangeNotifier {
  final DatabaseService _db;

  DiaryProvider(this._db);

  DateTime _selectedDate = DateTime.now();
  List<DiaryEntry> _entries = [];
  bool _isLoading = false;

  DateTime get selectedDate => _selectedDate;
  List<DiaryEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;

  DailyTotals get totals => DailyTotals.fromEntries(_entries);

  /// Raggruppa le voci per pasto.
  Map<String, List<DiaryEntry>> get entriesByMeal {
    final map = <String, List<DiaryEntry>>{};
    for (final entry in _entries) {
      map.putIfAbsent(entry.meal, () => []).add(entry);
    }
    return map;
  }

  Future<void> loadDate(DateTime date) async {
    _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    _entries = await _db.getEntriesForDate(date);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry({
    required Product product,
    required double grams,
    required String meal,
  }) async {
    final scaled = product.forGrams(grams);
    final entry = DiaryEntry(
      productBarcode: product.barcode,
      productName: product.name,
      meal: meal,
      grams: grams,
      kcal: scaled.kcal,
      carbs: scaled.carbs,
      proteins: scaled.proteins,
      fats: scaled.fats,
      date: _selectedDate,
    );

    final id = await _db.addDiaryEntry(entry);
    _entries.add(DiaryEntry(
      id: id,
      productBarcode: entry.productBarcode,
      productName: entry.productName,
      meal: entry.meal,
      grams: entry.grams,
      kcal: entry.kcal,
      carbs: entry.carbs,
      proteins: entry.proteins,
      fats: entry.fats,
      date: entry.date,
    ));
    notifyListeners();
  }

  Future<void> removeEntry(int id) async {
    await _db.deleteDiaryEntry(id);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
