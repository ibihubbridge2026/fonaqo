import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/widgets/section_title_strip.dart';
import 'package:fonaco/features/agent/presentation/dashboard/widgets/agent_boost_status_banner.dart';
import 'package:fonaco/features/agent/presentation/dashboard/widgets/agent_dashboard_quick_actions.dart';
import 'package:fonaco/features/agent/presentation/dashboard/widgets/agent_mission_strip.dart';
import 'package:fonaco/features/agent/presentation/dashboard/widgets/dashboard_header.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';
import 'package:fonaco/features/agent/widgets/shimmer_loading_card.dart';
import 'package:fonaco/widgets/main_wrapper.dart';

/// Dashboard agent : profil, actions rapides, missions en cours et disponibles.
class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    final agentProvider = context.read<AgentProvider>();
    await Future.wait([
      agentProvider.fetchWalletDetails(),
      agentProvider.fetchAvailableMissions(),
      agentProvider.fetchActiveMissions(),
      agentProvider.fetchStats(),
      agentProvider.fetchBoostData(),
      agentProvider.syncOnlineStatus(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  void _goToMissionsTab() {
    MainShellScope.maybeOf(context)?.setIndex(1);
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = context.watch<AgentProvider>();

    return RefreshIndicator(
      color: const Color(0xFFFFD400),
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: DashboardHeader(),
          ),
          const SizedBox(height: 20),
          const AgentDashboardQuickActions(),
          const SizedBox(height: 24),
          if (!_isLoading && agentProvider.isBoostActive)
            const AgentBoostStatusBanner(),
          SectionTitleStrip(
            title: 'Missions en cours',
            onSeeAllPressed: _goToMissionsTab,
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ShimmerLoadingCard(
                width: double.infinity,
                height: 160,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            )
          else
            AgentMissionStrip(
              missions: agentProvider.activeMissions,
              showAcceptButton: false,
              cardHeight: 168,
              emptyMessage:
                  'Aucune mission en cours. Acceptez une mission disponible.',
            ),
          const SizedBox(height: 24),
          SectionTitleStrip(
            title: 'Missions disponibles',
            onSeeAllPressed: _goToMissionsTab,
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 2,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, __) => const ShimmerLoadingCard(
                  width: 300,
                  height: 200,
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
              ),
            )
          else
            AgentMissionStrip(
              missions: agentProvider.availableMissions.take(8).toList(),
              cardHeight: 210,
              onRefreshAfterConflict: _loadDashboard,
              onMissionAccepted: _loadDashboard,
            ),
        ],
      ),
    );
  }
}
