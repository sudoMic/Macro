# Macro

App per tracciare calorie, macronutrienti e allenamenti. Nessun account, tutto salvato localmente sul dispositivo.

---

## Funzionalità

### Diario alimentare
- Aggiunta alimenti tramite **scansione barcode** (Open Food Facts)
- **Ricerca per nome** con suggerimenti automatici
- Scelta dalla **dispensa personale** di alimenti salvati
- Selezione grammi con chip preimpostati (50/100/150/200g) o valore custom
- Totali giornalieri di kcal, carboidrati, proteine e grassi
- Suddivisione per pasto: Colazione, Pranzo, Cena, Spuntino
- Navigazione tra date passate tramite calendario
- Dettaglio alimento con valori nutrizionali completi (kcal, carbo, proteine, grassi, fibre, zuccheri, sale)

### Workout
- Creazione di piani di allenamento personalizzati (es. Gambe, Upper, Full Body)
- Lista esercizi predefiniti per categoria + possibilità di aggiungerne custom
- Sessioni di allenamento con tracciamento serie × rip × peso
- **Timer di recupero** integrato con pausa, reset e avvio automatico configurabile
- **Schermo sempre acceso** durante il timer di recupero
- **PR automatico** — l'app rileva quando batti il tuo massimo storico
- Navigazione tra esercizi con frecce e swipe
- Storico sessioni con grafico del peso per set
- Drag & drop per riordinare i workout
- Storico consultabile per ogni piano

### Impostazioni
- Tema chiaro / scuro / sistema
- Tempo di recupero personalizzabile (30s → 5min)
- Avvio timer automatico on/off
- **Backup completo** del database (.db)
- **Esportazione selettiva** in JSON (scegli tra alimenti, diario, workout)
- **Importazione** da file .db o .json

---

## Stack tecnico

| Componente | Tecnologia |
|---|---|
| Framework | Flutter |
| State management | Provider |
| Database locale | SQLite (sqflite + sqflite_common_ffi) |
| Barcode scanning | mobile_scanner |
| Dati nutrizionali | Open Food Facts API |
| Preferenze | shared_preferences |
| Backup/share | share_plus |
| Selezione file import | file_picker |
| Schermo sempre acceso | wakelock_plus |
| Localizzazione | flutter_localizations (italiano) |

---

## Installazione

### Requisiti
- Flutter SDK ≥ 3.0.0
- Android SDK compileSdk 36

### Build

```bash
git clone https://github.com/sudoMic/Macro.git
cd Macro
flutter pub get
flutter run                        # debug su dispositivo collegato
flutter build apk --release        # APK release
```

L'APK si trova in:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Struttura del progetto

```
lib/
├── main.dart
├── models/
│   ├── product.dart
│   ├── diary_entry.dart
│   ├── recipe.dart
│   ├── workout.dart
│   └── predefined_exercises.dart
├── services/
│   ├── database_service.dart
│   └── open_food_facts_service.dart
├── providers/
│   ├── diary_provider.dart
│   ├── workout_provider.dart
│   └── theme_provider.dart
└── screens/
    ├── main_screen.dart
    ├── diary_screen.dart
    ├── diary_entry_detail_screen.dart
    ├── scanner_screen.dart
    ├── add_entry_screen.dart
    ├── manual_entry_screen.dart
    ├── food_search_screen.dart
    ├── saved_products_screen.dart
    ├── pick_from_pantry_screen.dart
    ├── product_detail_screen.dart
    ├── workout_screen.dart
    ├── workout_plan_screen.dart
    ├── workout_exercises_screen.dart
    ├── active_session_screen.dart
    ├── exercise_detail_screen.dart
    ├── workout_history_screen.dart
    └── settings_screen.dart
```

---

## Dati e privacy

Tutti i dati rimangono sul dispositivo. L'app non richiede account, non invia dati a server esterni ad eccezione delle chiamate a Open Food Facts per il lookup dei prodotti tramite barcode o ricerca testuale.
