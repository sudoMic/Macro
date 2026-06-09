import 'workout.dart';

/// Lista di esercizi predefiniti organizzati per categoria.
const List<Exercise> predefinedExercises = [
  // Petto
  Exercise(name: 'Panca Piana', category: 'Petto'),
  Exercise(name: 'Panca Inclinata', category: 'Petto'),
  Exercise(name: 'Panca Declinata', category: 'Petto'),
  Exercise(name: 'Croci con Manubri', category: 'Petto'),
  Exercise(name: 'Dip alle Parallele', category: 'Petto'),
  Exercise(name: 'Push Up', category: 'Petto'),
  Exercise(name: 'Cable Crossover', category: 'Petto'),

  // Schiena
  Exercise(name: 'Stacco da Terra', category: 'Schiena'),
  Exercise(name: 'Trazioni', category: 'Schiena'),
  Exercise(name: 'Lat Machine', category: 'Schiena'),
  Exercise(name: 'Rematore con Bilanciere', category: 'Schiena'),
  Exercise(name: 'Rematore con Manubrio', category: 'Schiena'),
  Exercise(name: 'Pulley', category: 'Schiena'),
  Exercise(name: 'Face Pull', category: 'Schiena'),

  // Gambe
  Exercise(name: 'Squat', category: 'Gambe'),
  Exercise(name: 'Leg Press', category: 'Gambe'),
  Exercise(name: 'Affondi', category: 'Gambe'),
  Exercise(name: 'Leg Curl', category: 'Gambe'),
  Exercise(name: 'Leg Extension', category: 'Gambe'),
  Exercise(name: 'Calf Raises', category: 'Gambe'),
  Exercise(name: 'Romanian Deadlift', category: 'Gambe'),
  Exercise(name: 'Hip Thrust', category: 'Gambe'),

  // Spalle
  Exercise(name: 'Lento Avanti', category: 'Spalle'),
  Exercise(name: 'Alzate Laterali', category: 'Spalle'),
  Exercise(name: 'Alzate Frontali', category: 'Spalle'),
  Exercise(name: 'Arnold Press', category: 'Spalle'),
  Exercise(name: 'Alzate Posteriori', category: 'Spalle'),
  Exercise(name: 'Upright Row', category: 'Spalle'),

  // Bicipiti
  Exercise(name: 'Curl con Bilanciere', category: 'Bicipiti'),
  Exercise(name: 'Curl con Manubri', category: 'Bicipiti'),
  Exercise(name: 'Curl al Cavo', category: 'Bicipiti'),
  Exercise(name: 'Curl Martello', category: 'Bicipiti'),
  Exercise(name: 'Curl Concentrato', category: 'Bicipiti'),

  // Tricipiti
  Exercise(name: 'French Press', category: 'Tricipiti'),
  Exercise(name: 'Pushdown al Cavo', category: 'Tricipiti'),
  Exercise(name: 'Tricipiti con Manubrio', category: 'Tricipiti'),
  Exercise(name: 'Dip con Panca', category: 'Tricipiti'),
  Exercise(name: 'Close Grip Bench', category: 'Tricipiti'),

  // Addome
  Exercise(name: 'Crunch', category: 'Addome'),
  Exercise(name: 'Plank', category: 'Addome'),
  Exercise(name: 'Leg Raise', category: 'Addome'),
  Exercise(name: 'Russian Twist', category: 'Addome'),
  Exercise(name: 'Ab Wheel', category: 'Addome'),
];
