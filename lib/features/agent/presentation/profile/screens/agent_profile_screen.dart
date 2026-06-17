import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/widgets/profile/profile_widgets.dart';
import 'package:fonaco/features/agent/presentation/profile/screens/agent_help_center_screen.dart';
import 'package:fonaco/features/agent/presentation/profile/screens/agent_security_settings_screen.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';
import 'package:fonaco/features/client/profile/screens/notifications_settings_screen.dart';
import 'package:go_router/go_router.dart';

/// Profil agent — stats, KYC, paramètres agent.
class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<AgentProvider>().fetchStats();
    final profile =
        await context.read<AgentProvider>().profileRepository.getProfile();
    if (mounted) setState(() => _profileData = profile);
  }

  int _kycProgress(String? status) {
    final hasId = _profileData['id_card_photo'] != null &&
        _profileData['id_card_photo'].toString().isNotEmpty;
    final hasSelfie = _profileData['selfie_photo'] != null &&
        _profileData['selfie_photo'].toString().isNotEmpty;

    if (status == 'APPROVED') return 100;
    if (hasId && hasSelfie) return 75;
    if (hasId || hasSelfie) return 50;
    return 25;
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final agentProvider = context.read<AgentProvider>();

    await authProvider.logout();
    agentProvider.reset();

    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final stats = context.watch<AgentProvider>().stats;
    final kyc = user?.kycStatus ?? 'PENDING';
    final kycProgress = _kycProgress(kyc);
    final rating = stats['average_rating'] ?? stats['avg_rating'] ?? '—';
    final disputes = stats['disputes_count'] ?? stats['open_disputes'] ?? 0;
    final reviews = stats['reviews_count'] ?? stats['total_reviews'] ?? 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const ProfileHeader(editRoute: AppRoutes.agentProfilePersonalInfo),
          const SizedBox(height: 16),
          if (kyc != 'APPROVED')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _KycWarningBanner(progress: kycProgress, status: kyc),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Avis',
                    value: '$reviews',
                    icon: Icons.star_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Note moy.',
                    value: '$rating',
                    icon: Icons.thumb_up_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Litiges',
                    value: '$disputes',
                    icon: Icons.gavel_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _ProfilePanel(
                  title: 'Vérification KYC',
                  subtitle: 'Pièce d\'identité et selfie',
                  initiallyExpanded: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil complété à $kycProgress%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: kycProgress / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF2EC4B6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Soumettez votre pièce d\'identité (CNI ou passeport) '
                        'et un selfie pour valider votre compte agent.',
                        style: TextStyle(height: 1.45),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.agentKycSubmit),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Soumettre mes documents'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _ProfilePanel(
                  title: 'Performance',
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Missions complétées',
                        value: '${stats['completed_missions'] ?? 0}',
                      ),
                      _InfoRow(
                        label: 'Gains totaux',
                        value: '${stats['total_earnings'] ?? 0} FCFA',
                      ),
                      _InfoRow(label: 'Note moyenne', value: '$rating'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _ProfilePanel(
                  title: 'Paramètres',
                  child: Column(
                    children: [
                      ProfileParamItem(
                        icon: Icons.rocket_launch_outlined,
                        title: 'Booster mon profil',
                        subtitle: 'Priorité missions + visibilité',
                        onTap: () =>
                            context.push(AppRoutes.agentBoost),
                      ),
                      ProfileParamItem(
                        icon: Icons.person_outline,
                        title: 'Informations personnelles',
                        subtitle: 'Compétences, contact, zone...',
                        onTap: () => context.push(AppRoutes.agentProfilePersonalInfo,
                        ),
                      ),
                      ProfileParamItem(
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        subtitle: 'Alertes missions, paiements, boost',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsSettingsScreen(),
                          ),
                        ),
                      ),
                      ProfileParamItem(
                        icon: Icons.security,
                        title: 'Sécurité',
                        subtitle: 'Mot de passe, biométrie',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AgentSecuritySettingsScreen(),
                          ),
                        ),
                      ),
                      ProfileParamItem(
                        icon: Icons.help_outline,
                        title: 'Centre d\'aide Agent',
                        subtitle: 'FAQ missions, KYC, litiges',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AgentHelpCenterScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ProfileParamItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              subtitle: 'Quitter l\'application',
              isLogout: true,
              onTap: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _KycWarningBanner extends StatelessWidget {
  final int progress;
  final String status;

  const _KycWarningBanner({required this.progress, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == 'REJECTED'
                      ? 'KYC refusé — soumettez à nouveau vos documents'
                      : 'Profil incomplet ($progress%)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Votre KYC doit être approuvé à 100% pour accepter des missions.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePanel extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  const _ProfilePanel({
    required this.title,
    this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<_ProfilePanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE0B800), size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
