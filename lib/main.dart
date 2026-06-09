import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'services/database_service.dart';
import 'providers/diary_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Carica preferenze prima di avviare
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(MacroApp(themeProvider: themeProvider));
}

class MacroApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const MacroApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: dbService),
        ChangeNotifierProvider(create: (_) => DiaryProvider(dbService)),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(dbService)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, tp, _) {
          return MaterialApp(
            title: 'Macro',
            debugShowCheckedModeBanner: false,
            themeMode: tp.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
