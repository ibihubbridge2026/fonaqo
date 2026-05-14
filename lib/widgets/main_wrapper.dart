import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../features/client/home/home_screen.dart';
import '../features/client/missions/missions_screen.dart';
import '../features/client/profile/profile_screen.dart';
import '../features/client/agents_screen.dart';
import '../features/events/events_screen.dart';
import 'custom_app_bar.dart';
import 'main_navigation_bar.dart';

/// Accès aux méthodes du shell principal (changement d’onglet).
class MainShellScope extends InheritedWidget {
  final int currentIndex;
  final ValueChanged<int> setIndex;
  final VoidCallback openCreateMission;
  final VoidCallback closeCreateMission;

  const MainShellScope({
    super.key,
    required this.currentIndex,
    required this.setIndex,
    required this.openCreateMission,
    required this.closeCreateMission,
    required super.child,
  });

  static MainShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      currentIndex != oldWidget.currentIndex;
}

/// Conteneur principal après authentification : app bar dynamique + 4 destinations + navigation basse.
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final ValueNotifier<bool> _showCreateMission = ValueNotifier<bool>(false);
  bool _locationPermissionGranted = false;
  bool _showLocationBanner = false;

  late final List<Widget> _pages = [
    const HomeScreen(),
    MissionsScreen(showCreateMissionListenable: _showCreateMission),
    const AgentsScreen(),
    const EventsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _showLocationBanner = true;
      });
      return;
    }

    // Demander la permission de localisation
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _showLocationBanner = true;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _showLocationBanner = true;
      });
      return;
    }

    setState(() {
      _locationPermissionGranted = true;
      _showLocationBanner = false;
    });
  }

  PreferredSizeWidget _appBarForIndex() {
    // Demande: mêmes header pour Missions/Agents/Événements/Profil que pour Home.
    return const CustomAppBar.mainShellHome();
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
      openCreateMission: () => _showCreateMission.value = true,
      closeCreateMission: () => _showCreateMission.value = false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: _appBarForIndex(),
        body: Column(
          children: [
            // Bannière discrète si GPS refusé
            if (_showLocationBanner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La position est désactivée. Vous devrez saisir les adresses manuellement.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showLocationBanner = false;
                        });
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
              ),
            // Contenu principal
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ],
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
