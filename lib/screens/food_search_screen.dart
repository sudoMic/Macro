import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/diary_provider.dart';
import '../services/open_food_facts_service.dart';

const _meals = ['Colazione', 'Pranzo', 'Cena', 'Spuntino'];
const _gramOptions = [50.0, 100.0, 150.0, 200.0, 250.0, 300.0];

/// Ricerca alimenti per testo con suggerimenti da Open Food Facts.
class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchController = TextEditingController();
  final _offService = OpenFoodFactsService();
  List<Product> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _results = [];
    });

    final results = await _offService.searchByText(query);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
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
      appBar: AppBar(title: const Text('Cerca alimento')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Es. gelato, pasta, pollo...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() { _results = []; _hasSearched = false; });
                    },
                  ),
              ],
              onSubmitted: _search,
              onChanged: (v) => setState(() {}),
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const Center(
                        child: Text(
                          'Cerca un alimento per nome.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : _results.isEmpty
                        ? const Center(
                            child: Text(
                              'Nessun risultato.\nProva con un termine diverso.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final p = _results[i];
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
          if (widget.product.brand.isNotEmpty)
            Text(widget.product.brand,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),

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
