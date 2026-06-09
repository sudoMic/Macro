/// Rappresenta un prodotto alimentare con i suoi valori nutrizionali per 100g.
class Product {
  final String barcode;
  final String name;
  final String brand;
  final double kcal;
  final double carbs;
  final double proteins;
  final double fats;
  final double? fiber;
  final double? sugars;

  const Product({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.kcal,
    required this.carbs,
    required this.proteins,
    required this.fats,
    this.fiber,
    this.sugars,
  });

  /// Crea un Product dal JSON di Open Food Facts.
  factory Product.fromOpenFoodFacts(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    return Product(
      barcode: product['code']?.toString() ?? '',
      name: product['product_name']?.toString() ?? 'Prodotto sconosciuto',
      brand: product['brands']?.toString() ?? '',
      kcal: parseDouble(nutriments['energy-kcal_100g']),
      carbs: parseDouble(nutriments['carbohydrates_100g']),
      proteins: parseDouble(nutriments['proteins_100g']),
      fats: parseDouble(nutriments['fat_100g']),
      fiber: parseDoubleOrNull(nutriments['fiber_100g']),
      sugars: parseDoubleOrNull(nutriments['sugars_100g']),
    );
  }

  /// Crea un Product da una riga del database locale.
  factory Product.fromDb(Map<String, dynamic> row) {
    return Product(
      barcode: row['barcode'] as String,
      name: row['name'] as String,
      brand: row['brand'] as String,
      kcal: row['kcal'] as double,
      carbs: row['carbs'] as double,
      proteins: row['proteins'] as double,
      fats: row['fats'] as double,
      fiber: row['fiber'] as double?,
      sugars: row['sugars'] as double?,
    );
  }

  Map<String, dynamic> toDb() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'kcal': kcal,
        'carbs': carbs,
        'proteins': proteins,
        'fats': fats,
        'fiber': fiber,
        'sugars': sugars,
      };

  /// Calcola i macro per una quantità specifica in grammi.
  Product forGrams(double grams) {
    final ratio = grams / 100.0;
    return Product(
      barcode: barcode,
      name: name,
      brand: brand,
      kcal: kcal * ratio,
      carbs: carbs * ratio,
      proteins: proteins * ratio,
      fats: fats * ratio,
      fiber: fiber != null ? fiber! * ratio : null,
      sugars: sugars != null ? sugars! * ratio : null,
    );
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static double? parseDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
