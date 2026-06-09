import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/diary_provider.dart';

const _meals = ['Colazione', 'Pranzo', 'Cena', 'Spuntino'];

/// Schermata mostrata dopo la scansione: conferma quantità e pasto,
/// poi aggiunge la voce al diario.
class AddEntryScreen extends StatefulWidget {
  final Product product;

  const AddEntryScreen({super.key, required this.product});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _gramsController = TextEditingController(text: '100');
  String _selectedMeal = 'Pranzo';
  bool _isSaving = false;

  double get _grams => double.tryParse(_gramsController.text) ?? 0;

  Product get _scaled => widget.product.forGrams(_grams);

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci una quantità valida')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await context.read<DiaryProvider>().addEntry(
          product: widget.product,
          grams: _grams,
          meal: _selectedMeal,
        );

    if (mounted) {
      Navigator.pop(context); // torna alla lista alimenti
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      appBar: AppBar(title: Text(p.name, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Marca
          if (p.brand.isNotEmpty)
            Text(p.brand,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),

          // Quantità
          TextField(
            controller: _gramsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantità (g)',
              border: OutlineInputBorder(),
              suffixText: 'g',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Selezione pasto
          DropdownButtonFormField<String>(
            value: _selectedMeal,
            decoration: const InputDecoration(
              labelText: 'Pasto',
              border: OutlineInputBorder(),
            ),
            items: _meals
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _selectedMeal = v!),
          ),
          const SizedBox(height: 24),

          // Anteprima macro calcolati per la quantità inserita
          _MacroPreview(product: _scaled, grams: _grams),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Aggiungi al diario'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroPreview extends StatelessWidget {
  final Product product;
  final double grams;

  const _MacroPreview({required this.product, required this.grams});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Per ${grams.toStringAsFixed(0)}g:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroTile('Kcal', product.kcal, Colors.orange),
                _MacroTile('Carbo', product.carbs, Colors.blue),
                _MacroTile('Proteine', product.proteins, Colors.red),
                _MacroTile('Grassi', product.fats, Colors.yellow[700]!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
