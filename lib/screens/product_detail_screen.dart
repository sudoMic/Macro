import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/database_service.dart';

const _gramOptions = [50.0, 100.0, 200.0];

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  double _selectedGrams = 100;
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Product get _scaled => _product.forGrams(_selectedGrams);

  Future<void> _openEdit() async {
    final updated = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProductSheet(product: _product),
    );
    if (updated != null) {
      await context.read<DatabaseService>().cacheProduct(updated);
      setState(() => _product = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifiche salvate')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica',
            onPressed: _openEdit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_product.brand.isNotEmpty)
            Text(_product.brand,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 20),

          const Text('Visualizza valori per:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SegmentedButton<double>(
            segments: _gramOptions
                .map((g) => ButtonSegment(value: g, label: Text('${g.toInt()}g')))
                .toList(),
            selected: {_selectedGrams},
            onSelectionChanged: (s) => setState(() => _selectedGrams = s.first),
          ),
          const SizedBox(height: 24),

          _MacroCard(product: _scaled, grams: _selectedGrams),
        ],
      ),
    );
  }
}

class _EditProductSheet extends StatefulWidget {
  final Product product;
  const _EditProductSheet({required this.product});

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _kcal;
  late final TextEditingController _carbs;
  late final TextEditingController _proteins;
  late final TextEditingController _fats;
  late final TextEditingController _fiber;
  late final TextEditingController _sugars;
  late final TextEditingController _salt;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p.name);
    _brand = TextEditingController(text: p.brand);
    _kcal = TextEditingController(text: p.kcal.toStringAsFixed(0));
    _carbs = TextEditingController(text: p.carbs.toStringAsFixed(1));
    _proteins = TextEditingController(text: p.proteins.toStringAsFixed(1));
    _fats = TextEditingController(text: p.fats.toStringAsFixed(1));
    _fiber = TextEditingController(text: p.fiber?.toStringAsFixed(1) ?? '');
    _sugars = TextEditingController(text: p.sugars?.toStringAsFixed(1) ?? '');
    _salt = TextEditingController(text: p.salt?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _brand, _kcal, _carbs, _proteins, _fats, _fiber, _sugars, _salt]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final updated = Product(
      barcode: widget.product.barcode,
      name: _name.text.trim().isEmpty ? widget.product.name : _name.text.trim(),
      brand: _brand.text.trim(),
      kcal: double.tryParse(_kcal.text) ?? widget.product.kcal,
      carbs: double.tryParse(_carbs.text) ?? widget.product.carbs,
      proteins: double.tryParse(_proteins.text) ?? widget.product.proteins,
      fats: double.tryParse(_fats.text) ?? widget.product.fats,
      fiber: double.tryParse(_fiber.text),
      sugars: double.tryParse(_sugars.text),
      salt: double.tryParse(_salt.text),
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modifica alimento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 16),
            _Field(_name, 'Nome'),
            const SizedBox(height: 10),
            _Field(_brand, 'Marca'),
            const SizedBox(height: 16),
            const Text('Valori per 100g',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            _Field(_kcal, 'Calorie (kcal)', color: Colors.orange),
            const SizedBox(height: 10),
            _Field(_carbs, 'Carboidrati (g)', color: Colors.blue),
            const SizedBox(height: 10),
            _Field(_proteins, 'Proteine (g)', color: Colors.red),
            const SizedBox(height: 10),
            _Field(_fats, 'Grassi (g)', color: Colors.yellow[700]!),
            const SizedBox(height: 10),
            _Field(_fiber, 'Fibre (g)', color: Colors.green),
            const SizedBox(height: 10),
            _Field(_sugars, 'Zuccheri (g)', color: Colors.purple),
            const SizedBox(height: 10),
            _Field(_salt, 'Sale (g)', color: Colors.blueGrey),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Salva'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color? color;

  const _Field(this.controller, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: label == 'Nome' || label == 'Marca'
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: color != null ? TextStyle(color: color) : null,
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
            Text('Valori per ${grams.toInt()}g',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
            if (product.salt != null) ...[
              const Divider(),
              _MacroRow('Sale', '${product.salt!.toStringAsFixed(2)}g', Colors.blueGrey),
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
