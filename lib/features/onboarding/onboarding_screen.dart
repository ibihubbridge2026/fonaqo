import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Gagnez du temps en déléguant vos tâches",
      "desc": "Ne faites plus jamais la queue. Nos agents s'en occupent pour vous.",
      "image": "assets/images/slide/slide-1.png",
    },
    {
      "title": "Découvrez nos services à la demande",
      "desc": "Courses, documents, procedure, déléguez vos missions en un clic et occupez vous de votre travail.",
      "image": "assets/images/slide/slide-2.png",
    },
    {
      "title": "Prêt pour L'aventure ? Démarrons ensemble",
      "desc": "Rejoignez l'écosystème de services humains le plus rapide du pays.",
      "image": "assets/images/slide/slide-3.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea empêche le contenu de coller en haut et en bas (encoches/barre système)
      body: SafeArea(
        child: Stack(
          children: [
            // Slider principal
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) {
                return OnboardingSlideView(
                  title: _onboardingData[index]['title']!,
                  description: _onboardingData[index]['desc']!,
                  imageAssetPath: _onboardingData[index]['image']!,
                );
              },
            ),

            // Bouton Passer (Positionné avec des marges sûres)
            if (_currentIndex < 2)
              Positioned(
                top: 10, // Un peu d'espace sous la barre de statut
                right: 20,
                child: TextButton(
                  onPressed: () => _pageController.animateToPage(2,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease),
                  child: const Text(
                    "Passer",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

            // Zone d'action (Indicateurs + Bouton)
            Positioned(
              bottom: 30, // Marge par rapport au bas de l'écran
              left: 30,
              right: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 6,
                        width: _currentIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? const Color(0xFFFFD700)
                              : Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Bouton Suivant / Démarrer
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < 2) {
                          _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease);
                        } else {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentIndex == 2
                            ? const Color(0xFFFFD700)
                            : Colors.black.withOpacity(0.08),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentIndex == 2 ? "Démarrer maintenant" : "Suivant",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentIndex == 2
                              ? Colors.black
                              : Colors.black.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page d’introduction : visuel en haut + titre + description sous le carrousel principal.
class OnboardingSlideView extends StatelessWidget {
  final String title;
  final String description;
  final String imageAssetPath;

  const OnboardingSlideView({
    super.key,
    required this.title,
    required this.description,
    required this.imageAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Image.asset(
                imageAssetPath,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, _, _) {
                  return Container(
                    color: const Color(0xFFE8E8E8),
                    alignment: Alignment.center,
                    child: const Icon(Icons.photo_size_select_actual_outlined, color: Colors.grey, size: 64),
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: Colors.black,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}