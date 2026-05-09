import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Jaune
            Container(
              height: 250, // Un peu plus court pour laisser de la place au formulaire plus long
              width: double.infinity,
              color: const Color(0xFFFFD400),
              child: Stack(
                alignment: Alignment.center,
                children: [                  
                  Image.asset(
                    'assets/icon/fonaco.png',
                    width: 100,
                    color: Colors.black,
                    errorBuilder: (_, _, _) {
                      return const Icon(Icons.bolt, color: Colors.black, size: 100);
                    },
                  ),
                ],
              ),
            ),

            // Formulaire d'inscription
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text("Créer un compte",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter')),
                          const Text("Rejoignez l'aventure FONAQO",
                              style: TextStyle(
                                  color: Color(0xFF5E5E5E),
                                  fontFamily: 'Manrope')),
                          const SizedBox(height: 24),

                          // CHAMP NOM COMPLET
                          _buildInputLabel("NOM COMPLET"),
                          _buildTextField("Jean Dupont", Icons.person_outline),
                          const SizedBox(height: 16),

                          // CHAMP TÉLÉPHONE (obligatoire)
                          _buildInputLabel("TÉLÉPHONE"),
                          _buildTextField("+225 00 00 00 00", Icons.phone_outlined),
                          const SizedBox(height: 16),

                          // CHAMP EMAIL (optionnel)
                          _buildInputLabel("EMAIL (OPTIONNEL)"),
                          _buildTextField("nom@exemple.com", Icons.mail_outline),
                          const SizedBox(height: 16),

                          // CHAMP MOT DE PASSE
                          _buildInputLabel("MOT DE PASSE"),
                          _buildTextField("••••••••", Icons.lock_outline, isPassword: true),
                          
                          const SizedBox(height: 24),

                          // Bouton S'inscrire
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                // Logique d'inscription
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD400),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              ),
                              child: const Text("S'inscrire", 
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[200])),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text("OU S'INSCRIRE AVEC", 
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
                              ),
                              Expanded(child: Divider(color: Colors.grey[200])),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Social Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _socialButton(const Color(0xFFEA4335), FontAwesomeIcons.google),
                              const SizedBox(width: 15),
                              _socialButton(const Color(0xFF1877F2), FontAwesomeIcons.facebookF),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Lien Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Déjà un compte ?", style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E))),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Se connecter", style: TextStyle(color: Color(0xFF715D00), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Propulsé par IBIHUB BRIDGE", 
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper pour les labels
  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4D4632))),
    );
  }

  // Helper pour les champs texte
  Widget _buildTextField(String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF4D4632), size: 18),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // Helper pour les boutons sociaux ronds
  Widget _socialButton(Color color, IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: FaIcon(icon, color: Colors.white, size: 18)),
    );
  }
}