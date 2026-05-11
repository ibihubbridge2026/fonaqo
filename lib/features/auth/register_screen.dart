import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final registerData = {
          'phone_number': _phoneController.text.trim(),
          'username': _nameController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': _selectedRole,
        };

        final email = _emailController.text.trim();

        if (email.isNotEmpty && email.contains('@')) {
          registerData['email'] = email;
        }

        final success = await authProvider.register(registerData);

        if (success && mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.mainShell);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
        // Afficher la SnackBar moderne d'erreur
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          authProvider.showErrorSnackBar(context, _errorMessage!);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              height: 250,
              width: double.infinity,
              color: const Color(0xFFFFD400),
              child: Center(
                child: Image.asset(
                  'assets/icon/fonaco.png',
                  width: 100,
                  color: Colors.black,
                  errorBuilder: (_, _, __) {
                    return const Icon(
                      Icons.bolt,
                      color: Colors.black,
                      size: 100,
                    );
                  },
                ),
              ),
            ),

            // FORM
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Container(
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
                        const Text(
                          "Créer un compte",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Rejoignez l'aventure FONACO : Devenez un Agent d'élite ou déléguez vos tâches en toute sérénité.",
                          style: TextStyle(color: Color(0xFF5E5E5E)),
                        ),

                        const SizedBox(height: 24),

                        // SÉLECTEUR DE RÔLE
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 30,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "JE SUIS",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedRole = 'client',
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'client'
                                              ? const Color(0xFFFFD400)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _selectedRole == 'client'
                                                ? const Color(0xFFFFD400)
                                                : Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              color: _selectedRole == 'client'
                                                  ? Colors.black
                                                  : Colors.grey[600],
                                              size: 28,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              "CLIENT",
                                              style: TextStyle(
                                                color: _selectedRole == 'client'
                                                    ? Colors.black
                                                    : Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedRole = 'agent',
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'agent'
                                              ? const Color(0xFFFFD400)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _selectedRole == 'agent'
                                                ? const Color(0xFFFFD400)
                                                : Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.verified_user,
                                              color: _selectedRole == 'agent'
                                                  ? Colors.black
                                                  : Colors.grey[600],
                                              size: 28,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              "AGENT",
                                              style: TextStyle(
                                                color: _selectedRole == 'agent'
                                                    ? Colors.black
                                                    : Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // NOM
                        _buildInputLabel("NOM COMPLET"),

                        _buildTextField(
                          controller: _nameController,
                          placeholder: "Jean Dupont",
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Veuillez entrer votre nom";
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // PHONE
                        _buildInputLabel("NUMÉRO DE TÉLÉPHONE"),

                        _buildTextField(
                          controller: _phoneController,
                          placeholder: "+225 00 00 00 00",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Veuillez entrer votre numéro";
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // EMAIL
                        _buildInputLabel("EMAIL (OPTIONNEL)"),

                        _buildTextField(
                          controller: _emailController,
                          placeholder: "nom@exemple.com",
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 32),

                        // PASSWORD
                        _buildInputLabel("MOT DE PASSE"),

                        _buildTextField(
                          controller: _passwordController,
                          placeholder: "••••••••",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return "Minimum 6 caractères";
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // ERROR
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD400),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "S'inscrire",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Séparateur Google
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.grey)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "OU",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: Colors.grey)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Bouton Google
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () async {
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
                              "S'inscrire avec Google",
                              style: TextStyle(
                                color: Color(0xFFEA4335),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFEA4335)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Déjà un compte ?"),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Se connecter"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4D4632),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _isObscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: Icon(icon),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              )
            : null,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
