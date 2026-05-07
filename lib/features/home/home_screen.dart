import 'package:flutter/material.dart';

import 'widgets/home_content.dart';

/// Onglet accueil du shell principal : corps défilant sans scaffold dupliqué.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: const HomeContent(),
      ),
    );
  }
}
