import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import 'scanner_screen.dart';
import 'manual_entry_screen.dart';
import 'product_detail_screen.dart';

class SavedProductsScreen extends StatefulWidget {
  const SavedProductsScreen({super.key});

  @override
  State<SavedProductsScreen> createState() => _SavedProductsScreenState();
}

class _SavedProductsScreenState extends State<SavedProductsScreen> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = context.read<DatabaseService>();
    final products = await db.getAllCachedProducts();
    setState(() {
      _products = products;
      _filtered = _applySearch(products);
      _isLoading = false;
    });
  }

  List<Product> _applySearch(List<Product> list) {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return list;
    return list.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.brand.toLowerCase().contains(q)
    ).toList();
  }

  void _onSearch() {
    setState(() => _filtered = _applySearch(_products));
  }

  Future<void> _confirmDelete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina alimento'),
        content: Text('Vuoi eliminare "${product.name}"?'),
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
    if (confirm == true) {
      await context.read<DatabaseService>().deleteCachedProduct(product.barcode);
      await _load();
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scansiona barcode'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScannerScreen(saveOnly: true)),
                ).then((_) => _load());
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Inserisci manualmente'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManualEntryScreen(onlySave: true)),
                ).then((_) => _load());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('I miei alimenti')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca prodotto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _products.isEmpty
                              ? 'Nessun alimento salvato.\nPremi + per aggiungere.'
                              : 'Nessun risultato.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final product = _filtered[i];
                          return _ProductTile(
                            product: product,
                            onLongPress: () => _confirmDelete(product),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: product),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(product.name, overflow: TextOverflow.ellipsis),
      subtitle: product.brand.isNotEmpty ? Text(product.brand) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${product.kcal.toStringAsFixed(0)} kcal',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text('per 100g', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
