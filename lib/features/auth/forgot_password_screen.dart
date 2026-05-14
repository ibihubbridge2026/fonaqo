import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/feedback_service.dart';
import 'widgets/input_card.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final authProvider = context.read<AuthProvider>();

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      FeedbackService.showError(
        context,
        'Veuillez entrer votre email',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final success = await authProvider.forgotPassword({
        'email': email,
      });

      if (success) {
        setState(() {
          _successMessage =
              'Un code de récupération a été envoyé à votre adresse email';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = authProvider.formatErrorMessage(
          e.toString(),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
            // HEADER STYLE REGISTER
            Container(
              height: 170,
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
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.bolt,
                        color: Colors.black,
                        size: 70,
                      );
                    },
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
                    "Mot de passe oublié",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Entrez votre adresse email pour recevoir un code de récupération.",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // EMAIL FIELD
                  const Text(
                    'EMAIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  InputCard(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'nom@exemple.com',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ERROR MESSAGE
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(
                          color: Colors.red.shade200,
                        ),
                        borderRadius: BorderRadius.circular(12),
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

                  // SUCCESS MESSAGE
                  if (_successMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(
                          color: Colors.green.shade200,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: Colors.green.shade800,
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
                      onPressed:
                          _isLoading ? null : _handleForgotPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: const Color(0xFFFFD400),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFD400),
                              ),
                            )
                          : const Text(
                              "Envoyer le code",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // BACK TO LOGIN
                  Center(
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Rééssayez  ?",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5E5E5E),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                          child: const Text(
                            "Connexion",
                            style: TextStyle(
                              color: Color(0xFF715D00),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // FOOTER
                  // const Center(
                  //   child: Text(
                  //     "Propulsé par IBIHUB BRIDGE",
                  //     style: TextStyle(
                  //       fontSize: 12,
                  //       color: Colors.grey,
                  //     ),
                  //   ),
                  // ),

                  // const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}