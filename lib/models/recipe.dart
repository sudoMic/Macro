import 'product.dart';

/// Un ingrediente all'interno di una ricetta: prodotto + quantità in grammi.
class RecipeIngredient {
  final String productBarcode;
  final String productName;
  final double grams;
  final double kcal;
  final double carbs;
  final double proteins;
  final double fats;

  const RecipeIngredient({
    required this.productBarcode,
    required this.productName,
    required this.grams,
    required this.kcal,
    required this.carbs,
    required this.proteins,
    required this.fats,
  });

  factory RecipeIngredient.fromProduct(Product product, double grams) {
    final scaled = product.forGrams(grams);
    return RecipeIngredient(
      productBarcode: product.barcode,
      productName: product.name,
      grams: grams,
      kcal: scaled.kcal,
      carbs: scaled.carbs,
      proteins: scaled.proteins,
      fats: scaled.fats,
    );
  }

  factory RecipeIngredient.fromDb(Map<String, dynamic> row) {
    return RecipeIngredient(
      productBarcode: row['product_barcode'] as String,
      productName: row['product_name'] as String,
      grams: row['grams'] as double,
      kcal: row['kcal'] as double,
      carbs: row['carbs'] as double,
      proteins: row['proteins'] as double,
      fats: row['fats'] as double,
    );
  }

  Map<String, dynamic> toDb(int recipeId) => {
        'recipe_id': recipeId,
        'product_barcode': productBarcode,
        'product_name': productName,
        'grams': grams,
        'kcal': kcal,
        'carbs': carbs,
        'proteins': proteins,
        'fats': fats,
      };
}

/// Una ricetta personalizzata con più ingredienti e un numero di porzioni.
class Recipe {
  final int? id;
  final String name;
  final int servings; // numero di porzioni totali
  final List<RecipeIngredient> ingredients;

  const Recipe({
    this.id,
    required this.name,
    required this.servings,
    required this.ingredients,
  });

  /// Macro totali per l'intera ricetta.
  double get totalKcal => ingredients.fold(0, (s, i) => s + i.kcal);
  double get totalCarbs => ingredients.fold(0, (s, i) => s + i.carbs);
  double get totalProteins => ingredients.fold(0, (s, i) => s + i.proteins);
  double get totalFats => ingredients.fold(0, (s, i) => s + i.fats);

  /// Macro per una singola porzione.
  double get kcalPerServing => totalKcal / servings;
  double get carbsPerServing => totalCarbs / servings;
  double get proteinsPerServing => totalProteins / servings;
  double get fatsPerServing => totalFats / servings;
}
