import 'package:flutter/material.dart';

import '../../../widgets/custom_app_bar.dart';

/// Paramètres de sécurité (mot de passe, biométrie).
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        detailTitleWidget: Text('Sécurité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
              ),
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Changer le mot de passe', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Mettre à jour vos identifiants', style: TextStyle(color: Colors.grey)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
              ),
              child: SwitchListTile(
                activeThumbColor: const Color(0xFFFFD400),
                value: _biometricEnabled,
                onChanged: (v) => setState(() => _biometricEnabled = v),
                title: const Text('Biométrie', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Empreinte / FaceID', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

