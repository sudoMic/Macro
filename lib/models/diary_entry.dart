/// Una voce nel diario giornaliero: un prodotto consumato in una certa quantità.
class DiaryEntry {
  final int? id; // null finché non è salvato nel DB
  final String productBarcode;
  final String productName;
  final String meal; // colazione, pranzo, cena, spuntino
  final double grams;
  final double kcal;
  final double carbs;
  final double proteins;
  final double fats;
  final DateTime date;

  const DiaryEntry({
    this.id,
    required this.productBarcode,
    required this.productName,
    required this.meal,
    required this.grams,
    required this.kcal,
    required this.carbs,
    required this.proteins,
    required this.fats,
    required this.date,
  });

  factory DiaryEntry.fromDb(Map<String, dynamic> row) {
    return DiaryEntry(
      id: row['id'] as int?,
      productBarcode: row['product_barcode'] as String,
      productName: row['product_name'] as String,
      meal: row['meal'] as String,
      grams: row['grams'] as double,
      kcal: row['kcal'] as double,
      carbs: row['carbs'] as double,
      proteins: row['proteins'] as double,
      fats: row['fats'] as double,
      date: DateTime.parse(row['date'] as String),
    );
  }

  Map<String, dynamic> toDb() => {
        if (id != null) 'id': id,
        'product_barcode': productBarcode,
        'product_name': productName,
        'meal': meal,
        'grams': grams,
        'kcal': kcal,
        'carbs': carbs,
        'proteins': proteins,
        'fats': fats,
        'date': date.toIso8601String().substring(0, 10), // solo data YYYY-MM-DD
      };
}

/// Totali macro per un giorno, calcolati aggregando le DiaryEntry.
class DailyTotals {
  final double kcal;
  final double carbs;
  final double proteins;
  final double fats;

  const DailyTotals({
    required this.kcal,
    required this.carbs,
    required this.proteins,
    required this.fats,
  });

  factory DailyTotals.fromEntries(List<DiaryEntry> entries) {
    return DailyTotals(
      kcal: entries.fold(0, (sum, e) => sum + e.kcal),
      carbs: entries.fold(0, (sum, e) => sum + e.carbs),
      proteins: entries.fold(0, (sum, e) => sum + e.proteins),
      fats: entries.fold(0, (sum, e) => sum + e.fats),
    );
  }

  static const DailyTotals zero = DailyTotals(
    kcal: 0,
    carbs: 0,
    proteins: 0,
    fats: 0,
  );
}
