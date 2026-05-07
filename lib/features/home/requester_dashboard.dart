import 'package:flutter/material.dart';
import 'dart:async';

class RequesterDashboard extends StatefulWidget {
  const RequesterDashboard({super.key});

  @override
  State<RequesterDashboard> createState() => _RequesterDashboardState();
}

class _RequesterDashboardState extends State<RequesterDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // URLs d'images de secours au cas où Unsplash échoue (404)
  final List<String> _heroImages = [
    'assets/images/hero/img-1.jpeg',
    'assets/images/hero/img-2.jpg',
    'assets/images/hero/img-3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      // Utilisation de SafeArea pour éviter les artefacts en bas/haut sur certains modèles
      body: SafeArea(
        bottom: false, // On laisse le menu toucher le bas
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomAppBar(),              
              
              // Welcome Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bonjour, Thomas !", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    Text("Où pouvons-nous vous aider aujourd'hui ?", 
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 2. SLIDER AUTO UNISENS
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _pageController,
                  itemBuilder: (context, index) {
                    return _buildHeroSlide(index);
                  },
                ),
              ),

              const SizedBox(height: 25),

              // 1. BOUTON CRÉER (Ecart optimisé)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle, size: 22),
                  label: const Text("CRÉER UNE MISSION", 
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                ),
              ),

              // Missions en cours
              _buildSectionTitle("Missions en cours"),
              const SizedBox(height: 12),
              SizedBox(
                height: 85,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildMissionItem("Banque Nationale", "Marc", "En route"),
                    _buildMissionItem("Poste Centrale", "Julie", "Sur place"),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Suggestions
              _buildSectionTitle("Suggestions", showSeeAll: false),
              const SizedBox(height: 12),
              GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildCatCard("Banque", Icons.account_balance_rounded),
                  _buildCatCard("Admin", Icons.description_rounded),
                  _buildCatCard("Courses", Icons.shopping_bag_rounded),
                  _buildCatCard("Tickets", Icons.confirmation_number_rounded),
                  _buildCatCard("Resto", Icons.restaurant_rounded),
                  _buildCatCard("Santé", Icons.medical_services_rounded),
                ],
              ),

              const SizedBox(height: 25),

              // Historique rapide
              _buildSectionTitle("Historique rapide"),
              const SizedBox(height: 10),
              _buildHistoryItem("Bureau de Poste", "Hier, 14:30", "12,50€"),
              _buildHistoryItem("Billetterie Concert", "12 Oct, 10:15", "25,00€"),

              const SizedBox(height: 25),

              // 3. SECTION SIGNALER UN PROBLÈME
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: _buildReportProblemCard(),
              ),
              
              const SizedBox(height: 80), // Espace pour la navigation bar bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // --- WIDGETS DE CONSTRUCTION ---

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('assets/images/avatar/user.png'),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded), 
            onPressed: () => Navigator.pushNamed(context, '/chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSlide(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _heroImages[index % _heroImages.length],
            fit: BoxFit.cover,
            // GESTION DE L'ERREUR 404 / RESEAU
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomLeft,
            child: const Text("Palais des Congrès, Paris", 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showSeeAll = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (showSeeAll)
            TextButton(
              onPressed: () {}, 
              child: const Text("Voir tous", style: TextStyle(color: Color(0xFF715D00), fontWeight: FontWeight.bold))
            ),
        ],
      ),
    );
  }

  Widget _buildReportProblemCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFFFD400), shape: BoxShape.circle),
                child: const Icon(Icons.gpp_maybe_rounded, color: Colors.black),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Signaler un problème", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Un souci ? Nous intervenons.", 
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD400),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
            ),
            child: const Text("OUVRIR UN LITIGE", style: TextStyle(fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled, "Home"),
          _buildNavItem(1, Icons.assignment_rounded, "Missions"),
          _buildNavItem(2, Icons.confirmation_number_rounded, "Tickets"),
          _buildNavItem(3, Icons.person_rounded, "Profil"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFFD400) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isActive ? Colors.black : Colors.grey[400], size: 24),
          ),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, 
            color: isActive ? Colors.black : Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildCatCard(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFD400), size: 30),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMissionItem(String title, String waiter, String status) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text("Agent: $waiter", style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFD400).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.brown)),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, String price) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const CircleAvatar(backgroundColor: Color(0xFFF3F3F3), child: Icon(Icons.history, color: Colors.grey, size: 18)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ]),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}