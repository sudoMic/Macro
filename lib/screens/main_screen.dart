import 'package:flutter/material.dart';
import 'diary_screen.dart';
import 'workout_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    WorkoutScreen(),
    DiaryScreen(),
    _GalleryPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: Image.asset('assets/gym.png', width: 24),
            selectedIcon: Image.asset('assets/gym.png', width: 24),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Image.asset('assets/recipe.png', width: 24),
            selectedIcon: Image.asset('assets/recipe.png', width: 24),
            label: 'Diario',
          ),
          NavigationDestination(
            icon: Image.asset('assets/photo-gallery.png', width: 24),
            selectedIcon: Image.asset('assets/photo-gallery.png', width: 24),
            label: 'Galleria',
          ),
        ],
      ),
    );
  }
}

class _GalleryPlaceholder extends StatelessWidget {
  const _GalleryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Galleria',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 22,
          ),
        ),
      ),
      body: const Center(
        child: Text('Prossimamente', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
