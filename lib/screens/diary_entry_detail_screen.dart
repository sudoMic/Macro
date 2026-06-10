import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diary_entry.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class DiaryEntryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  const DiaryEntryDetailScreen({super.key, required this.entry});

  @override
  State<DiaryEntryDetailScreen> createState() => _DiaryEntryDetailScreenState();
}

class _DiaryEntryDetailScreenState extends State<DiaryEntryDetailScreen> {
  Product? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final product = await context
        .read<DatabaseService>()
        .getCachedProduct(widget.entry.productBarcode);
    if (mounted) setState(() => _product = product);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;

    return Scaffold(
      appBar: AppBar(title: Text(e.productName, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info base
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_product?.brand.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_product!.brand,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(e.meal, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Text('${e.grams.toStringAsFixed(0)}g',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Valori per la quantità consumata
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valori per ${e.grams.toStringAsFixed(0)}g',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  _Row('Calorie', '${e.kcal.toStringAsFixed(0)} kcal', Colors.orange),
                  const Divider(),
                  _Row('Carboidrati', '${e.carbs.toStringAsFixed(1)}g', Colors.blue),
                  const Divider(),
                  _Row('Proteine', '${e.proteins.toStringAsFixed(1)}g', Colors.red),
                  const Divider(),
                  _Row('Grassi', '${e.fats.toStringAsFixed(1)}g', Colors.yellow[700]!),
                  if (_product?.fiber != null) ...[
                    const Divider(),
                    _Row('Fibre',
                        '${(_product!.fiber! * e.grams / 100).toStringAsFixed(1)}g',
                        Colors.green),
                  ],
                  if (_product?.salt != null) ...[
                    const Divider(),
                    _Row('Sale',
                        '${(_product!.salt! * e.grams / 100).toStringAsFixed(2)}g',
                        Colors.blueGrey),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Row(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 16,
              color: color,
              margin: const EdgeInsets.only(right: 10)),
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
