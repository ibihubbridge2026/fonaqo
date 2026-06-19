import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/widgets/custom_app_bar.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/widgets/profile/profile_widgets.dart';

/// Paramètres de sécurité (mot de passe, biométrie à venir).
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoadingPassword = false;
  bool _showPasswordForm = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.trim().isEmpty ||
        _newPasswordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    if (_newPasswordController.text.length < 8) {
      _showErrorSnackBar('Le mot de passe doit contenir au moins 8 caractères');
      return;
    }

    setState(() => _isLoadingPassword = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.changePassword({
        'old_password': _oldPasswordController.text.trim(),
        'new_password': _newPasswordController.text.trim(),
        'confirm_password': _confirmPasswordController.text.trim(),
      });

      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar('Mot de passe changé avec succès');
        _clearPasswordFields();
        setState(() => _showPasswordForm = false);
      } else {
        _showErrorSnackBar(
          authProvider.errorMessage ??
              'Erreur lors du changement de mot de passe',
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Erreur inattendue: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPassword = false);
    }
  }

  void _showBiometricComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité en développement'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Sécurité',
        detailTitleWidget: Text(
          'Sécurité',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ProfileParamItem(
              icon: Icons.lock_outline,
              title: 'Changer le mot de passe',
              subtitle: 'Mettre à jour vos identifiants',
              onTap: () =>
                  setState(() => _showPasswordForm = !_showPasswordForm),
            ),
            if (_showPasswordForm) _buildPasswordForm(),
            const SizedBox(height: 12),
            Opacity(
              opacity: 0.45,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: SwitchListTile(
                  value: false,
                  onChanged: (_) => _showBiometricComingSoon(),
                  title: const Text(
                    'Biométrie',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Empreinte / Face ID — bientôt disponible',
                    style: TextStyle(color: Colors.grey),
                  ),
                  secondary: Icon(
                    Icons.fingerprint,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Changer le mot de passe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            controller: _oldPasswordController,
            label: 'Ancien mot de passe',
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _newPasswordController,
            label: 'Nouveau mot de passe',
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmation',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoadingPassword ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoadingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'VALIDER',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD400)),
        ),
      ),
    );
  }
}
