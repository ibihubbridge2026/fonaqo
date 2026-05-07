import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Importation nécessaire
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header: Section Jaune (Height 309px selon HTML)
            Container(
              height: 309,
              width: double.infinity,
              color: const Color(0xFFFFD400),
              child: Stack(
                alignment: Alignment.center,
                children: [              
                  // Logo Central en Noir (filter: brightness(500) invert(1) simulé)
                  Image.asset(
                    'assets/icon/fonaco.png',
                    width: 120,
                    color: Colors.black, // Force le logo en noir
                  ),
                ],
              ),
            ),

            // Main Content Area (-mt-16 pour l'effet de chevauchement)
            Transform.translate(
              offset: const Offset(0, -64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Carte Login
                    Container(
                      padding: const EdgeInsets.all(32),
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
                          const Text("Bon retour 👋",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter')),
                          const Text("Connectez-vous maintenant !",
                              style: TextStyle(
                                  color: Color(0xFF5E5E5E),
                                  fontFamily: 'Manrope')),
                          const SizedBox(height: 32),

                          // Formulaire
                          _buildInputLabel("EMAIL"),
                          _buildTextField("nom@exemple.com", Icons.mail_outline),
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInputLabel("MOT DE PASSE"),
                              TextButton(
                                onPressed: () {},
                                child: const Text("Mot de passe oublié ?",
                                    style: TextStyle(color: Color(0xFF715D00), fontSize: 12)),
                              ),
                            ],
                          ),
                          _buildTextField("••••••••", Icons.lock_outline, isPassword: true),
                          
                          const SizedBox(height: 32),

                          // Bouton Se Connecter
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD400),
                                foregroundColor: Colors.black,
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              ),
                              child: const Text("Se connecter", 
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text("OU CONTINUER AVEC", 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5E5E5E))),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Social Login Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _socialButton(
                                color: const Color(0xFFEA4335), // Rouge Google
                                icon: FontAwesomeIcons.google,
                                onTap: () => print("Google Login"),
                              ),
                              const SizedBox(width: 20),
                              _socialButton(
                                color: const Color(0xFF1877F2), // Bleu Facebook
                                icon: FontAwesomeIcons.facebookF,
                                onTap: () => print("Facebook Login"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Pas encore de compte ?", style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E))),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                child: const Text("S'inscrire", style: TextStyle(color: Color(0xFF715D00), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text("Propulsé par IBIHUB BRIDGE", 
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4D4632))),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF4D4632), size: 20),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _socialButton({required Color color, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
        ),
        alignment: Alignment.center,
        child: FaIcon(icon, color: Colors.white, size: 20), // Utilise FaIcon pour FontAwesome
      ),
    );
  }
}