import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/country_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/feedback_service.dart';
import 'widgets/phone_input_card.dart';

/// Écran pour compléter le profil avec le numéro de téléphone (obligatoire après Google Auth)
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  Country _selectedCountry = Country.defaultCountry;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updatePhoneNumber() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final phoneNumber = '${_selectedCountry.dialCode}${_phoneController.text.trim()}';
      
      final success = await authProvider.updatePhoneNumber(phoneNumber);
      
      if (success && mounted) {
        FeedbackService.showSuccess(context, 'Numéro de téléphone enregistré avec succès !');
        
        // Rediriger vers le mainShell maintenant que le profil est complet
        Navigator.pushReplacementNamed(context, AppRoutes.mainShell);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Retour à l'écran de login si l'utilisateur refuse de compléter
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD400),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Finalisez votre profil',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pour utiliser Fonaqo, nous avons besoin de votre numéro de téléphone',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Formulaire
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Sélecteur de pays et téléphone
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

                  const SizedBox(height: 30),

                  // Message d'erreur
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Bouton de validation
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updatePhoneNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: const Color(0xFFFFD400),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFD400),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Valider',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Texte informatif
                  Text(
                    'Ce numéro sera utilisé pour vous contacter et pour la géolocalisation des missions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
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
