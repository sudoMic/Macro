import 'package:flutter/material.dart';
import '../models/product.dart';

const _gramOptions = [50.0, 100.0, 200.0];

/// Schermata dettaglio prodotto con selettore grammi per visualizzare i valori scalati.
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  double _selectedGrams = 100;

  Product get _scaled => widget.product.forGrams(_selectedGrams);

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      appBar: AppBar(title: Text(p.name, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.brand.isNotEmpty)
            Text(p.brand, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 20),

          // Selettore grammi
          const Text('Visualizza valori per:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SegmentedButton<double>(
            segments: _gramOptions.map((g) =>
              ButtonSegment(value: g, label: Text('${g.toInt()}g'))
            ).toList(),
            selected: {_selectedGrams},
            onSelectionChanged: (s) => setState(() => _selectedGrams = s.first),
          ),
          const SizedBox(height: 24),

          // Valori nutrizionali scalati
          _MacroCard(product: _scaled, grams: _selectedGrams),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final Product product;
  final double grams;

  const _MacroCard({required this.product, required this.grams});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valori per ${grams.toInt()}g',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            _MacroRow('Calorie', '${product.kcal.toStringAsFixed(0)} kcal', Colors.orange),
            const Divider(),
            _MacroRow('Carboidrati', '${product.carbs.toStringAsFixed(1)}g', Colors.blue),
            const Divider(),
            _MacroRow('Proteine', '${product.proteins.toStringAsFixed(1)}g', Colors.red),
            const Divider(),
            _MacroRow('Grassi', '${product.fats.toStringAsFixed(1)}g', Colors.yellow[700]!),
            if (product.fiber != null) ...[
              const Divider(),
              _MacroRow('Fibre', '${product.fiber!.toStringAsFixed(1)}g', Colors.green),
            ],
            if (product.sugars != null) ...[
              const Divider(),
              _MacroRow('Zuccheri', '${product.sugars!.toStringAsFixed(1)}g', Colors.purple),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: color,
              margin: const EdgeInsets.only(right: 10)),
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
