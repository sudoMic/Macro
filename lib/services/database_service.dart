import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/diary_entry.dart';
import '../models/recipe.dart';
import '../models/workout.dart';
import '../models/predefined_exercises.dart';

class DatabaseService {
  static Database? _db;

  /// Chiude e azzera l'istanza del DB (necessario per backup/restore).
  static void resetInstance() {
    _db = null;
  }

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'macro.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await _createFoodTables(db);
    await _createWorkoutTables(db);
    await _seedExercises(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createWorkoutTables(db);
      await _seedExercises(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN salt REAL');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      // Elimina duplicati in workout_plan_exercises tenendo solo il primo per coppia
      await db.execute('''
        DELETE FROM workout_plan_exercises
        WHERE id NOT IN (
          SELECT MIN(id) FROM workout_plan_exercises
          GROUP BY workout_plan_id, exercise_id
        )
      ''');
    }
  }

  Future<void> _createFoodTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        barcode TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        kcal REAL NOT NULL,
        carbs REAL NOT NULL,
        proteins REAL NOT NULL,
        fats REAL NOT NULL,
        fiber REAL,
        sugars REAL,
        salt REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diary_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_barcode TEXT NOT NULL,
        product_name TEXT NOT NULL,
        meal TEXT NOT NULL,
        grams REAL NOT NULL,
        kcal REAL NOT NULL,
        carbs REAL NOT NULL,
        proteins REAL NOT NULL,
        fats REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        servings INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        product_barcode TEXT NOT NULL,
        product_name TEXT NOT NULL,
        grams REAL NOT NULL,
        kcal REAL NOT NULL,
        carbs REAL NOT NULL,
        proteins REAL NOT NULL,
        fats REAL NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createWorkoutTables(Database db) async {
    // Esercizi (predefiniti + custom)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // Piani di allenamento
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    // Esercizi in un piano
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_plan_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (workout_plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE
      )
    ''');
    // Sessioni eseguite
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_plan_id INTEGER NOT NULL,
        workout_name TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    // Esercizi in una sessione
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE
      )
    ''');
    // Serie
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (session_exercise_id) REFERENCES session_exercises(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _seedExercises(Database db) async {
    for (final ex in predefinedExercises) {
      await db.insert('exercises', {
        'name': ex.name,
        'category': ex.category,
        'is_custom': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ─── PRODOTTI ─────────────────────────────────────────────────────────────

  Future<List<Product>> getAllCachedProducts() async {
    final d = await db;
    final rows = await d.query('products', orderBy: 'name ASC');
    return rows.map(Product.fromDb).toList();
  }

  Future<void> deleteCachedProduct(String barcode) async {
    final d = await db;
    await d.delete('products', where: 'barcode = ?', whereArgs: [barcode]);
  }

  Future<void> cacheProduct(Product product) async {
    final d = await db;
    await d.insert('products', product.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Product?> getCachedProduct(String barcode) async {
    final d = await db;
    final rows = await d.query('products', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    if (rows.isEmpty) return null;
    return Product.fromDb(rows.first);
  }

  // ─── DIARIO ───────────────────────────────────────────────────────────────

  Future<int> addDiaryEntry(DiaryEntry entry) async {
    final d = await db;
    return d.insert('diary_entries', entry.toDb());
  }

  Future<List<DiaryEntry>> getEntriesForDate(DateTime date) async {
    final d = await db;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await d.query('diary_entries',
        where: 'date = ?', whereArgs: [dateStr], orderBy: 'meal ASC, id ASC');
    return rows.map(DiaryEntry.fromDb).toList();
  }

  Future<void> deleteDiaryEntry(int id) async {
    final d = await db;
    await d.delete('diary_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ─── RICETTE ──────────────────────────────────────────────────────────────

  Future<int> saveRecipe(Recipe recipe) async {
    final d = await db;
    return d.transaction((txn) async {
      final recipeId = await txn.insert('recipes', {
        if (recipe.id != null) 'id': recipe.id,
        'name': recipe.name,
        'servings': recipe.servings,
      });
      for (final ingredient in recipe.ingredients) {
        await txn.insert('recipe_ingredients', ingredient.toDb(recipeId));
      }
      return recipeId;
    });
  }

  Future<List<Recipe>> getAllRecipes() async {
    final d = await db;
    final recipeRows = await d.query('recipes', orderBy: 'name ASC');
    final recipes = <Recipe>[];
    for (final row in recipeRows) {
      final id = row['id'] as int;
      final ingredientRows = await d.query('recipe_ingredients',
          where: 'recipe_id = ?', whereArgs: [id]);
      recipes.add(Recipe(
        id: id,
        name: row['name'] as String,
        servings: row['servings'] as int,
        ingredients: ingredientRows.map(RecipeIngredient.fromDb).toList(),
      ));
    }
    return recipes;
  }

  Future<void> deleteRecipe(int id) async {
    final d = await db;
    await d.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ESERCIZI ─────────────────────────────────────────────────────────────

  Future<List<Exercise>> getAllExercises() async {
    final d = await db;
    final rows = await d.query('exercises', orderBy: 'category ASC, name ASC');
    return rows.map(Exercise.fromDb).toList();
  }

  Future<int> addCustomExercise(String name, String category) async {
    final d = await db;
    return d.insert('exercises', {'name': name, 'category': category, 'is_custom': 1});
  }

  Future<void> deleteExercise(int id) async {
    final d = await db;
    await d.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteExerciseHistory(int exerciseId) async {
    final d = await db;
    // Elimina tutte le serie legate a quell'esercizio in tutte le sessioni
    await d.rawDelete('''
      DELETE FROM exercise_sets
      WHERE session_exercise_id IN (
        SELECT id FROM session_exercises WHERE exercise_id = ?
      )
    ''', [exerciseId]);
  }

  // ─── WORKOUT PLANS ────────────────────────────────────────────────────────

  Future<List<WorkoutPlan>> getAllWorkoutPlans() async {
    final d = await db;
    final planRows = await d.query('workout_plans', orderBy: 'name ASC');
    final plans = <WorkoutPlan>[];
    for (final row in planRows) {
      final id = row['id'] as int;
      final exRows = await d.query('workout_plan_exercises',
          where: 'workout_plan_id = ?', whereArgs: [id], orderBy: 'sort_order ASC');
      final exercises = exRows.map((r) => Exercise(
        id: r['exercise_id'] as int,
        name: r['exercise_name'] as String,
        category: '',
      )).toList();
      plans.add(WorkoutPlan(id: id, name: row['name'] as String, exercises: exercises));
    }
    return plans;
  }

  Future<int> createWorkoutPlan(String name) async {
    final d = await db;
    return d.insert('workout_plans', {'name': name});
  }

  Future<void> deleteWorkoutPlan(int id) async {
    final d = await db;
    await d.delete('workout_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addExerciseToPlan(int planId, Exercise exercise, int order) async {
    final d = await db;
    // Controlla se esiste già prima di inserire
    final existing = await d.query('workout_plan_exercises',
        where: 'workout_plan_id = ? AND exercise_id = ?',
        whereArgs: [planId, exercise.id ?? 0]);
    if (existing.isNotEmpty) return; // già presente, non duplicare
    await d.insert('workout_plan_exercises', {
      'workout_plan_id': planId,
      'exercise_id': exercise.id ?? 0,
      'exercise_name': exercise.name,
      'sort_order': order,
    });
  }

  Future<void> removeExerciseFromPlan(int planId, int exerciseId) async {
    final d = await db;
    await d.delete('workout_plan_exercises',
        where: 'workout_plan_id = ? AND exercise_id = ?',
        whereArgs: [planId, exerciseId]);
  }

  // ─── SESSIONI ─────────────────────────────────────────────────────────────

  Future<int> startSession(WorkoutPlan plan) async {
    final d = await db;
    // Ricarica gli esercizi del piano direttamente dal DB per evitare dati in cache errati
    final exRows = await d.query('workout_plan_exercises',
        where: 'workout_plan_id = ?',
        whereArgs: [plan.id],
        orderBy: 'sort_order ASC');
    final exercises = exRows.map((r) => Exercise(
      id: r['exercise_id'] as int,
      name: r['exercise_name'] as String,
      category: '',
    )).toList();

    return d.transaction((txn) async {
      final sessionId = await txn.insert('workout_sessions', {
        'workout_plan_id': plan.id ?? 0,
        'workout_name': plan.name,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      });
      for (final ex in exercises) {
        await txn.insert('session_exercises', {
          'session_id': sessionId,
          'exercise_id': ex.id ?? 0,
          'exercise_name': ex.name,
          'completed': 0,
        });
      }
      return sessionId;
    });
  }

  Future<WorkoutSession?> getSession(int sessionId) async {
    final d = await db;
    final rows = await d.query('workout_sessions', where: 'id = ?', whereArgs: [sessionId]);
    if (rows.isEmpty) return null;
    final exRows = await d.query('session_exercises',
        where: 'session_id = ?', whereArgs: [sessionId]);
    final exercises = <SessionExercise>[];
    for (final exRow in exRows) {
      final seId = exRow['id'] as int;
      final setRows = await d.query('exercise_sets',
          where: 'session_exercise_id = ?', whereArgs: [seId], orderBy: 'set_number ASC');
      exercises.add(SessionExercise.fromDb(exRow, sets: setRows.map(ExerciseSet.fromDb).toList()));
    }
    return WorkoutSession.fromDb(rows.first, exercises: exercises);
  }

  Future<List<WorkoutSession>> getSessionsForPlan(int planId) async {
    final d = await db;
    final rows = await d.query('workout_sessions',
        where: 'workout_plan_id = ?', whereArgs: [planId], orderBy: 'date DESC');
    return rows.map((r) => WorkoutSession.fromDb(r)).toList();
  }

  Future<void> deleteSession(int sessionId) async {
    final d = await db;
    // CASCADE elimina session_exercises e exercise_sets
    await d.delete('workout_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<void> markExerciseCompleted(int sessionExerciseId) async {
    final d = await db;
    await d.update('session_exercises', {'completed': 1},
        where: 'id = ?', whereArgs: [sessionExerciseId]);
  }

  Future<int> addSet(ExerciseSet set) async {
    final d = await db;
    return d.insert('exercise_sets', set.toDb());
  }

  Future<void> updateSet(ExerciseSet set) async {
    final d = await db;
    await d.update('exercise_sets', set.toDb(), where: 'id = ?', whereArgs: [set.id]);
  }

  Future<void> deleteSet(int id) async {
    final d = await db;
    await d.delete('exercise_sets', where: 'id = ?', whereArgs: [id]);
  }

  /// Storico serie per un esercizio specifico (tutte le sessioni).
  Future<List<Map<String, dynamic>>> getExerciseHistory(int exerciseId) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT ws.date, ws.id as session_id, es.weight, es.reps, es.set_number
      FROM exercise_sets es
      JOIN session_exercises se ON es.session_exercise_id = se.id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE se.exercise_id = ?
      ORDER BY ws.date ASC, es.set_number ASC
    ''', [exerciseId]);
    return rows;
  }

  // ─── EXPORT / IMPORT ──────────────────────────────────────────────────────

  /// Esporta i dati selezionati come Map JSON-serializzabile.
  Future<Map<String, dynamic>> exportData({
    bool products = true,
    bool diary = true,
    bool workouts = true,
  }) async {
    final d = await db;
    final data = <String, dynamic>{
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
    };

    if (products) {
      data['products'] = await d.query('products');
    }
    if (diary) {
      data['diary_entries'] = await d.query('diary_entries', orderBy: 'date ASC');
    }
    if (workouts) {
      data['workout_plans'] = await d.query('workout_plans');
      data['workout_plan_exercises'] = await d.query('workout_plan_exercises');
      data['exercises_custom'] = await d.query('exercises', where: 'is_custom = 1');
      data['workout_sessions'] = await d.query('workout_sessions', orderBy: 'date ASC');
      data['session_exercises'] = await d.query('session_exercises');
      data['exercise_sets'] = await d.query('exercise_sets');
    }

    return data;
  }

  /// Importa dati da un Map JSON. Elimina i dati esistenti prima di inserire per evitare duplicati.
  Future<void> importData(Map<String, dynamic> data) async {
    final d = await db;

    await d.transaction((txn) async {
      if (data.containsKey('products')) {
        for (final row in (data['products'] as List)) {
          await txn.insert('products', Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data.containsKey('diary_entries')) {
        for (final row in (data['diary_entries'] as List)) {
          final r = Map<String, dynamic>.from(row)..remove('id');
          await txn.insert('diary_entries', r,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      if (data.containsKey('workout_plans')) {
        // Elimina prima gli esercizi dei piani che verranno sovrascritti
        for (final row in (data['workout_plans'] as List)) {
          final planId = (row as Map)['id'];
          if (planId != null) {
            await txn.delete('workout_plan_exercises',
                where: 'workout_plan_id = ?', whereArgs: [planId]);
          }
        }
        for (final row in (data['workout_plans'] as List)) {
          await txn.insert('workout_plans', Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data.containsKey('workout_plan_exercises')) {
        for (final row in (data['workout_plan_exercises'] as List)) {
          await txn.insert('workout_plan_exercises', Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data.containsKey('exercises_custom')) {
        for (final row in (data['exercises_custom'] as List)) {
          await txn.insert('exercises', Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data.containsKey('workout_sessions')) {
        for (final row in (data['workout_sessions'] as List)) {
          // Elimina session_exercises esistenti per questa sessione
          final sessionId = (row as Map)['id'];
          if (sessionId != null) {
            await txn.delete('session_exercises',
                where: 'session_id = ?', whereArgs: [sessionId]);
          }
          await txn.insert('workout_sessions', Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data.containsKey('session_exercises')) {
        for (final row in (data['session_exercises'] as List)) {
          final seId = (row as Map)['id'];
          if (seId != null) {
            await txn.delete('exercise_sets',
                where: 'session_exercise_id = ?', whereArgs: [seId]);
          }
          await txn.insert('session_exercises', Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data.containsKey('exercise_sets')) {
        for (final row in (data['exercise_sets'] as List)) {
          await txn.insert('exercise_sets', Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}
