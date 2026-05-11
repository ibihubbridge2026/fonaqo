import 'package:flutter/material.dart';

import 'widgets/home_content.dart';
import '../../../widgets/main_wrapper.dart';

/// Onglet accueil du shell principal : corps défilant avec bouton flottant.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = MainShellScope.maybeOf(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: const HomeContent(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (shell != null) {
            shell.setIndex(1);
            shell.openCreateMission();
          }
        },
        backgroundColor: const Color(0xFFFFD400),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
