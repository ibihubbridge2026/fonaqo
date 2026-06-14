import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/config/app_configuration.dart';
import 'package:fonaco/core/widgets/profile/profile_widgets.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';

/// Sécurité agent — mot de passe et biométrie (sans code PIN).
class AgentSecuritySettingsScreen extends StatefulWidget {
  const AgentSecuritySettingsScreen({super.key});

  @override
  State<AgentSecuritySettingsScreen> createState() =>
      _AgentSecuritySettingsScreenState();
}

class _AgentSecuritySettingsScreenState
    extends State<AgentSecuritySettingsScreen> {
  final _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  bool _showPasswordForm = false;
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().changePassword({
          'old_password': _oldPassword.text,
          'new_password': _newPassword.text,
        });
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Mot de passe mis à jour' : 'Échec de la modification',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok) {
      setState(() => _showPasswordForm = false);
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    }
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ProfileParamItem(
            icon: Icons.lock_outline,
            title: 'Changer le mot de passe',
            subtitle: 'Mettre à jour votre accès',
            onTap: () => setState(() => _showPasswordForm = !_showPasswordForm),
          ),
          if (_showPasswordForm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _oldPassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Connexion biométrique'),
            subtitle: const Text('Empreinte ou Face ID'),
            value: _biometricEnabled,
            activeThumbColor: kAgentSuccessGreen,
            activeTrackColor: kAgentSuccessGreen.withValues(alpha: 0.4),
            onChanged: (v) async {
              if (v) {
                final can = await _localAuth.canCheckBiometrics;
                if (!can && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biométrie non disponible'),
                    ),
                  );
                  return;
                }
              }
              setState(() => _biometricEnabled = v);
            },
          ),
        ],
      ),
    );
  }
}
