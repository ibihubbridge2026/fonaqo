import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fonaco/core/config/app_configuration.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Écran bloquant affiché lorsque le compte est suspendu (403 ACCOUNT_SUSPENDED).
class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({super.key});

  Future<void> _contactPhone() async {
    final phone = AppConfiguration.instance.clientServicePhone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _contactEmail() async {
    final uri = Uri.parse('mailto:${AppConfiguration.instance.agentSupportEmail}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade400, width: 2),
                ),
                child: const Icon(Icons.block, size: 44, color: Colors.red),
              ),
              const SizedBox(height: 24),
              const Text(
                'Compte suspendu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                context.watch<AuthProvider>().errorMessage ??
                    'Votre compte a été temporairement suspendu par l\'administration FONACO. '
                        'Contactez le support pour faire appel de cette décision.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  height: 1.55,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _contactPhone,
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler le support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD100),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _contactEmail,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Envoyer un email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                child: const Text(
                  'Retour à la connexion',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
