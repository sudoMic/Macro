import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import 'saved_products_screen.dart';
import 'settings_screen.dart';
import 'pick_from_pantry_screen.dart';
import 'food_search_screen.dart';
import 'diary_entry_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadDate(DateTime.now());
    });
  }

  Future<void> _changeDate() async {
    final provider = context.read<DiaryProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) await provider.loadDate(picked);
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.kitchen_outlined),
              title: const Text('Dalla mia dispensa'),
              subtitle: const Text('Scegli tra i tuoi alimenti salvati'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PickFromPantryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Alimento generico'),
              subtitle: const Text('Cerca per nome con suggerimenti'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FoodSearchScreen()));
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
      appBar: AppBar(
        title: const Text(
          'Diario',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/schedule.png', width: 26),
            tooltip: 'Cambia data',
            onPressed: _changeDate,
          ),
          IconButton(
            icon: Image.asset('assets/chicken-leg.png', width: 26),
            tooltip: 'I miei alimenti',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SavedProductsScreen())),
          ),
          IconButton(
            icon: Image.asset('assets/settings.png', width: 24),
            tooltip: 'Impostazioni',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Consumer<DiaryProvider>(
        builder: (context, diary, _) {
          if (diary.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _DailyTotalsCard(totals: diary.totals, date: diary.selectedDate),
              ),
              if (diary.entries.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Nessun alimento registrato.\nPremi + per aggiungere.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: diary.entriesByMeal.length,
                  itemBuilder: (context, index) {
                    final meal = diary.entriesByMeal.keys.elementAt(index);
                    final entries = diary.entriesByMeal[meal]!;
                    return _MealSection(meal: meal, entries: entries);
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DailyTotalsCard extends StatelessWidget {
  final DailyTotals totals;
  final DateTime date;

  const _DailyTotalsCard({required this.totals, required this.date});

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    if (selected == today) return 'Oggi';
    if (selected == today.subtract(const Duration(days: 1))) return 'Ieri';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dateLabel, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TotalTile('Kcal', totals.kcal, Colors.orange, isKcal: true),
                _TotalTile('Carbo', totals.carbs, Colors.blue),
                _TotalTile('Proteine', totals.proteins, Colors.red),
                _TotalTile('Grassi', totals.fats, Colors.yellow[700]!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isKcal;

  const _TotalTile(this.label, this.value, this.color, {this.isKcal = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isKcal ? value.toStringAsFixed(0) : '${value.toStringAsFixed(1)}g',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  final String meal;
  final List<DiaryEntry> entries;

  const _MealSection({required this.meal, required this.entries});

  @override
  Widget build(BuildContext context) {
    final mealKcal = entries.fold(0.0, (s, e) => s + e.kcal);
    final mealCarbs = entries.fold(0.0, (s, e) => s + e.carbs);
    final mealProteins = entries.fold(0.0, (s, e) => s + e.proteins);
    final mealFats = entries.fold(0.0, (s, e) => s + e.fats);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(meal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text(
                '${mealKcal.toStringAsFixed(0)} kcal  '
                'C:${mealCarbs.toStringAsFixed(0)} '
                'P:${mealProteins.toStringAsFixed(0)} '
                'G:${mealFats.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        ...entries.map((e) => _DiaryEntryTile(entry: e)),
        const Divider(),
      ],
    );
  }
}

class _DiaryEntryTile extends StatelessWidget {
  final DiaryEntry entry;
  const _DiaryEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryEntryDetailScreen(entry: entry),
        ),
      ),
      title: Text(entry.productName, overflow: TextOverflow.ellipsis),
      subtitle: Text('${entry.grams.toStringAsFixed(0)}g'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.kcal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'C:${entry.carbs.toStringAsFixed(0)} P:${entry.proteins.toStringAsFixed(0)} G:${entry.fats.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => context.read<DiaryProvider>().removeEntry(entry.id!),
          ),
        ],
      ),
    );
  }
}
