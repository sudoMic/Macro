import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/open_food_facts_service.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import 'add_entry_screen.dart';

/// [saveOnly] = true  → salva in dispensa, non aggiunge al diario
/// [saveOnly] = false → aggiunge al diario
class ScannerScreen extends StatefulWidget {
  final bool saveOnly;
  const ScannerScreen({super.key, this.saveOnly = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _offService = OpenFoodFactsService();
  bool _isProcessing = false;

  Future<void> _onBarcodeDetected(String barcode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final db = context.read<DatabaseService>();
    Product? product = await db.getCachedProduct(barcode);

    if (product == null) {
      if (!mounted) return;
      _showSnackbar('Ricerca prodotto...');
      final result = await _offService.fetchByBarcode(barcode);
      if (!mounted) return;

      switch (result) {
        case BarcodeFound(:final product as Product):
          if (widget.saveOnly) {
            // Salva in dispensa e torna
            await db.cacheProduct(product);
            _showSnackbar('"${product.name}" aggiunto alla dispensa');
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) Navigator.pop(context);
          } else {
            // Non casha — va al diario
            _navigateToAddEntry(product);
          }

        case BarcodeNotFound():
          _showSnackbar('Prodotto non trovato nel database');
          setState(() => _isProcessing = false);

        case BarcodeError(:final message):
          _showSnackbar('Errore: $message');
          setState(() => _isProcessing = false);
      }
    } else {
      if (widget.saveOnly) {
        _showSnackbar('"${product.name}" è già in dispensa');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        _navigateToAddEntry(product);
      }
    }
  }

  void _navigateToAddEntry(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEntryScreen(product: product)),
    ).then((_) => setState(() => _isProcessing = false));
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.saveOnly ? 'Scansiona per dispensa' : 'Scansiona'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull?.rawValue;
              if (barcode != null) _onBarcodeDetected(barcode);
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Text(
              'Inquadra il codice a barre del prodotto',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
