import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/diary_provider.dart';
import '../services/database_service.dart';

const _meals = ['Colazione', 'Pranzo', 'Cena', 'Spuntino'];

/// Schermata per aggiungere un prodotto manualmente.
/// [onlySave] = true → salva solo in cache (da "I miei alimenti")
/// [onlySave] = false → aggiunge al diario (default)
class ManualEntryScreen extends StatefulWidget {
  final bool onlySave;
  const ManualEntryScreen({super.key, this.onlySave = false});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  final _kcalController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _fiberController = TextEditingController();
  final _saltController = TextEditingController();
  String _selectedMeal = 'Pranzo';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _gramsController.dispose();
    _kcalController.dispose();
    _carbsController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _fiberController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  double get _grams => double.tryParse(_gramsController.text) ?? 100;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final product = Product(
      barcode: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      kcal: double.tryParse(_kcalController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      proteins: double.tryParse(_proteinsController.text) ?? 0,
      fats: double.tryParse(_fatsController.text) ?? 0,
      fiber: double.tryParse(_fiberController.text),
      salt: double.tryParse(_saltController.text),
    );

    // Salva in cache SOLO se è modalità "salva in dispensa"
    if (widget.onlySave) {
      await context.read<DatabaseService>().cacheProduct(product);
    } else {
      // Aggiunge al diario senza toccare la dispensa
      await context.read<DiaryProvider>().addEntry(
            product: product,
            grams: _grams,
            meal: _selectedMeal,
          );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.onlySave ? 'Nuovo alimento' : 'Aggiungi manualmente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome prodotto *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Grammi e pasto solo se si aggiunge al diario
            if (!widget.onlySave) ...[
              TextFormField(
                controller: _gramsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantità (g) *',
                  border: OutlineInputBorder(),
                  suffixText: 'g',
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Inserisci una quantità valida';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 8),

            Text(
              'Valori nutrizionali per 100g',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            _MacroField(controller: _kcalController, label: 'Calorie (kcal)', color: Colors.orange),
            const SizedBox(height: 10),
            _MacroField(controller: _carbsController, label: 'Carboidrati (g)', color: Colors.blue),
            const SizedBox(height: 10),
            _MacroField(controller: _proteinsController, label: 'Proteine (g)', color: Colors.red),
            const SizedBox(height: 10),
            _MacroField(controller: _fatsController, label: 'Grassi (g)', color: Colors.yellow[700]!),
            const SizedBox(height: 10),
            _MacroField(controller: _fiberController, label: 'Fibre (g)', color: Colors.green),
            const SizedBox(height: 10),
            _MacroField(controller: _saltController, label: 'Sale (g)', color: Colors.blueGrey),
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
                    : Text(widget.onlySave ? 'Salva alimento' : 'Aggiungi al diario'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;

  const _MacroField({required this.controller, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(color: color),
      ),
    );
  }
}
