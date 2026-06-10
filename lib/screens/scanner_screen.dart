import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/open_food_facts_service.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import 'add_entry_screen.dart';

class ScannerScreen extends StatefulWidget {
  final bool saveOnly;
  const ScannerScreen({super.key, this.saveOnly = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final _offService = OpenFoodFactsService();
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _disposed = false;
  // Token di annullamento — incrementato al dispose, ogni task lo controlla
  int _taskToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller?.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _controller?.stop();
      default:
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _taskToken++; // invalida tutti i task in corso
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(String barcode) async {
    if (_isProcessing || _disposed) return;
    setState(() => _isProcessing = true);
    _controller?.stop();

    // Salva il token corrente — se cambia vuol dire che siamo usciti
    final myToken = _taskToken;

    final db = context.read<DatabaseService>();
    Product? product = await db.getCachedProduct(barcode);

    if (_taskToken != myToken) return; // usciti durante l'attesa

    if (product == null) {
      final result = await _offService.fetchByBarcode(barcode);

      if (_taskToken != myToken) return; // usciti durante la chiamata API

      switch (result) {
        case BarcodeFound(:final product as Product):
          if (widget.saveOnly) {
            await db.cacheProduct(product);
            if (_taskToken != myToken) return;
            _showSnackbar('"${product.name}" aggiunto alla dispensa');
            await Future.delayed(const Duration(seconds: 1));
            if (_taskToken != myToken) return;
            if (mounted) Navigator.pop(context);
          } else {
            _navigateToAddEntry(product);
          }
        case BarcodeNotFound():
          if (_taskToken != myToken) return;
          _showSnackbar('Prodotto non trovato nel database');
          _controller?.start();
          if (_taskToken == myToken) setState(() => _isProcessing = false);
        case BarcodeError(:final message):
          if (_taskToken != myToken) return;
          _showSnackbar('Errore: $message');
          _controller?.start();
          if (_taskToken == myToken) setState(() => _isProcessing = false);
      }
    } else {
      if (_taskToken != myToken) return;
      if (widget.saveOnly) {
        _showSnackbar('"${product.name}" è già in dispensa');
        await Future.delayed(const Duration(seconds: 1));
        if (_taskToken != myToken) return;
        if (mounted) Navigator.pop(context);
      } else {
        _navigateToAddEntry(product);
      }
    }
  }

  void _navigateToAddEntry(Product product) {
    if (_disposed) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEntryScreen(product: product)),
    ).then((_) {
      if (!_disposed && mounted) {
        _controller?.start();
        setState(() => _isProcessing = false);
      }
    });
  }

  void _showSnackbar(String message) {
    if (_disposed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scansiona barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull?.rawValue;
              if (barcode != null && !_disposed) _onBarcodeDetected(barcode);
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
          const Positioned(
            bottom: 40, left: 0, right: 0,
            child: Text(
              'Inquadra il codice a barre del prodotto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
