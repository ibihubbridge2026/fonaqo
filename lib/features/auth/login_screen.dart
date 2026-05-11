import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import 'widgets/input_card.dart';
import 'widgets/phone_input_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isPasswordVisible = false;

  Country _country =
      Country.benin(); // Bénin par défaut pour l'Afrique de l'Ouest
  final bool _usePhone = true; // Téléphone par défaut pour l'Afrique

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();

    final identifier = _usePhone ? _phone.text : _email.text;
    final password = _password.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await authProvider.login({
      'phone_number': identifier,
      'password': password,
    });

    if (success && authProvider.isAuthenticated) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.mainShell);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void initState() {
    super.initState();

    // Écouter les erreurs de l'AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().addListener(_onAuthStateChanged);
    });
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.errorMessage != null && mounted) {
      _showErrorSnackBar(authProvider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 309,
              width: double.infinity,
              color: const Color(0xFFFFD400),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/icon/fonaco.png',
                    width: 120,
                    color: Colors.black,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.bolt, color: Colors.black, size: 120),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(26),
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
                          const Text(
                            "Bon retour",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Connectez-vous maintenant !",
                            style: TextStyle(color: Color(0xFF5E5E5E)),
                          ),
                          const SizedBox(height: 18),

                          // Champ téléphone uniquement
                          PhoneInputCard(
                            country: _country,
                            onCountryPressed: () async {
                              final picked = await pickCountry(
                                context,
                                _country,
                              );
                              if (picked != null) {
                                setState(() => _country = picked);
                              }
                            },
                            controller: _phone,
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'MOT DE PASSE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.forgotPassword,
                                ),
                                child: const Text(
                                  "Mot de passe oublié ?",
                                  style: TextStyle(
                                    color: Color(0xFF715D00),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          InputCard(
                            child: TextField(
                              controller: _password,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFFD400,
                                        ),
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                      child: authProvider.isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.black,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              "Se connecter",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (authProvider.errorMessage != null)
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            authProvider.errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            border: Border.all(
                                              color: Colors.red.shade200,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            authProvider.errorMessage!,
                                            style: TextStyle(
                                              color: Colors.red.shade800,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "OU CONTINUER AVEC",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF5E5E5E),
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final authProvider = context
                                    .read<AuthProvider>();
                                final success = await authProvider
                                    .signInWithGoogle();
                                if (success && mounted) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.mainShell,
                                  );
                                }
                              },
                              icon: const FaIcon(
                                FontAwesomeIcons.google,
                                color: Color(0xFFEA4335),
                                size: 20,
                              ),
                              label: const Text(
                                "Continuer avec Google",
                                style: TextStyle(
                                  color: Color(0xFFEA4335),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFEA4335),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Pas encore de compte ?",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5E5E5E),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.register,
                                ),
                                child: const Text(
                                  "S'inscrire",
                                  style: TextStyle(
                                    color: Color(0xFF715D00),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "Propulsé par IBIHUB BRIDGE",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
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
}
