import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/models/country_model.dart' as country_model;
import '../../core/providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/location_service.dart';
import 'widgets/input_card.dart';
import 'widgets/phone_input_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _isPasswordVisible = false;

  country_model.Country _country = country_model.Country.defaultCountry;

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();

    final identifier = '${_country.dialCode}${_phone.text.trim()}';

    final password = _password.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      FeedbackService.showError(
        context,
        'Veuillez remplir tous les champs',
      );
      return;
    }

    final success = await authProvider.login({
      'phone_number': identifier,
      'password': password,
    });

    if (success && mounted) {
      // Demander la localisation après une connexion réussie
      await _requestLocationAfterLogin();

      // Vérifier si l'utilisateur a un numéro de téléphone
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser?.phoneNumber == null ||
          currentUser!.phoneNumber!.isEmpty) {
        // Rediriger vers l'écran de complétion de profil
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.completeProfile,
        );
      } else {
        // Rediriger vers le mainShell si le profil est complet
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.mainShell,
        );
      }
    }
  }

  /// Demande la localisation après une connexion réussie
  Future<void> _requestLocationAfterLogin() async {
    try {
      final locationService = LocationService();
      final permissionStatus = await locationService.checkAndRequestLocation();

      if (permissionStatus == LocationPermissionStatus.granted) {
        // La permission est accordée, obtenir la position actuelle
        await locationService.getCurrentLocation();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Localisation activée avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // La permission est refusée, afficher un message explicatif
        String message =
            'La localisation est nécessaire pour vous proposer des missions proches de vous.';

        if (permissionStatus == LocationPermissionStatus.deniedForever) {
          message +=
              ' Veuillez l\'activer dans les paramètres de votre appareil.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: permissionStatus == LocationPermissionStatus.deniedForever
                  ? SnackBarAction(
                      label: 'Paramètres',
                      textColor: Colors.white,
                      onPressed: () => locationService.openAppSettings(),
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erreur lors de l\'activation de la localisation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD400),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon/fonaco.png',
                    width: 70,
                    color: Colors.black,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.bolt,
                      size: 70,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FONACO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bon retour 👋",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Connectez-vous à votre compte.",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // PHONE INPUT
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

                  const SizedBox(height: 18),

                  const Text(
                    'MOT DE PASSE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  InputCard(
                    child: TextField(
                      controller: _password,
                      obscureText: !_isPasswordVisible,
                      autofocus: false,
                      focusNode: FocusNode(),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.lock_outline),
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

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        );
                      },
                      child: const Text(
                        "Mot de passe oublié ?",
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
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
                              onPressed:
                                  authProvider.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: const Color(0xFFFFD400),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFFFD400),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Se connecter",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          if (authProvider.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                authProvider.errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey[300]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        child: Text(
                          "OU",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey[300]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();

                        final success = await authProvider.signInWithGoogle();

                        if (success && mounted) {
                          // Demander la localisation après une connexion Google réussie
                          await _requestLocationAfterLogin();
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.mainShell,
                          );
                        }
                      },
                      icon: const FaIcon(
                        FontAwesomeIcons.google,
                        color: Color(0xFFEA4335),
                        size: 18,
                      ),
                      label: const Text(
                        "Continuer avec Google",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Pas encore de compte ?",
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.register,
                          );
                        },
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
