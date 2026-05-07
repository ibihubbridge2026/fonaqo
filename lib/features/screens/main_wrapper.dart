import 'package:flutter/material.dart';
import '../home/requester_dashboard.dart'; // Ta page actuelle (renommée)
import '../widgets/main_navigation_bar.dart';
import '../widgets/custom_app_bar.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Liste de tes pages
  final List<Widget> _pages = [
    const RequesterDashboard(), // Le contenu de ton dashboard actuel
    const Center(child: Text("Page Missions")),
    const Center(child: Text("Page Tickets")),
    const Center(child: Text("Page Profil")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: _pages[_currentIndex],
      bottomNavigationBar: MainNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}