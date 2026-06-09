import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../providers/diary_provider.dart';

const _meals = ['Colazione', 'Pranzo', 'Cena', 'Spuntino'];
const _gramOptions = [50.0, 100.0, 150.0, 200.0, 250.0, 300.0];

/// Schermata per scegliere un alimento dalla dispensa e aggiungerlo al diario.
class PickFromPantryScreen extends StatefulWidget {
  const PickFromPantryScreen({super.key});

  @override
  State<PickFromPantryScreen> createState() => _PickFromPantryScreenState();
}

class _PickFromPantryScreenState extends State<PickFromPantryScreen> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      final q = _searchController.text.toLowerCase();
      setState(() => _filtered = q.isEmpty
          ? _products
          : _products.where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q)).toList());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final products = await context.read<DatabaseService>().getAllCachedProducts();
    setState(() {
      _products = products;
      _filtered = products;
      _isLoading = false;
    });
  }

  void _openAddDialog(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddToDiarySheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scegli alimento')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: _searchController.clear)
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessun alimento nella dispensa.\nAggiungi prodotti da "I miei alimenti".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final p = _filtered[i];
                          return ListTile(
                            title: Text(p.name, overflow: TextOverflow.ellipsis),
                            subtitle: p.brand.isNotEmpty ? Text(p.brand) : null,
                            trailing: Text(
                              '${p.kcal.toStringAsFixed(0)} kcal/100g',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => _openAddDialog(p),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet per selezionare grammi e pasto prima di aggiungere al diario.
class _AddToDiarySheet extends StatefulWidget {
  final Product product;
  const _AddToDiarySheet({required this.product});

  @override
  State<_AddToDiarySheet> createState() => _AddToDiarySheetState();
}

class _AddToDiarySheetState extends State<_AddToDiarySheet> {
  double _grams = 100;
  String _meal = 'Pranzo';
  bool _customGrams = false;
  final _customController = TextEditingController(text: '100');

  double get _effectiveGrams =>
      _customGrams ? (double.tryParse(_customController.text) ?? 100) : _grams;

  Product get _scaled => widget.product.forGrams(_effectiveGrams);

  Future<void> _add() async {
    final grams = _effectiveGrams;
    if (grams <= 0) return;

    await context.read<DiaryProvider>().addEntry(
      product: widget.product,
      grams: grams,
      meal: _meal,
    );

    if (mounted) {
      Navigator.pop(context); // chiude sheet
      Navigator.pop(context); // torna al diario
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 16),

          // Selettore grammi preimpostati
          const Text('Quantità:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._gramOptions.map((g) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${g.toInt()}g'),
                    selected: !_customGrams && _grams == g,
                    onSelected: (_) => setState(() {
                      _grams = g;
                      _customGrams = false;
                    }),
                  ),
                )),
                ChoiceChip(
                  label: const Text('Altro'),
                  selected: _customGrams,
                  onSelected: (_) => setState(() => _customGrams = true),
                ),
              ],
            ),
          ),

          // Campo grammi custom
          if (_customGrams) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Grammi',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 16),

          // Anteprima macro
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Mini('Kcal', _scaled.kcal.toStringAsFixed(0), Colors.orange),
              _Mini('Carbo', '${_scaled.carbs.toStringAsFixed(1)}g', Colors.blue),
              _Mini('Prot', '${_scaled.proteins.toStringAsFixed(1)}g', Colors.red),
              _Mini('Grassi', '${_scaled.fats.toStringAsFixed(1)}g', Colors.yellow[700]!),
            ],
          ),
          const SizedBox(height: 16),

          // Selezione pasto
          DropdownButtonFormField<String>(
            value: _meal,
            decoration: const InputDecoration(
              labelText: 'Pasto',
              border: OutlineInputBorder(),
            ),
            items: _meals.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _meal = v!),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _add,
              child: const Text('Aggiungi al diario'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Mini(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
