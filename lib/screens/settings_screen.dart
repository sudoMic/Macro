import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isWorking = false;

  // ─── Export ───────────────────────────────────────────────────────────────

  Future<void> _exportDb() async {
    setState(() => _isWorking = true);
    try {
      final dbPath = p.join(await getDatabasesPath(), 'macro.db');
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        _showSnack('File DB non trovato.');
        return;
      }

      // Copia con nome leggibile nella temp dir
      final now = DateTime.now();
      final fileName =
          'macro_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.db';
      final tempFile = File(p.join(Directory.systemTemp.path, fileName));
      await dbFile.copy(tempFile.path);

      // Share sheet — l'utente sceglie dove salvarlo
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Macro DB Backup',
      );
    } catch (e) {
      _showSnack('Errore: $e');
    } finally {
      setState(() => _isWorking = false);
    }
  }

  // ─── Import ───────────────────────────────────────────────────────────────

  Future<void> _importDb() async {
    // Mostra istruzioni su dove mettere il file
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importa backup'),
        content: const Text(
          'Copia il file di backup (.db) nella cartella Download del telefono '
          'e rinominalo "macro_backup.db", poi premi Importa.\n\n'
          'I dati attuali verranno sostituiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importa'),
          ),
        ],
      ),
    );
    if (proceed != true) return;

    setState(() => _isWorking = true);
    try {
      // Cerca il file in Download
      final possiblePaths = [
        '/sdcard/Download/macro_backup.db',
        '/storage/emulated/0/Download/macro_backup.db',
      ];

      File? backupFile;
      for (final path in possiblePaths) {
        final f = File(path);
        if (await f.exists()) {
          backupFile = f;
          break;
        }
      }

      if (backupFile == null) {
        _showSnack('File non trovato. Assicurati che si chiami "macro_backup.db" e sia in Download.');
        return;
      }

      final dbPath = p.join(await getDatabasesPath(), 'macro.db');

      // Chiudi DB prima di sovrascriverlo
      final db = context.read<DatabaseService>();
      await (await db.db).close();
      DatabaseService.resetInstance();

      await backupFile.copy(dbPath);
      _showSnack('Backup ripristinato. Riavvia l\'app per applicare le modifiche.');
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

  // ─── UI ───────────────────────────────────────────────────────────────────

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
                child: Text('Aspetto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode, size: 18),
                          tooltip: 'Chiaro',
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto, size: 18),
                          tooltip: 'Sistema',
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode, size: 18),
                          tooltip: 'Scuro',
                        ),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (s) => themeProvider.setTheme(s.first),
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // ─── Workout ────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Workout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
              const Divider(),

              // ─── Dati ───────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Dati',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('Esporta backup'),
                subtitle: const Text('Condividi o salva una copia del database'),
                onTap: _isWorking ? null : _exportDb,
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Importa backup'),
                subtitle: const Text('Ripristina da macro_backup.db in Download'),
                onTap: _isWorking ? null : _importDb,
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

  static int _nearestValue(int seconds) {
    return _validValues.reduce((a, b) =>
        (a - seconds).abs() < (b - seconds).abs() ? a : b);
  }
}
