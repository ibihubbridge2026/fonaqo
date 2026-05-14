import 'package:flutter/material.dart';
import 'package:fonaco/features/profile/widgets/country_selector.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/models/country_model.dart';
import '../../core/services/location_service.dart';
import '../../core/services/feedback_service.dart';
import '../auth/widgets/phone_input_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;
  String? _errorMessage;
  String _selectedRole = 'client';
  Country _selectedCountry = Country.defaultCountry;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fonction pour rendre l'erreur "humaine" (utilise le ErrorMapper du provider)
  String _cleanError(String error) {
    // Utiliser le formatage standard du AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.formatErrorMessage(error);
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Nettoyer le username pour qu'il soit valide selon Django (lettres, chiffres, @/./+/-/_)
        String cleanUsername = _nameController.text
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-zA-Z0-9@./+/-/_]'), '_')
            .replaceAll(RegExp(r'\s+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');

        final registerData = {
          'phone_number':
              '${_selectedCountry.dialCode}${_phoneController.text.trim()}',
          'username': cleanUsername.isEmpty
              ? 'user_${DateTime.now().millisecondsSinceEpoch}'
              : cleanUsername,
          'password': _passwordController.text.trim(),
          'role': _selectedRole,
          'email': _emailController.text.trim(),
        };

        final success = await authProvider.register(registerData);

        if (success && mounted) {
          // Demander la localisation après une inscription réussie
          await _requestLocationAfterRegistration();
          Navigator.pushReplacementNamed(context, AppRoutes.mainShell);
        }
      } catch (e) {
        setState(() => _errorMessage = _cleanError(e.toString()));
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
            // HEADER COMPACT
            Container(
              height: 160,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Créer un compte",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Rejoignez la communauté FONACO.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),

                    const SizedBox(height: 25),

                    // SÉLECTEUR DE RÔLE (HORIZONTAL & COMPACT)
                    Row(
                      children: [
                        _buildRoleOption(
                          "CLIENT",
                          Icons.person_outline,
                          _selectedRole == 'client',
                          () {
                            setState(() => _selectedRole = 'client');
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildRoleOption(
                          "AGENT",
                          Icons.verified_user_outlined,
                          _selectedRole == 'agent',
                          () {
                            setState(() => _selectedRole = 'agent');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // CHAMPS DE SAISIE
                    // _buildField(
                    //   controller: _nameController,
                    //   hint: "Nom complet",
                    //   icon: Icons.person_outline,
                    // ),
                    // const SizedBox(height: 15),

                    PhoneInputCard(
                      country: _selectedCountry,
                      onCountryPressed: () async {
                        final picked = await pickCountry(
                          context,
                          _selectedCountry,
                        );

                        if (picked != null) {
                          setState(() {
                            _selectedCountry = picked;
                          });
                        }
                      },
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 15),

                    _buildField(
                      controller: _emailController,
                      hint: "Email (Optionnel)",
                      icon: Icons.alternate_email,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    _buildField(
                      controller: _passwordController,
                      hint: "Mot de passe",
                      icon: Icons.lock_outline,
                      isPass: true,
                    ),

                    const SizedBox(height: 25),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // BOUTON PRINCIPAL (NOIR POUR LE CONTRASTE)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: const Color(0xFFFFD400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFD400),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "S'inscrire",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Déjà membre ?",
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Connexion",
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 35),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Demande la localisation après une inscription réussie
  Future<void> _requestLocationAfterRegistration() async {
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

  // Widget pour les boutons de rôle
  Widget _buildRoleOption(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFD400) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD400) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.black : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour les champs de texte
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPass = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPass && _isObscure,
      keyboardType: type,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }
}
