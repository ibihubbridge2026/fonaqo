import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';

/// Écran de verrouillage KYC — accès dashboard bloqué tant que non APPROVED.
class KycLockScreen extends StatelessWidget {
  const KycLockScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final agent = context.read<AgentProvider>();
    await auth.logout();
    agent.reset();
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kycStatus = auth.currentUser?.kycStatus ?? 'PENDING';
    final isRejected = kycStatus == 'REJECTED';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isRejected
                      ? Colors.red.shade50
                      : const Color(0xFFFFF6D8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.block : Icons.hourglass_top_rounded,
                  size: 44,
                  color: isRejected ? Colors.red : const Color(0xFFC79A00),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isRejected
                    ? 'Compte refusé'
                    : 'Validation en cours',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isRejected
                    ? 'Votre dossier KYC a été rejeté. Contactez le support FONAQO ou soumettez à nouveau vos documents.'
                    : 'Compte en attente de validation par l\'administration FONAQO. Vous pourrez accepter des missions dès approbation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _ProgressSteps(isRejected: isRejected),
              const Spacer(),
              if (isRejected || kycStatus == 'PENDING') ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.agentKycSubmit),
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      isRejected
                          ? 'Soumettre à nouveau mes documents'
                          : 'Soumettre mes documents',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  final bool isRejected;

  const _ProgressSteps({required this.isRejected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _step('Inscription', true),
          _step('Documents KYC', !isRejected),
          _step('Approbation admin', false, isLast: true),
        ],
      ),
    );
  }

  Widget _step(String label, bool done, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? Colors.green : Colors.grey.shade400,
              size: 22,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                color: done ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
