import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

/// Risultato della ricerca barcode: successo, non trovato, o errore di rete.
sealed class BarcodeResult {
  const BarcodeResult();
}

class BarcodeFound extends BarcodeResult {
  final Product product;
  const BarcodeFound(this.product);
}

class BarcodeNotFound extends BarcodeResult {
  const BarcodeNotFound();
}

class BarcodeError extends BarcodeResult {
  final String message;
  const BarcodeError(this.message);
}

/// Servizio per recuperare dati nutrizionali da Open Food Facts.
/// Tutta la logica di rete è qui: nessun widget tocca http direttamente.
class OpenFoodFactsService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';
  static const _timeout = Duration(seconds: 10);

  /// Cerca prodotti per nome/testo. Restituisce lista di risultati (max 15).
  Future<List<Product>> searchByText(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl'
      '?search_terms=${Uri.encodeComponent(query.trim())}'
      '&search_simple=1&action=process&json=1&page_size=15'
      '&sort_by=unique_scans_n'
      '&fields=code,product_name,brands,nutriments',
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'MacroApp/1.0'},
      ).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final products = json['products'] as List<dynamic>? ?? [];

      return products
          .map((p) {
            final nutriments = p['nutriments'] as Map<String, dynamic>? ?? {};
            final kcal = nutriments['energy-kcal_100g'];
            if (kcal == null) return null;
            final name = p['product_name']?.toString().trim() ?? '';
            if (name.isEmpty) return null;
            return Product(
              barcode: p['code']?.toString() ?? '',
              name: name,
              brand: p['brands']?.toString() ?? '',
              kcal: Product.parseDouble(kcal),
              carbs: Product.parseDouble(nutriments['carbohydrates_100g']),
              proteins: Product.parseDouble(nutriments['proteins_100g']),
              fats: Product.parseDouble(nutriments['fat_100g']),
              fiber: Product.parseDoubleOrNull(nutriments['fiber_100g']),
              sugars: Product.parseDoubleOrNull(nutriments['sugars_100g']),
            );
          })
          .whereType<Product>()
          .toList();
    } on Exception {
      return [];
    }
  }
  /// Restituisce sempre un [BarcodeResult] — non lancia mai eccezioni.
  Future<BarcodeResult> fetchByBarcode(String barcode) async {
    final uri = Uri.parse('$_baseUrl/$barcode.json');

    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        return BarcodeError('Errore server: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as int? ?? 0;

      if (status == 0) {
        return const BarcodeNotFound();
      }

      // Controlla che ci siano almeno i dati minimi utili
      final nutriments = (json['product'] as Map?)?['nutriments'];
      if (nutriments == null) {
        return const BarcodeNotFound();
      }

      return BarcodeFound(Product.fromOpenFoodFacts(json));
    } on Exception catch (e) {
      return BarcodeError('Nessuna connessione o timeout: $e');
    }
  }
}
