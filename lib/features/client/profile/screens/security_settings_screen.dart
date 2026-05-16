import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:fonaco/widgets/custom_app_bar.dart';
import 'package:fonaco/core/providers/auth_provider.dart';

/// Paramètres de sécurité (mot de passe, PIN, biométrie).
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _biometricEnabled = false;
  bool _pinEnabled = false;

  // Password change controllers
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // PIN setup controllers
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isLoadingPassword = false;
  bool _isLoadingPin = false;
  bool _showPasswordForm = false;
  bool _showPinForm = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final biometric = await _secureStorage.read(key: 'biometric_enabled');
    final pin = await _secureStorage.read(key: 'transaction_pin');

    setState(() {
      _biometricEnabled = biometric == 'true';
      _pinEnabled = pin != null && pin.isNotEmpty;
    });

    // Check biometric availability
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    if (!canCheckBiometrics && mounted) {
      setState(() {
        _biometricEnabled = false;
      });
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
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

    setState(() {
      _isLoadingPassword = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.changePassword({
        'old_password': _oldPasswordController.text.trim(),
        'new_password': _newPasswordController.text.trim(),
        'confirm_password': _confirmPasswordController.text.trim(),
      });

      if (mounted) {
        if (success) {
          _showSuccessSnackBar('Mot de passe changé avec succès');
          _clearPasswordFields();
          setState(() {
            _showPasswordForm = false;
          });
        } else {
          _showErrorSnackBar(
            authProvider.errorMessage ??
                'Erreur lors du changement de mot de passe',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur inattendue: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPassword = false;
        });
      }
    }
  }

  Future<void> _setupPin() async {
    if (_pinController.text.trim().isEmpty ||
        _confirmPinController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs');
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      _showErrorSnackBar('Les codes PIN ne correspondent pas');
      return;
    }

    if (_pinController.text.length != 4 || !_isNumeric(_pinController.text)) {
      _showErrorSnackBar('Le PIN doit contenir exactement 4 chiffres');
      return;
    }

    setState(() {
      _isLoadingPin = true;
    });

    try {
      await _secureStorage.write(
        key: 'transaction_pin',
        value: _pinController.text,
      );

      setState(() {
        _pinEnabled = true;
        _showPinForm = false;
        _isLoadingPin = false;
      });

      _showSuccessSnackBar('Code PIN configuré avec succès');
      _clearPinFields();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la configuration du PIN: $e');
        setState(() {
          _isLoadingPin = false;
        });
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!value) {
      await _secureStorage.write(key: 'biometric_enabled', value: 'false');
      setState(() {
        _biometricEnabled = false;
      });
      return;
    }

    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Activer l\'authentification biométrique',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await _secureStorage.write(key: 'biometric_enabled', value: 'true');
        setState(() {
          _biometricEnabled = true;
        });
        _showSuccessSnackBar('Authentification biométrique activée');
      }
    } catch (e) {
      _showErrorSnackBar('Échec de l\'authentification biométrique');
    }
  }

  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _clearPinFields() {
    _pinController.clear();
    _confirmPinController.clear();
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

  bool _isNumeric(String str) {
    return str.isNotEmpty && int.tryParse(str) != null;
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
            // Password Change Section
            ProfileParamItem(
              icon: Icons.lock_outline,
              title: "Changer le mot de passe",
              subtitle: "Mettre à jour vos identifiants",
              onTap: () =>
                  setState(() => _showPasswordForm = !_showPasswordForm),
            ),

            if (_showPasswordForm) _buildPasswordForm(),

            const SizedBox(height: 12),

            // PIN Setup Section
            ProfileParamItem(
              icon: Icons.pin,
              title: "Code PIN de transaction",
              subtitle: _pinEnabled
                  ? "PIN configuré"
                  : "Configurer un code à 4 chiffres",
              onTap: () => setState(() => _showPinForm = !_showPinForm),
            ),

            if (_showPinForm) _buildPinForm(),

            const SizedBox(height: 12),

            // Biometric Section
            Container(
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
                activeThumbColor: const Color(0xFFFFD400),
                value: _biometricEnabled,
                onChanged: _toggleBiometric,
                title: const Text(
                  'Biométrie',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Empreinte / FaceID',
                  style: TextStyle(color: Colors.black),
                ),
                secondary: const Icon(
                  Icons.fingerprint,
                  color: Color(0xFFFFD400),
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
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _newPasswordController,
            label: 'Nouveau mot de passe',
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmation',
            isPassword: true,
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

  Widget _buildPinForm() {
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
          Text(
            _pinEnabled ? 'Modifier le code PIN' : 'Configurer le code PIN',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ce code sera demandé pour valider les paiements de missions',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            controller: _pinController,
            label: 'Code PIN (4 chiffres)',
            isPassword: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPinController,
            label: 'Confirmation du PIN',
            isPassword: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoadingPin ? null : _setupPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoadingPin
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
    required bool isPassword,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLength: maxLength,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD400)),
        ),
        counterText: maxLength != null ? '' : null,
      ),
    );
  }
}

/// Élément de menu dans Paramètres de sécurité.
/// Utilise le même style que ProfileParamItem pour la cohérence UI.
class ProfileParamItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ProfileParamItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
