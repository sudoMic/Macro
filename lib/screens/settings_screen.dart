import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/workout_provider.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isWorking = false;

  // ─── Export ───────────────────────────────────────────────────────────────

  Future<void> _export() async {
    bool expAll = true;
    bool expProducts = true;
    bool expDiary = true;
    bool expWorkouts = true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Esporta backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                title: const Text('Tutto (backup completo)'),
                value: true,
                groupValue: expAll,
                onChanged: (v) => setS(() => expAll = true),
                dense: true,
              ),
              RadioListTile<bool>(
                title: const Text('Selezione personalizzata'),
                value: false,
                groupValue: expAll,
                onChanged: (v) => setS(() => expAll = false),
                dense: true,
              ),
              if (!expAll) ...[
                const Divider(),
                CheckboxListTile(
                  title: const Text('I miei alimenti'),
                  value: expProducts,
                  onChanged: (v) => setS(() => expProducts = v!),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Diario alimentare'),
                  value: expDiary,
                  onChanged: (v) => setS(() => expDiary = v!),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Workout e sessioni'),
                  value: expWorkouts,
                  onChanged: (v) => setS(() => expWorkouts = v!),
                  dense: true,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Esporta')),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    setState(() => _isWorking = true);
    try {
      if (expAll) {
        // Backup DB grezzo
        final dbPath = p.join(await getDatabasesPath(), 'macro.db');
        final dbFile = File(dbPath);
        if (!await dbFile.exists()) { _showSnack('File DB non trovato.'); return; }
        final tempFile = File(p.join(Directory.systemTemp.path, 'macro_backup.db'));
        await dbFile.copy(tempFile.path);
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Attenzione'),
              content: const Text(
                'Se salvi su Google Drive assicurati che il nome finisca con ".db"\n\n'
                'Esempio: macro_backup.db\n\n'
                'Altrimenti l\'app non riuscirà ad importarlo.',
              ),
              actions: [
                FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        }
        await Share.shareXFiles(
          [XFile(tempFile.path, mimeType: 'application/octet-stream', name: 'macro_backup.db')],
          subject: 'Macro Backup',
        );
      } else {
        // JSON selettivo
        if (!expProducts && !expDiary && !expWorkouts) {
          _showSnack('Seleziona almeno una categoria.');
          return;
        }
        final db = context.read<DatabaseService>();
        final data = await db.exportData(
          products: expProducts,
          diary: expDiary,
          workouts: expWorkouts,
        );
        final json = const JsonEncoder.withIndent('  ').convert(data);
        final tempFile = File(p.join(Directory.systemTemp.path, 'macro_export.json'));
        await tempFile.writeAsString(json);
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Attenzione'),
              content: const Text(
                'Se salvi su Google Drive assicurati che il nome finisca con ".json"\n\n'
                'Esempio: macro_export.json\n\n'
                'Altrimenti l\'app non riuscirà ad importarlo.',
              ),
              actions: [
                FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        }
        await Share.shareXFiles(
          [XFile(tempFile.path, mimeType: 'application/json', name: 'macro_export.json')],
          subject: 'Macro Export',
        );
      }
    } catch (e) {
      _showSnack('Errore: $e');
    } finally {
      setState(() => _isWorking = false);
    }
  }

  // ─── Import ───────────────────────────────────────────────────────────────

  Future<void> _import() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importa backup'),
        content: const Text(
          'Seleziona un file di backup:\n\n'
          '• .db → ripristino completo (sostituisce tutto)\n'
          '• .json → importazione selettiva (integra i dati)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Seleziona file')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isWorking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // legge i bytes direttamente, funziona con Drive e qualsiasi fonte
      );
      if (result == null || result.files.single.bytes == null) return;

      final bytes = result.files.single.bytes!;
      final ext = result.files.single.extension?.toLowerCase();

      if (ext == 'db') {
        final dbPath = p.join(await getDatabasesPath(), 'macro.db');
        final db = context.read<DatabaseService>();
        await (await db.db).close();
        DatabaseService.resetInstance();
        await File(dbPath).writeAsBytes(bytes);
        _showSnack('Backup ripristinato. Riavvia l\'app.');
      } else if (ext == 'json') {
        final content = utf8.decode(bytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final db = context.read<DatabaseService>();
        await db.importData(data);
        // Ricarica il provider workout per mostrare subito i dati importati
        if (mounted && context.mounted) {
          await context.read<WorkoutProvider>().loadPlans();
        }
        _showSnack('Dati importati con successo.');
      } else {
        _showSnack('Formato non supportato. Usa .db o .json');
      }
    } catch (e) {
      _showSnack('Errore: $e');
    } finally {
      setState(() => _isWorking = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: Stack(
        children: [
          ListView(
            children: [
              // ─── Aspetto ────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Aspetto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.brightness_6_outlined),
                    const SizedBox(width: 16),
                    const Text('Tema'),
                    const Spacer(),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 18), tooltip: 'Chiaro'),
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 18), tooltip: 'Sistema'),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18), tooltip: 'Scuro'),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (s) => themeProvider.setTheme(s.first),
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // ─── Workout ────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined),
                    const SizedBox(width: 16),
                    const Text('Tempo recupero'),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _nearestValue(themeProvider.restSeconds),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30s')),
                        DropdownMenuItem(value: 45, child: Text('45s')),
                        DropdownMenuItem(value: 60, child: Text('1 min')),
                        DropdownMenuItem(value: 90, child: Text('1 min 30s')),
                        DropdownMenuItem(value: 120, child: Text('2 min')),
                        DropdownMenuItem(value: 150, child: Text('2 min 30s')),
                        DropdownMenuItem(value: 180, child: Text('3 min')),
                        DropdownMenuItem(value: 240, child: Text('4 min')),
                        DropdownMenuItem(value: 300, child: Text('5 min')),
                      ],
                      onChanged: (v) => themeProvider.setRestSeconds(v!),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.play_circle_outline),
                title: const Text('Avvia timer automaticamente'),
                subtitle: const Text('Parte dopo ogni serie aggiunta'),
                value: themeProvider.autoStartTimer,
                onChanged: (v) => themeProvider.setAutoStartTimer(v),
              ),
              const Divider(),

              // ─── Dati ───────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Dati', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('Esporta backup'),
                subtitle: const Text('Scegli cosa esportare'),
                onTap: _isWorking ? null : _export,
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Importa backup'),
                subtitle: const Text('Seleziona un file .db o .json'),
                onTap: _isWorking ? null : _import,
              ),
              const Divider(),
            ],
          ),
          if (_isWorking)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  static const _validValues = [30, 45, 60, 90, 120, 150, 180, 240, 300];
  static int _nearestValue(int seconds) =>
      _validValues.reduce((a, b) => (a - seconds).abs() < (b - seconds).abs() ? a : b);
}
