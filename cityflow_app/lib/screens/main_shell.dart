import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'alerts_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

/// Barre de navigation basse — Accueil / Carte / Alertes / Favoris / Profil.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  static const _screens = [
    HomeScreen(),
    MapScreen(),
    AlertsScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Carte'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: 'Alertes'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline_rounded), label: 'Favoris'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}
