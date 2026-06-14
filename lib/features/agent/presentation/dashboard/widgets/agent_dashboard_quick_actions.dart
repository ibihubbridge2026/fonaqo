import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';
import 'package:fonaco/widgets/main_wrapper.dart';

/// Boutons d'action rapide sur le dashboard agent.
class AgentDashboardQuickActions extends StatefulWidget {
  const AgentDashboardQuickActions({super.key});

  @override
  State<AgentDashboardQuickActions> createState() =>
      _AgentDashboardQuickActionsState();
}

class _AgentDashboardQuickActionsState extends State<AgentDashboardQuickActions> {
  bool _downloadingReport = false;

  Future<void> _downloadReport() async {
    setState(() => _downloadingReport = true);
    try {
      final path = await context
          .read<AgentProvider>()
          .missionRepository
          .downloadMonthlyReport(
            month: DateTime.now().month,
            year: DateTime.now().year,
          );
      if (!mounted) return;
      if (path != null) {
        await OpenFile.open(path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relevé mensuel téléchargé'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de télécharger le relevé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionIcon(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Relevé',
            loading: _downloadingReport,
            onTap: _downloadingReport ? null : _downloadReport,
          ),
          _ActionIcon(
            icon: Icons.rocket_launch_outlined,
            label: 'Booster',
            onTap: () => Navigator.pushNamed(context, AppRoutes.agentBoost),
          ),
          _ActionIcon(
            icon: Icons.description_outlined,
            label: 'Contrat',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Téléchargement contrat — bientôt disponible'),
                ),
              );
            },
          ),
          _ActionIcon(
            icon: Icons.add_circle_outline,
            label: 'Recharger',
            onTap: () {
              final shell = MainShellScope.maybeOf(context);
              shell?.setIndex(3);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _ActionIcon({
    required this.icon,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFFD400),
                    ),
                  )
                : Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
