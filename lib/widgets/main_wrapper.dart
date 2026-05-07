import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../features/missions/missions_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/agents/agents_screen.dart';
import '../features/events/events_screen.dart';
import 'custom_app_bar.dart';
import 'main_navigation_bar.dart';

/// Accès aux méthodes du shell principal (changement d’onglet).
class MainShellScope extends InheritedWidget {
  final int currentIndex;
  final ValueChanged<int> setIndex;

  const MainShellScope({
    super.key,
    required this.currentIndex,
    required this.setIndex,
    required super.child,
  });

  static MainShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => currentIndex != oldWidget.currentIndex;
}

/// Conteneur principal après authentification : app bar dynamique + 4 destinations + navigation basse.
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    HomeScreen(),
    MissionsScreen(),
    AgentsScreen(),
    EventsScreen(),
    ProfileScreen(),
  ];  

  PreferredSizeWidget _appBarForIndex() {
    switch (_currentIndex) {
      case 0:
        return const CustomAppBar.mainShellHome();
      case 1:
        return const CustomAppBar.mainShellSection(sectionTitle: 'Missions');
      case 2:
        return const CustomAppBar.mainShellSection(sectionTitle: 'Agents');
      case 3:
        return const CustomAppBar.mainShellSection(sectionTitle: 'Événements');  
      case 4:
        return const CustomAppBar.mainShellSection(sectionTitle: 'Profil');
      default:
        return const CustomAppBar.mainShellHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      currentIndex: _currentIndex,
      setIndex: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: _appBarForIndex(),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: MainNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
